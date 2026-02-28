import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:test/test.dart';

/// Minimal handler implementing only the three required methods.
class MinimalAgentHandler extends AgentHandler {
  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const NewSessionResponse(sessionId: 'test-session');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async => const PromptResponse(stopReason: 'end_turn');
}

void main() {
  late MinimalAgentHandler handler;
  late AcpCancellationToken token;

  setUp(() {
    handler = MinimalAgentHandler();
    token = AcpCancellationSource().token;
  });

  group('AgentHandler optional methods throw methodNotFound', () {
    test('authenticate throws RpcErrorException with code -32601', () {
      expect(
        () => handler.authenticate(
          const AuthenticateRequest(methodId: 'test'),
          cancelToken: token,
        ),
        throwsA(isA<RpcErrorException>().having((e) => e.code, 'code', -32601)),
      );
    });

    test('loadSession throws RpcErrorException with code -32601', () {
      expect(
        () => handler.loadSession(
          const LoadSessionRequest(sessionId: 's1', cwd: '/tmp'),
          cancelToken: token,
        ),
        throwsA(isA<RpcErrorException>().having((e) => e.code, 'code', -32601)),
      );
    });

    test('setMode throws RpcErrorException with code -32601', () {
      expect(
        () => handler.setMode(
          const SetSessionModeRequest(sessionId: 's1', modeId: 'code'),
          cancelToken: token,
        ),
        throwsA(isA<RpcErrorException>().having((e) => e.code, 'code', -32601)),
      );
    });

    test('setConfigOption throws RpcErrorException with code -32601', () {
      expect(
        () => handler.setConfigOption(
          const SetSessionConfigOptionRequest(
            sessionId: 's1',
            configId: 'c1',
            value: 'v1',
          ),
          cancelToken: token,
        ),
        throwsA(isA<RpcErrorException>().having((e) => e.code, 'code', -32601)),
      );
    });
  });

  group('AgentHandler default notification/extension handlers', () {
    test('cancel does nothing', () async {
      await handler.cancel(const CancelNotification(sessionId: 's1'));
    });

    test('onExtMethod returns null', () async {
      final result = await handler.onExtMethod('_vendor/custom', {
        'key': 'value',
      }, cancelToken: token);
      expect(result, isNull);
    });

    test('onExtNotification does nothing', () async {
      await handler.onExtNotification('_vendor/notify', {'key': 'value'});
    });
  });
}
