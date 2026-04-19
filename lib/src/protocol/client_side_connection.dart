import 'dart:async';

import 'package:acp/src/protocol/acp_methods.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/protocol/protocol_validation.dart';
import 'package:acp/src/protocol/protocol_warning.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/implementation_info.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:acp/src/schema/unstable_methods.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _log = Logger('acp.protocol.client_side');

/// A parsed session update event containing the session ID and update payload.
final class SessionUpdateEvent {
  /// The session this update belongs to.
  final String sessionId;

  /// The parsed session update.
  final SessionUpdate update;

  /// Creates a [SessionUpdateEvent].
  const SessionUpdateEvent({required this.sessionId, required this.update});
}

/// Typed connection facade for client implementers.
///
/// Wraps a [Connection] and provides:
/// - Deserialized dispatch of incoming agent requests to a [ClientHandler].
/// - Typed convenience methods for client → agent requests and notifications.
/// - Capability enforcement for outgoing requests.
final class ClientSideConnection {
  final Connection _connection;
  final ClientHandler _handler;
  final ClientCapabilities _clientCapabilities;
  final ImplementationInfo? _clientInfo;
  final bool _useUnstableProtocol;
  final CapabilityEnforcement _capabilityEnforcement;

  AgentCapabilities? _remoteCapabilities;

  final StreamController<SessionUpdateEvent> _sessionUpdateController =
      StreamController<SessionUpdateEvent>.broadcast();

  /// Creates a [ClientSideConnection] over [transport].
  ///
  /// [handler] receives incoming requests and notifications from the agent.
  ///
  /// [clientCapabilities] are advertised to the agent during initialization.
  ///
  /// [clientInfo] optionally describes this client implementation.
  ///
  /// [capabilityEnforcement] controls whether outgoing requests are checked
  /// against peer-advertised capabilities before sending.
  ///
  /// [useUnstableProtocol] is reserved for future use.
  ///
  /// [defaultTimeout] controls how long outgoing requests wait for a
  /// response before throwing [RequestTimeoutException].
  ClientSideConnection(
    AcpTransport transport, {
    required ClientHandler handler,
    ClientCapabilities clientCapabilities = const ClientCapabilities(),
    ImplementationInfo? clientInfo,
    CapabilityEnforcement capabilityEnforcement = CapabilityEnforcement.strict,
    bool useUnstableProtocol = false,
    Duration defaultTimeout = const Duration(seconds: 60),
  }) : _connection = Connection(transport, defaultTimeout: defaultTimeout),
       _handler = handler,
       _clientCapabilities = clientCapabilities,
       _clientInfo = clientInfo,
       _useUnstableProtocol = useUnstableProtocol,
       _capabilityEnforcement = capabilityEnforcement {
    _registerHandlers();
    _connection.start();
  }

  // -- Delegated properties --

  /// The current connection state.
  ConnectionState get state => _connection.state;

  /// A stream of connection state changes.
  Stream<ConnectionState> get onStateChange => _connection.onStateChange;

  /// A stream of non-fatal protocol warnings.
  Stream<ProtocolWarning> get warnings => _connection.warnings;

  /// Capabilities advertised by the remote agent, available after
  /// `sendInitialize`.
  AgentCapabilities? get remoteCapabilities => _remoteCapabilities;

  /// Capabilities advertised by this client.
  ClientCapabilities get localCapabilities => _clientCapabilities;

  /// Optional callback invoked before each outgoing message is written.
  set onSend(void Function(Map<String, dynamic> message)? callback) =>
      _connection.onSend = callback;

  /// Optional callback invoked after each incoming message is read.
  set onReceive(void Function(Map<String, dynamic> message)? callback) =>
      _connection.onReceive = callback;

  /// A stream of parsed session update events from the agent.
  Stream<SessionUpdateEvent> get sessionUpdates =>
      _sessionUpdateController.stream;

  /// Closes the connection with an optional [flushTimeout].
  Future<void> close({
    Duration flushTimeout = const Duration(seconds: 5),
  }) async {
    await _connection.close(flushTimeout: flushTimeout);
    await _sessionUpdateController.close();
  }

  // -- Client → Agent request methods --

  /// Sends an `initialize` request to the agent.
  ///
  /// Stores the agent's capabilities and transitions to open state.
  Future<InitializeResponse> sendInitialize({
    required int protocolVersion,
    ImplementationInfo? clientInfo,
  }) async {
    final request = InitializeRequest(
      protocolVersion: protocolVersion,
      clientCapabilities: _clientCapabilities,
      clientInfo: clientInfo ?? _clientInfo,
    );
    final result = await _connection.sendRequest(
      AcpMethods.initialize,
      request.toJson(),
    );
    final response = InitializeResponse.fromJson(result);
    _remoteCapabilities = response.agentCapabilities;
    _log.fine('Remote capabilities: ${_remoteCapabilities?.toJson()}');
    _connection.markOpen();
    return response;
  }

  /// Sends an `authenticate` request.
  Future<AuthenticateResponse> sendAuthenticate({
    required String methodId,
  }) async {
    final request = AuthenticateRequest(methodId: methodId);
    final result = await _connection.sendRequest(
      AcpMethods.authenticate,
      request.toJson(),
    );
    return AuthenticateResponse.fromJson(result);
  }

  /// Sends a `session/new` request.
  Future<NewSessionResponse> sendNewSession({
    required String cwd,
    List<Map<String, dynamic>> mcpServers = const [],
  }) async {
    validateAbsolutePath(cwd, 'cwd');
    final request = NewSessionRequest(cwd: cwd, mcpServers: mcpServers);
    late final Map<String, dynamic> result;
    try {
      result = await _connection.sendRequest(
        AcpMethods.sessionNew,
        request.toJson(),
      );
    } on RpcErrorException catch (e) {
      if (e.code == -32000) {
        throw AuthenticationException(e.message);
      }
      rethrow;
    }
    return NewSessionResponse.fromJson(result);
  }

  /// Sends a `session/load` request.
  ///
  /// Requires the agent to have advertised `loadSession` capability
  /// when [CapabilityEnforcement.strict] is active.
  Future<LoadSessionResponse> sendLoadSession({
    required String sessionId,
    required String cwd,
    List<Map<String, dynamic>> mcpServers = const [],
  }) async {
    validateAbsolutePath(cwd, 'cwd');
    _enforceCapability(
      AcpMethods.sessionLoad,
      'loadSession',
      _remoteCapabilities?.loadSession ?? false,
    );
    final request = LoadSessionRequest(
      sessionId: sessionId,
      cwd: cwd,
      mcpServers: mcpServers,
    );
    final result = await _connection.sendRequest(
      AcpMethods.sessionLoad,
      request.toJson(),
    );
    return LoadSessionResponse.fromJson(result);
  }

  /// Sends a `session/prompt` request.
  Future<PromptResponse> sendPrompt({
    required String sessionId,
    required List<ContentBlock> prompt,
  }) async {
    validatePromptCapabilities(
      method: AcpMethods.sessionPrompt,
      prompt: prompt,
      capabilities:
          _remoteCapabilities?.promptCapabilities ?? const PromptCapabilities(),
      strict: _capabilityEnforcement == CapabilityEnforcement.strict,
    );
    final request = PromptRequest(sessionId: sessionId, prompt: prompt);
    final result = await _connection.sendRequest(
      AcpMethods.sessionPrompt,
      request.toJson(),
    );
    return PromptResponse.fromJson(result);
  }

  /// Sends a `session/cancel` notification.
  Future<void> sendCancel({required String sessionId}) => _connection.notify(
    AcpMethods.sessionCancel,
    <String, dynamic>{'sessionId': sessionId},
  );

  /// Sends a `session/set_mode` request.
  Future<SetSessionModeResponse> sendSetMode({
    required String sessionId,
    required String modeId,
  }) async {
    final request = SetSessionModeRequest(sessionId: sessionId, modeId: modeId);
    final result = await _connection.sendRequest(
      AcpMethods.sessionSetMode,
      request.toJson(),
    );
    return SetSessionModeResponse.fromJson(result);
  }

  /// Sends a `session/set_config_option` request.
  Future<SetSessionConfigOptionResponse> sendSetConfigOption({
    required String sessionId,
    required String configId,
    required String value,
  }) async {
    final request = SetSessionConfigOptionRequest(
      sessionId: sessionId,
      configId: configId,
      value: value,
    );
    final result = await _connection.sendRequest(
      AcpMethods.sessionSetConfigOption,
      request.toJson(),
    );
    return SetSessionConfigOptionResponse.fromJson(result);
  }

  /// Sends a `session/list` request.
  ///
  /// Requires the agent to advertise `sessionCapabilities.list` when
  /// [CapabilityEnforcement.strict] is active.
  Future<ListSessionsResponse> sendListSessions({
    String? cwd,
    String? cursor,
  }) async {
    validateOptionalAbsolutePath(cwd, 'cwd');
    _enforceCapability(
      AcpMethods.sessionList,
      'sessionCapabilities.list',
      _remoteCapabilities?.sessionCapabilities.list != null,
    );
    final request = ListSessionsRequest(cwd: cwd, cursor: cursor);
    final result = await _connection.sendRequest(
      AcpMethods.sessionList,
      request.toJson(),
    );
    return ListSessionsResponse.fromJson(result);
  }

  /// Sends a `session/fork` request (unstable).
  ///
  /// Requires `useUnstableProtocol: true` on this connection.
  @experimental
  Future<ForkSessionResponse> sendForkSession({
    required String sessionId,
    required String cwd,
  }) async {
    _ensureUnstable(AcpMethods.sessionFork);
    validateAbsolutePath(cwd, 'cwd');
    final request = ForkSessionRequest(sessionId: sessionId, cwd: cwd);
    final result = await _connection.sendRequest(
      AcpMethods.sessionFork,
      request.toJson(),
    );
    return ForkSessionResponse.fromJson(result);
  }

  /// Sends a `providers/list` request (unstable).
  @experimental
  Future<ListProvidersResponse> sendListProviders([
    ListProvidersRequest request = const ListProvidersRequest(),
  ]) async {
    _ensureUnstable(AcpMethods.providersList);
    final result = await _connection.sendRequest(
      AcpMethods.providersList,
      request.toJson(),
    );
    return ListProvidersResponse.fromJson(result);
  }

  /// Sends a `providers/set` request (unstable).
  @experimental
  Future<SetProvidersResponse> sendSetProviders(
    SetProvidersRequest request,
  ) async {
    _ensureUnstable(AcpMethods.providersSet);
    final result = await _connection.sendRequest(
      AcpMethods.providersSet,
      request.toJson(),
    );
    return SetProvidersResponse.fromJson(result);
  }

  /// Sends a `providers/disable` request (unstable).
  @experimental
  Future<DisableProvidersResponse> sendDisableProviders(
    DisableProvidersRequest request,
  ) async {
    _ensureUnstable(AcpMethods.providersDisable);
    final result = await _connection.sendRequest(
      AcpMethods.providersDisable,
      request.toJson(),
    );
    return DisableProvidersResponse.fromJson(result);
  }

  /// Sends a `logout` request (unstable).
  @experimental
  Future<LogoutResponse> sendLogout([
    LogoutRequest request = const LogoutRequest(),
  ]) async {
    _ensureUnstable(AcpMethods.logout);
    final result = await _connection.sendRequest(
      AcpMethods.logout,
      request.toJson(),
    );
    return LogoutResponse.fromJson(result);
  }

  /// Sends a `session/resume` request (unstable).
  @experimental
  Future<ResumeSessionResponse> sendResumeSession(
    ResumeSessionRequest request,
  ) async {
    _ensureUnstable(AcpMethods.sessionResume);
    validateAbsolutePath(request.cwd, 'cwd');
    for (final path in request.additionalDirectories) {
      validateAbsolutePath(path, 'additionalDirectories');
    }
    final result = await _connection.sendRequest(
      AcpMethods.sessionResume,
      request.toJson(),
    );
    return ResumeSessionResponse.fromJson(result);
  }

  /// Sends a `session/close` request (unstable).
  @experimental
  Future<CloseSessionResponse> sendCloseSession(
    CloseSessionRequest request,
  ) async {
    _ensureUnstable(AcpMethods.sessionClose);
    final result = await _connection.sendRequest(
      AcpMethods.sessionClose,
      request.toJson(),
    );
    return CloseSessionResponse.fromJson(result);
  }

  /// Sends a `session/set_model` request (unstable).
  @experimental
  Future<SetSessionModelResponse> sendSetModel(
    SetSessionModelRequest request,
  ) async {
    _ensureUnstable(AcpMethods.sessionSetModel);
    final result = await _connection.sendRequest(
      AcpMethods.sessionSetModel,
      request.toJson(),
    );
    return SetSessionModelResponse.fromJson(result);
  }

  /// Sends a `nes/start` request (unstable).
  @experimental
  Future<StartNesResponse> sendStartNes(StartNesRequest request) async {
    _ensureUnstable(AcpMethods.nesStart);
    final result = await _connection.sendRequest(
      AcpMethods.nesStart,
      request.toJson(),
    );
    return StartNesResponse.fromJson(result);
  }

  /// Sends a `nes/suggest` request (unstable).
  @experimental
  Future<SuggestNesResponse> sendSuggestNes(SuggestNesRequest request) async {
    _ensureUnstable(AcpMethods.nesSuggest);
    final result = await _connection.sendRequest(
      AcpMethods.nesSuggest,
      request.toJson(),
    );
    return SuggestNesResponse.fromJson(result);
  }

  /// Sends a `nes/close` request (unstable).
  @experimental
  Future<CloseNesResponse> sendCloseNes(CloseNesRequest request) async {
    _ensureUnstable(AcpMethods.nesClose);
    final result = await _connection.sendRequest(
      AcpMethods.nesClose,
      request.toJson(),
    );
    return CloseNesResponse.fromJson(result);
  }

  /// Sends a `document/didOpen` notification (unstable).
  @experimental
  Future<void> notifyDidOpenDocument(DidOpenDocumentNotification notification) {
    _ensureUnstable(AcpMethods.documentDidOpen);
    return _connection.notify(
      AcpMethods.documentDidOpen,
      notification.toJson(),
    );
  }

  /// Sends a `document/didChange` notification (unstable).
  @experimental
  Future<void> notifyDidChangeDocument(
    DidChangeDocumentNotification notification,
  ) {
    _ensureUnstable(AcpMethods.documentDidChange);
    return _connection.notify(
      AcpMethods.documentDidChange,
      notification.toJson(),
    );
  }

  /// Sends a `document/didClose` notification (unstable).
  @experimental
  Future<void> notifyDidCloseDocument(
    DidCloseDocumentNotification notification,
  ) {
    _ensureUnstable(AcpMethods.documentDidClose);
    return _connection.notify(
      AcpMethods.documentDidClose,
      notification.toJson(),
    );
  }

  /// Sends a `document/didSave` notification (unstable).
  @experimental
  Future<void> notifyDidSaveDocument(DidSaveDocumentNotification notification) {
    _ensureUnstable(AcpMethods.documentDidSave);
    return _connection.notify(
      AcpMethods.documentDidSave,
      notification.toJson(),
    );
  }

  /// Sends a `document/didFocus` notification (unstable).
  @experimental
  Future<void> notifyDidFocusDocument(
    DidFocusDocumentNotification notification,
  ) {
    _ensureUnstable(AcpMethods.documentDidFocus);
    return _connection.notify(
      AcpMethods.documentDidFocus,
      notification.toJson(),
    );
  }

  /// Sends a `nes/accept` notification (unstable).
  @experimental
  Future<void> notifyAcceptNes(AcceptNesNotification notification) {
    _ensureUnstable(AcpMethods.nesAccept);
    return _connection.notify(AcpMethods.nesAccept, notification.toJson());
  }

  /// Sends a `nes/reject` notification (unstable).
  @experimental
  Future<void> notifyRejectNes(RejectNesNotification notification) {
    _ensureUnstable(AcpMethods.nesReject);
    return _connection.notify(AcpMethods.nesReject, notification.toJson());
  }

  // -- Extension methods --

  /// Sends an extension request (method starting with `_`).
  Future<Map<String, dynamic>> extMethod(
    String method,
    Map<String, dynamic>? params, {
    AcpCancellationToken? cancelToken,
  }) => _connection.sendRequest(method, params, cancelToken: cancelToken);

  /// Sends an extension notification (method starting with `_`).
  Future<void> extNotification(String method, [Map<String, dynamic>? params]) =>
      _connection.notify(method, params);

  // -- Private --

  void _registerHandlers() {
    // Agent → Client request handlers
    _connection.setRequestHandler(
      AcpMethods.fsReadTextFile,
      _handleReadTextFile,
    );
    _connection.setRequestHandler(
      AcpMethods.fsWriteTextFile,
      _handleWriteTextFile,
    );
    _connection.setRequestHandler(
      AcpMethods.terminalCreate,
      _handleCreateTerminal,
    );
    _connection.setRequestHandler(
      AcpMethods.terminalOutput,
      _handleTerminalOutput,
    );
    _connection.setRequestHandler(
      AcpMethods.terminalRelease,
      _handleReleaseTerminal,
    );
    _connection.setRequestHandler(AcpMethods.terminalKill, _handleKillTerminal);
    _connection.setRequestHandler(
      AcpMethods.terminalWaitForExit,
      _handleWaitForTerminalExit,
    );
    _connection.setRequestHandler(
      AcpMethods.sessionRequestPermission,
      _handleRequestPermission,
    );
    _connection.setRequestHandler(
      AcpMethods.elicitationCreate,
      _handleCreateElicitation,
    );

    // Agent → Client notification handler
    _connection.setNotificationHandler(
      AcpMethods.sessionUpdate,
      _handleSessionUpdate,
    );
    _connection.setNotificationHandler(
      AcpMethods.elicitationComplete,
      _handleCompleteElicitation,
    );

    // Extension handlers
    _connection.setExtensionRequestHandler(_handleExtRequest);
    _connection.setExtensionNotificationHandler(_handleExtNotification);
  }

  Future<Map<String, dynamic>> _handleReadTextFile(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = ReadTextFileRequest.fromJson(request.params ?? {});
    final response = await _handler.readTextFile(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleWriteTextFile(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = WriteTextFileRequest.fromJson(request.params ?? {});
    final response = await _handler.writeTextFile(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleCreateTerminal(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = CreateTerminalRequest.fromJson(request.params ?? {});
    final response = await _handler.createTerminal(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleTerminalOutput(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = TerminalOutputRequest.fromJson(request.params ?? {});
    final response = await _handler.terminalOutput(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleReleaseTerminal(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = ReleaseTerminalRequest.fromJson(request.params ?? {});
    final response = await _handler.releaseTerminal(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleKillTerminal(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = KillTerminalCommandRequest.fromJson(request.params ?? {});
    final response = await _handler.killTerminal(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleWaitForTerminalExit(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = WaitForTerminalExitRequest.fromJson(request.params ?? {});
    final response = await _handler.waitForTerminalExit(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleRequestPermission(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = RequestPermissionRequest.fromJson(request.params ?? {});
    final response = await _handler.requestPermission(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleCreateElicitation(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.elicitationCreate);
    final handler = _handler;
    if (handler is! UnstableClientHandler) {
      throw RpcErrorException.methodNotFound(
        'Handler does not mix in UnstableClientHandler',
      );
    }
    final req = CreateElicitationRequest.fromJson(request.params ?? {});
    final response = await handler.createElicitation(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<void> _handleSessionUpdate(JsonRpcNotification notification) async {
    final sessionNotif = SessionNotification.fromJson(
      notification.params ?? {},
    );
    final update = SessionUpdate.fromJson(sessionNotif.update);
    _handler.onSessionUpdate(sessionNotif.sessionId, update);
    _sessionUpdateController.add(
      SessionUpdateEvent(sessionId: sessionNotif.sessionId, update: update),
    );
  }

  Future<void> _handleCompleteElicitation(
    JsonRpcNotification notification,
  ) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableClientHandler) return;
    final req = CompleteElicitationNotification.fromJson(
      notification.params ?? {},
    );
    await handler.onElicitationComplete(req);
  }

  Future<Map<String, dynamic>> _handleExtRequest(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final result = await _handler.onExtMethod(
      request.method,
      request.params,
      cancelToken: cancelToken,
    );
    if (result == null) {
      throw RpcErrorException.methodNotFound(
        'Method not found: ${request.method}',
      );
    }
    return result;
  }

  Future<void> _handleExtNotification(JsonRpcNotification notification) =>
      _handler.onExtNotification(notification.method, notification.params);

  void _ensureUnstable(String method) {
    if (!_useUnstableProtocol) {
      throw UnsupportedError(
        'Method "$method" is unstable. Pass useUnstableProtocol: true '
        'to ClientSideConnection to enable it.',
      );
    }
  }

  void _ensureUnstableIncoming(String method) {
    if (!_useUnstableProtocol) {
      throw RpcErrorException.methodNotFound(
        'Unstable method not enabled: $method',
      );
    }
  }

  void _enforceCapability(String method, String capability, bool isAdvertised) {
    if (_capabilityEnforcement == CapabilityEnforcement.strict &&
        !isAdvertised) {
      throw CapabilityException(method, capability);
    }
  }
}
