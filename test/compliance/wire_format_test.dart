@Tags(['compliance'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

/// Loads and decodes a JSON fixture file from `test/fixtures/`.
Future<Map<String, dynamic>> _loadFixture(String name) async {
  final file = File('test/fixtures/$name');
  final content = await file.readAsString();
  return jsonDecode(content) as Map<String, dynamic>;
}

void main() {
  group('initialize', () {
    test('request parses as JsonRpcRequest', () async {
      final json = await _loadFixture('initialize_request.json');
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcRequest>());
      final req = msg as JsonRpcRequest;
      expect(req.id, 1);
      expect(req.method, 'initialize');
      expect(req.params, isNotNull);
      final params = req.params!;
      expect(params['protocolVersion'], 1);
      expect(
        (params['clientCapabilities'] as Map<String, dynamic>)['terminal'],
        false,
      );
    });

    test('request round-trips through toJson', () async {
      final json = await _loadFixture('initialize_request.json');
      final roundTripped = JsonRpcMessage.fromJson(json).toJson();
      // Full-envelope comparison: catches any field added or dropped, not
      // only fields the test happens to enumerate.
      expect(roundTripped, json);
    });

    test('response parses as JsonRpcResponse', () async {
      final json = await _loadFixture('initialize_response.json');
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcResponse>());
      final resp = msg as JsonRpcResponse;
      expect(resp.id, 1);
      expect(resp.isSuccess, isTrue);
      final result = resp.result! as Map<String, dynamic>;
      expect(result['protocolVersion'], 1);
      expect(result['authMethods'], isEmpty);
    });

    test('response round-trips through toJson', () async {
      final json = await _loadFixture('initialize_response.json');
      final roundTripped = JsonRpcMessage.fromJson(json).toJson();
      expect(roundTripped, json);
    });
  });

  group('session/new', () {
    test('request parses as JsonRpcRequest with correct params', () async {
      final json = await _loadFixture('session_new_request.json');
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcRequest>());
      final req = msg as JsonRpcRequest;
      expect(req.id, 2);
      expect(req.method, 'session/new');

      final params = NewSessionRequest.fromJson(req.params!);
      expect(params.cwd, '/home/user');
      expect(params.mcpServers, isEmpty);
    });

    test('request round-trips through toJson', () async {
      final json = await _loadFixture('session_new_request.json');
      final roundTripped = JsonRpcMessage.fromJson(json).toJson();
      expect(roundTripped, json);
    });

    test('response parses as JsonRpcResponse', () async {
      final json = await _loadFixture('session_new_response.json');
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcResponse>());
      final resp = msg as JsonRpcResponse;
      expect(resp.id, 2);
      expect(resp.isSuccess, isTrue);

      final result = NewSessionResponse.fromJson(
        resp.result! as Map<String, dynamic>,
      );
      expect(result.sessionId, 'sess-abc-123');
    });

    test('response round-trips through toJson', () async {
      final json = await _loadFixture('session_new_response.json');
      final roundTripped = JsonRpcMessage.fromJson(json).toJson();
      expect(roundTripped, json);
    });
  });

  group('session/update — agent_message_chunk', () {
    test('parses as JsonRpcNotification', () async {
      final json = await _loadFixture('session_update_agent_message.json');
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcNotification>());
      final notif = msg as JsonRpcNotification;
      expect(notif.method, 'session/update');
    });

    test('SessionNotification extracts update', () async {
      final json = await _loadFixture('session_update_agent_message.json');
      final notif = JsonRpcMessage.fromJson(json) as JsonRpcNotification;
      final sessionNotif = SessionNotification.fromJson(notif.params!);
      expect(sessionNotif.sessionId, 'sess-abc-123');

      expect(sessionNotif.update, isA<AgentMessageChunk>());
      final chunk = sessionNotif.update as AgentMessageChunk;
      expect(chunk.content, isA<TextContent>());
      expect((chunk.content as TextContent).text, 'Hello world');
    });

    test('round-trips through toJson', () async {
      final json = await _loadFixture('session_update_agent_message.json');
      final roundTripped = JsonRpcMessage.fromJson(json).toJson();
      expect(roundTripped, json);
    });
  });

  group('session/update — tool_call', () {
    test('parses as JsonRpcNotification', () async {
      final json = await _loadFixture('session_update_tool_call.json');
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcNotification>());
    });

    test('SessionNotification extracts ToolCallSessionUpdate', () async {
      final json = await _loadFixture('session_update_tool_call.json');
      final notif = JsonRpcMessage.fromJson(json) as JsonRpcNotification;
      final sessionNotif = SessionNotification.fromJson(notif.params!);
      expect(sessionNotif.sessionId, 'sess-abc-123');

      expect(sessionNotif.update, isA<ToolCallSessionUpdate>());
      final toolCall = sessionNotif.update as ToolCallSessionUpdate;
      expect(toolCall.toolCallId, 'tc-1');
      final toolCallJson = toolCall.toJson();
      expect(toolCallJson['name'], 'read_file');
      expect(
        (toolCallJson['args'] as Map<String, dynamic>)['path'],
        '/etc/hosts',
      );
    });

    test('round-trips through toJson', () async {
      final json = await _loadFixture('session_update_tool_call.json');
      final roundTripped = JsonRpcMessage.fromJson(json).toJson();
      expect(roundTripped, json);
    });
  });

  group('extension method', () {
    test('parses as JsonRpcRequest with _ prefix', () async {
      final json = await _loadFixture('extension_request.json');
      final msg = JsonRpcMessage.fromJson(json);
      expect(msg, isA<JsonRpcRequest>());
      final req = msg as JsonRpcRequest;
      expect(req.id, 5);
      expect(req.method, startsWith('_'));
      expect(req.method, '_vendor/custom');
      expect(req.params!['data'], 42);
    });

    test('round-trips through toJson', () async {
      final json = await _loadFixture('extension_request.json');
      final roundTripped = JsonRpcMessage.fromJson(json).toJson();
      expect(roundTripped, json);
    });
  });

  group('_meta preservation', () {
    test('PromptRequest preserves _meta through round-trip', () async {
      final json = await _loadFixture('meta_preservation.json');
      final msg = JsonRpcMessage.fromJson(json) as JsonRpcRequest;
      expect(msg.method, 'session/prompt');

      final promptReq = PromptRequest.fromJson(msg.params!);
      expect(promptReq.sessionId, 'sess-1');
      expect(promptReq.meta, isNotNull);
      expect(promptReq.meta!['progressToken'], 'p-1');

      final roundTripped = promptReq.toJson();
      expect(roundTripped['_meta'], {'progressToken': 'p-1'});
      expect(roundTripped['sessionId'], 'sess-1');
    });

    test('extensionData does not include _meta', () async {
      final json = await _loadFixture('meta_preservation.json');
      final msg = JsonRpcMessage.fromJson(json) as JsonRpcRequest;
      final promptReq = PromptRequest.fromJson(msg.params!);
      expect(promptReq.extensionData, isNull);
    });
  });

  group('SessionUpdate discriminators', () {
    test('agent_message_chunk', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'agent_message_chunk',
        'content': {'type': 'text', 'text': 'hi'},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<AgentMessageChunk>());
    });

    test('user_message_chunk', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'user_message_chunk',
        'content': {'type': 'text', 'text': 'hey'},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UserMessageChunk>());
    });

    test('tool_call', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'tool_call',
        'title': 'Writing file',
        'toolCallId': 'tc-2',
        'name': 'write_file',
        'args': <String, dynamic>{},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<ToolCallSessionUpdate>());
    });

    test('current_mode_update', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'current_mode_update',
        'currentModeId': 'code',
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<CurrentModeSessionUpdate>());
      expect((update as CurrentModeSessionUpdate).currentModeId, 'code');
    });

    test('unknown discriminator produces UnknownSessionUpdate', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'future_feature',
        'data': 123,
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UnknownSessionUpdate>());
      final unknown = update as UnknownSessionUpdate;
      expect(unknown.sessionUpdateType, 'future_feature');
      expect(unknown.rawJson, json);
    });

    test('missing discriminator produces UnknownSessionUpdate', () {
      final json = <String, dynamic>{'data': 'no discriminator'};
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UnknownSessionUpdate>());
      expect((update as UnknownSessionUpdate).sessionUpdateType, isNull);
    });
  });
}
