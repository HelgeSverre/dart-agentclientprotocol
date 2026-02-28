import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

/// Handler implementing only the required [onSessionUpdate] callback.
class DefaultClientHandler extends ClientHandler {
  /// Recorded session updates as (sessionId, update) pairs.
  final List<(String, SessionUpdate)> updates = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    updates.add((sessionId, update));
  }
}

void main() {
  late DefaultClientHandler handler;
  late AcpCancellationToken token;

  setUp(() {
    handler = DefaultClientHandler();
    token = AcpCancellationSource().token;
  });

  group('ClientHandler optional methods throw methodNotFound', () {
    test('readTextFile throws RpcErrorException with code -32601', () {
      expect(
        () => handler.readTextFile(
          const ReadTextFileRequest(sessionId: 's1', path: '/tmp/f.txt'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('writeTextFile throws RpcErrorException with code -32601', () {
      expect(
        () => handler.writeTextFile(
          const WriteTextFileRequest(
            sessionId: 's1',
            path: '/tmp/f.txt',
            content: 'hello',
          ),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('createTerminal throws RpcErrorException with code -32601', () {
      expect(
        () => handler.createTerminal(
          const CreateTerminalRequest(sessionId: 's1', command: 'ls'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('terminalOutput throws RpcErrorException with code -32601', () {
      expect(
        () => handler.terminalOutput(
          const TerminalOutputRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('releaseTerminal throws RpcErrorException with code -32601', () {
      expect(
        () => handler.releaseTerminal(
          const ReleaseTerminalRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('killTerminal throws RpcErrorException with code -32601', () {
      expect(
        () => handler.killTerminal(
          const KillTerminalCommandRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('waitForTerminalExit throws RpcErrorException with code -32601', () {
      expect(
        () => handler.waitForTerminalExit(
          const WaitForTerminalExitRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('requestPermission throws RpcErrorException with code -32601', () {
      expect(
        () => handler.requestPermission(
          const RequestPermissionRequest(
            sessionId: 's1',
            toolCall: {'tool': 'test'},
            options: [
              {'id': 'allow'},
            ],
          ),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });
  });

  group('ClientHandler onSessionUpdate', () {
    test('records updates', () {
      final update = AgentMessageChunk(
        content: const {'type': 'text', 'text': 'hello'},
      );
      handler.onSessionUpdate('s1', update);

      expect(handler.updates, hasLength(1));
      expect(handler.updates.first.$1, 's1');
      expect(handler.updates.first.$2, same(update));
    });
  });

  group('ClientHandler default extension handlers', () {
    test('onExtMethod returns null', () async {
      final result = await handler.onExtMethod(
        '_vendor/custom',
        {'key': 'value'},
        cancelToken: token,
      );
      expect(result, isNull);
    });

    test('onExtNotification does nothing', () async {
      await handler.onExtNotification('_vendor/notify', {'key': 'value'});
    });
  });
}
