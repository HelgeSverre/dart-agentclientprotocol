@Timeout(Duration(seconds: 30))
library;

import 'dart:async';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/reconnecting_transport.dart';
import 'package:test/test.dart';

import '../helpers/mock_transport.dart';

void main() {
  group('ReconnectingTransport', () {
    test('initial connection — messages flow through', () async {
      final mock = MockTransport();
      final transport = ReconnectingTransport(
        transportFactory: () async => mock,
        initialDelay: const Duration(milliseconds: 10),
      );

      final messages = <JsonRpcMessage>[];
      transport.messages.listen(messages.add);

      // Wait for initial connection.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      mock.receive(
        const JsonRpcNotification(method: 'test/hello'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(messages, hasLength(1));
      expect((messages[0] as JsonRpcNotification).method, 'test/hello');

      await transport.close();
    });

    test('reconnects when underlying transport closes', () async {
      final mocks = <MockTransport>[];
      var factoryCalls = 0;

      final transport = ReconnectingTransport(
        transportFactory: () async {
          factoryCalls++;
          final mock = MockTransport();
          mocks.add(mock);
          return mock;
        },
        initialDelay: const Duration(milliseconds: 10),
      );

      final messages = <JsonRpcMessage>[];
      transport.messages.listen(messages.add);

      // Wait for initial connection.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(factoryCalls, 1);

      // Send a message on first transport.
      mocks[0].receive(
        const JsonRpcNotification(method: 'test/first'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simulate close — should trigger reconnection.
      await mocks[0].simulateClose();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(factoryCalls, 2);

      // Send a message on second transport.
      mocks[1].receive(
        const JsonRpcNotification(method: 'test/second'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(messages, hasLength(2));
      expect((messages[0] as JsonRpcNotification).method, 'test/first');
      expect((messages[1] as JsonRpcNotification).method, 'test/second');

      await transport.close();
    });

    test('send delegates to current transport', () async {
      final mock = MockTransport();
      final transport = ReconnectingTransport(
        transportFactory: () async => mock,
        initialDelay: const Duration(milliseconds: 10),
      );

      // Ensure messages stream has a listener.
      transport.messages.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      const notification = JsonRpcNotification(method: 'test/send');
      await transport.send(notification);

      expect(mock.sent, hasLength(1));
      expect((mock.sent[0] as JsonRpcNotification).method, 'test/send');

      await transport.close();
    });

    test('send throws when disconnected', () async {
      var factoryCalls = 0;
      final firstMock = MockTransport();
      final reconnectCompleter = Completer<MockTransport>();

      final transport = ReconnectingTransport(
        transportFactory: () async {
          factoryCalls++;
          if (factoryCalls == 1) return firstMock;
          // Block the second connection attempt so we stay disconnected.
          return reconnectCompleter.future;
        },
        initialDelay: const Duration(milliseconds: 10),
      );

      transport.messages.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Disconnect the first transport.
      await firstMock.simulateClose();
      // Give time for disconnection to be detected, but not enough for
      // factory to return (it's blocked).
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        () => transport.send(
          const JsonRpcNotification(method: 'test/fail'),
        ),
        throwsStateError,
      );

      // Clean up.
      reconnectCompleter.complete(MockTransport());
      await transport.close();
    });

    test('gives up after maxAttempts consecutive failures', () async {
      var factoryCalls = 0;
      final transport = ReconnectingTransport(
        transportFactory: () async {
          factoryCalls++;
          throw StateError('connection failed');
        },
        initialDelay: const Duration(milliseconds: 5),
        maxDelay: const Duration(milliseconds: 20),
        maxAttempts: 3,
      );

      final events = <ReconnectionEvent>[];
      transport.events.listen(events.add);
      transport.messages.listen((_) {});

      // Wait for all attempts to exhaust.
      await Future<void>.delayed(const Duration(milliseconds: 500));

      expect(factoryCalls, 3);
      expect(
        events.whereType<ReconnectionFailed>().toList(),
        hasLength(1),
      );
      expect(
        events.whereType<ReconnectionFailed>().first.attempts,
        3,
      );
    });

    test('close stops reconnection attempts', () async {
      final mocks = <MockTransport>[];

      final transport = ReconnectingTransport(
        transportFactory: () async {
          final mock = MockTransport();
          mocks.add(mock);
          return mock;
        },
        initialDelay: const Duration(milliseconds: 50),
      );

      transport.messages.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(mocks, hasLength(1));

      // Disconnect and immediately close.
      await mocks[0].simulateClose();
      await transport.close();

      // Wait to verify no further factory calls happen.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(mocks, hasLength(1));
    });

    test('exponential backoff — delay increases', () async {
      final delays = <Duration>[];

      final transport = ReconnectingTransport(
        transportFactory: () async {
          throw StateError('fail');
        },
        initialDelay: const Duration(milliseconds: 10),
        maxDelay: const Duration(milliseconds: 200),
        maxAttempts: 4,
      );

      transport.events.listen((ReconnectionEvent event) {
        if (event is Reconnecting) {
          delays.add(event.delay);
        }
      });
      transport.messages.listen((_) {});

      // Wait for all attempts.
      await Future<void>.delayed(const Duration(seconds: 2));

      // We get 4 failures -> 3 reconnecting events (between 1st fail and
      // 2nd attempt, 2nd and 3rd, 3rd and 4th). The 4th failure triggers
      // gave_up, not another reconnecting event.
      expect(delays, hasLength(3));

      // Verify delays are generally increasing (with jitter, check the
      // base trend).
      for (var i = 1; i < delays.length; i++) {
        // Each delay should be roughly double the previous (±jitter).
        // We check that delay[i] >= delay[i-1] * 0.5 to account for jitter.
        expect(
          delays[i].inMicroseconds,
          greaterThanOrEqualTo(delays[i - 1].inMicroseconds ~/ 2),
        );
      }
    });

    test('reconnection events stream emits expected events', () async {
      final mocks = <MockTransport>[];

      final transport = ReconnectingTransport(
        transportFactory: () async {
          final mock = MockTransport();
          mocks.add(mock);
          return mock;
        },
        initialDelay: const Duration(milliseconds: 10),
      );

      final events = <ReconnectionEvent>[];
      transport.events.listen(events.add);
      transport.messages.listen((_) {});

      // Wait for initial connection.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(events, hasLength(1));
      expect(events[0], isA<Connected>());

      // Disconnect.
      await mocks[0].simulateClose();
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should have: Connected, Disconnected, Reconnecting, Connected.
      expect(events, hasLength(4));
      expect(events[0], isA<Connected>());
      expect(events[1], isA<Disconnected>());
      expect(events[2], isA<Reconnecting>());
      expect(events[3], isA<Connected>());

      await transport.close();
    });

    test('send throws after close', () async {
      final mock = MockTransport();
      final transport = ReconnectingTransport(
        transportFactory: () async => mock,
        initialDelay: const Duration(milliseconds: 10),
      );

      transport.messages.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await transport.close();

      expect(
        () => transport.send(
          const JsonRpcNotification(method: 'test/closed'),
        ),
        throwsStateError,
      );
    });

    test('successful reconnection resets failure count', () async {
      var factoryCalls = 0;
      final mocks = <MockTransport>[];

      final transport = ReconnectingTransport(
        transportFactory: () async {
          factoryCalls++;
          // Fail on second call (first reconnect), succeed on third.
          if (factoryCalls == 2) {
            throw StateError('temporary failure');
          }
          final mock = MockTransport();
          mocks.add(mock);
          return mock;
        },
        initialDelay: const Duration(milliseconds: 10),
        maxDelay: const Duration(milliseconds: 20),
        maxAttempts: 3,
      );

      final events = <ReconnectionEvent>[];
      transport.events.listen(events.add);
      transport.messages.listen((_) {});

      // Wait for initial connection.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Disconnect first transport.
      await mocks[0].simulateClose();
      // Wait for failed reconnect + successful reconnect.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // Should have reconnected successfully.
      final connectedEvents = events.whereType<Connected>().toList();
      expect(connectedEvents, hasLength(2));

      // Now disconnect again — failure count should be reset, so it should
      // try again (not give up).
      await mocks[1].simulateClose();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final allConnected = events.whereType<Connected>().toList();
      expect(allConnected, hasLength(3));

      await transport.close();
    });
  });
}
