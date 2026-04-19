import 'dart:async';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// Unsupported fallback for [StdioTransport] on non-`dart:io` platforms.
final class StdioTransport implements AcpTransport {
  /// Always throws because stdio transport requires `dart:io`.
  StdioTransport({Stream<List<int>>? input, Object? output}) {
    throw UnsupportedError(
      'StdioTransport is only available on dart:io platforms',
    );
  }

  /// Always throws because stdio transport requires `dart:io`.
  void start() {
    throw UnsupportedError(
      'StdioTransport is only available on dart:io platforms',
    );
  }

  @override
  Stream<JsonRpcMessage> get messages =>
      throw UnsupportedError(
        'StdioTransport is only available on dart:io platforms',
      );

  @override
  Future<void> send(JsonRpcMessage message) =>
      throw UnsupportedError(
        'StdioTransport is only available on dart:io platforms',
      );

  @override
  Future<void> close() =>
      throw UnsupportedError(
        'StdioTransport is only available on dart:io platforms',
      );
}
