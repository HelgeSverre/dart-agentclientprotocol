import 'dart:async';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// Unsupported fallback for [StreamableHttpTransport] on non-`dart:io`
/// platforms.
final class StreamableHttpTransport implements AcpTransport {
  /// Always throws because Streamable HTTP transport requires `dart:io`.
  StreamableHttpTransport(
    Uri endpoint, {
    Map<String, String>? headers,
    Object? httpClient,
  }) {
    throw UnsupportedError(
      'StreamableHttpTransport is only available on dart:io platforms',
    );
  }

  @override
  Stream<JsonRpcMessage> get messages =>
      throw UnsupportedError(
        'StreamableHttpTransport is only available on dart:io platforms',
      );

  @override
  Future<void> send(JsonRpcMessage message) =>
      throw UnsupportedError(
        'StreamableHttpTransport is only available on dart:io platforms',
      );

  @override
  Future<void> close() =>
      throw UnsupportedError(
        'StreamableHttpTransport is only available on dart:io platforms',
      );
}
