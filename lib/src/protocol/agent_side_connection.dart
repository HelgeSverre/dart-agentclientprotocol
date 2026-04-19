import 'dart:async';

import 'package:acp/src/protocol/acp_methods.dart';
import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/protocol/protocol_validation.dart';
import 'package:acp/src/protocol/protocol_warning.dart';
import 'package:acp/src/protocol/terminal_handle.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:acp/src/schema/unstable_methods.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

final _log = Logger('acp.protocol.agent_side');

/// Typed connection facade for agent implementers.
///
/// Wraps a [Connection] and provides:
/// - Deserialized dispatch of incoming client requests to an [AgentHandler].
/// - Typed convenience methods for agent → client requests and notifications.
/// - Capability enforcement for outgoing requests.
final class AgentSideConnection {
  final Connection _connection;
  late final AgentHandler _handler;
  final bool _useUnstableProtocol;
  final CapabilityEnforcement _capabilityEnforcement;

  ClientCapabilities? _remoteCapabilities;
  AgentCapabilities? _localCapabilities;
  final Map<String, Set<AcpCancellationSource>> _activePromptCancellations =
      <String, Set<AcpCancellationSource>>{};

  /// Creates an [AgentSideConnection] over [transport].
  ///
  /// [handlerFactory] is called with this connection to create the
  /// [AgentHandler], breaking circular dependency between handler and
  /// connection.
  ///
  /// [capabilityEnforcement] controls whether outgoing requests are checked
  /// against peer-advertised capabilities before sending.
  ///
  /// [useUnstableProtocol] is reserved for future use.
  ///
  /// [defaultTimeout] controls how long outgoing requests wait for a
  /// response before throwing [RequestTimeoutException].
  AgentSideConnection(
    AcpTransport transport, {
    required AgentHandler Function(AgentSideConnection conn) handlerFactory,
    CapabilityEnforcement capabilityEnforcement = CapabilityEnforcement.strict,
    bool useUnstableProtocol = false,
    Duration defaultTimeout = const Duration(seconds: 60),
  }) : _connection = Connection(transport, defaultTimeout: defaultTimeout),
       _useUnstableProtocol = useUnstableProtocol,
       _capabilityEnforcement = capabilityEnforcement {
    _handler = handlerFactory(this);
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

  /// Capabilities advertised by the remote client, available after
  /// `initialize`.
  ClientCapabilities? get remoteCapabilities => _remoteCapabilities;

  /// Capabilities advertised by this agent, available after `initialize`.
  AgentCapabilities? get localCapabilities => _localCapabilities;

  /// Optional callback invoked before each outgoing message is written.
  set onSend(void Function(Map<String, dynamic> message)? callback) =>
      _connection.onSend = callback;

  /// Optional callback invoked after each incoming message is read.
  set onReceive(void Function(Map<String, dynamic> message)? callback) =>
      _connection.onReceive = callback;

  /// Closes the connection with an optional [flushTimeout].
  Future<void> close({Duration flushTimeout = const Duration(seconds: 5)}) =>
      _connection.close(flushTimeout: flushTimeout);

  // -- Agent → Client request methods --

  /// Sends an `fs/read_text_file` request.
  Future<ReadTextFileResponse> sendReadTextFile({
    required String sessionId,
    required String path,
    int? line,
    int? limit,
    AcpCancellationToken? cancelToken,
  }) async {
    validateAbsolutePath(path, 'path');
    _enforceCapability(
      AcpMethods.fsReadTextFile,
      'fs.readTextFile',
      _remoteCapabilities?.fs.readTextFile ?? false,
    );
    final request = ReadTextFileRequest(
      sessionId: sessionId,
      path: path,
      line: line,
      limit: limit,
    );
    final result = await _connection.sendRequest(
      AcpMethods.fsReadTextFile,
      request.toJson(),
      cancelToken: cancelToken,
    );
    return ReadTextFileResponse.fromJson(result);
  }

  /// Sends an `fs/write_text_file` request.
  Future<WriteTextFileResponse> sendWriteTextFile({
    required String sessionId,
    required String path,
    required String content,
    AcpCancellationToken? cancelToken,
  }) async {
    validateAbsolutePath(path, 'path');
    _enforceCapability(
      AcpMethods.fsWriteTextFile,
      'fs.writeTextFile',
      _remoteCapabilities?.fs.writeTextFile ?? false,
    );
    final request = WriteTextFileRequest(
      sessionId: sessionId,
      path: path,
      content: content,
    );
    final result = await _connection.sendRequest(
      AcpMethods.fsWriteTextFile,
      request.toJson(),
      cancelToken: cancelToken,
    );
    return WriteTextFileResponse.fromJson(result);
  }

  /// Sends a `terminal/create` request.
  Future<CreateTerminalResponse> sendCreateTerminal({
    required String sessionId,
    required String command,
    List<String>? args,
    List<Map<String, dynamic>>? env,
    String? cwd,
    int? outputByteLimit,
    AcpCancellationToken? cancelToken,
  }) async {
    validateOptionalAbsolutePath(cwd, 'cwd');
    _enforceCapability(
      AcpMethods.terminalCreate,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final request = CreateTerminalRequest(
      sessionId: sessionId,
      command: command,
      args: args ?? const [],
      env: env ?? const [],
      cwd: cwd,
      outputByteLimit: outputByteLimit,
    );
    final result = await _connection.sendRequest(
      AcpMethods.terminalCreate,
      request.toJson(),
      cancelToken: cancelToken,
    );
    return CreateTerminalResponse.fromJson(result);
  }

  /// Creates a terminal and returns a [TerminalHandle] for ergonomic
  /// lifecycle management.
  Future<TerminalHandle> createTerminalHandle({
    required String sessionId,
    required String command,
    List<String>? args,
    List<Map<String, dynamic>>? env,
    String? cwd,
    int? outputByteLimit,
    AcpCancellationToken? cancelToken,
  }) async {
    final response = await sendCreateTerminal(
      sessionId: sessionId,
      command: command,
      args: args,
      env: env,
      cwd: cwd,
      outputByteLimit: outputByteLimit,
      cancelToken: cancelToken,
    );
    return TerminalHandle(
      connection: this,
      sessionId: sessionId,
      terminalId: response.terminalId,
    );
  }

  /// Sends a `terminal/output` request.
  Future<TerminalOutputResponse> sendTerminalOutput({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalOutput,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final request = TerminalOutputRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    );
    final result = await _connection.sendRequest(
      AcpMethods.terminalOutput,
      request.toJson(),
      cancelToken: cancelToken,
    );
    return TerminalOutputResponse.fromJson(result);
  }

  /// Sends a `terminal/release` request.
  Future<void> sendReleaseTerminal({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalRelease,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final request = ReleaseTerminalRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    );
    final result = await _connection.sendRequest(
      AcpMethods.terminalRelease,
      request.toJson(),
      cancelToken: cancelToken,
    );
    ReleaseTerminalResponse.fromJson(result);
  }

  /// Sends a `terminal/kill` request.
  Future<void> sendKillTerminal({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalKill,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final request = KillTerminalCommandRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    );
    final result = await _connection.sendRequest(
      AcpMethods.terminalKill,
      request.toJson(),
      cancelToken: cancelToken,
    );
    KillTerminalCommandResponse.fromJson(result);
  }

  /// Sends a `terminal/wait_for_exit` request.
  Future<WaitForTerminalExitResponse> sendWaitForTerminalExit({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalWaitForExit,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final request = WaitForTerminalExitRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    );
    final result = await _connection.sendRequest(
      AcpMethods.terminalWaitForExit,
      request.toJson(),
      cancelToken: cancelToken,
    );
    return WaitForTerminalExitResponse.fromJson(result);
  }

  /// Sends a `session/request_permission` request.
  ///
  /// This method does not require any capability — it is always available.
  Future<RequestPermissionResponse> sendRequestPermission({
    required String sessionId,
    required Map<String, dynamic> toolCall,
    required List<Map<String, dynamic>> options,
    AcpCancellationToken? cancelToken,
  }) async {
    final request = RequestPermissionRequest(
      sessionId: sessionId,
      toolCall: toolCall,
      options: options,
    );
    final result = await _connection.sendRequest(
      AcpMethods.sessionRequestPermission,
      request.toJson(),
      cancelToken: cancelToken,
    );
    return RequestPermissionResponse.fromJson(result);
  }

  /// Sends an `elicitation/create` request (unstable).
  @experimental
  Future<CreateElicitationResponse> sendCreateElicitation(
    CreateElicitationRequest request, {
    AcpCancellationToken? cancelToken,
  }) async {
    _ensureUnstable(AcpMethods.elicitationCreate);
    final result = await _connection.sendRequest(
      AcpMethods.elicitationCreate,
      request.toJson(),
      cancelToken: cancelToken,
    );
    return CreateElicitationResponse.fromJson(result);
  }

  // -- Agent → Client notification methods --

  /// Sends a `session/update` notification.
  Future<void> notifySessionUpdate(String sessionId, SessionUpdate update) =>
      _connection.notify(AcpMethods.sessionUpdate, <String, dynamic>{
        'sessionId': sessionId,
        'update': update.toJson(),
      });

  /// Sends an `elicitation/complete` notification (unstable).
  @experimental
  Future<void> notifyCompleteElicitation(
    CompleteElicitationNotification notification,
  ) {
    _ensureUnstable(AcpMethods.elicitationComplete);
    return _connection.notify(
      AcpMethods.elicitationComplete,
      notification.toJson(),
    );
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
    // Client → Agent request handlers
    _connection.setRequestHandler(AcpMethods.initialize, _handleInitialize);
    _connection.setRequestHandler(AcpMethods.authenticate, _handleAuthenticate);
    _connection.setRequestHandler(AcpMethods.sessionNew, _handleNewSession);
    _connection.setRequestHandler(AcpMethods.sessionLoad, _handleLoadSession);
    _connection.setRequestHandler(AcpMethods.sessionPrompt, _handlePrompt);
    _connection.setRequestHandler(AcpMethods.sessionSetMode, _handleSetMode);
    _connection.setRequestHandler(
      AcpMethods.sessionSetConfigOption,
      _handleSetConfigOption,
    );

    // Client → Agent notification handler
    _connection.setNotificationHandler(AcpMethods.sessionCancel, _handleCancel);

    // Stable method handlers
    _connection.setRequestHandler(AcpMethods.sessionList, _handleListSessions);

    // Unstable method handlers
    _connection.setRequestHandler(AcpMethods.sessionFork, _handleForkSession);
    _connection.setRequestHandler(
      AcpMethods.providersList,
      _handleListProviders,
    );
    _connection.setRequestHandler(AcpMethods.providersSet, _handleSetProviders);
    _connection.setRequestHandler(
      AcpMethods.providersDisable,
      _handleDisableProviders,
    );
    _connection.setRequestHandler(AcpMethods.logout, _handleLogout);
    _connection.setRequestHandler(
      AcpMethods.sessionResume,
      _handleResumeSession,
    );
    _connection.setRequestHandler(AcpMethods.sessionClose, _handleCloseSession);
    _connection.setRequestHandler(AcpMethods.sessionSetModel, _handleSetModel);
    _connection.setRequestHandler(AcpMethods.nesStart, _handleStartNes);
    _connection.setRequestHandler(AcpMethods.nesSuggest, _handleSuggestNes);
    _connection.setRequestHandler(AcpMethods.nesClose, _handleCloseNes);
    _connection.setNotificationHandler(
      AcpMethods.documentDidOpen,
      _handleDidOpenDocument,
    );
    _connection.setNotificationHandler(
      AcpMethods.documentDidChange,
      _handleDidChangeDocument,
    );
    _connection.setNotificationHandler(
      AcpMethods.documentDidClose,
      _handleDidCloseDocument,
    );
    _connection.setNotificationHandler(
      AcpMethods.documentDidSave,
      _handleDidSaveDocument,
    );
    _connection.setNotificationHandler(
      AcpMethods.documentDidFocus,
      _handleDidFocusDocument,
    );
    _connection.setNotificationHandler(AcpMethods.nesAccept, _handleAcceptNes);
    _connection.setNotificationHandler(AcpMethods.nesReject, _handleRejectNes);

    // Extension handlers
    _connection.setExtensionRequestHandler(_handleExtRequest);
    _connection.setExtensionNotificationHandler(_handleExtNotification);
  }

  Future<Map<String, dynamic>> _handleInitialize(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final initReq = InitializeRequest.fromJson(request.params ?? {});
    _remoteCapabilities = initReq.clientCapabilities;
    _log.fine('Remote capabilities: ${_remoteCapabilities?.toJson()}');

    final response = await _handler.initialize(
      initReq,
      cancelToken: cancelToken,
    );
    _localCapabilities = response.agentCapabilities;

    _connection.markOpen();
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleAuthenticate(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final authReq = AuthenticateRequest.fromJson(request.params ?? {});
    final response = await _handler.authenticate(
      authReq,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleNewSession(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final newReq = NewSessionRequest.fromJson(request.params ?? {});
    final response = await _handler.newSession(
      newReq,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleLoadSession(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final loadReq = LoadSessionRequest.fromJson(request.params ?? {});
    final response = await _handler.loadSession(
      loadReq,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handlePrompt(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final promptReq = PromptRequest.fromJson(request.params ?? {});
    final sessionCancelSource = AcpCancellationSource();
    final sessionSources = _activePromptCancellations.putIfAbsent(
      promptReq.sessionId,
      () => <AcpCancellationSource>{},
    );
    sessionSources.add(sessionCancelSource);
    try {
      final response = await _handler.prompt(
        promptReq,
        cancelToken: _LinkedCancellationToken(
          cancelToken,
          sessionCancelSource.token,
        ),
      );
      return response.toJson();
    } finally {
      sessionSources.remove(sessionCancelSource);
      if (sessionSources.isEmpty) {
        _activePromptCancellations.remove(promptReq.sessionId);
      }
    }
  }

  Future<Map<String, dynamic>> _handleSetMode(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final modeReq = SetSessionModeRequest.fromJson(request.params ?? {});
    final response = await _handler.setMode(modeReq, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleSetConfigOption(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final configReq = SetSessionConfigOptionRequest.fromJson(
      request.params ?? {},
    );
    final response = await _handler.setConfigOption(
      configReq,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<void> _handleCancel(JsonRpcNotification notification) async {
    final cancelNotif = CancelNotification.fromJson(notification.params ?? {});
    final sources = _activePromptCancellations[cancelNotif.sessionId];
    if (sources != null) {
      for (final source in List<AcpCancellationSource>.of(sources)) {
        source.cancel('Session ${cancelNotif.sessionId} canceled');
      }
    }
    await _handler.cancel(cancelNotif);
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

  Future<Map<String, dynamic>> _handleListSessions(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final listReq = ListSessionsRequest.fromJson(request.params ?? {});
    final response = await _handler.listSessions(
      listReq,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  UnstableAgentHandler _requireUnstableHandler() {
    final handler = _handler;
    if (handler is! UnstableAgentHandler) {
      throw RpcErrorException.methodNotFound(
        'Handler does not mix in UnstableAgentHandler',
      );
    }
    return handler;
  }

  Future<Map<String, dynamic>> _handleForkSession(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.sessionFork);
    final handler = _requireUnstableHandler();
    final forkReq = ForkSessionRequest.fromJson(request.params ?? {});
    final response = await handler.forkSession(
      forkReq,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleListProviders(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.providersList);
    final handler = _requireUnstableHandler();
    final req = ListProvidersRequest.fromJson(request.params ?? {});
    final response = await handler.listProviders(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleSetProviders(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.providersSet);
    final handler = _requireUnstableHandler();
    final req = SetProvidersRequest.fromJson(request.params ?? {});
    final response = await handler.setProviders(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleDisableProviders(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.providersDisable);
    final handler = _requireUnstableHandler();
    final req = DisableProvidersRequest.fromJson(request.params ?? {});
    final response = await handler.disableProviders(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleLogout(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.logout);
    final handler = _requireUnstableHandler();
    final req = LogoutRequest.fromJson(request.params ?? {});
    final response = await handler.logout(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleResumeSession(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.sessionResume);
    final handler = _requireUnstableHandler();
    final req = ResumeSessionRequest.fromJson(request.params ?? {});
    final response = await handler.resumeSession(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleCloseSession(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.sessionClose);
    final handler = _requireUnstableHandler();
    final req = CloseSessionRequest.fromJson(request.params ?? {});
    final response = await handler.closeSession(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleSetModel(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.sessionSetModel);
    final handler = _requireUnstableHandler();
    final req = SetSessionModelRequest.fromJson(request.params ?? {});
    final response = await handler.setModel(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleStartNes(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.nesStart);
    final handler = _requireUnstableHandler();
    final req = StartNesRequest.fromJson(request.params ?? {});
    final response = await handler.startNes(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleSuggestNes(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.nesSuggest);
    final handler = _requireUnstableHandler();
    final req = SuggestNesRequest.fromJson(request.params ?? {});
    final response = await handler.suggestNes(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleCloseNes(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    _ensureUnstableIncoming(AcpMethods.nesClose);
    final handler = _requireUnstableHandler();
    final req = CloseNesRequest.fromJson(request.params ?? {});
    final response = await handler.closeNes(req, cancelToken: cancelToken);
    return response.toJson();
  }

  Future<void> _handleDidOpenDocument(JsonRpcNotification notification) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableAgentHandler) return;
    return handler.didOpenDocument(
      DidOpenDocumentNotification.fromJson(notification.params ?? {}),
    );
  }

  Future<void> _handleDidChangeDocument(
    JsonRpcNotification notification,
  ) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableAgentHandler) return;
    return handler.didChangeDocument(
      DidChangeDocumentNotification.fromJson(notification.params ?? {}),
    );
  }

  Future<void> _handleDidCloseDocument(JsonRpcNotification notification) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableAgentHandler) return;
    return handler.didCloseDocument(
      DidCloseDocumentNotification.fromJson(notification.params ?? {}),
    );
  }

  Future<void> _handleDidSaveDocument(JsonRpcNotification notification) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableAgentHandler) return;
    return handler.didSaveDocument(
      DidSaveDocumentNotification.fromJson(notification.params ?? {}),
    );
  }

  Future<void> _handleDidFocusDocument(JsonRpcNotification notification) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableAgentHandler) return;
    return handler.didFocusDocument(
      DidFocusDocumentNotification.fromJson(notification.params ?? {}),
    );
  }

  Future<void> _handleAcceptNes(JsonRpcNotification notification) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableAgentHandler) return;
    return handler.acceptNes(
      AcceptNesNotification.fromJson(notification.params ?? {}),
    );
  }

  Future<void> _handleRejectNes(JsonRpcNotification notification) async {
    if (!_useUnstableProtocol) return;
    final handler = _handler;
    if (handler is! UnstableAgentHandler) return;
    return handler.rejectNes(
      RejectNesNotification.fromJson(notification.params ?? {}),
    );
  }

  void _ensureUnstable(String method) {
    if (!_useUnstableProtocol) {
      throw UnsupportedError(
        'Method "$method" is unstable. Pass useUnstableProtocol: true '
        'to AgentSideConnection to enable it.',
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

final class _LinkedCancellationToken implements AcpCancellationToken {
  final AcpCancellationToken _request;
  final AcpCancellationToken _session;

  _LinkedCancellationToken(this._request, this._session);

  @override
  bool get isCanceled => _request.isCanceled || _session.isCanceled;

  @override
  late final Future<void> whenCanceled = Future.any([
    _request.whenCanceled,
    _session.whenCanceled,
  ]);

  @override
  void throwIfCanceled() {
    _request.throwIfCanceled();
    _session.throwIfCanceled();
  }
}
