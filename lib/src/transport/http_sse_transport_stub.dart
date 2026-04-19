import 'dart:async';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

final class HttpSseTransport implements AcpTransport {
  static Future<HttpSseTransport> connect(Uri sseUri, Uri messageUri, {Map<String, String>? headers}) =>
      throw UnsupportedError('HttpSseTransport is only available on dart:io platforms');

  @override
  Stream<JsonRpcMessage> get messages => throw UnsupportedError('HttpSseTransport is only available on dart:io platforms');

  @override
  Future<void> send(JsonRpcMessage message) => throw UnsupportedError('HttpSseTransport is only available on dart:io platforms');

  @override
  Future<void> close() => throw UnsupportedError('HttpSseTransport is only available on dart:io platforms');
}
