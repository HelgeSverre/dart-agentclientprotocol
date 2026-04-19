import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:acp/src/schema/unstable_methods.dart';
import 'package:test/test.dart';

import '../helpers/linked_transport.dart';

class _TestAgentHandler extends AgentHandler {
  _TestAgentHandler();

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const InitializeResponse(
    protocolVersion: 1,
    agentCapabilities: AgentCapabilities(
      sessionCapabilities: SessionCapabilities(list: <String, dynamic>{}),
    ),
  );

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

  @override
  Future<ListSessionsResponse> listSessions(
    ListSessionsRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const ListSessionsResponse(
    sessions: [SessionInfo(sessionId: 'sess-1', cwd: '/home')],
  );

  @override
  Future<ForkSessionResponse> forkSession(
    ForkSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => ForkSessionResponse(sessionId: 'sess-forked');
}

class _NoListAgentHandler extends _TestAgentHandler {
  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const InitializeResponse(protocolVersion: 1);
}

class _TestClientHandler extends ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {}
}

void main() {
  group('Stable session/list', () {
    test('sendListSessions works without unstable opt-in', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _TestAgentHandler(),
      );

      final clientConn = ClientSideConnection(
        clientTransport,
        handler: _TestClientHandler(),
      );

      await clientConn.sendInitialize(protocolVersion: 1);

      final response = await clientConn.sendListSessions(cwd: '/home');
      expect(response.sessions, hasLength(1));
      expect(response.sessions.first.sessionId, 'sess-1');
      expect(response.sessions.first.cwd, '/home');

      await clientConn.close();
    });

    test('sendListSessions enforces sessionCapabilities.list', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _NoListAgentHandler(),
      );

      final clientConn = ClientSideConnection(
        clientTransport,
        handler: _TestClientHandler(),
      );

      await clientConn.sendInitialize(protocolVersion: 1);

      expect(
        () => clientConn.sendListSessions(),
        throwsA(isA<CapabilityException>()),
      );

      await clientConn.close();
    });
  });

  group('Unstable method gating', () {
    test('sendForkSession throws UnsupportedError without opt-in', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _TestAgentHandler(),
        useUnstableProtocol: true,
      );

      final clientConn = ClientSideConnection(
        clientTransport,
        handler: _TestClientHandler(),
      );

      await clientConn.sendInitialize(protocolVersion: 1);

      expect(
        () => clientConn.sendForkSession(sessionId: 'sess-1', cwd: '/tmp'),
        throwsUnsupportedError,
      );

      await clientConn.close();
    });

    test('sendForkSession works with useUnstableProtocol: true', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _TestAgentHandler(),
        useUnstableProtocol: true,
      );

      final clientConn = ClientSideConnection(
        clientTransport,
        handler: _TestClientHandler(),
        useUnstableProtocol: true,
      );

      await clientConn.sendInitialize(protocolVersion: 1);

      final response = await clientConn.sendForkSession(
        sessionId: 'sess-1',
        cwd: '/tmp',
      );
      expect(response.sessionId, 'sess-forked');

      await clientConn.close();
    });

    test('agent-side rejects unstable methods without opt-in', () async {
      final (agentTransport, clientTransport) = createLinkedTransports();

      // Agent does NOT opt in to unstable
      AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _TestAgentHandler(),
      );

      final clientConn = ClientSideConnection(
        clientTransport,
        handler: _TestClientHandler(),
        useUnstableProtocol: true,
      );

      await clientConn.sendInitialize(protocolVersion: 1);

      // Agent should return an error (internal error wrapping UnsupportedError).
      expect(
        clientConn.sendForkSession(sessionId: 'sess-1', cwd: '/tmp'),
        throwsA(anything),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await clientConn.close();
    });
  });

  group('Unstable method schema round-trip', () {
    test('ListSessionsRequest round-trip', () {
      final json = <String, dynamic>{
        '_meta': {'trace': '123'},
      };
      final req = ListSessionsRequest.fromJson(json);
      expect(req.meta?['trace'], '123');
      expect(req.toJson(), json);
    });

    test('ListSessionsResponse round-trip', () {
      final json = <String, dynamic>{
        'sessions': [
          {'sessionId': 's1', 'cwd': '/home'},
        ],
      };
      final resp = ListSessionsResponse.fromJson(json);
      expect(resp.sessions, hasLength(1));
      expect(resp.sessions.first.sessionId, 's1');
      expect(resp.toJson(), json);
    });

    test('ForkSessionRequest round-trip', () {
      final json = <String, dynamic>{
        'additionalDirectories': <dynamic>[],
        'cwd': '/tmp',
        'mcpServers': <dynamic>[],
        'sessionId': 's1',
      };
      final req = ForkSessionRequest.fromJson(json);
      expect(req.sessionId, 's1');
      expect(req.cwd, '/tmp');
      expect(req.toJson(), json);
    });

    test('ForkSessionResponse round-trip', () {
      final json = <String, dynamic>{'sessionId': 's-forked'};
      final resp = ForkSessionResponse.fromJson(json);
      expect(resp.sessionId, 's-forked');
      expect(resp.toJson(), json);
    });

    test('extensionData preserved', () {
      final json = <String, dynamic>{
        'additionalDirectories': <dynamic>[],
        'cwd': '/home',
        'mcpServers': <dynamic>[],
        'sessionId': 's1',
        'customField': 42,
      };
      final req = ForkSessionRequest.fromJson(json);
      expect(req.extensionData?['customField'], 42);
      expect(req.toJson(), json);
    });
  });
}
