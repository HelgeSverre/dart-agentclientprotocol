@TestOn('vm')
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/http_sse_transport.dart';
import 'package:test/test.dart';

/// Starts a local HTTP server with SSE (GET /sse) and POST (/message)
/// endpoints. Returns a record with the server, transport, and a function
/// to push SSE events.
Future<_SseFixture> _startFixture({Map<String, String>? headers}) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final postedBodies = <String>[];
  final postCompleters = <Completer<void>>[];
  HttpResponse? sseResponse;

  // ignore: cancel_subscriptions
  server.listen((HttpRequest request) {
    if (request.method == 'GET' && request.uri.path == '/sse') {
      // ignore: close_sinks
      final response = request.response;
      response.headers.set('Content-Type', 'text/event-stream');
      response.headers.set('Cache-Control', 'no-cache');
      response.bufferOutput = false;
      // Write an SSE comment to flush headers to client.
      response.write(': connected\n\n');
      sseResponse = response;
    } else if (request.method == 'POST' && request.uri.path == '/message') {
      utf8.decoder.bind(request).join().then((body) {
        postedBodies.add(body);
        request.response.statusCode = HttpStatus.ok;
        unawaited(request.response.close());
        for (final c in postCompleters) {
          if (!c.isCompleted) c.complete();
        }
        postCompleters.clear();
      });
    } else {
      request.response.statusCode = HttpStatus.notFound;
      unawaited(request.response.close());
    }
  });

  final baseUri = Uri.parse('http://localhost:${server.port}');
  final transport = await HttpSseTransport.connect(
    baseUri.resolve('/sse'),
    baseUri.resolve('/message'),
    headers: headers,
  );

  return _SseFixture._(
    server: server,
    transport: transport,
    postedBodies: postedBodies,
    postCompleters: postCompleters,
    getSseResponse: () => sseResponse,
  );
}

class _SseFixture {
  final HttpServer server;
  final HttpSseTransport transport;
  final List<String> postedBodies;
  final List<Completer<void>> _postCompleters;
  final HttpResponse? Function() _getSseResponse;

  _SseFixture._({
    required this.server,
    required this.transport,
    required this.postedBodies,
    required List<Completer<void>> postCompleters,
    required HttpResponse? Function() getSseResponse,
  }) : _postCompleters = postCompleters,
       _getSseResponse = getSseResponse;

  /// Returns a future that completes when the next POST is received.
  Future<void> get nextPost {
    final c = Completer<void>();
    _postCompleters.add(c);
    return c.future;
  }

  /// Writes raw SSE text to the connected client and flushes.
  Future<void> sendSse(String text) async {
    // ignore: close_sinks
    var response = _getSseResponse();
    for (var i = 0; i < 100 && response == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      response = _getSseResponse();
    }
    // ignore: close_sinks
    final r = _getSseResponse();
    if (r == null) throw StateError('No SSE client connected');
    r.write(text);
    await r.flush();
  }

  /// Closes everything cleanly: server first (terminates sockets),
  /// then transport.
  Future<void> close() async {
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
  group('HttpSseTransport', () {
    group('message exchange', () {
      late _SseFixture f;

      setUp(() async {
        f = await _startFixture();
      });

      tearDown(() => f.close());

      test('receives a message via SSE', () async {
        final received = Completer<JsonRpcMessage>();
        final sub = f.transport.messages.listen(received.complete);
        addTearDown(sub.cancel);

        final msg = {'jsonrpc': '2.0', 'method': 'test/hello'};
        await f.sendSse('data: ${jsonEncode(msg)}\n\n');

        final message = await received.future;
        expect(message, isA<JsonRpcNotification>());
        expect((message as JsonRpcNotification).method, 'test/hello');
      });

      test('receives multiple SSE events in sequence', () async {
        final messages = <JsonRpcMessage>[];
        final gotTwo = Completer<void>();
        final sub = f.transport.messages.listen((JsonRpcMessage msg) {
          messages.add(msg);
          if (messages.length == 2 && !gotTwo.isCompleted) gotTwo.complete();
        });
        addTearDown(sub.cancel);

        final msg1 = {'jsonrpc': '2.0', 'method': 'test/first'};
        final msg2 = {'jsonrpc': '2.0', 'method': 'test/second'};
        await f.sendSse('data: ${jsonEncode(msg1)}\n\n');
        await f.sendSse('data: ${jsonEncode(msg2)}\n\n');

        await gotTwo.future;
        expect(messages, hasLength(2));
        expect((messages[0] as JsonRpcNotification).method, 'test/first');
        expect((messages[1] as JsonRpcNotification).method, 'test/second');
      });

      test('ignores SSE comment lines', () async {
        final received = Completer<JsonRpcMessage>();
        final sub = f.transport.messages.listen(received.complete);
        addTearDown(sub.cancel);

        final msg = {'jsonrpc': '2.0', 'method': 'test/comment'};
        await f.sendSse(': this is a comment\ndata: ${jsonEncode(msg)}\n\n');

        final message = await received.future;
        expect(message, isA<JsonRpcNotification>());
        expect((message as JsonRpcNotification).method, 'test/comment');
      });

      test('stores last event ID', () async {
        final received = Completer<JsonRpcMessage>();
        final sub = f.transport.messages.listen(received.complete);
        addTearDown(sub.cancel);

        final msg = {'jsonrpc': '2.0', 'method': 'test/id'};
        await f.sendSse('id: 42\ndata: ${jsonEncode(msg)}\n\n');

        await received.future;
        expect(f.transport.lastEventId, '42');
      });

      test('sends a message via POST', () async {
        final sub = f.transport.messages.listen((_) {});
        addTearDown(sub.cancel);

        final postFuture = f.nextPost;
        final notification = JsonRpcNotification(
          method: 'test/out',
          params: {'key': 'value'},
        );
        await f.transport.send(notification);
        await postFuture;

        expect(f.postedBodies, hasLength(1));
        final decoded =
            jsonDecode(f.postedBodies.first) as Map<String, dynamic>;
        expect(decoded['jsonrpc'], '2.0');
        expect(decoded['method'], 'test/out');
        expect(decoded['params'], {'key': 'value'});
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
        await f.sendSse('data: ${jsonEncode(req)}\n\n');
        await f.sendSse('data: ${jsonEncode(resp)}\n\n');

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
    });

    group('custom headers', () {
      test('custom headers are sent on SSE and POST requests', () async {
        // Set up a separate server that captures request headers.
        final headerServer = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        addTearDown(() => headerServer.close(force: true));

        final sseHeaders = Completer<HttpHeaders>();
        final postHeaders = Completer<HttpHeaders>();

        headerServer.listen((HttpRequest request) {
          if (request.method == 'GET' && request.uri.path == '/sse') {
            sseHeaders.complete(request.headers);
            request.response.headers.set('Content-Type', 'text/event-stream');
            request.response.bufferOutput = false;
            request.response.write(': connected\n\n');
            // Keep SSE connection open.
          } else if (request.method == 'POST' &&
              request.uri.path == '/message') {
            postHeaders.complete(request.headers);
            request.drain<void>().then((_) {
              request.response.statusCode = HttpStatus.ok;
              unawaited(request.response.close());
            });
          }
        });

        final baseUri = Uri.parse('http://localhost:${headerServer.port}');
        final customTransport = await HttpSseTransport.connect(
          baseUri.resolve('/sse'),
          baseUri.resolve('/message'),
          headers: {'X-Custom': 'test-value'},
        );

        final receivedSseHeaders = await sseHeaders.future;
        expect(receivedSseHeaders.value('X-Custom'), 'test-value');

        await customTransport.send(JsonRpcNotification(method: 'test/headers'));
        final receivedPostHeaders = await postHeaders.future;
        expect(receivedPostHeaders.value('X-Custom'), 'test-value');

        // Clean up: server first, then transport.
        await headerServer.close(force: true);
        await customTransport.close();
      });
    });
  });
}
