import 'dart:async';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// Creates a pair of linked in-memory transports.
/// Messages sent by one side are received by the other.
(AcpTransport, AcpTransport) createLinkedTransports() {
  // Closed by _LinkedTransport.close()
  // ignore: close_sinks
  final aToB = StreamController<JsonRpcMessage>();
  // ignore: close_sinks
  final bToA = StreamController<JsonRpcMessage>();
  final transportA = _LinkedTransport(inbound: bToA.stream, outboundSink: aToB);
  final transportB = _LinkedTransport(inbound: aToB.stream, outboundSink: bToA);
  return (transportA, transportB);
}

class _LinkedTransport implements AcpTransport {
  final Stream<JsonRpcMessage> _inbound;
  final StreamController<JsonRpcMessage> _outboundSink;
  bool _closed = false;

  _LinkedTransport({
    required Stream<JsonRpcMessage> inbound,
    required StreamController<JsonRpcMessage> outboundSink,
  }) : _inbound = inbound,
       _outboundSink = outboundSink;

  @override
  Stream<JsonRpcMessage> get messages => _inbound;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) throw StateError('Transport is closed');
    _outboundSink.add(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _outboundSink.close();
  }
}
