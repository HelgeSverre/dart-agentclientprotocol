@TestOn('vm')
@Tags(['integration'])
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/reconnecting_transport.dart';
import 'package:acp/src/transport/web_socket_transport.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// An echo WebSocket server that tracks connected sockets so they can be
/// forcefully closed.
class _EchoServer {
  final HttpServer _httpServer;
  final List<WebSocket> _sockets = [];

  _EchoServer._(this._httpServer);

  int get port => _httpServer.port;

  static Future<_EchoServer> start({int port = 0}) async {
    final httpServer = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      port,
    );
    final echoServer = _EchoServer._(httpServer);
    httpServer.listen((request) {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        WebSocketTransformer.upgrade(request).then((socket) {
          echoServer._sockets.add(socket);
          socket.listen((data) {
            socket.add(data);
          });
        });
      } else {
        request.response.statusCode = HttpStatus.notFound;
        unawaited(request.response.close());
      }
    });
    return echoServer;
  }

  /// Forcefully closes the server and all active WebSocket connections.
  Future<void> close() async {
    for (final socket in _sockets) {
      await socket.close();
    }
    _sockets.clear();
    await _httpServer.close(force: true);
  }
}

/// Creates a [JsonRpcNotification] for testing.
JsonRpcNotification _notification(String method) =>
    JsonRpcNotification(method: method);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReconnectingTransport + WebSocket integration', () {
    test('messages flow through reconnecting WebSocket transport', () async {
      final server = await _EchoServer.start();
      addTearDown(server.close);
      final port = server.port;

      final connected = Completer<void>();

      final transport = ReconnectingTransport(
        transportFactory:
            () => WebSocketTransport.connect(Uri.parse('ws://localhost:$port')),
        initialDelay: const Duration(milliseconds: 50),
        maxDelay: const Duration(milliseconds: 200),
        maxAttempts: 5,
      );
      addTearDown(transport.close);

      final eventSub = transport.events.listen((e) {
        if (e is Connected && !connected.isCompleted) connected.complete();
      });
      addTearDown(eventSub.cancel);

      await connected.future;

      // Send a message and expect the echo back.
      final received = transport.messages.first;
      await transport.send(_notification('test/ping'));

      final echo = await received;
      expect(echo, isA<JsonRpcNotification>());
      expect((echo as JsonRpcNotification).method, 'test/ping');
    });

    test('reconnects after server restart', () async {
      var server = await _EchoServer.start();
      final port = server.port;

      final events = <ReconnectionEvent>[];
      final initialConnected = Completer<void>();
      final disconnected = Completer<void>();
      final reconnected = Completer<void>();
      var connectedCount = 0;

      final transport = ReconnectingTransport(
        transportFactory:
            () => WebSocketTransport.connect(Uri.parse('ws://localhost:$port')),
        initialDelay: const Duration(milliseconds: 50),
        maxDelay: const Duration(milliseconds: 200),
        maxAttempts: 10,
      );
      addTearDown(transport.close);

      final eventSub = transport.events.listen((e) {
        events.add(e);
        if (e is Connected) {
          connectedCount++;
          if (connectedCount == 1 && !initialConnected.isCompleted) {
            initialConnected.complete();
          } else if (connectedCount >= 2 && !reconnected.isCompleted) {
            reconnected.complete();
          }
        }
        if (e is Disconnected && !disconnected.isCompleted) {
          disconnected.complete();
        }
      });
      addTearDown(eventSub.cancel);

      await initialConnected.future;

      // Kill the server (including WebSocket connections) to force
      // disconnection.
      await server.close();
      await disconnected.future;

      // Restart the server on the same port.
      server = await _EchoServer.start(port: port);
      addTearDown(server.close);

      // Wait for the transport to reconnect.
      await reconnected.future;

      // Verify message flow works after reconnection.
      final received = transport.messages.first;
      await transport.send(_notification('test/after-reconnect'));

      final echo = await received;
      expect(echo, isA<JsonRpcNotification>());
      expect((echo as JsonRpcNotification).method, 'test/after-reconnect');

      // Verify we saw the expected event sequence.
      expect(events, contains(isA<Connected>()));
      expect(events, contains(isA<Disconnected>()));
      expect(events, contains(isA<Reconnecting>()));
      final lastConnectedIndex = events.lastIndexWhere((e) => e is Connected);
      final reconnectingIndex = events.lastIndexWhere((e) => e is Reconnecting);
      expect(lastConnectedIndex, greaterThan(reconnectingIndex));
    });

    test('send fails gracefully during reconnection', () async {
      final server = await _EchoServer.start();
      final port = server.port;

      final initialConnected = Completer<void>();
      final disconnected = Completer<void>();

      final transport = ReconnectingTransport(
        transportFactory:
            () => WebSocketTransport.connect(Uri.parse('ws://localhost:$port')),
        initialDelay: const Duration(milliseconds: 50),
        maxDelay: const Duration(milliseconds: 200),
        maxAttempts: 5,
      );
      addTearDown(transport.close);

      final eventSub = transport.events.listen((e) {
        if (e is Connected && !initialConnected.isCompleted) {
          initialConnected.complete();
        }
        if (e is Disconnected && !disconnected.isCompleted) {
          disconnected.complete();
        }
      });
      addTearDown(eventSub.cancel);

      await initialConnected.future;

      // Kill the server — do NOT restart it.
      await server.close();
      await disconnected.future;

      // Trying to send while disconnected should throw.
      expect(
        () => transport.send(_notification('test/should-fail')),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Transport is not connected',
          ),
        ),
      );
    });
  });
}
