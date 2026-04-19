/// A pair of in-memory transports that pipe messages directly between two
/// `dart:async` `StreamController`s — useful for examples and tests where
/// running both peers in the same process is convenient.
///
/// In real code you'd use `StdioProcessTransport` (spawns an agent
/// subprocess) or `WebSocketTransport` (connects to a remote agent).
library;

import 'dart:async';

import 'package:acp/acp.dart';

/// Returns a `(agent, client)` transport pair where each end's `send` lands
/// on the other end's `messages` stream.
(AcpTransport, AcpTransport) createInMemoryTransports() {
  // ignore: close_sinks
  final aToB = StreamController<JsonRpcMessage>();
  // ignore: close_sinks
  final bToA = StreamController<JsonRpcMessage>();
  return (
    InMemoryTransport(inbound: bToA.stream, outbound: aToB),
    InMemoryTransport(inbound: aToB.stream, outbound: bToA),
  );
}

/// One end of an in-process transport pair. Created by
/// [createInMemoryTransports].
final class InMemoryTransport implements AcpTransport {
  final Stream<JsonRpcMessage> _inbound;
  final StreamController<JsonRpcMessage> _outbound;
  bool _closed = false;

  /// Creates an [InMemoryTransport] from the [inbound] stream and the
  /// peer's [outbound] sink.
  InMemoryTransport({
    required Stream<JsonRpcMessage> inbound,
    required StreamController<JsonRpcMessage> outbound,
  }) : _inbound = inbound,
       _outbound = outbound;

  @override
  Stream<JsonRpcMessage> get messages => _inbound;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) throw StateError('Transport is closed');
    _outbound.add(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _outbound.close();
  }
}
