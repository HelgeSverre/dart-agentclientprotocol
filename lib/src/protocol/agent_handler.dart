import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/unstable_methods.dart';
import 'package:meta/meta.dart';

/// Handler interface for agent-side ACP method dispatch.
///
/// Implement this interface to handle incoming requests from a client.
/// The three core methods ([initialize], [newSession], [prompt]) must be
/// overridden. Optional methods throw [RpcErrorException.methodNotFound]
/// by default.
abstract class AgentHandler {
  // -- Required methods (must be overridden) --

  /// Handles an `initialize` request.
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  });

  /// Handles a `session/new` request.
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  });

  /// Handles a `session/prompt` request.
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  });

  // -- Optional methods (throw methodNotFound by default) --

  /// Handles an `authenticate` request.
  Future<AuthenticateResponse> authenticate(
    AuthenticateRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/load` request.
  Future<LoadSessionResponse> loadSession(
    LoadSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/set_mode` request.
  Future<SetSessionModeResponse> setMode(
    SetSessionModeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/set_config_option` request.
  Future<SetSessionConfigOptionResponse> setConfigOption(
    SetSessionConfigOptionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/list` request.
  Future<ListSessionsResponse> listSessions(
    ListSessionsRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/fork` request (unstable).
  @experimental
  Future<ForkSessionResponse> forkSession(
    ForkSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  // -- Notification handler --

  /// Handles a `session/cancel` notification.
  ///
  /// Does nothing by default.
  Future<void> cancel(CancelNotification notification) async {}

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
