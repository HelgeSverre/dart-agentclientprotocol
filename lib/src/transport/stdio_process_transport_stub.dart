import 'dart:async';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

final class StdioProcessTransport implements AcpTransport {
  static Future<StdioProcessTransport> start(String command, {List<String> args = const [], Map<String, String>? env, String? workingDirectory}) =>
      throw UnsupportedError('StdioProcessTransport is only available on dart:io platforms');

  @override
  Stream<JsonRpcMessage> get messages => throw UnsupportedError('StdioProcessTransport is only available on dart:io platforms');

  @override
  Future<void> send(JsonRpcMessage message) => throw UnsupportedError('StdioProcessTransport is only available on dart:io platforms');

  @override
  Future<void> close() => throw UnsupportedError('StdioProcessTransport is only available on dart:io platforms');
}
