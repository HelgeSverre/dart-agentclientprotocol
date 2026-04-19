import 'dart:async';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// Unsupported fallback for [WebSocketTransport] on non-`dart:io` platforms.
final class WebSocketTransport implements AcpTransport {
  /// Always throws because the IO WebSocket transport requires `dart:io`.
  WebSocketTransport(Object socket) {
    throw UnsupportedError(
      'WebSocketTransport is only available on dart:io platforms',
    );
  }

  /// Always throws because the IO WebSocket transport requires `dart:io`.
  static Future<WebSocketTransport> connect(
    Uri url, {
    Map<String, String>? headers,
    Iterable<String>? protocols,
  }) =>
      throw UnsupportedError(
        'WebSocketTransport is only available on dart:io platforms',
      );

  @override
  Stream<JsonRpcMessage> get messages =>
      throw UnsupportedError(
        'WebSocketTransport is only available on dart:io platforms',
      );

  @override
  Future<void> send(JsonRpcMessage message) =>
      throw UnsupportedError(
        'WebSocketTransport is only available on dart:io platforms',
      );

  @override
  Future<void> close() =>
      throw UnsupportedError(
        'WebSocketTransport is only available on dart:io platforms',
      );
}
