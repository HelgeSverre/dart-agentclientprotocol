import 'dart:async';
import 'dart:collection';

import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/protocol/protocol_warning.dart';
import 'package:acp/src/protocol/request_id_allocator.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.protocol.connection');

/// Signature for a handler that processes an incoming JSON-RPC request
/// and returns a result map.
typedef RequestHandler =
    Future<Map<String, dynamic>> Function(
      JsonRpcRequest request,
      AcpCancellationToken cancelToken,
    );

/// Signature for a handler that processes an incoming JSON-RPC notification.
typedef NotificationHandler =
    Future<void> Function(JsonRpcNotification notification);

/// JSON-RPC connection state machine with request correlation, timeouts,
/// and write serialization.
///
/// [Connection] wraps an [AcpTransport] and adds:
/// - Request/response correlation with configurable timeouts.
/// - A single-writer queue to prevent interleaved writes.
/// - Connection lifecycle management (idle → opening → open → closing → closed).
/// - Tracing hooks for observability.
///
/// Both `AgentSideConnection` and `ClientSideConnection` wrap a [Connection].
final class Connection {
  final AcpTransport _transport;
  final RequestIdAllocator _idAllocator = RequestIdAllocator();
  final Duration _defaultTimeout;

  // State machine
  ConnectionState _state = ConnectionState.idle;
  final StreamController<ConnectionState> _stateController =
      StreamController<ConnectionState>.broadcast();

  // Pending outgoing requests awaiting responses
  final Map<Object, _PendingRequest> _pendingRequests =
      <Object, _PendingRequest>{};

  // Incoming message handlers
  final Map<String, RequestHandler> _requestHandlers =
      <String, RequestHandler>{};
  final Map<String, NotificationHandler> _notificationHandlers =
      <String, NotificationHandler>{};

  // Extension fallback handlers
  RequestHandler? _extensionRequestHandler;
  NotificationHandler? _extensionNotificationHandler;

  // Write queue
  final Queue<_WriteEntry> _writeQueue = Queue<_WriteEntry>();
  bool _draining = false;

  // Warnings stream
  final StreamController<ProtocolWarning> _warningController =
      StreamController<ProtocolWarning>.broadcast();

  // Transport subscription
  StreamSubscription<JsonRpcMessage>? _transportSubscription;

  /// Optional callback invoked before each outgoing message is written.
  void Function(Map<String, dynamic> message)? onSend;

  /// Optional callback invoked after each incoming message is read.
  void Function(Map<String, dynamic> message)? onReceive;

  /// Creates a connection over [transport].
  ///
  /// [defaultTimeout] controls how long [sendRequest] waits for a response
  /// before throwing [RequestTimeoutException]. Defaults to 60 seconds.
  Connection(
    this._transport, {
    Duration defaultTimeout = const Duration(seconds: 60),
  }) : _defaultTimeout = defaultTimeout;

  /// The current connection state.
  ConnectionState get state => _state;

  /// A stream of connection state changes.
  Stream<ConnectionState> get onStateChange => _stateController.stream;

  /// A stream of non-fatal protocol warnings.
  Stream<ProtocolWarning> get warnings => _warningController.stream;

  /// Registers a handler for incoming requests with [method].
  void setRequestHandler(String method, RequestHandler handler) {
    _requestHandlers[method] = handler;
  }

  /// Registers a handler for incoming notifications with [method].
  void setNotificationHandler(String method, NotificationHandler handler) {
    _notificationHandlers[method] = handler;
  }

  /// Registers a fallback handler for extension requests (methods starting
  /// with `_`).
  void setExtensionRequestHandler(RequestHandler handler) {
    _extensionRequestHandler = handler;
  }

  /// Registers a fallback handler for extension notifications (methods
  /// starting with `_`).
  void setExtensionNotificationHandler(NotificationHandler handler) {
    _extensionNotificationHandler = handler;
  }

  /// Starts the connection by subscribing to the transport's message stream.
  ///
  /// Transitions from [ConnectionState.idle] to [ConnectionState.opening].
  void start() {
    if (_state != ConnectionState.idle) {
      throw StateError('Connection is not idle (current state: $_state)');
    }
    _transition(ConnectionState.opening);

    _transportSubscription = _transport.messages.listen(
      _handleIncomingMessage,
      onError: _handleTransportError,
      onDone: _handleTransportDone,
    );
  }

  /// Marks the connection as fully open.
  ///
  /// Call this after the initialization handshake completes.
  void markOpen() {
    if (_state != ConnectionState.opening) {
      throw StateError(
        'Cannot mark open: connection is not opening (current state: $_state)',
      );
    }
    _transition(ConnectionState.open);
  }

  /// Sends a JSON-RPC request and waits for the response.
  ///
  /// Returns the response result as a map. Throws [RpcErrorException] if the
  /// response is an error, [RequestTimeoutException] if [timeout] elapses,
  /// or [RequestCanceledException] if [cancelToken] is canceled.
  Future<Map<String, dynamic>> sendRequest(
    String method,
    Map<String, dynamic>? params, {
    Duration? timeout,
    AcpCancellationToken? cancelToken,
  }) async {
    _ensureCanSend();

    final id = _idAllocator.next();
    final request = JsonRpcRequest(id: id, method: method, params: params);
    final completer = Completer<Map<String, dynamic>>();
    final effectiveTimeout = timeout ?? _defaultTimeout;

    final pending = _PendingRequest(
      completer: completer,
      method: method,
      timer: Timer(effectiveTimeout, () {
        final removed = _pendingRequests.remove(id);
        if (removed != null && !removed.completer.isCompleted) {
          removed.completer.completeError(
            RequestTimeoutException(id, effectiveTimeout),
          );
        }
      }),
    );

    _pendingRequests[id] = pending;

    // Handle cancellation
    if (cancelToken != null) {
      if (cancelToken.isCanceled) {
        _pendingRequests.remove(id);
        pending.timer.cancel();
        throw RequestCanceledException(id, 'Already canceled');
      }
      unawaited(
        cancelToken.whenCanceled.then((_) {
          final removed = _pendingRequests.remove(id);
          if (removed != null && !removed.completer.isCompleted) {
            removed.timer.cancel();
            removed.completer.completeError(RequestCanceledException(id));
          }
        }),
      );
    }

    await _enqueueWrite(request);
    return completer.future;
  }

  /// Sends a JSON-RPC notification (no response expected).
  Future<void> notify(String method, [Map<String, dynamic>? params]) async {
    _ensureCanSend();
    final notification = JsonRpcNotification(method: method, params: params);
    await _enqueueWrite(notification);
  }

  /// Sends a JSON-RPC response.
  Future<void> sendResponse(JsonRpcResponse response) async {
    // Responses can be sent in closing state (draining)
    if (_state == ConnectionState.closed) {
      throw ConnectionClosedException();
    }
    await _enqueueWrite(response);
  }

  /// Closes the connection with an optional [flushTimeout].
  ///
  /// 1. Transitions to [ConnectionState.closing].
  /// 2. Flushes the write queue up to [flushTimeout].
  /// 3. Closes the transport.
  /// 4. Fails all pending requests with [ConnectionClosedException].
  /// 5. Transitions to [ConnectionState.closed].
  Future<void> close({
    Duration flushTimeout = const Duration(seconds: 5),
  }) async {
    if (_state == ConnectionState.closed || _state == ConnectionState.closing) {
      return;
    }

    _transition(ConnectionState.closing);

    // Wait for write queue to drain, with timeout
    if (_writeQueue.isNotEmpty || _draining) {
      await Future.any([
        _waitForWriteQueueDrain(),
        Future<void>.delayed(flushTimeout),
      ]);
    }

    await _cleanup();
  }

  void _ensureCanSend() {
    if (_state == ConnectionState.closing || _state == ConnectionState.closed) {
      throw ConnectionClosedException();
    }
    if (_state == ConnectionState.idle) {
      throw StateError('Connection has not been started');
    }
  }

  void _transition(ConnectionState newState) {
    _log.fine('Connection state: $_state → $newState');
    _state = newState;
    _stateController.add(newState);
  }

  Future<void> _enqueueWrite(JsonRpcMessage message) {
    final completer = Completer<void>();
    _writeQueue.add(_WriteEntry(message, completer));
    _drainWriteQueue();
    return completer.future;
  }

  void _drainWriteQueue() {
    if (_draining) return;
    _draining = true;
    unawaited(_doDrain());
  }

  Future<void> _doDrain() async {
    try {
      while (_writeQueue.isNotEmpty) {
        final entry = _writeQueue.removeFirst();
        try {
          final json = entry.message.toJson();
          onSend?.call(json);
          await _transport.send(entry.message);
          entry.completer.complete();
        } on Object catch (e, stack) {
          _log.severe('Transport write error', e, stack);
          entry.completer.completeError(TransportException('Write failed', e));
          // Write error → close connection
          await _cleanup();
          return;
        }
      }
    } finally {
      _draining = false;
    }
  }

  Future<void> _waitForWriteQueueDrain() async {
    while (_writeQueue.isNotEmpty || _draining) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  void _handleIncomingMessage(JsonRpcMessage message) {
    onReceive?.call(message.toJson());

    switch (message) {
      case JsonRpcRequest():
        _handleIncomingRequest(message);
      case JsonRpcResponse():
        _handleIncomingResponse(message);
      case JsonRpcNotification():
        _handleIncomingNotification(message);
    }
  }

  void _handleIncomingRequest(JsonRpcRequest request) {
    final method = request.method;
    var handler = _requestHandlers[method];

    // Extension method dispatch: methods starting with _ go to extension
    // handler
    if (handler == null && method.startsWith('_')) {
      handler = _extensionRequestHandler;
    }

    if (handler == null) {
      _log.warning('No handler for method: $method');
      unawaited(
        _sendErrorResponse(
          request.id,
          RpcErrorException.methodNotFound('Method not found: $method'),
        ),
      );
      return;
    }

    final cancelSource = AcpCancellationSource();
    unawaited(_runHandler(request, handler, cancelSource.token));
  }

  Future<void> _runHandler(
    JsonRpcRequest request,
    RequestHandler handler,
    AcpCancellationToken cancelToken,
  ) async {
    try {
      final result = await handler(request, cancelToken);
      await sendResponse(JsonRpcResponse(id: request.id, result: result));
    } on RpcErrorException catch (e) {
      await _sendErrorResponse(request.id, e);
    } on Object catch (e, stack) {
      _log.severe('Handler error for ${request.method}', e, stack);
      await _sendErrorResponse(
        request.id,
        RpcErrorException.internalError(e.toString()),
      );
    }
  }

  Future<void> _sendErrorResponse(Object id, RpcErrorException error) async {
    try {
      await sendResponse(
        JsonRpcResponse(
          id: id,
          error: JsonRpcError(
            code: error.code,
            message: error.message,
            data: error.data,
          ),
        ),
      );
    } on Object catch (e) {
      _log.warning('Failed to send error response: $e');
    }
  }

  void _handleIncomingResponse(JsonRpcResponse response) {
    final id = response.id;
    final pending = _pendingRequests.remove(id);

    if (pending == null) {
      // Late response — request was already timed out or canceled
      _log.fine('Late response for request $id');
      _warningController.add(ProtocolWarning.lateResponse(id ?? 'null'));
      return;
    }

    pending.timer.cancel();

    if (pending.completer.isCompleted) return;

    if (response.isError) {
      final error = response.error!;
      pending.completer.completeError(
        RpcErrorException(error.code, error.message, error.data),
      );
    } else {
      final result = response.result;
      pending.completer.complete(
        result is Map<String, dynamic> ? result : <String, dynamic>{},
      );
    }
  }

  void _handleIncomingNotification(JsonRpcNotification notification) {
    final method = notification.method;
    var handler = _notificationHandlers[method];

    // Extension notification dispatch
    if (handler == null && method.startsWith('_')) {
      handler = _extensionNotificationHandler;
    }

    if (handler == null) {
      _log.fine('No handler for notification: $method');
      return;
    }

    unawaited(
      handler(notification).catchError((Object e, StackTrace stack) {
        _log.severe('Notification handler error for $method', e, stack);
      }),
    );
  }

  void _handleTransportError(Object error, StackTrace stack) {
    _log.severe('Transport error', error, stack);
    unawaited(_cleanup());
  }

  void _handleTransportDone() {
    _log.fine('Transport stream ended (remote EOF)');
    unawaited(_cleanup());
  }

  Future<void> _cleanup() async {
    if (_state == ConnectionState.closed) return;

    await _transportSubscription?.cancel();
    _transportSubscription = null;

    // Fail all pending requests
    final pending = Map<Object, _PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    for (final entry in pending.values) {
      entry.timer.cancel();
      if (!entry.completer.isCompleted) {
        entry.completer.completeError(ConnectionClosedException());
      }
    }

    try {
      await _transport.close();
    } on Object catch (e) {
      _log.fine('Error closing transport: $e');
    }

    _transition(ConnectionState.closed);
    await _stateController.close();
    await _warningController.close();
  }
}

final class _PendingRequest {
  final Completer<Map<String, dynamic>> completer;
  final String method;
  final Timer timer;

  _PendingRequest({
    required this.completer,
    required this.method,
    required this.timer,
  });
}

final class _WriteEntry {
  final JsonRpcMessage message;
  final Completer<void> completer;

  _WriteEntry(this.message, this.completer);
}
