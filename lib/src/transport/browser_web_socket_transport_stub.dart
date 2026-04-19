import 'dart:async';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

final class BrowserWebSocketTransport implements AcpTransport {
  static Future<BrowserWebSocketTransport> connect(Uri url) =>
      throw UnsupportedError('BrowserWebSocketTransport is only available in browser environments');

  @override
  Stream<JsonRpcMessage> get messages => throw UnsupportedError('BrowserWebSocketTransport is only available in browser environments');

  @override
  Future<void> send(JsonRpcMessage message) => throw UnsupportedError('BrowserWebSocketTransport is only available in browser environments');

  @override
  Future<void> close() => throw UnsupportedError('BrowserWebSocketTransport is only available in browser environments');
}
