@TestOn('vm')
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/streamable_http_transport.dart';
import 'package:test/test.dart';

/// Starts a local HTTP server that handles POST, GET, and DELETE on `/acp`.
/// Returns a fixture with helpers for driving tests.
Future<_StreamableFixture> _startFixture() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final postedBodies = <String>[];
  final postedHeaders = <HttpHeaders>[];
  final postCompleters = <Completer<void>>[];
  HttpResponse? sseResponse;
  var sessionId = '';
  var replyMode = _ReplyMode.json;
  Map<String, dynamic>? jsonReply;
  List<String>? sseReplyEvents;
  var postStatus = HttpStatus.ok;
  var getStatus = HttpStatus.ok;

  // ignore: cancel_subscriptions
  server.listen((HttpRequest request) {
    if (request.method == 'POST' && request.uri.path == '/acp') {
      utf8.decoder.bind(request).join().then((body) {
        postedBodies.add(body);
        postedHeaders.add(request.headers);

        if (sessionId.isNotEmpty) {
          request.response.headers.set('Mcp-Session-Id', sessionId);
        }

        if (postStatus == HttpStatus.accepted) {
          request.response.statusCode = HttpStatus.accepted;
          unawaited(request.response.close());
        } else if (replyMode == _ReplyMode.sse) {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.set('Content-Type', 'text/event-stream');
          request.response.bufferOutput = false;
          if (sseReplyEvents != null) {
            for (final event in sseReplyEvents!) {
              request.response.write(event);
            }
          }
          unawaited(request.response.close());
        } else {
          request.response.statusCode = postStatus;
          request.response.headers.set('Content-Type', 'application/json');
          if (jsonReply != null) {
            request.response.write(jsonEncode(jsonReply));
          }
          unawaited(request.response.close());
        }

        for (final c in postCompleters) {
          if (!c.isCompleted) c.complete();
        }
        postCompleters.clear();
      });
    } else if (request.method == 'GET' && request.uri.path == '/acp') {
      if (getStatus != HttpStatus.ok) {
        request.response.statusCode = getStatus;
        unawaited(request.response.close());
        return;
      }
      // ignore: close_sinks
      final response = request.response;
      response.statusCode = HttpStatus.ok;
      response.headers.set('Content-Type', 'text/event-stream');
      response.headers.set('Cache-Control', 'no-cache');
      response.bufferOutput = false;
      response.write(': connected\n\n');
      sseResponse = response;
    } else if (request.method == 'DELETE' && request.uri.path == '/acp') {
      request.response.statusCode = HttpStatus.ok;
      unawaited(request.response.close());
    } else {
      request.response.statusCode = HttpStatus.notFound;
      unawaited(request.response.close());
    }
  });

  final baseUri = Uri.parse('http://localhost:${server.port}/acp');
  final transport = StreamableHttpTransport(baseUri);

  return _StreamableFixture._(
    server: server,
    transport: transport,
    postedBodies: postedBodies,
    postedHeaders: postedHeaders,
    postCompleters: postCompleters,
    getSseResponse: () => sseResponse,
    setSessionId: (String id) => sessionId = id,
    setReplyMode: (_ReplyMode mode) => replyMode = mode,
    setJsonReply: (Map<String, dynamic>? reply) => jsonReply = reply,
    setSseReplyEvents: (List<String>? events) => sseReplyEvents = events,
    setPostStatus: (int status) => postStatus = status,
    setGetStatus: (int status) => getStatus = status,
  );
}

enum _ReplyMode { json, sse }

class _StreamableFixture {
  final HttpServer server;
  final StreamableHttpTransport transport;
  final List<String> postedBodies;
  final List<HttpHeaders> postedHeaders;
  final List<Completer<void>> _postCompleters;
  final HttpResponse? Function() _getSseResponse;
  final void Function(String) setSessionId;
  final void Function(_ReplyMode) setReplyMode;
  final void Function(Map<String, dynamic>?) setJsonReply;
  final void Function(List<String>?) setSseReplyEvents;
  final void Function(int) setPostStatus;
  final void Function(int) setGetStatus;

  _StreamableFixture._({
    required this.server,
    required this.transport,
    required this.postedBodies,
    required this.postedHeaders,
    required List<Completer<void>> postCompleters,
    required HttpResponse? Function() getSseResponse,
    required this.setSessionId,
    required this.setReplyMode,
    required this.setJsonReply,
    required this.setSseReplyEvents,
    required this.setPostStatus,
    required this.setGetStatus,
  }) : _postCompleters = postCompleters,
       _getSseResponse = getSseResponse;

  /// Returns a future that completes when the next POST is received.
  Future<void> get nextPost {
    final c = Completer<void>();
    _postCompleters.add(c);
    return c.future;
  }

  /// Writes raw SSE text to the connected GET SSE client and flushes.
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

  /// Closes everything cleanly: server first, then transport.
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
  group('StreamableHttpTransport', () {
    group('POST message exchange', () {
      late _StreamableFixture f;

      setUp(() async {
        f = await _startFixture();
      });

      tearDown(() => f.close());

      test('sends notification and receives 202', () async {
        f.setPostStatus(HttpStatus.accepted);

        final notification = JsonRpcNotification(method: 'notifications/test');
        await f.transport.send(notification);

        expect(f.postedBodies, hasLength(1));
        final decoded =
            jsonDecode(f.postedBodies.first) as Map<String, dynamic>;
        expect(decoded['method'], 'notifications/test');
      });

      test('sends request and receives JSON response', () async {
        final responseJson = {
          'jsonrpc': '2.0',
          'id': 1,
          'result': {'status': 'ok'},
        };
        f.setReplyMode(_ReplyMode.json);
        f.setJsonReply(responseJson);

        final received = Completer<JsonRpcMessage>();
        final sub = f.transport.messages.listen(received.complete);
        addTearDown(sub.cancel);

        final request = JsonRpcRequest(
          id: 1,
          method: 'initialize',
          params: {'clientInfo': 'test'},
        );
        await f.transport.send(request);

        final message = await received.future;
        expect(message, isA<JsonRpcResponse>());
        final response = message as JsonRpcResponse;
        expect(response.id, 1);
        expect(response.result, {'status': 'ok'});
      });

      test('sends request and receives SSE response', () async {
        final responseJson = {
          'jsonrpc': '2.0',
          'id': 2,
          'result': {'name': 'test-agent'},
        };
        f.setReplyMode(_ReplyMode.sse);
        f.setSseReplyEvents(['data: ${jsonEncode(responseJson)}\n\n']);

        final received = Completer<JsonRpcMessage>();
        final sub = f.transport.messages.listen(received.complete);
        addTearDown(sub.cancel);

        final request = JsonRpcRequest(id: 2, method: 'initialize');
        await f.transport.send(request);

        final message = await received.future;
        expect(message, isA<JsonRpcResponse>());
        final response = message as JsonRpcResponse;
        expect(response.id, 2);
      });

      test('captures session ID from response header', () async {
        f.setSessionId('test-session-123');
        f.setPostStatus(HttpStatus.accepted);

        expect(f.transport.sessionId, isNull);
        await f.transport.send(JsonRpcNotification(method: 'test/init'));
        expect(f.transport.sessionId, 'test-session-123');
      });

      test('includes session ID in subsequent requests', () async {
        f.setSessionId('session-abc');
        f.setPostStatus(HttpStatus.accepted);

        // First request — captures the session ID.
        await f.transport.send(JsonRpcNotification(method: 'test/first'));
        expect(f.transport.sessionId, 'session-abc');

        // Second request — should include Mcp-Session-Id header.
        await f.transport.send(JsonRpcNotification(method: 'test/second'));

        expect(f.postedHeaders, hasLength(2));
        expect(f.postedHeaders[1].value('Mcp-Session-Id'), 'session-abc');
      });

      test('handles batch SSE response', () async {
        final batch = [
          {'jsonrpc': '2.0', 'id': 1, 'result': 'first'},
          {'jsonrpc': '2.0', 'id': 2, 'result': 'second'},
        ];
        f.setReplyMode(_ReplyMode.sse);
        f.setSseReplyEvents(['data: ${jsonEncode(batch)}\n\n']);

        final messages = <JsonRpcMessage>[];
        final gotTwo = Completer<void>();
        final sub = f.transport.messages.listen((JsonRpcMessage msg) {
          messages.add(msg);
          if (messages.length == 2 && !gotTwo.isCompleted) gotTwo.complete();
        });
        addTearDown(sub.cancel);

        await f.transport.send(JsonRpcRequest(id: 1, method: 'test/batch'));

        await gotTwo.future;
        expect(messages, hasLength(2));
        expect((messages[0] as JsonRpcResponse).id, 1);
        expect((messages[1] as JsonRpcResponse).id, 2);
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
    });

    group('GET SSE stream', () {
      late _StreamableFixture f;

      setUp(() async {
        f = await _startFixture();
      });

      tearDown(() => f.close());

      test('opens SSE stream for server-initiated messages', () async {
        final received = Completer<JsonRpcMessage>();
        final sub = f.transport.messages.listen(received.complete);
        addTearDown(sub.cancel);

        await f.transport.openSseStream();

        final notification = {
          'jsonrpc': '2.0',
          'method': 'server/push',
          'params': {'data': 'hello'},
        };
        await f.sendSse('data: ${jsonEncode(notification)}\n\n');

        final message = await received.future;
        expect(message, isA<JsonRpcNotification>());
        expect((message as JsonRpcNotification).method, 'server/push');
      });

      test('handles 405 gracefully', () async {
        f.setGetStatus(HttpStatus.methodNotAllowed);

        // Should not throw.
        await f.transport.openSseStream();
      });
    });
  });
}
