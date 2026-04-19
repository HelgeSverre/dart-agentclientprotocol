import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:test/test.dart';

void main() {
  group('JsonRpcRequest', () {
    test('parses a valid request', () {
      final json = {
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {'protocolVersion': 1},
      };
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcRequest>());
      final req = msg as JsonRpcRequest;
      expect(req.id, 1);
      expect(req.method, 'initialize');
      expect(req.params, {'protocolVersion': 1});
    });

    test('parses request with string id', () {
      final json = {'jsonrpc': '2.0', 'id': 'abc-123', 'method': 'session/new'};
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcRequest>());
      expect((msg as JsonRpcRequest).id, 'abc-123');
    });

    test('round-trips through toJson/fromJson', () {
      final original = JsonRpcRequest(
        id: 42,
        method: 'authenticate',
        params: {'methodId': 'env_var'},
      );
      final json = original.toJson();
      final parsed = JsonRpcMessage.fromJson(json) as JsonRpcRequest;
      expect(parsed.id, 42);
      expect(parsed.method, 'authenticate');
      expect(parsed.params, {'methodId': 'env_var'});
    });

    test('serializes without params when null', () {
      final req = JsonRpcRequest(id: 1, method: 'test');
      final json = req.toJson();
      expect(json.containsKey('params'), isFalse);
      expect(json['jsonrpc'], '2.0');
    });
  });

  group('JsonRpcNotification', () {
    test('parses a valid notification', () {
      final json = {
        'jsonrpc': '2.0',
        'method': 'session/update',
        'params': {'sessionId': 's1', 'update': <String, dynamic>{}},
      };
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcNotification>());
      final notif = msg as JsonRpcNotification;
      expect(notif.method, 'session/update');
      expect(notif.params!['sessionId'], 's1');
    });

    test('notification has no id', () {
      final notif = JsonRpcNotification(method: 'session/cancel');
      final json = notif.toJson();
      expect(json.containsKey('id'), isFalse);
    });
  });

  group('JsonRpcResponse', () {
    test('parses a success response', () {
      final json = {
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'protocolVersion': 1},
      };
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcResponse>());
      final resp = msg as JsonRpcResponse;
      expect(resp.isSuccess, isTrue);
      expect(resp.isError, isFalse);
      expect(resp.id, 1);
    });

    test('parses an error response', () {
      final json = {
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32601, 'message': 'Method not found'},
      };
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcResponse>());
      final resp = msg as JsonRpcResponse;
      expect(resp.isError, isTrue);
      expect(resp.error!.code, -32601);
      expect(resp.error!.message, 'Method not found');
    });

    test('parses error response with data', () {
      final json = {
        'jsonrpc': '2.0',
        'id': 2,
        'error': {
          'code': -32000,
          'message': 'Auth required',
          'data': {'hint': 'call authenticate first'},
        },
      };
      final resp = JsonRpcMessage.fromJson(json) as JsonRpcResponse;
      expect(resp.error!.data, isA<Map<String, dynamic>>());
    });

    test('rejects response with both result and error', () {
      expect(
        () => JsonRpcMessage.fromJson({
          'jsonrpc': '2.0',
          'id': 1,
          'result': <String, dynamic>{},
          'error': {'code': -32603, 'message': 'Internal error'},
        }),
        throwsFormatException,
      );
    });

    test('rejects response without result or error', () {
      expect(
        () => JsonRpcMessage.fromJson({'jsonrpc': '2.0', 'id': 1}),
        throwsFormatException,
      );
    });
  });

  group('fromJson error cases', () {
    test('rejects missing jsonrpc field', () {
      expect(
        () => JsonRpcMessage.fromJson({'id': 1, 'method': 'test'}),
        throwsFormatException,
      );
    });

    test('rejects wrong jsonrpc version', () {
      expect(
        () => JsonRpcMessage.fromJson({
          'jsonrpc': '1.0',
          'id': 1,
          'method': 'test',
        }),
        throwsFormatException,
      );
    });

    test('rejects message with no method or result/error', () {
      expect(
        () => JsonRpcMessage.fromJson({'jsonrpc': '2.0', 'id': 1}),
        throwsFormatException,
      );
    });
  });

  group('batch parsing', () {
    test('parseBatch with single object returns single-element list', () {
      final json = <String, dynamic>{
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
      };
      final messages = JsonRpcMessage.parseBatch(json);
      expect(messages, hasLength(1));
      expect(messages[0], isA<JsonRpcRequest>());
      expect((messages[0] as JsonRpcRequest).method, 'initialize');
    });

    test('parseBatch with array returns multiple messages', () {
      final json = <Object>[
        <String, dynamic>{'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'},
        <String, dynamic>{'jsonrpc': '2.0', 'id': 2, 'method': 'shutdown'},
      ];
      final messages = JsonRpcMessage.parseBatch(json);
      expect(messages, hasLength(2));
      expect((messages[0] as JsonRpcRequest).method, 'initialize');
      expect((messages[1] as JsonRpcRequest).method, 'shutdown');
    });

    test('parseBatch with empty array throws FormatException', () {
      expect(
        () => JsonRpcMessage.parseBatch(<Object>[]),
        throwsFormatException,
      );
    });

    test('parseBatch with non-object/array throws FormatException', () {
      expect(
        () => JsonRpcMessage.parseBatch('not valid'),
        throwsFormatException,
      );
    });

    test('parseBatch rejects non-object items in array', () {
      final json = <Object>[
        <String, dynamic>{'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'},
        42,
        'garbage',
      ];
      expect(() => JsonRpcMessage.parseBatch(json), throwsFormatException);
    });

    test('parseBatch handles mixed request/notification/response array', () {
      final json = <Object>[
        <String, dynamic>{'jsonrpc': '2.0', 'id': 1, 'method': 'initialize'},
        <String, dynamic>{'jsonrpc': '2.0', 'method': 'session/update'},
        <String, dynamic>{
          'jsonrpc': '2.0',
          'id': 2,
          'result': <String, dynamic>{'status': 'ok'},
        },
      ];
      final messages = JsonRpcMessage.parseBatch(json);
      expect(messages, hasLength(3));
      expect(messages[0], isA<JsonRpcRequest>());
      expect(messages[1], isA<JsonRpcNotification>());
      expect(messages[2], isA<JsonRpcResponse>());
    });
  });
}
