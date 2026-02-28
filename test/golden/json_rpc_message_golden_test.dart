import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:test/test.dart';

void main() {
  group('Error envelope shapes', () {
    test('parse error (-32700) without data', () {
      final resp = JsonRpcResponse(
        id: 1,
        error: JsonRpcError(code: -32700, message: 'Parse error'),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 1,
        'error': {'code': -32700, 'message': 'Parse error'},
      }));
    });

    test('parse error (-32700) with data', () {
      final resp = JsonRpcResponse(
        id: 1,
        error: JsonRpcError(
          code: -32700,
          message: 'Parse error',
          data: {'offset': 42},
        ),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 1,
        'error': {
          'code': -32700,
          'message': 'Parse error',
          'data': {'offset': 42},
        },
      }));
    });

    test('invalid request (-32600) without data', () {
      final resp = JsonRpcResponse(
        id: 2,
        error: JsonRpcError(code: -32600, message: 'Invalid request'),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 2,
        'error': {'code': -32600, 'message': 'Invalid request'},
      }));
    });

    test('invalid request (-32600) with data', () {
      final resp = JsonRpcResponse(
        id: 2,
        error: JsonRpcError(
          code: -32600,
          message: 'Invalid request',
          data: 'missing method',
        ),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 2,
        'error': {
          'code': -32600,
          'message': 'Invalid request',
          'data': 'missing method',
        },
      }));
    });

    test('method not found (-32601) without data', () {
      final resp = JsonRpcResponse(
        id: 3,
        error: JsonRpcError(code: -32601, message: 'Method not found'),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 3,
        'error': {'code': -32601, 'message': 'Method not found'},
      }));
    });

    test('method not found (-32601) with data', () {
      final resp = JsonRpcResponse(
        id: 3,
        error: JsonRpcError(
          code: -32601,
          message: 'Method not found',
          data: {'method': 'unknown/call'},
        ),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 3,
        'error': {
          'code': -32601,
          'message': 'Method not found',
          'data': {'method': 'unknown/call'},
        },
      }));
    });

    test('internal error (-32603) without data', () {
      final resp = JsonRpcResponse(
        id: 4,
        error: JsonRpcError(code: -32603, message: 'Internal error'),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 4,
        'error': {'code': -32603, 'message': 'Internal error'},
      }));
    });

    test('internal error (-32603) with data', () {
      final resp = JsonRpcResponse(
        id: 4,
        error: JsonRpcError(
          code: -32603,
          message: 'Internal error',
          data: {'stack': 'trace here'},
        ),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 4,
        'error': {
          'code': -32603,
          'message': 'Internal error',
          'data': {'stack': 'trace here'},
        },
      }));
    });

    test('auth required (-32000) without data', () {
      final resp = JsonRpcResponse(
        id: 5,
        error: JsonRpcError(code: -32000, message: 'Auth required'),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 5,
        'error': {'code': -32000, 'message': 'Auth required'},
      }));
    });

    test('auth required (-32000) with data', () {
      final resp = JsonRpcResponse(
        id: 5,
        error: JsonRpcError(
          code: -32000,
          message: 'Auth required',
          data: {'hint': 'call authenticate first'},
        ),
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 5,
        'error': {
          'code': -32000,
          'message': 'Auth required',
          'data': {'hint': 'call authenticate first'},
        },
      }));
    });
  });

  group('Notification golden shapes', () {
    test('notification without params', () {
      final notif = JsonRpcNotification(method: 'session/cancel');
      expect(notif.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'method': 'session/cancel',
      }));
    });

    test('notification with params', () {
      final notif = JsonRpcNotification(
        method: 'session/update',
        params: {'sessionId': 's1', 'update': <String, dynamic>{}},
      );
      expect(notif.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'method': 'session/update',
        'params': {'sessionId': 's1', 'update': <String, dynamic>{}},
      }));
    });
  });

  group('Request golden shapes', () {
    test('request with int id and no params', () {
      final req = JsonRpcRequest(id: 1, method: 'initialize');
      expect(req.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
      }));
    });

    test('request with int id and params', () {
      final req = JsonRpcRequest(
        id: 42,
        method: 'authenticate',
        params: {'methodId': 'env_var'},
      );
      expect(req.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 42,
        'method': 'authenticate',
        'params': {'methodId': 'env_var'},
      }));
    });

    test('request with string id and no params', () {
      final req = JsonRpcRequest(id: 'abc-123', method: 'session/new');
      expect(req.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 'abc-123',
        'method': 'session/new',
      }));
    });

    test('request with string id and params', () {
      final req = JsonRpcRequest(
        id: 'req-7',
        method: 'session/prompt',
        params: {'sessionId': 's1', 'text': 'hello'},
      );
      expect(req.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 'req-7',
        'method': 'session/prompt',
        'params': {'sessionId': 's1', 'text': 'hello'},
      }));
    });
  });

  group('Response golden shapes', () {
    test('success response with map result', () {
      final resp = JsonRpcResponse(
        id: 1,
        result: <String, dynamic>{'protocolVersion': 1, 'name': 'agent'},
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 1,
        'result': {'protocolVersion': 1, 'name': 'agent'},
      }));
    });

    test('success response with empty map result', () {
      final resp = JsonRpcResponse(
        id: 2,
        result: <String, dynamic>{},
      );
      expect(resp.toJson(), equals(<String, dynamic>{
        'jsonrpc': '2.0',
        'id': 2,
        'result': <String, dynamic>{},
      }));
    });
  });

  group('Malformed message rejection', () {
    test('missing jsonrpc field entirely', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'id': 1,
          'method': 'test',
        }),
        throwsFormatException,
      );
    });

    test('wrong jsonrpc version ("1.0")', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': '1.0',
          'id': 1,
          'method': 'test',
        }),
        throwsFormatException,
      );
    });

    test('null jsonrpc value', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': null,
          'id': 1,
          'method': 'test',
        }),
        throwsFormatException,
      );
    });

    test('missing method and no result/error (just has id)', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': 1,
        }),
        throwsFormatException,
      );
    });

    test('invalid id type: bool', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': true,
          'method': 'test',
        }),
        throwsFormatException,
      );
    });

    test('invalid id type: list', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': <int>[1, 2],
          'method': 'test',
        }),
        throwsFormatException,
      );
    });

    test('invalid id type: null', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': null,
          'method': 'test',
        }),
        throwsFormatException,
      );
    });

    test('method is not a string: int', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': 1,
          'method': 42,
        }),
        throwsFormatException,
      );
    });

    test('method is not a string: null when has id', () {
      expect(
        () => JsonRpcMessage.fromJson(<String, dynamic>{
          'jsonrpc': '2.0',
          'id': 1,
          'method': null,
        }),
        throwsFormatException,
      );
    });
  });
}
