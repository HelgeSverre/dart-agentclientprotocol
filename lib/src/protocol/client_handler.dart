import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/session_update.dart';

/// Handler interface for client-side ACP method dispatch.
///
/// Implement this interface to handle incoming requests from an agent.
/// The [onSessionUpdate] callback must be overridden. Optional methods
/// throw [RpcErrorException.methodNotFound] by default.
abstract class ClientHandler {
  // -- Required callback (must be overridden) --

  /// Called when a session update notification is received.
  void onSessionUpdate(String sessionId, SessionUpdate update);

  // -- Optional methods (throw methodNotFound by default) --

  /// Handles a `fs/read_text_file` request.
  Future<ReadTextFileResponse> readTextFile(
    ReadTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `fs/write_text_file` request.
  Future<WriteTextFileResponse> writeTextFile(
    WriteTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `terminal/create` request.
  Future<CreateTerminalResponse> createTerminal(
    CreateTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `terminal/output` request.
  Future<TerminalOutputResponse> terminalOutput(
    TerminalOutputRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `terminal/release` request.
  Future<void> releaseTerminal(
    ReleaseTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `terminal/kill` request.
  Future<void> killTerminal(
    KillTerminalCommandRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `terminal/wait_for_exit` request.
  Future<WaitForTerminalExitResponse> waitForTerminalExit(
    WaitForTerminalExitRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/request_permission` request.
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  // -- Extension handlers --

  /// Handles an incoming extension request (method starting with `_`).
  ///
  /// Returns `null` by default.
  Future<Map<String, dynamic>?> onExtMethod(
    String method,
    Map<String, dynamic>? params, {
    required AcpCancellationToken cancelToken,
  }) async => null;

  /// Handles an incoming extension notification (method starting with `_`).
  ///
  /// Does nothing by default.
  Future<void> onExtNotification(
    String method,
    Map<String, dynamic>? params,
  ) async {}
}
