import 'package:acp/schema.dart';
import 'package:test/test.dart';

void main() {
  group('ContentBlock', () {
    test('deserializes TextContent', () {
      final json = {'type': 'text', 'text': 'hello world'};
      final block = ContentBlock.fromJson(json);
      expect(block, isA<TextContent>());
      expect((block as TextContent).text, 'hello world');
    });

    test('deserializes ImageContent', () {
      final json = {
        'type': 'image',
        'data': 'base64data',
        'mimeType': 'image/png',
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<ImageContent>());
      final img = block as ImageContent;
      expect(img.data, 'base64data');
      expect(img.mimeType, 'image/png');
    });

    test('deserializes AudioContent', () {
      final json = {
        'type': 'audio',
        'data': 'audiodata',
        'mimeType': 'audio/wav',
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<AudioContent>());
    });

    test('deserializes ResourceLink', () {
      final json = {
        'type': 'resource_link',
        'uri': 'file:///test.txt',
        'name': 'test.txt',
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<ResourceLink>());
      expect((block as ResourceLink).uri, 'file:///test.txt');
    });

    test('deserializes EmbeddedResource', () {
      final json = {
        'type': 'resource',
        'resource': {'text': 'content', 'uri': 'file:///x'},
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<EmbeddedResource>());
    });

    test('unknown type becomes UnknownContentBlock', () {
      final json = {'type': 'future_type', 'data': 'whatever'};
      final block = ContentBlock.fromJson(json);
      expect(block, isA<UnknownContentBlock>());
      expect((block as UnknownContentBlock).type, 'future_type');
      expect(block.rawJson, json);
    });

    test('missing type becomes UnknownContentBlock', () {
      final json = <String, dynamic>{'data': 'no type field'};
      final block = ContentBlock.fromJson(json);
      expect(block, isA<UnknownContentBlock>());
    });

    test('TextContent round-trips through JSON', () {
      final original = TextContent(
        text: 'hello',
        annotations: Annotations(priority: 0.5),
        meta: {'traceId': 'abc'},
      );
      final json = original.toJson();
      final parsed = ContentBlock.fromJson(json) as TextContent;
      expect(parsed.text, 'hello');
      expect(parsed.annotations!.priority, 0.5);
      expect(parsed.meta!['traceId'], 'abc');
    });

    test('UnknownContentBlock round-trips raw JSON', () {
      final json = {'type': 'new_type', 'x': 1, 'y': 'z'};
      final block = ContentBlock.fromJson(json) as UnknownContentBlock;
      expect(block.toJson(), json);
    });
  });

  group('SessionUpdate', () {
    test('deserializes agent_message_chunk', () {
      final json = {
        'sessionUpdate': 'agent_message_chunk',
        'content': {'type': 'text', 'text': 'hi'},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<AgentMessageChunk>());
    });

    test('deserializes user_message_chunk', () {
      final json = {
        'sessionUpdate': 'user_message_chunk',
        'content': {'type': 'text', 'text': 'prompt'},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UserMessageChunk>());
    });

    test('deserializes agent_thought_chunk', () {
      final json = {
        'sessionUpdate': 'agent_thought_chunk',
        'content': {'type': 'text', 'text': 'thinking...'},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<AgentThoughtChunk>());
    });

    test('deserializes tool_call', () {
      final json = {
        'sessionUpdate': 'tool_call',
        'toolCallId': 'tc1',
        'title': 'Read file',
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<ToolCallSessionUpdate>());
    });

    test('deserializes current_mode_update', () {
      final json = {
        'sessionUpdate': 'current_mode_update',
        'currentModeId': 'fast',
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<CurrentModeSessionUpdate>());
      expect((update as CurrentModeSessionUpdate).currentModeId, 'fast');
    });

    test('unknown sessionUpdate type becomes UnknownSessionUpdate', () {
      final json = {'sessionUpdate': 'future_update_type', 'data': 42};
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UnknownSessionUpdate>());
      final unknown = update as UnknownSessionUpdate;
      expect(unknown.sessionUpdateType, 'future_update_type');
      expect(unknown.rawJson, json);
    });

    test('missing sessionUpdate key becomes UnknownSessionUpdate', () {
      final json = <String, dynamic>{'data': 'no discriminator'};
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UnknownSessionUpdate>());
    });

    test('UnknownSessionUpdate round-trips raw JSON', () {
      final json = {
        'sessionUpdate': 'new_type',
        'x': 1,
        '_meta': {'trace': 'a'},
      };
      final update = SessionUpdate.fromJson(json) as UnknownSessionUpdate;
      expect(update.toJson(), json);
    });

    test('AgentMessageChunk round-trips', () {
      final json = {
        'sessionUpdate': 'agent_message_chunk',
        'content': {'type': 'text', 'text': 'hello'},
        '_meta': {'id': 1},
      };
      final chunk = SessionUpdate.fromJson(json) as AgentMessageChunk;
      expect(chunk.toJson()['sessionUpdate'], 'agent_message_chunk');
      expect(chunk.meta!['id'], 1);
    });
  });

  group('InitializeRequest', () {
    test('deserializes with defaults', () {
      final json = {'protocolVersion': 1};
      final req = InitializeRequest.fromJson(json);
      expect(req.protocolVersion, 1);
      expect(req.clientCapabilities.terminal, isFalse);
      expect(req.clientInfo, isNull);
    });

    test('round-trips with all fields', () {
      final original = InitializeRequest(
        protocolVersion: 1,
        clientCapabilities: ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true),
          terminal: true,
        ),
        clientInfo: ImplementationInfo(name: 'test', version: '0.1.0'),
        meta: {'trace': 'x'},
      );
      final json = original.toJson();
      final parsed = InitializeRequest.fromJson(json);
      expect(parsed.protocolVersion, 1);
      expect(parsed.clientCapabilities.terminal, isTrue);
      expect(parsed.clientCapabilities.fs.readTextFile, isTrue);
      expect(parsed.clientInfo!.name, 'test');
      expect(parsed.meta!['trace'], 'x');
    });
  });

  group('InitializeResponse', () {
    test('deserializes with auth methods', () {
      final json = {
        'protocolVersion': 1,
        'agentCapabilities': {'loadSession': true},
        'authMethods': [
          {'id': 'env_var', 'name': 'Environment Variable'},
        ],
        'agentInfo': {'name': 'TestAgent', 'version': '1.0.0'},
      };
      final resp = InitializeResponse.fromJson(json);
      expect(resp.protocolVersion, 1);
      expect(resp.agentCapabilities.loadSession, isTrue);
      expect(resp.authMethods, hasLength(1));
      expect(resp.authMethods.first['id'], 'env_var');
      expect(resp.agentInfo!.name, 'TestAgent');
    });
  });

  group('extensionData preservation', () {
    test('TextContent preserves unknown fields', () {
      final json = {
        'type': 'text',
        'text': 'hi',
        'customField': 42,
        'vendor_data': {'x': true},
      };
      final block = ContentBlock.fromJson(json) as TextContent;
      expect(block.extensionData, isNotNull);
      expect(block.extensionData!['customField'], 42);
      // Round-trip
      final out = block.toJson();
      expect(out['customField'], 42);
      expect((out['vendor_data'] as Map)['x'], true);
    });

    test('ClientCapabilities preserves unknown capability fields', () {
      final json = {
        'fs': {'readTextFile': true, 'writeTextFile': false},
        'terminal': true,
        '_customVendor': {'feature': true},
      };
      final caps = ClientCapabilities.fromJson(json);
      expect(caps.extensionData, isNotNull);
      expect(caps.extensionData!['_customVendor'], isNotNull);
      final out = caps.toJson();
      expect(out['_customVendor'], isNotNull);
    });
  });

  group('_meta preservation', () {
    test('InitializeRequest preserves _meta', () {
      final json = {
        'protocolVersion': 1,
        '_meta': {'requestId': 'r1', 'timestamp': 12345},
      };
      final req = InitializeRequest.fromJson(json);
      expect(req.meta, isNotNull);
      expect(req.meta!['requestId'], 'r1');
      final out = req.toJson();
      expect(out['_meta'], isNotNull);
      expect((out['_meta'] as Map)['requestId'], 'r1');
    });
  });

  group('AuthMethod', () {
    test('is a plain struct, not a discriminated union', () {
      final json = {
        'id': 'env_var',
        'name': 'Environment Variable Auth',
        'description': 'Set API key via env var',
      };
      final method = AuthMethod.fromJson(json);
      expect(method.id, 'env_var');
      expect(method.name, 'Environment Variable Auth');
      expect(method.description, 'Set API key via env var');
    });

    test('round-trips with extensionData', () {
      final json = {'id': 'custom', 'name': 'Custom', '_vendor_flag': true};
      final method = AuthMethod.fromJson(json);
      expect(method.extensionData!['_vendor_flag'], true);
      expect(method.toJson()['_vendor_flag'], true);
    });
  });

  group('Session models', () {
    test('PromptRequest round-trips', () {
      final req = PromptRequest(
        sessionId: 's1',
        prompt: [TextContent(text: 'Hello')],
      );
      final json = req.toJson();
      final parsed = PromptRequest.fromJson(json);
      expect(parsed.sessionId, 's1');
      expect(parsed.prompt, hasLength(1));
      expect((parsed.prompt.first as TextContent).text, 'Hello');
    });

    test('StopReason parses known values', () {
      expect(StopReason.fromString('end_turn'), StopReason.endTurn);
      expect(StopReason.fromString('cancelled'), StopReason.cancelled);
      expect(StopReason.fromString('unknown_value'), isNull);
    });

    test('PromptResponse exposes parsed stopReason', () {
      final resp = PromptResponse(stopReason: 'end_turn');
      expect(StopReason.fromString(resp.stopReason), StopReason.endTurn);
    });

    test('PromptResponse with unknown stopReason', () {
      final resp = PromptResponse(stopReason: 'future_reason');
      expect(StopReason.fromString(resp.stopReason), isNull);
      expect(resp.stopReason, 'future_reason');
    });
  });
}
