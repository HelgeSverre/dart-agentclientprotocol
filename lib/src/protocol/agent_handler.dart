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
///
/// To opt into unstable (`@experimental`) method dispatch, mix in
/// [UnstableAgentHandler]:
///
/// ```dart
/// class MyAgent extends AgentHandler with UnstableAgentHandler {
///   // ... override stable + unstable methods ...
/// }
/// ```
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

/// Mix-in for handling unstable (`@experimental`) agent-side ACP methods.
///
/// Opt-in by declaring `with UnstableAgentHandler` on your [AgentHandler]
/// subclass. The `AgentSideConnection` only dispatches unstable methods to
/// handlers that mix this in; otherwise they respond with `methodNotFound`.
///
/// This mirrors the connection-level `useUnstableProtocol` flag at the
/// handler type level — both must be opted into for unstable dispatch to
/// reach handler code.
@experimental
mixin UnstableAgentHandler on AgentHandler {
  /// Handles a `session/fork` request (unstable).
  Future<ForkSessionResponse> forkSession(
    ForkSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `providers/list` request (unstable).
  Future<ListProvidersResponse> listProviders(
    ListProvidersRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `providers/set` request (unstable).
  Future<SetProvidersResponse> setProviders(
    SetProvidersRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `providers/disable` request (unstable).
  Future<DisableProvidersResponse> disableProviders(
    DisableProvidersRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `logout` request (unstable).
  Future<LogoutResponse> logout(
    LogoutRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/resume` request (unstable).
  Future<ResumeSessionResponse> resumeSession(
    ResumeSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/close` request (unstable).
  Future<CloseSessionResponse> closeSession(
    CloseSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `session/set_model` request (unstable).
  Future<SetSessionModelResponse> setModel(
    SetSessionModelRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `nes/start` request (unstable).
  Future<StartNesResponse> startNes(
    StartNesRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `nes/suggest` request (unstable).
  Future<SuggestNesResponse> suggestNes(
    SuggestNesRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `nes/close` request (unstable).
  Future<CloseNesResponse> closeNes(
    CloseNesRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => throw RpcErrorException.methodNotFound();

  /// Handles a `document/didOpen` notification (unstable).
  Future<void> didOpenDocument(
    DidOpenDocumentNotification notification,
  ) async {}

  /// Handles a `document/didChange` notification (unstable).
  Future<void> didChangeDocument(
    DidChangeDocumentNotification notification,
  ) async {}

  /// Handles a `document/didClose` notification (unstable).
  Future<void> didCloseDocument(
    DidCloseDocumentNotification notification,
  ) async {}

  /// Handles a `document/didSave` notification (unstable).
  Future<void> didSaveDocument(
    DidSaveDocumentNotification notification,
  ) async {}

  /// Handles a `document/didFocus` notification (unstable).
  Future<void> didFocusDocument(
    DidFocusDocumentNotification notification,
  ) async {}

  /// Handles a `nes/accept` notification (unstable).
  Future<void> acceptNes(AcceptNesNotification notification) async {}

  /// Handles a `nes/reject` notification (unstable).
  Future<void> rejectNes(RejectNesNotification notification) async {}
}
