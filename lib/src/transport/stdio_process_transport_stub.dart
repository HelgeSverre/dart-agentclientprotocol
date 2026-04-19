import 'dart:async';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// Unsupported fallback for [StdioProcessTransport] on non-`dart:io` platforms.
final class StdioProcessTransport implements AcpTransport {
  /// Always throws because process spawning requires `dart:io`.
  static Future<StdioProcessTransport> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) =>
      throw UnsupportedError(
        'StdioProcessTransport is only available on dart:io platforms',
      );

  @override
  Stream<JsonRpcMessage> get messages =>
      throw UnsupportedError(
        'StdioProcessTransport is only available on dart:io platforms',
      );

  @override
  Future<void> send(JsonRpcMessage message) =>
      throw UnsupportedError(
        'StdioProcessTransport is only available on dart:io platforms',
      );

  @override
  Future<void> close() =>
      throw UnsupportedError(
        'StdioProcessTransport is only available on dart:io platforms',
      );
}
