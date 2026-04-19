import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:acp/acp.dart';
import 'package:acp/agent.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';

void main() {
  final explorer = AcpExplorer();
  explorer.init();
}

/// A Mock Agent that runs entirely in the browser for exploration.
class MockAgent extends AgentHandler {
  final AgentSideConnection connection;

  MockAgent(this.connection);

  @override
  Future<InitializeResponse> initialize(InitializeRequest request, {required AcpCancellationToken cancelToken}) async {
    return InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: const AgentCapabilities(
        loadSession: true,
      ),
      agentInfo: ImplementationInfo(name: 'Mock Web Agent', version: '1.0.0'),
    );
  }

  @override
  Future<NewSessionResponse> newSession(NewSessionRequest request, {required AcpCancellationToken cancelToken}) async {
    return const NewSessionResponse(sessionId: 'mock-session-123');
  }

  @override
  Future<PromptResponse> prompt(PromptRequest request, {required AcpCancellationToken cancelToken}) async {
    final text = request.prompt
        .whereType<TextContent>()
        .map((b) => b.text)
        .join(' ');
    
    // Simulate thinking
    Timer(const Duration(milliseconds: 500), () {
      connection.notifySessionUpdate(
        request.sessionId, 
        AgentMessageChunk(content: {'type': 'text', 'text': 'I am a mock agent running in your browser! You said: "$text"'})
      );
    });

    return const PromptResponse(stopReason: 'end_turn');
  }
}

class AcpExplorer implements ClientHandler {
  // UI Elements
  late final web.HTMLInputElement agentUrlInput;
  late final web.HTMLButtonElement connectBtn;
  late final web.HTMLButtonElement disconnectBtn;
  late final web.HTMLButtonElement toggleMockBtn;
  late final web.HTMLSpanElement mockBtnText;
  
  late final web.HTMLDivElement statusCard;
  late final web.HTMLSpanElement statusText;
  late final web.HTMLDivElement sessionInfo;
  late final web.HTMLDivElement capabilitiesList;
  
  late final web.HTMLDivElement messagesContainer;
  late final web.HTMLTextAreaElement userInput;
  late final web.HTMLButtonElement sendBtn;
  
  late final web.HTMLDivElement connectionForm;
  late final web.HTMLDivElement activeAgentInfo;
  late final web.HTMLSpanElement displayAgentName;
  late final web.HTMLSpanElement displayAgentVersion;
  
  late final web.HTMLDivElement toastContainer;

  ClientSideConnection? _connection;
  AgentSideConnection? _mockAgentConnection;
  String? _currentSessionId;
  bool _isMockMode = false;

  void init() {
    // Select elements
    agentUrlInput = web.document.querySelector('#agent-url') as web.HTMLInputElement;
    connectBtn = web.document.querySelector('#connect-btn') as web.HTMLButtonElement;
    disconnectBtn = web.document.querySelector('#disconnect-btn') as web.HTMLButtonElement;
    toggleMockBtn = web.document.querySelector('#toggle-mock-btn') as web.HTMLButtonElement;
    mockBtnText = web.document.querySelector('#mock-btn-text') as web.HTMLSpanElement;
    
    statusCard = web.document.querySelector('#status-card') as web.HTMLDivElement;
    statusText = web.document.querySelector('#status-text') as web.HTMLSpanElement;
    sessionInfo = web.document.querySelector('#session-info') as web.HTMLDivElement;
    capabilitiesList = web.document.querySelector('#capabilities-list') as web.HTMLDivElement;
    
    messagesContainer = web.document.querySelector('#messages-container') as web.HTMLDivElement;
    userInput = web.document.querySelector('#user-input') as web.HTMLTextAreaElement;
    sendBtn = web.document.querySelector('#send-btn') as web.HTMLButtonElement;
    
    connectionForm = web.document.querySelector('#connection-form') as web.HTMLDivElement;
    activeAgentInfo = web.document.querySelector('#active-agent-info') as web.HTMLDivElement;
    displayAgentName = web.document.querySelector('#display-agent-name') as web.HTMLSpanElement;
    displayAgentVersion = web.document.querySelector('#display-agent-version') as web.HTMLSpanElement;
    
    toastContainer = web.document.querySelector('#toast-container') as web.HTMLDivElement;

    // Listeners
    connectBtn.onClick.listen((_) => _connect());
    disconnectBtn.onClick.listen((_) => _disconnect());
    toggleMockBtn.onClick.listen((_) => _toggleMockMode());
    sendBtn.onClick.listen((_) => _sendMessage());
    
    userInput.onKeyDown.listen((event) {
      if (event.key == 'Enter' && !event.shiftKey) {
        event.preventDefault();
        _sendMessage();
      }
    });

    // Auto-resize textarea
    userInput.onInput.listen((_) {
      userInput.style.height = 'auto';
      userInput.style.height = '${userInput.scrollHeight}px';
    });
  }

  void _toggleMockMode() {
    if (_connection != null) {
      _showToast('Disconnect first to change mode');
      return;
    }
    _isMockMode = !_isMockMode;
    mockBtnText.textContent = _isMockMode ? 'Use Real Agent' : 'Use Mock Agent';
    agentUrlInput.disabled = _isMockMode;
    connectBtn.textContent = _isMockMode ? 'Start Mock' : 'Connect';
    _showToast(_isMockMode ? 'Switched to Mock Mode' : 'Switched to Real Mode');
  }

  Future<void> _connect() async {
    try {
      _setConnecting();
      
      AcpTransport clientTransport;
      
      if (_isMockMode) {
        // Create in-memory linked transports
        final aToB = StreamController<JsonRpcMessage>.broadcast();
        final bToA = StreamController<JsonRpcMessage>.broadcast();
        
        clientTransport = _LinkedTransport(inbound: bToA.stream, outboundSink: aToB);
        final agentTransport = _LinkedTransport(inbound: aToB.stream, outboundSink: bToA);
        
        _mockAgentConnection = AgentSideConnection(
          agentTransport, 
          handlerFactory: (conn) => MockAgent(conn)
        );
      } else {
        final url = agentUrlInput.value.trim();
        if (url.isEmpty) throw Exception('URL is required');
        clientTransport = await BrowserWebSocketTransport.connect(Uri.parse(url));
      }
      
      _connection = ClientSideConnection(
        clientTransport,
        handler: this,
        clientInfo: ImplementationInfo(name: 'ACP Web Explorer', version: '0.1.0'),
      );

      _connection!.onStateChange.listen((state) => _updateStatus(state));

      // 1. Initialize
      final initResponse = await _connection!.sendInitialize(protocolVersion: 1);
      _setConnected(initResponse);

      // 2. Create Session
      final sessionResponse = await _connection!.sendNewSession(cwd: '/web-explorer');
      _currentSessionId = sessionResponse.sessionId;
      _updateSessionInfo(_currentSessionId!);
      
      _addSystemMessage('Connection established. Ready.');
    } catch (e) {
      _setDisconnected();
      _showToast('Error: $e');
    }
  }

  void _disconnect() async {
    await _connection?.close();
    await _mockAgentConnection?.close();
    _setDisconnected();
  }

  void _sendMessage() async {
    final text = userInput.value.trim();
    if (text.isEmpty || _connection == null || _currentSessionId == null) return;

    userInput.value = '';
    userInput.style.height = 'auto';
    _addMessage(text, 'user');

    try {
      await _connection!.sendPrompt(
        sessionId: _currentSessionId!,
        prompt: [TextContent(text: text)],
      );
    } catch (e) {
      _showToast('Send failed: $e');
    }
  }

  void _updateStatus(ConnectionState state) {
    statusCard.className = 'status-card ${state.name.toLowerCase()}';
    statusText.textContent = state.name;
    if (state == ConnectionState.closed) _setDisconnected();
  }

  void _setConnecting() {
    connectBtn.disabled = true;
    toggleMockBtn.disabled = true;
    _updateStatus(ConnectionState.opening);
  }

  void _setConnected(InitializeResponse init) {
    connectionForm.classList.add('hidden');
    activeAgentInfo.classList.remove('hidden');
    displayAgentName.textContent = init.agentInfo?.name ?? 'Unknown';
    displayAgentVersion.textContent = 'v${init.agentInfo?.version ?? '?.?.?'}';
    
    userInput.disabled = false;
    sendBtn.disabled = false;
    
    _displayCapabilities(init.agentCapabilities);
    
    // Clear welcome screen
    if (messagesContainer.querySelector('.welcome-screen') != null) {
      messagesContainer.innerHTML = ''.toJS;
    }
  }

  void _setDisconnected() {
    connectionForm.classList.remove('hidden');
    activeAgentInfo.classList.add('hidden');
    connectBtn.disabled = false;
    toggleMockBtn.disabled = false;
    userInput.disabled = true;
    sendBtn.disabled = true;
    
    _updateStatus(ConnectionState.closed);
    _updateSessionInfo(null);
    capabilitiesList.innerHTML = ''.toJS;
    _connection = null;
    _mockAgentConnection = null;
    _currentSessionId = null;
  }

  void _updateSessionInfo(String? id) {
    if (id == null) {
      sessionInfo.textContent = 'No active session';
      sessionInfo.classList.add('empty');
    } else {
      sessionInfo.textContent = id;
      sessionInfo.classList.remove('empty');
    }
  }

  void _addMessage(String text, String sender) {
    final msgDiv = web.document.createElement('div') as web.HTMLDivElement;
    msgDiv.className = 'message $sender';
    
    final bubble = web.document.createElement('div') as web.HTMLDivElement;
    bubble.className = 'bubble';
    bubble.textContent = text;
    
    final meta = web.document.createElement('span') as web.HTMLSpanElement;
    meta.className = 'message-meta';
    meta.textContent = sender == 'user' ? 'You' : (displayAgentName.textContent ?? 'Agent');
    
    msgDiv.appendChild(meta);
    msgDiv.appendChild(bubble);
    messagesContainer.appendChild(msgDiv);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  void _addSystemMessage(String text) {
    final div = web.document.createElement('div') as web.HTMLDivElement;
    div.className = 'system-msg';
    div.textContent = text;
    messagesContainer.appendChild(div);
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }

  void _displayCapabilities(AgentCapabilities caps) {
    capabilitiesList.innerHTML = ''.toJS;
    final json = caps.toJson();
    json.forEach((key, value) {
      if (value == true || value is Map) {
        final span = web.document.createElement('span') as web.HTMLSpanElement;
        span.className = 'capability-tag';
        span.textContent = key;
        capabilitiesList.appendChild(span);
      }
    });
  }

  void _showToast(String message) {
    final toast = web.document.createElement('div') as web.HTMLDivElement;
    toast.className = 'toast';
    toast.textContent = message;
    toastContainer.appendChild(toast);
    Timer(const Duration(seconds: 4), () => toast.remove());
  }

  // --- ClientHandler Implementation ---

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    if (update is AgentMessageChunk) {
      final text = update.content['text'] as String?;
      if (text != null) {
        _addMessage(text, 'agent');
      }
    } else if (update is ToolCallSessionUpdate) {
      _addSystemMessage('Agent requested tool call: ${update.title}');
    }
  }

  @override
  Future<ReadTextFileResponse> readTextFile(ReadTextFileRequest request, {AcpCancellationToken? cancelToken}) async {
    _addSystemMessage('Agent read request: ${request.path}');
    throw Exception('Not allowed in explorer');
  }

  @override
  Future<WriteTextFileResponse> writeTextFile(WriteTextFileRequest request, {AcpCancellationToken? cancelToken}) async {
    _addSystemMessage('Agent write request: ${request.path}');
    throw Exception('Not allowed in explorer');
  }

  @override
  Future<CreateTerminalResponse> createTerminal(CreateTerminalRequest request, {AcpCancellationToken? cancelToken}) async {
    _addSystemMessage('Agent terminal request: ${request.command}');
    throw Exception('Terminal not supported in browser');
  }

  @override
  Future<TerminalOutputResponse> terminalOutput(TerminalOutputRequest request, {AcpCancellationToken? cancelToken}) async => 
      const TerminalOutputResponse(output: '', truncated: false);

  @override
  Future<void> killTerminal(KillTerminalCommandRequest request, {AcpCancellationToken? cancelToken}) async {}
  @override
  Future<void> releaseTerminal(ReleaseTerminalRequest request, {AcpCancellationToken? cancelToken}) async {}
  @override
  Future<WaitForTerminalExitResponse> waitForTerminalExit(WaitForTerminalExitRequest request, {AcpCancellationToken? cancelToken}) async => 
      const WaitForTerminalExitResponse(exitCode: 0);

  @override
  Future<RequestPermissionResponse> requestPermission(RequestPermissionRequest request, {AcpCancellationToken? cancelToken}) async {
    final granted = web.window.confirm('Agent requests permission for tool: ${request.toolCall['name']}');
    return RequestPermissionResponse(outcome: {'granted': granted});
  }

  @override
  Future<Map<String, dynamic>?> onExtMethod(String method, Map<String, dynamic>? params, {AcpCancellationToken? cancelToken}) async => null;
  @override
  Future<void> onExtNotification(String method, Map<String, dynamic>? params) async {}
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
    // Simulate network delay
    Timer(const Duration(milliseconds: 10), () => _outboundSink.add(message));
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _outboundSink.close();
  }
}
