@TestOn('vm')
library;

import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/stdio_process_transport.dart';
import 'package:test/test.dart';

/// Writes [source] to a temporary `.dart` file and returns its path.
String _writeTempScript(String source) {
  final dir = Directory.systemTemp.createTempSync('acp_test_');
  final file = File('${dir.path}/script.dart')..writeAsStringSync(source);
  return file.path;
}

void main() {
  final tempScripts = <String>[];

  String script(String source) {
    final path = _writeTempScript(source);
    tempScripts.add(path);
    return path;
  }

  tearDown(() {
    for (final path in tempScripts) {
      try {
        final file = File(path);
        file.deleteSync();
        file.parent.deleteSync();
      } on FileSystemException catch (_) {}
    }
    tempScripts.clear();
  });

  group('StdioProcessTransport', () {
    test('spawns process and receives NDJSON messages', () async {
      final scriptPath = script('''
import 'dart:convert';
import 'dart:io';
void main() {
  final msg = {'jsonrpc': '2.0', 'method': 'test/hello', 'params': {'greeting': 'hi'}};
  stdout.writeln(jsonEncode(msg));
}
''');

      final transport = await StdioProcessTransport.start(Platform.executable, [
        scriptPath,
      ]);

      final message = await transport.messages.first;
      expect(message, isA<JsonRpcNotification>());
      final notification = message as JsonRpcNotification;
      expect(notification.method, 'test/hello');
      expect(notification.params?['greeting'], 'hi');

      await transport.close();
    });

    test('sends message to process stdin', () async {
      final scriptPath = script('''
import 'dart:convert';
import 'dart:io';
void main() {
  final line = stdin.readLineSync()!;
  final req = jsonDecode(line) as Map<String, dynamic>;
  final resp = {'jsonrpc': '2.0', 'id': req['id'], 'result': {'echo': true}};
  stdout.writeln(jsonEncode(resp));
}
''');

      final transport = await StdioProcessTransport.start(Platform.executable, [
        scriptPath,
      ]);

      await transport.send(
        JsonRpcRequest(id: 1, method: 'test/echo', params: {}),
      );

      final response = await transport.messages.first;
      expect(response, isA<JsonRpcResponse>());
      final resp = response as JsonRpcResponse;
      expect(resp.id, 1);
      expect(resp.result, isA<Map<String, dynamic>>());
      expect((resp.result! as Map<String, dynamic>)['echo'], true);

      await transport.close();
    });

    test('exposes underlying process', () async {
      final scriptPath = script('''
import 'dart:io';
void main() async {
  ProcessSignal.sigterm.watch().listen((_) => exit(0));
  await stdin.first;
}
''');

      final transport = await StdioProcessTransport.start(Platform.executable, [
        scriptPath,
      ]);

      expect(transport.process, isA<Process>());
      expect(transport.process.pid, isPositive);

      await transport.close();
    });

    test('close sends SIGTERM and process exits', () async {
      final scriptPath = script('''
import 'dart:io';
void main() async {
  ProcessSignal.sigterm.watch().listen((_) => exit(0));
  await stdin.first;
}
''');

      final transport = await StdioProcessTransport.start(Platform.executable, [
        scriptPath,
      ]);

      await transport.close();
      final code = await transport.exitCode;
      expect(code, isNotNull);
    });

    test('propagates exit code', () async {
      final scriptPath = script('''
import 'dart:io';
void main() {
  exit(42);
}
''');

      final transport = await StdioProcessTransport.start(Platform.executable, [
        scriptPath,
      ]);

      final code = await transport.exitCode;
      expect(code, 42);

      await transport.close();
    });

    test('close is idempotent', () async {
      final scriptPath = script('''
void main() {}
''');

      final transport = await StdioProcessTransport.start(Platform.executable, [
        scriptPath,
      ]);

      // Wait for the process to exit naturally first.
      await transport.exitCode;
      await transport.close();
      await transport.close();
    });

    test('send after close throws StateError', () async {
      final scriptPath = script('''
void main() {}
''');

      final transport = await StdioProcessTransport.start(Platform.executable, [
        scriptPath,
      ]);

      await transport.close();

      expect(
        () => transport.send(JsonRpcNotification(method: 'test/noop')),
        throwsStateError,
      );
    });
  });
}
