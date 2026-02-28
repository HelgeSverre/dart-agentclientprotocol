@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/stdio_transport.dart';
import 'package:test/test.dart';

/// A mock IOSink that captures written data.
class _MockIOSink implements IOSink {
  final StringBuffer buffer = StringBuffer();
  final Completer<void> _doneCompleter = Completer<void>();
  bool flushed = false;

  @override
  Encoding encoding = utf8;

  @override
  void write(Object? object) => buffer.write(object);

  @override
  void writeln([Object? object = '']) {
    buffer.write(object);
    buffer.write('\n');
  }

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {
    buffer.writeAll(objects, separator);
  }

  @override
  void writeCharCode(int charCode) => buffer.writeCharCode(charCode);

  @override
  void add(List<int> data) => buffer.write(utf8.decode(data));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final data in stream) {
      add(data);
    }
  }

  @override
  Future<void> flush() async {
    flushed = true;
  }

  @override
  Future<void> close() async {}

  @override
  Future<void> get done => _doneCompleter.future;
}

void main() {
  group('StdioTransport', () {
    // ignore: close_sinks
    late StreamController<List<int>> inputController;
    // ignore: close_sinks
    late _MockIOSink mockOutput;
    late StdioTransport transport;
    // ignore: cancel_subscriptions
    late StreamSubscription<JsonRpcMessage> messageSub;

    setUp(() {
      inputController = StreamController<List<int>>();
      mockOutput = _MockIOSink();
      transport = StdioTransport(
        input: inputController.stream,
        output: mockOutput,
      );
    });

    /// Starts the transport and subscribes to messages so that
    /// [transport.close] can complete (the internal controller needs a
    /// listener to deliver its done event).
    void startAndListen({
      void Function(JsonRpcMessage)? onData,
      void Function(Object)? onError,
      void Function()? onDone,
    }) {
      transport.start();
      messageSub = transport.messages.listen(
        onData ?? (_) {},
        onError: onError ?? (Object _) {},
        onDone: onDone,
      );
    }

    tearDown(() async {
      await inputController.close();
      await transport.close();
      await messageSub.cancel();
    });

    test('start() begins listening and emits parsed messages', () async {
      final received = Completer<JsonRpcMessage>();
      startAndListen(onData: received.complete);

      final msg = {'jsonrpc': '2.0', 'method': 'test/hello'};
      inputController.add(utf8.encode('${jsonEncode(msg)}\n'));

      final message = await received.future;
      expect(message, isA<JsonRpcNotification>());
      expect((message as JsonRpcNotification).method, 'test/hello');
    });

    test('start() called twice throws StateError', () {
      startAndListen();
      expect(() => transport.start(), throwsStateError);
    });

    test('empty lines are skipped', () async {
      final received = Completer<JsonRpcMessage>();
      startAndListen(onData: received.complete);

      final msg = {'jsonrpc': '2.0', 'method': 'test/msg'};
      inputController.add(utf8.encode('\n\n${jsonEncode(msg)}\n\n'));

      final message = await received.future;
      expect(message, isA<JsonRpcNotification>());
    });

    test('whitespace-only lines are skipped', () async {
      final received = Completer<JsonRpcMessage>();
      startAndListen(onData: received.complete);

      final msg = {'jsonrpc': '2.0', 'method': 'test/msg'};
      inputController.add(utf8.encode('   \n${jsonEncode(msg)}\n'));

      final message = await received.future;
      expect(message, isA<JsonRpcNotification>());
    });

    test('invalid JSON emits FormatException error on stream', () async {
      final errors = <Object>[];
      startAndListen(onError: (Object e) => errors.add(e));

      inputController.add(utf8.encode('not valid json\n'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(errors, hasLength(1));
      expect(errors.first, isA<FormatException>());
    });

    test('multiple messages parsed in order', () async {
      final messages = <JsonRpcMessage>[];
      final gotTwo = Completer<void>();
      startAndListen(
        onData: (JsonRpcMessage msg) {
          messages.add(msg);
          if (messages.length == 2) gotTwo.complete();
        },
      );

      final msg1 = {'jsonrpc': '2.0', 'method': 'test/first'};
      final msg2 = {'jsonrpc': '2.0', 'method': 'test/second'};
      inputController.add(
        utf8.encode('${jsonEncode(msg1)}\n${jsonEncode(msg2)}\n'),
      );

      await gotTwo.future;
      expect(messages, hasLength(2));
      expect((messages[0] as JsonRpcNotification).method, 'test/first');
      expect((messages[1] as JsonRpcNotification).method, 'test/second');
    });

    test('send() writes NDJSON to output', () async {
      startAndListen();

      final notification = JsonRpcNotification(
        method: 'test/out',
        params: {'key': 'value'},
      );
      await transport.send(notification);

      final written = mockOutput.buffer.toString();
      final decoded = jsonDecode(written.trim()) as Map<String, dynamic>;
      expect(decoded['jsonrpc'], '2.0');
      expect(decoded['method'], 'test/out');
      expect(decoded['params'], {'key': 'value'});
    });

    test('send() after close throws StateError', () async {
      startAndListen();
      await inputController.close();
      // Wait for transport to close via the onDone handler.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        () => transport.send(JsonRpcNotification(method: 'test/noop')),
        throwsStateError,
      );
    });

    test('close() is idempotent', () async {
      startAndListen();
      await inputController.close();
      // Transport closes itself when input ends; calling close() again is safe.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await transport.close();
    });

    test('input stream ending closes transport', () async {
      final closed = Completer<void>();
      startAndListen(onDone: closed.complete);

      await inputController.close();
      await closed.future;
    });

    test('request message round-trip', () async {
      final received = Completer<JsonRpcMessage>();
      startAndListen(onData: received.complete);

      final reqJson = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'test/echo',
        'params': {'data': 'hello'},
      };
      inputController.add(utf8.encode('${jsonEncode(reqJson)}\n'));

      final message = await received.future;
      expect(message, isA<JsonRpcRequest>());
      final req = message as JsonRpcRequest;
      expect(req.id, 1);
      expect(req.method, 'test/echo');
      expect(req.params?['data'], 'hello');
    });

    test('response message round-trip', () async {
      final received = Completer<JsonRpcMessage>();
      startAndListen(onData: received.complete);

      final respJson = {
        'jsonrpc': '2.0',
        'id': 42,
        'result': {'status': 'ok'},
      };
      inputController.add(utf8.encode('${jsonEncode(respJson)}\n'));

      final message = await received.future;
      expect(message, isA<JsonRpcResponse>());
      final resp = message as JsonRpcResponse;
      expect(resp.id, 42);
      expect(resp.isSuccess, isTrue);
    });
  });
}
