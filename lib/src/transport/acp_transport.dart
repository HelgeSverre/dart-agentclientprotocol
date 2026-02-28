import 'dart:async';

import 'package:acp/src/protocol/json_rpc_message.dart';

/// Abstract transport interface for ACP message exchange.
///
/// Transports handle the raw framed message I/O layer. They are responsible
/// for reading and writing [JsonRpcMessage] objects over a communication
/// channel (stdio, WebSocket, etc.) without any ACP-specific semantics.
///
/// Implementations must guarantee:
/// - Messages are delivered in the order they are sent via [send].
/// - [messages] completes (closes) when the transport is closed or the
///   remote side disconnects.
/// - After [close] is called, no further messages are emitted and [send]
///   throws.
///
/// See also: [StdioTransport] for the NDJSON-over-stdio implementation.
abstract interface class AcpTransport {
  /// A stream of incoming messages from the remote side.
  ///
  /// The stream completes when the transport is closed, either by calling
  /// [close] or by the remote side disconnecting.
  Stream<JsonRpcMessage> get messages;

  /// Sends a message to the remote side.
  ///
  /// Messages are delivered in the order [send] is called.
  ///
  /// Throws [StateError] if the transport has been closed.
  Future<void> send(JsonRpcMessage message);

  /// Closes the transport.
  ///
  /// After closing:
  /// - The [messages] stream completes.
  /// - Subsequent calls to [send] throw [StateError].
  /// - Calling [close] again is a no-op.
  Future<void> close();
}
