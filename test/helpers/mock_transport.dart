import 'dart:async';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// In-memory transport for testing.
class MockTransport implements AcpTransport {
  final StreamController<JsonRpcMessage> _inbound =
      StreamController<JsonRpcMessage>();

  /// All messages sent via [send], in order.
  final List<JsonRpcMessage> sent = [];

  /// Whether [close] has been called.
  bool closed = false;

  @override
  Stream<JsonRpcMessage> get messages => _inbound.stream;

  /// Simulates an incoming message from the remote side.
  void receive(JsonRpcMessage message) => _inbound.add(message);

  /// Simulates a transport error from the remote side.
  void simulateError(Object error, [StackTrace? stackTrace]) =>
      _inbound.addError(error, stackTrace);

  /// Simulates the remote side closing.
  Future<void> simulateClose() => _inbound.close();

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (closed) throw StateError('closed');
    sent.add(message);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _inbound.close();
  }
}
