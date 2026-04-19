import 'dart:async';
import 'dart:collection';

import 'package:acp/src/protocol/acp_methods.dart';
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
  final Duration? _keepaliveInterval;
  final Duration? _keepaliveTimeout;
  Timer? _keepaliveTimer;
  DateTime? _lastPong;
  Timer? _keepaliveTimeoutTimer;

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
  final Map<Object, AcpCancellationSource> _activeIncomingRequests =
      <Object, AcpCancellationSource>{};

  // Extension fallback handlers
  RequestHandler? _extensionRequestHandler;
  NotificationHandler? _extensionNotificationHandler;

  // Write queue
  final Queue<_WriteEntry> _writeQueue = Queue<_WriteEntry>();
  bool _draining = false;

  // Resolved when the current drain finishes; null when the queue is
  // already empty. Lets `_waitForWriteQueueDrain` block on a real signal
  // instead of polling.
  Completer<void>? _drainCompleter;

  // Warnings stream
  final StreamController<ProtocolWarning> _warningController =
      StreamController<ProtocolWarning>.broadcast();

  // Transport subscription
  StreamSubscription<JsonRpcMessage>? _transportSubscription;

  // Re-entry guard for _cleanup. Set as soon as the first invocation enters
  // the cleanup body; later invocations (e.g. from a transport error firing
  // during graceful close drain) early-return rather than racing the same
  // controllers and pending requests.
  bool _cleaningUp = false;

  /// Optional callback invoked before each outgoing message is written.
  void Function(Map<String, dynamic> message)? onSend;

  /// Optional callback invoked after each incoming message is read.
  void Function(Map<String, dynamic> message)? onReceive;

  /// Creates a connection over [transport].
  ///
  /// [defaultTimeout] controls how long [sendRequest] waits for a response
  /// before throwing [RequestTimeoutException]. Defaults to 60 seconds.
  ///
  /// [keepaliveInterval] enables periodic ping notifications when set.
  /// [keepaliveTimeout] sets the maximum time to wait for a pong before
  /// closing the connection.
  Connection(
    this._transport, {
    Duration defaultTimeout = const Duration(seconds: 60),
    Duration? keepaliveInterval,
    Duration? keepaliveTimeout,
  }) : _defaultTimeout = defaultTimeout,
       _keepaliveInterval = keepaliveInterval,
       _keepaliveTimeout = keepaliveTimeout {
    _notificationHandlers[AcpMethods.ping] = _handlePing;
    _notificationHandlers[AcpMethods.pong] = _handlePong;
    _notificationHandlers[AcpMethods.cancelRequest] = _handleCancelRequest;
  }

  /// The timestamp of the last received pong, or `null` if no pong received.
  DateTime? get lastPong => _lastPong;

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
    _startKeepalive();
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

    // Per-request cancellation source. Forwarded cancellations from the
    // caller's token complete this source instead of subscribing directly to
    // `whenCanceled`, so when the request finishes normally we cancel the
    // local source and the listener closure is released for GC.
    final localCancel = AcpCancellationSource();
    StreamSubscription<void>? cancelForwarder;

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
        localCancel.cancel('Request timed out');
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
      // Forward the caller's cancel into the per-request source. Once the
      // request completes (success/error/timeout), cancelling the local
      // source resolves `whenCanceled` and the closure can be GC'd.
      cancelForwarder = cancelToken.whenCanceled.asStream().listen((_) {
        if (!localCancel.token.isCanceled) {
          localCancel.cancel('Cancelled by caller');
        }
      });
    }

    unawaited(
      localCancel.token.whenCanceled.then((_) {
        final removed = _pendingRequests.remove(id);
        if (removed == null) return;
        removed.timer.cancel();
        if (!removed.completer.isCompleted) {
          unawaited(_notifyCancelRequest(id));
          removed.completer.completeError(RequestCanceledException(id));
        }
      }),
    );

    try {
      await _enqueueWrite(request);
      return await completer.future;
    } finally {
      if (!localCancel.token.isCanceled) {
        localCancel.cancel('Request completed');
      }
      await cancelForwarder?.cancel();
    }
  }

  /// Sends a JSON-RPC notification (no response expected).
  Future<void> notify(String method, [Map<String, dynamic>? params]) async {
    _ensureCanSend();
    final notification = JsonRpcNotification(method: method, params: params);
    await _enqueueWrite(notification);
  }

  /// Sends multiple JSON-RPC notifications as a batch.
  ///
  /// All notifications are enqueued to the write queue in order and
  /// sent sequentially. This is a convenience method for sending
  /// multiple related notifications together.
  Future<void> sendNotifications(
    List<(String method, Map<String, dynamic>? params)> notifications,
  ) async {
    _ensureCanSend();
    for (final (method, params) in notifications) {
      final notification = JsonRpcNotification(method: method, params: params);
      await _enqueueWrite(notification);
    }
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
      final waiter = _drainCompleter;
      _drainCompleter = null;
      waiter?.complete();
    }
  }

  Future<void> _waitForWriteQueueDrain() {
    if (!_draining && _writeQueue.isEmpty) return Future<void>.value();
    final completer = _drainCompleter ??= Completer<void>();
    return completer.future;
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
    _activeIncomingRequests[request.id] = cancelSource;
    unawaited(_runHandler(request, handler, cancelSource.token));
  }

  Future<void> _runHandler(
    JsonRpcRequest request,
    RequestHandler handler,
    AcpCancellationToken cancelToken,
  ) async {
    try {
      final result = await handler(request, cancelToken);
      if (cancelToken.isCanceled) {
        await _sendErrorResponse(
          request.id,
          RpcErrorException.requestCancelled(),
        );
      } else {
        await sendResponse(JsonRpcResponse(id: request.id, result: result));
      }
    } on RpcErrorException catch (e) {
      await _sendErrorResponse(request.id, e);
    } on CanceledException {
      await _sendErrorResponse(
        request.id,
        RpcErrorException.requestCancelled(),
      );
    } on Object catch (e, stack) {
      _log.severe('Handler error for ${request.method}', e, stack);
      // Send a generic message to the peer — exception toString() can leak
      // file paths, query fragments, environment values, or internal class
      // names. Keep detail in the local log only.
      await _sendErrorResponse(
        request.id,
        RpcErrorException.internalError('Internal server error'),
      );
    } finally {
      _activeIncomingRequests.remove(request.id);
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
      if (result is Map<String, dynamic>) {
        pending.completer.complete(result);
      } else {
        // ACP responses are always JSON objects. A scalar/null/array result
        // would be silently discarded if coerced to {}, so surface the
        // protocol violation to the caller instead of returning fake-empty.
        pending.completer.completeError(
          RpcErrorException.internalError(
            'Expected response result to be a JSON object, '
            'got ${result.runtimeType}',
          ),
        );
      }
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

  void _startKeepalive() {
    final interval = _keepaliveInterval;
    if (interval == null) return;
    _keepaliveTimer = Timer.periodic(interval, (_) {
      if (_state != ConnectionState.open) return;
      unawaited(notify(AcpMethods.ping));
      _startKeepaliveTimeout();
    });
  }

  void _startKeepaliveTimeout() {
    final timeout = _keepaliveTimeout;
    if (timeout == null) return;
    _keepaliveTimeoutTimer?.cancel();
    _keepaliveTimeoutTimer = Timer(timeout, () {
      _log.warning('Keepalive timeout — no pong received');
      unawaited(_cleanup());
    });
  }

  void _stopKeepalive() {
    _keepaliveTimer?.cancel();
    _keepaliveTimer = null;
    _keepaliveTimeoutTimer?.cancel();
    _keepaliveTimeoutTimer = null;
  }

  Future<void> _handlePing(JsonRpcNotification notification) async {
    await notify(AcpMethods.pong);
  }

  Future<void> _handlePong(JsonRpcNotification notification) async {
    _lastPong = DateTime.now();
    _keepaliveTimeoutTimer?.cancel();
    _keepaliveTimeoutTimer = null;
  }

  Future<void> _handleCancelRequest(JsonRpcNotification notification) async {
    final requestId = notification.params?['requestId'];
    if (requestId is! String && requestId is! int) {
      return;
    }
    _activeIncomingRequests[requestId]?.cancel('Cancelled by peer');
  }

  Future<void> _notifyCancelRequest(Object requestId) async {
    try {
      await notify(AcpMethods.cancelRequest, <String, dynamic>{
        'requestId': requestId,
      });
    } on Object catch (e) {
      _log.fine('Failed to notify request cancellation for $requestId: $e');
    }
  }

  Future<void> _cleanup() async {
    if (_state == ConnectionState.closed || _cleaningUp) return;
    _cleaningUp = true;

    _stopKeepalive();

    await _transportSubscription?.cancel();
    _transportSubscription = null;

    // Cancel in-flight incoming request handlers.
    for (final source in _activeIncomingRequests.values) {
      source.cancel('Connection closed');
    }
    _activeIncomingRequests.clear();

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
