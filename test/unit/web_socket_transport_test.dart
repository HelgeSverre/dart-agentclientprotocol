@TestOn('vm')
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/web_socket_transport.dart';
import 'package:test/test.dart';

/// Starts a local HTTP server that upgrades to WebSocket, then connects
/// a [WebSocketTransport] to it. Exposes the server-side socket for
/// sending/receiving frames in tests.
Future<_WsFixture> _startFixture() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final serverSocketCompleter = Completer<WebSocket>();

  server.listen((HttpRequest request) {
    if (request.uri.path == '/ws') {
      // ignore: close_sinks
      WebSocketTransformer.upgrade(request).then(
        serverSocketCompleter.complete,
        onError: serverSocketCompleter.completeError,
      );
    } else {
      request.response.statusCode = HttpStatus.notFound;
      unawaited(request.response.close());
    }
  });

  final url = Uri.parse('ws://localhost:${server.port}/ws');
  final transport = await WebSocketTransport.connect(url);
  // ignore: close_sinks
  final serverSocket = await serverSocketCompleter.future;

  return _WsFixture._(
    server: server,
    transport: transport,
    serverSocket: serverSocket,
  );
}

class _WsFixture {
  final HttpServer server;
  final WebSocketTransport transport;
  final WebSocket serverSocket;

  /// Messages received by the server socket.
  final List<String> receivedByServer = [];
  final List<Completer<void>> _receiveCompleters = [];
  StreamSubscription<dynamic>? _serverSub;

  _WsFixture._({
    required this.server,
    required this.transport,
    required this.serverSocket,
  }) {
    _serverSub = serverSocket.listen((dynamic frame) {
      if (frame is String) {
        receivedByServer.add(frame);
        for (final c in _receiveCompleters) {
          if (!c.isCompleted) c.complete();
        }
        _receiveCompleters.clear();
      }
    });
  }

  /// Returns a future that completes when the server receives a message.
  Future<void> get nextServerMessage {
    final c = Completer<void>();
    _receiveCompleters.add(c);
    return c.future;
  }

  /// Sends a JSON text frame from the server to the client.
  void sendFromServer(String text) {
    serverSocket.add(text);
  }

  /// Closes everything cleanly: server first, then transport.
  Future<void> close() async {
    try {
      await _serverSub?.cancel();
    } on Object {
      // Best effort.
    }
    try {
      await serverSocket.close();
    } on Object {
      // Best effort.
    }
    try {
      await server.close(force: true);
    } on Object {
      // Best effort.
    }
    try {
      await transport.close();
    } on Object {
      // Best effort.
    }
  }
}

void main() {
  group('WebSocketTransport', () {
    group('message exchange', () {
      late _WsFixture f;

      setUp(() async {
        f = await _startFixture();
      });

      tearDown(() => f.close());

      test('receives a message from server', () async {
        final received = Completer<JsonRpcMessage>();
        final sub = f.transport.messages.listen(received.complete);
        addTearDown(sub.cancel);

        final msg = {'jsonrpc': '2.0', 'method': 'test/hello'};
        f.sendFromServer(jsonEncode(msg));

        final message = await received.future;
        expect(message, isA<JsonRpcNotification>());
        expect((message as JsonRpcNotification).method, 'test/hello');
      });

      test('sends a message to server', () async {
        final sub = f.transport.messages.listen((_) {});
        addTearDown(sub.cancel);

        final postFuture = f.nextServerMessage;
        final notification = JsonRpcNotification(
          method: 'test/out',
          params: {'key': 'value'},
        );
        await f.transport.send(notification);
        await postFuture;

        expect(f.receivedByServer, hasLength(1));
        final decoded =
            jsonDecode(f.receivedByServer.first) as Map<String, dynamic>;
        expect(decoded['jsonrpc'], '2.0');
        expect(decoded['method'], 'test/out');
        expect(decoded['params'], {'key': 'value'});
      });

      test('receives multiple messages in sequence', () async {
        final messages = <JsonRpcMessage>[];
        final gotTwo = Completer<void>();
        final sub = f.transport.messages.listen((JsonRpcMessage msg) {
          messages.add(msg);
          if (messages.length == 2 && !gotTwo.isCompleted) gotTwo.complete();
        });
        addTearDown(sub.cancel);

        final msg1 = {'jsonrpc': '2.0', 'method': 'test/first'};
        final msg2 = {'jsonrpc': '2.0', 'method': 'test/second'};
        f.sendFromServer(jsonEncode(msg1));
        f.sendFromServer(jsonEncode(msg2));

        await gotTwo.future;
        expect(messages, hasLength(2));
        expect((messages[0] as JsonRpcNotification).method, 'test/first');
        expect((messages[1] as JsonRpcNotification).method, 'test/second');
      });

      test('receives request and response messages', () async {
        final messages = <JsonRpcMessage>[];
        final gotTwo = Completer<void>();
        final sub = f.transport.messages.listen((JsonRpcMessage msg) {
          messages.add(msg);
          if (messages.length == 2 && !gotTwo.isCompleted) {
            gotTwo.complete();
          }
        });
        addTearDown(sub.cancel);

        final req = {
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'test/echo',
          'params': {'data': 'hello'},
        };
        final resp = {
          'jsonrpc': '2.0',
          'id': 1,
          'result': {'data': 'hello'},
        };
        f.sendFromServer(jsonEncode(req));
        f.sendFromServer(jsonEncode(resp));

        await gotTwo.future;
        expect(messages, hasLength(2));
        expect(messages[0], isA<JsonRpcRequest>());
        expect((messages[0] as JsonRpcRequest).method, 'test/echo');
        expect(messages[1], isA<JsonRpcResponse>());
        expect((messages[1] as JsonRpcResponse).id, 1);
      });
    });

    group('close behavior', () {
      test('send after close throws StateError', () async {
        final f = await _startFixture();
        await f.close();
        expect(
          () => f.transport.send(JsonRpcNotification(method: 'test/noop')),
          throwsStateError,
        );
      });

      test('close is idempotent', () async {
        final f = await _startFixture();
        await f.close();
        // Second close should be a no-op.
        await f.transport.close();
      });

      test('close completes the message stream', () async {
        final f = await _startFixture();
        final done = Completer<void>();
        final sub = f.transport.messages.listen((_) {}, onDone: done.complete);
        addTearDown(sub.cancel);

        await f.close();
        await done.future;
      });

      test('server disconnect closes transport', () async {
        final f = await _startFixture();
        final done = Completer<void>();
        final sub = f.transport.messages.listen((_) {}, onDone: done.complete);
        addTearDown(sub.cancel);
        addTearDown(() => f.close());

        // Close only the server-side socket.
        await f.serverSocket.close();
        await done.future;
      });
    });

    group('error handling', () {
      late _WsFixture f;

      setUp(() async {
        f = await _startFixture();
      });

      tearDown(() => f.close());

      test('handles malformed JSON gracefully', () async {
        final errorReceived = Completer<Object>();
        final sub = f.transport.messages.listen(
          (_) {},
          onError: (Object error) {
            if (!errorReceived.isCompleted) errorReceived.complete(error);
          },
        );
        addTearDown(sub.cancel);

        f.sendFromServer('not valid json {{{');

        final error = await errorReceived.future;
        expect(error, isA<FormatException>());
      });

      test('exposes closeCode and closeReason', () async {
        final done = Completer<void>();
        final sub = f.transport.messages.listen((_) {}, onDone: done.complete);
        addTearDown(sub.cancel);

        await f.serverSocket.close(WebSocketStatus.normalClosure, 'all done');
        await done.future;

        expect(f.transport.closeCode, WebSocketStatus.normalClosure);
        expect(f.transport.closeReason, 'all done');
      });
    });
  });
}
