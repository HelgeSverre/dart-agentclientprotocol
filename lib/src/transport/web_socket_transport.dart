import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.transport.web_socket');

/// A transport that communicates via WebSocket text frames.
///
/// Each JSON-RPC message is encoded as a single JSON text frame. This
/// transport can be used for both client and server scenarios:
///
/// - Use [WebSocketTransport.connect] to establish a new outgoing connection.
/// - Use the default constructor to wrap an existing [WebSocket] (e.g. one
///   accepted by an HTTP server upgrade handler).
///
/// This transport is only available on `dart:io` platforms.
final class WebSocketTransport implements AcpTransport {
  final WebSocket _socket;
  final StreamController<JsonRpcMessage> _controller =
      StreamController<JsonRpcMessage>();
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;

  /// Creates a WebSocket transport wrapping an existing [socket].
  ///
  /// The caller is responsible for having already connected/accepted
  /// the WebSocket. Call this constructor when you have a server-side
  /// [WebSocket] obtained from [WebSocketTransformer.upgrade] or similar.
  ///
  /// Listening begins immediately upon construction.
  WebSocketTransport(WebSocket socket) : _socket = socket {
    _startListening();
  }

  /// Connects to a remote ACP agent over WebSocket.
  ///
  /// [url] is the WebSocket endpoint to connect to.
  /// [headers] are optional additional HTTP headers (e.g. for auth).
  /// [protocols] are optional WebSocket sub-protocols to request.
  static Future<WebSocketTransport> connect(
    Uri url, {
    Map<String, String>? headers,
    Iterable<String>? protocols,
  }) async {
    // Ownership transfers to WebSocketTransport which closes in close().
    // ignore: close_sinks
    final socket = await WebSocket.connect(
      url.toString(),
      headers: headers,
      protocols: protocols,
    );
    _log.fine('WebSocket connection established to $url');
    return WebSocketTransport(socket);
  }

  void _startListening() {
    _subscription = _socket.listen(
      _handleFrame,
      onError: (Object error, StackTrace stack) {
        if (_closed) return;
        _log.severe('WebSocket stream error', error, stack);
        _controller.addError(error, stack);
        unawaited(close());
      },
      onDone: () {
        _log.fine('WebSocket stream ended');
        if (!_closed) unawaited(close());
      },
    );
  }

  void _handleFrame(dynamic frame) {
    if (frame is! String) {
      _log.warning('Ignoring non-String WebSocket frame: ${frame.runtimeType}');
      return;
    }

    try {
      final json = jsonDecode(frame) as Map<String, dynamic>;
      final message = JsonRpcMessage.fromJson(json);
      _controller.add(message);
    } on FormatException catch (e, stack) {
      _log.warning('Failed to parse WebSocket message: $e');
      _controller.addError(e, stack);
    }
  }

  /// The WebSocket close code received from the remote side, or `null` if
  /// the connection has not been closed.
  int? get closeCode => _socket.closeCode;

  /// The WebSocket close reason received from the remote side, or `null` if
  /// the connection has not been closed.
  String? get closeReason => _socket.closeReason;

  @override
  Stream<JsonRpcMessage> get messages => _controller.stream;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) {
      throw StateError('Cannot send on a closed transport');
    }
    final body = jsonEncode(message.toJson());
    _socket.add(body);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // Close the WebSocket first to signal the remote side.
    try {
      await _socket.close();
    } on Object {
      // Connection may already be closed by the remote side.
    }
    // Cancel the subscription with a timeout — it may block if the
    // underlying stream is in an intermediate state.
    if (_subscription != null) {
      await _subscription!.cancel().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
      _subscription = null;
    }
    unawaited(_controller.close());
    _log.fine('Transport closed');
  }
}
