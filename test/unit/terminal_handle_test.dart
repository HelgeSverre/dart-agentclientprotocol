import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

import '../helpers/linked_transport.dart';

class _TerminalAgentHandler extends AgentHandler {
  final AgentSideConnection conn;

  _TerminalAgentHandler(this.conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const NewSessionResponse(sessionId: 'sess-1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const PromptResponse(stopReason: 'end_turn');
}

class _TerminalClientHandler extends ClientHandler {
  final List<String> calls = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {}

  @override
  Future<CreateTerminalResponse> createTerminal(
    CreateTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('createTerminal:${request.command}');
    return const CreateTerminalResponse(terminalId: 'term-1');
  }

  @override
  Future<TerminalOutputResponse> terminalOutput(
    TerminalOutputRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('terminalOutput:${request.terminalId}');
    return const TerminalOutputResponse(
      output: 'hello world',
      truncated: false,
    );
  }

  @override
  Future<void> killTerminal(
    KillTerminalCommandRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('killTerminal:${request.terminalId}');
  }

  @override
  Future<WaitForTerminalExitResponse> waitForTerminalExit(
    WaitForTerminalExitRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('waitForExit:${request.terminalId}');
    return const WaitForTerminalExitResponse(exitCode: 0);
  }

  @override
  Future<void> releaseTerminal(
    ReleaseTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    calls.add('releaseTerminal:${request.terminalId}');
  }
}

void main() {
  group('TerminalHandle', () {
    late AgentSideConnection agentConn;
    late ClientSideConnection clientConn;
    late _TerminalClientHandler clientHandler;

    setUp(() async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _TerminalAgentHandler(conn),
        capabilityEnforcement: CapabilityEnforcement.permissive,
      );

      clientHandler = _TerminalClientHandler();
      clientConn = ClientSideConnection(
        clientTransport,
        handler: clientHandler,
        clientCapabilities: const ClientCapabilities(terminal: true),
      );

      await clientConn.sendInitialize(protocolVersion: 1);
      await clientConn.sendNewSession(cwd: '/home');
    });

    tearDown(() async {
      await clientConn.close();
      await agentConn.close();
    });

    test('createTerminalHandle returns a handle', () async {
      final handle = await agentConn.createTerminalHandle(
        sessionId: 'sess-1',
        command: 'echo',
        args: ['hello'],
      );

      expect(handle.terminalId, 'term-1');
      expect(handle.sessionId, 'sess-1');
      expect(handle.isDisposed, isFalse);
      expect(clientHandler.calls, contains('createTerminal:echo'));

      await handle.dispose();
    });

    test('output() delegates to connection', () async {
      final handle = await agentConn.createTerminalHandle(
        sessionId: 'sess-1',
        command: 'ls',
      );

      final output = await handle.output();
      expect(output.output, 'hello world');
      expect(clientHandler.calls, contains('terminalOutput:term-1'));

      await handle.dispose();
    });

    test('kill() delegates to connection', () async {
      final handle = await agentConn.createTerminalHandle(
        sessionId: 'sess-1',
        command: 'sleep',
      );

      await handle.kill();
      expect(clientHandler.calls, contains('killTerminal:term-1'));

      await handle.dispose();
    });

    test('waitForExit() delegates to connection', () async {
      final handle = await agentConn.createTerminalHandle(
        sessionId: 'sess-1',
        command: 'true',
      );

      final result = await handle.waitForExit();
      expect(result.exitCode, 0);
      expect(clientHandler.calls, contains('waitForExit:term-1'));

      await handle.dispose();
    });

    test('dispose() releases terminal', () async {
      final handle = await agentConn.createTerminalHandle(
        sessionId: 'sess-1',
        command: 'cat',
      );

      await handle.dispose();
      expect(handle.isDisposed, isTrue);
      expect(clientHandler.calls, contains('releaseTerminal:term-1'));
    });

    test('dispose() is idempotent', () async {
      final handle = await agentConn.createTerminalHandle(
        sessionId: 'sess-1',
        command: 'cat',
      );

      await handle.dispose();
      await handle.dispose();
      expect(
        clientHandler.calls.where((c) => c == 'releaseTerminal:term-1'),
        hasLength(1),
      );
    });

    test('methods throw after dispose', () async {
      final handle = await agentConn.createTerminalHandle(
        sessionId: 'sess-1',
        command: 'cat',
      );

      await handle.dispose();

      expect(() => handle.output(), throwsStateError);
      expect(() => handle.kill(), throwsStateError);
      expect(() => handle.waitForExit(), throwsStateError);
      expect(() => handle.release(), throwsStateError);
    });
  });
}
