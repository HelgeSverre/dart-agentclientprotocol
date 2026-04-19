@TestOn('vm')
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:io';

import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:acp/src/transport/stdio_process_transport.dart';
import 'package:test/test.dart';

class _RecordingClientHandler extends ClientHandler {
  final List<SessionUpdateEvent> receivedUpdates = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    receivedUpdates.add(
      SessionUpdateEvent(sessionId: sessionId, update: update),
    );
  }
}

void main() {
  group('StdioProcessTransport integration', () {
    test(
      'full flow: initialize → session/new → prompt → streaming update → close',
      () async {
        final transport = await StdioProcessTransport.start(
          Platform.resolvedExecutable,
          ['run', 'example/main.dart'],
        );
        addTearDown(() => transport.close());

        final handler = _RecordingClientHandler();
        final client = ClientSideConnection(transport, handler: handler);

        final streamUpdates = <SessionUpdateEvent>[];
        final updateSub = client.sessionUpdates.listen(streamUpdates.add);
        addTearDown(() => updateSub.cancel());

        // 1. Initialize
        final initResponse = await client.sendInitialize(protocolVersion: 1);
        expect(initResponse.protocolVersion, 1);

        // 2. New session
        final sessionResponse = await client.sendNewSession(cwd: '/home');
        expect(sessionResponse.sessionId, 'session-1');

        // 3. Prompt (agent streams an update before responding)
        final promptResponse = await client.sendPrompt(
          sessionId: 'session-1',
          prompt: [const TextContent(text: 'Hello')],
        );
        expect(promptResponse.stopReason, StopReason.endTurn);

        // Give the streaming notification time to arrive.
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Verify session update via handler callback.
        expect(handler.receivedUpdates, hasLength(1));
        expect(handler.receivedUpdates.first.sessionId, 'session-1');
        final chunk = handler.receivedUpdates.first.update as AgentMessageChunk;
        expect((chunk.content as TextContent).text, 'Echo: Hello');

        // Verify session update via stream.
        expect(streamUpdates, hasLength(1));
        expect(streamUpdates.first.sessionId, 'session-1');

        // 4. Close
        await client.close();
        final exitCode = await transport.exitCode.timeout(
          const Duration(seconds: 10),
        );
        // Accept clean exit (0), SIGTERM (143 on Linux/macOS), or SIGKILL
        // (137). Any of those proves close() actually terminated the child
        // — `isNotNull` could not distinguish that from "the process happened
        // to exit on its own for an unrelated reason".
        expect(exitCode, anyOf(0, 137, 143, lessThan(0)));
      },
    );

    test('process cleanup: closing transport kills subprocess', () async {
      final transport = await StdioProcessTransport.start(
        Platform.resolvedExecutable,
        ['run', 'example/main.dart'],
      );
      addTearDown(() => transport.close());

      final handler = _RecordingClientHandler();
      final client = ClientSideConnection(transport, handler: handler);

      await client.sendInitialize(protocolVersion: 1);

      await client.close();

      final exitCode = await transport.exitCode.timeout(
        const Duration(seconds: 10),
      );
      expect(exitCode, isNotNull);
    });
  });
}
