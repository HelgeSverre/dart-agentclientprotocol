import 'dart:async';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

final class StdioTransport implements AcpTransport {
  StdioTransport(dynamic stdin, dynamic stdout) {
    throw UnsupportedError('StdioTransport is only available on dart:io platforms');
  }

  @override
  Stream<JsonRpcMessage> get messages => throw UnsupportedError('StdioTransport is only available on dart:io platforms');

  @override
  Future<void> send(JsonRpcMessage message) => throw UnsupportedError('StdioTransport is only available on dart:io platforms');

  @override
  Future<void> close() => throw UnsupportedError('StdioTransport is only available on dart:io platforms');
}
