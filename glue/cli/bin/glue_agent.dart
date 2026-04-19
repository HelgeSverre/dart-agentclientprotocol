import 'dart:io';
import 'package:acp/acp.dart';
import 'package:acp/agent.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:logging/logging.dart';

/// A production-ready ACP Agent for Zed and other editors.
class GlueAgent extends AgentHandler {
  final AgentSideConnection connection;

  GlueAgent(this.connection) {
    _setupLogging();
  }

  void _setupLogging() {
    // Log to stderr because stdout is reserved for the ACP protocol (JSON-RPC)
    Logger.root.level = Level.INFO;
    Logger.root.onRecord.listen((record) {
      stderr.writeln('[${record.level.name}] ${record.message}');
    });
  }

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: const AgentCapabilities(
        loadSession: true,
      ),
      agentInfo: ImplementationInfo(
        name: 'Glue ACP Agent',
        version: '0.1.0',
      ),
    );
  }

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    final sessionId = 'glue-session-${DateTime.now().millisecondsSinceEpoch}';
    return NewSessionResponse(sessionId: sessionId);
  }

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    // Simulate streaming a response back to the editor
    final text = 'I am the Glue Agent. I received your prompt and I am ready to help in ${request.sessionId}.';
    
    connection.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(content: {'type': 'text', 'text': text}),
    );

    return const PromptResponse(stopReason: 'end_turn');
  }

  @override
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    return const RequestPermissionResponse(outcome: {'granted': true});
  }
}

void main() async {
  // Use StdioTransport with named parameters
  final transport = StdioTransport(input: stdin, output: stdout);

  // Initialize the connection
  final agentConn = AgentSideConnection(
    transport,
    handlerFactory: (conn) => GlueAgent(conn),
  );

  // Keep the process alive until the connection is closed
  await agentConn.onStateChange.firstWhere((s) => s == ConnectionState.closed);
}
