import 'package:acp/src/schema/auth_method.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/implementation_info.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:acp/src/schema/unstable_methods.dart';
import 'package:test/test.dart';

/// Verifies lossless round-trip: fromJson(json).toJson() == json
void expectRoundTrip<T>(
  T Function(Map<String, dynamic>) fromJson,
  Map<String, dynamic> Function(T) toJson,
  Map<String, dynamic> json,
) {
  final deserialized = fromJson(json);
  final reserialized = toJson(deserialized);
  expect(reserialized, json);
}

void main() {
  group('Golden schema round-trip', () {
    // -- Initialize --

    test('InitializeRequest', () {
      final json = <String, dynamic>{
        'protocolVersion': 1,
        'clientCapabilities': {
          'fs': {'readTextFile': true, 'writeTextFile': false},
          'terminal': true,
        },
        'clientInfo': {'name': 'test-client', 'version': '1.0.0'},
        '_meta': {'traceId': 'abc123'},
        '_vendorX': {'custom': true},
      };
      expectRoundTrip(InitializeRequest.fromJson, (r) => r.toJson(), json);
    });

    test('InitializeResponse', () {
      final json = <String, dynamic>{
        'protocolVersion': 1,
        'agentCapabilities': {
          'loadSession': true,
          'promptCapabilities': {
            'image': true,
            'audio': false,
            'embeddedContext': false,
          },
          'mcpCapabilities': {'http': true, 'sse': false},
          'sessionCapabilities': <String, dynamic>{},
        },
        'authMethods': [
          {'id': 'agent_auth', 'name': 'Agent Auth'},
        ],
        'agentInfo': {'name': 'test-agent', 'version': '2.0.0'},
        '_meta': {'timing': 42},
      };
      expectRoundTrip(InitializeResponse.fromJson, (r) => r.toJson(), json);
    });

    test('AuthenticateRequest', () {
      final json = <String, dynamic>{
        'methodId': 'agent_auth',
        '_meta': {'step': 1},
      };
      expectRoundTrip(AuthenticateRequest.fromJson, (r) => r.toJson(), json);
    });

    test('AuthenticateResponse', () {
      final json = <String, dynamic>{
        '_meta': {'token': 'xyz'},
        '_custom': 'data',
      };
      expectRoundTrip(AuthenticateResponse.fromJson, (r) => r.toJson(), json);
    });

    // -- Session --

    test('NewSessionRequest', () {
      final json = <String, dynamic>{
        'cwd': '/home/user',
        'mcpServers': [
          {'url': 'http://mcp.local', 'type': 'http'},
        ],
        '_meta': {'source': 'test'},
      };
      expectRoundTrip(NewSessionRequest.fromJson, (r) => r.toJson(), json);
    });

    test('NewSessionResponse', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-abc',
        'modes': {
          'available': ['fast', 'careful'],
          'current': 'fast',
        },
        'configOptions': [
          {'id': 'opt1', 'label': 'Option 1', 'type': 'bool', 'value': true},
        ],
        '_meta': {'created': '2026-01-01'},
      };
      expectRoundTrip(NewSessionResponse.fromJson, (r) => r.toJson(), json);
    });

    test('LoadSessionRequest', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'cwd': '/home/user',
        'mcpServers': [
          {'url': 'http://mcp.local', 'type': 'http'},
        ],
        '_meta': {'source': 'test'},
      };
      expectRoundTrip(LoadSessionRequest.fromJson, (r) => r.toJson(), json);
    });

    test('LoadSessionResponse', () {
      final json = <String, dynamic>{
        'modes': {
          'available': ['fast'],
          'current': 'fast',
        },
        'configOptions': [
          {'id': 'opt1', 'value': 'x'},
        ],
        '_meta': {'loaded': true},
      };
      expectRoundTrip(LoadSessionResponse.fromJson, (r) => r.toJson(), json);
    });

    test('PromptRequest', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'prompt': [
          {'type': 'text', 'text': 'Hello'},
        ],
        '_meta': {'turn': 1},
      };
      expectRoundTrip(PromptRequest.fromJson, (r) => r.toJson(), json);
    });

    test('PromptResponse', () {
      final json = <String, dynamic>{
        'stopReason': 'end_turn',
        '_meta': {'tokens': 100},
      };
      expectRoundTrip(PromptResponse.fromJson, (r) => r.toJson(), json);
    });

    test('CancelNotification', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        '_meta': {'reason': 'user'},
      };
      expectRoundTrip(CancelNotification.fromJson, (r) => r.toJson(), json);
    });

    test('SetSessionModeRequest', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'modeId': 'careful',
      };
      expectRoundTrip(SetSessionModeRequest.fromJson, (r) => r.toJson(), json);
    });

    test('SetSessionConfigOptionRequest', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'configId': 'maxTokens',
        'value': '4096',
      };
      expectRoundTrip(
        SetSessionConfigOptionRequest.fromJson,
        (r) => r.toJson(),
        json,
      );
    });

    test('SetSessionConfigOptionResponse', () {
      final json = <String, dynamic>{
        'configOptions': [
          {'id': 'maxTokens', 'value': '4096'},
        ],
      };
      expectRoundTrip(
        SetSessionConfigOptionResponse.fromJson,
        (r) => r.toJson(),
        json,
      );
    });

    test('SessionNotification', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'update': {
          'sessionUpdate': 'agent_message_chunk',
          'content': {'type': 'text', 'text': 'hi'},
        },
        '_meta': {'seq': 1},
      };
      expectRoundTrip(SessionNotification.fromJson, (r) => r.toJson(), json);
    });

    // -- Content Blocks --

    test('TextContent', () {
      final json = <String, dynamic>{
        'type': 'text',
        'text': 'Hello world',
        '_meta': {'source': 'user'},
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<TextContent>());
      expect(block.toJson(), json);
    });

    test('ImageContent', () {
      final json = <String, dynamic>{
        'type': 'image',
        'data': 'base64data==',
        'mimeType': 'image/png',
        '_meta': {'size': 1024},
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<ImageContent>());
      expect(block.toJson(), json);
    });

    test('AudioContent', () {
      final json = <String, dynamic>{
        'type': 'audio',
        'data': 'audiodata==',
        'mimeType': 'audio/wav',
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<AudioContent>());
      expect(block.toJson(), json);
    });

    test('ResourceLink', () {
      final json = <String, dynamic>{
        'type': 'resource_link',
        'uri': 'file:///tmp/readme.md',
        'name': 'readme',
        'description': 'A readme file',
        'mimeType': 'text/markdown',
        'title': 'README',
        'size': 512,
        '_meta': {'source': 'fs'},
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<ResourceLink>());
      expect(block.toJson(), json);
    });

    test('EmbeddedResource', () {
      final json = <String, dynamic>{
        'type': 'resource',
        'resource': {'uri': 'file:///tmp/x', 'text': 'content'},
        '_meta': {'inline': true},
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<EmbeddedResource>());
      expect(block.toJson(), json);
    });

    test('UnknownContentBlock preserves raw JSON', () {
      final json = <String, dynamic>{
        'type': 'future_type',
        'payload': {'key': 'value'},
        '_meta': {'version': 2},
      };
      final block = ContentBlock.fromJson(json);
      expect(block, isA<UnknownContentBlock>());
      expect(block.toJson(), json);
    });

    // -- Session Updates --

    test('AgentMessageChunk', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'agent_message_chunk',
        'content': {'type': 'text', 'text': 'response'},
        '_meta': {'seq': 1},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<AgentMessageChunk>());
      expect(update.toJson(), json);
    });

    test('UserMessageChunk', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'user_message_chunk',
        'content': {'type': 'text', 'text': 'input'},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UserMessageChunk>());
      expect(update.toJson(), json);
    });

    test('AgentThoughtChunk', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'agent_thought_chunk',
        'content': {'type': 'text', 'text': 'thinking...'},
        '_meta': {'step': 1},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<AgentThoughtChunk>());
      expect(update.toJson(), json);
    });

    test('ToolCallSessionUpdate preserves raw JSON', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'tool_call',
        'title': 'Reading file',
        'toolCallId': 'tc-1',
        'name': 'read_file',
        'args': {'path': '/tmp/x'},
        '_meta': {'seq': 2},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<ToolCallSessionUpdate>());
      expect(update.toJson(), json);
    });

    test('ToolCallDeltaSessionUpdate preserves raw JSON', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'tool_call_update',
        'toolCallId': 'tc-1',
        'output': 'partial output',
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<ToolCallDeltaSessionUpdate>());
      expect(update.toJson(), json);
    });

    test('PlanUpdate preserves raw JSON', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'plan',
        'entries': [
          {'title': 'Step 1', 'status': 'done'},
        ],
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<PlanUpdate>());
      expect(update.toJson(), json);
    });

    test('AvailableCommandsSessionUpdate preserves raw JSON', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'available_commands_update',
        'availableCommands': [
          {'id': 'cmd1', 'label': 'Command 1'},
        ],
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<AvailableCommandsSessionUpdate>());
      expect(update.toJson(), json);
    });

    test('CurrentModeSessionUpdate', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'current_mode_update',
        'currentModeId': 'careful',
        '_meta': {'changed': true},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<CurrentModeSessionUpdate>());
      expect(update.toJson(), json);
    });

    test('ConfigOptionSessionUpdate preserves raw JSON', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'config_option_update',
        'configOptions': [
          {'id': 'maxTokens', 'value': '8192'},
        ],
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<ConfigOptionSessionUpdate>());
      expect(update.toJson(), json);
    });

    test('UnknownSessionUpdate preserves raw JSON', () {
      final json = <String, dynamic>{
        'sessionUpdate': 'future_update_type',
        'data': [1, 2, 3],
        '_meta': {'version': 99},
      };
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UnknownSessionUpdate>());
      expect(update.toJson(), json);
    });

    test('SessionUpdate with missing discriminator', () {
      final json = <String, dynamic>{'someField': 'value'};
      final update = SessionUpdate.fromJson(json);
      expect(update, isA<UnknownSessionUpdate>());
      expect(update.toJson(), json);
    });

    // -- Auth Methods --

    test('AuthMethod', () {
      final json = <String, dynamic>{
        'id': 'agent_auth',
        'name': 'Agent Auth',
        'description': 'OAuth-based authentication',
        '_meta': {'provider': 'oauth'},
        'url': 'https://auth.example.com',
      };
      final method = AuthMethod.fromJson(json);
      expect(method.id, 'agent_auth');
      expect(method.name, 'Agent Auth');
      expect(method.description, 'OAuth-based authentication');
      expect(method.toJson(), json);
    });

    test('AuthMethod without optional fields', () {
      final json = <String, dynamic>{
        'id': 'env_var_auth',
        'name': 'Env Var Auth',
      };
      final method = AuthMethod.fromJson(json);
      expect(method.id, 'env_var_auth');
      expect(method.toJson(), json);
    });

    // -- Capabilities --

    test('ClientCapabilities with extension data', () {
      final json = <String, dynamic>{
        'fs': {'readTextFile': true, 'writeTextFile': true},
        'terminal': true,
        '_vendorCap': {'custom': true},
      };
      expectRoundTrip(ClientCapabilities.fromJson, (r) => r.toJson(), json);
    });

    test('AgentCapabilities', () {
      final json = <String, dynamic>{
        'loadSession': true,
        'promptCapabilities': {
          'image': true,
          'audio': true,
          'embeddedContext': false,
        },
        'mcpCapabilities': {'http': false, 'sse': true},
        'sessionCapabilities': <String, dynamic>{},
      };
      expectRoundTrip(AgentCapabilities.fromJson, (r) => r.toJson(), json);
    });

    test('FileSystemCapability', () {
      final json = <String, dynamic>{
        'readTextFile': true,
        'writeTextFile': false,
        '_meta': {'v': 1},
      };
      expectRoundTrip(FileSystemCapability.fromJson, (r) => r.toJson(), json);
    });

    test('PromptCapabilities', () {
      final json = <String, dynamic>{
        'image': true,
        'audio': false,
        'embeddedContext': true,
      };
      expectRoundTrip(PromptCapabilities.fromJson, (r) => r.toJson(), json);
    });

    test('McpCapabilities', () {
      final json = <String, dynamic>{
        'http': true,
        'sse': false,
        '_meta': {'version': 1},
      };
      expectRoundTrip(McpCapabilities.fromJson, (r) => r.toJson(), json);
    });

    test('SessionCapabilities with extension data', () {
      final json = <String, dynamic>{
        '_meta': {'v': 1},
        'customCap': true,
      };
      expectRoundTrip(SessionCapabilities.fromJson, (r) => r.toJson(), json);
    });

    // -- Client Methods --

    test('ReadTextFileRequest', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'path': '/etc/hosts',
        'line': 10,
        'limit': 50,
        '_meta': {'request': true},
      };
      expectRoundTrip(ReadTextFileRequest.fromJson, (r) => r.toJson(), json);
    });

    test('ReadTextFileResponse', () {
      final json = <String, dynamic>{
        'content': 'file contents here',
        '_meta': {'bytes': 18},
      };
      expectRoundTrip(ReadTextFileResponse.fromJson, (r) => r.toJson(), json);
    });

    test('WriteTextFileRequest', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'path': '/tmp/out.txt',
        'content': 'hello',
        '_meta': {'op': 'write'},
      };
      expectRoundTrip(WriteTextFileRequest.fromJson, (r) => r.toJson(), json);
    });

    test('WriteTextFileResponse', () {
      final json = <String, dynamic>{
        '_meta': {'ok': true},
        '_vendor': 'extra',
      };
      expectRoundTrip(WriteTextFileResponse.fromJson, (r) => r.toJson(), json);
    });

    test('CreateTerminalRequest', () {
      final json = <String, dynamic>{
        'args': ['-la'],
        'command': 'ls',
        'cwd': '/home',
        'env': <dynamic>[],
        'outputByteLimit': 10000,
        'sessionId': 'sess-1',
      };
      expectRoundTrip(CreateTerminalRequest.fromJson, (r) => r.toJson(), json);
    });

    test('WaitForTerminalExitResponse with values', () {
      final json = <String, dynamic>{'exitCode': 0};
      expectRoundTrip(
        WaitForTerminalExitResponse.fromJson,
        (r) => r.toJson(),
        json,
      );
    });

    test('WaitForTerminalExitResponse with signal', () {
      final json = <String, dynamic>{'exitCode': 137, 'signal': 'SIGKILL'};
      expectRoundTrip(
        WaitForTerminalExitResponse.fromJson,
        (r) => r.toJson(),
        json,
      );
    });

    test('WaitForTerminalExitResponse omits nulls', () {
      final resp = WaitForTerminalExitResponse.fromJson(<String, dynamic>{
        'exitCode': null,
        'signal': null,
      });
      expect(resp.exitCode, isNull);
      expect(resp.signal, isNull);
      expect(resp.toJson(), <String, dynamic>{});
    });

    test('RequestPermissionRequest', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-1',
        'toolCall': {
          'name': 'write_file',
          'args': {'path': '/tmp/x'},
        },
        'options': [
          {'id': 'allow', 'label': 'Allow'},
          {'id': 'deny', 'label': 'Deny'},
        ],
      };
      expectRoundTrip(
        RequestPermissionRequest.fromJson,
        (r) => r.toJson(),
        json,
      );
    });

    test('RequestPermissionResponse', () {
      final json = <String, dynamic>{
        'outcome': {'outcome': 'selected', 'optionId': 'allow'},
        '_meta': {'decision': 'auto'},
      };
      expectRoundTrip(
        RequestPermissionResponse.fromJson,
        (r) => r.toJson(),
        json,
      );
    });

    // -- Unstable Methods --

    test('ListSessionsRequest', () {
      final json = <String, dynamic>{
        '_meta': {'source': 'cli'},
        '_vendor': 'extra',
      };
      expectRoundTrip(ListSessionsRequest.fromJson, (r) => r.toJson(), json);
    });

    test('ListSessionsResponse', () {
      final json = <String, dynamic>{
        'sessions': [
          {'sessionId': 's1', 'cwd': '/home'},
          {'sessionId': 's2', 'cwd': '/tmp'},
        ],
        '_meta': {'count': 2},
      };
      expectRoundTrip(ListSessionsResponse.fromJson, (r) => r.toJson(), json);
    });

    test('ForkSessionRequest', () {
      final json = <String, dynamic>{
        'additionalDirectories': <dynamic>[],
        'cwd': '/home/user',
        'mcpServers': <dynamic>[],
        'sessionId': 'sess-original',
        '_meta': {'reason': 'branch'},
        '_vendor': 42,
      };
      expectRoundTrip(ForkSessionRequest.fromJson, (r) => r.toJson(), json);
    });

    test('ForkSessionResponse', () {
      final json = <String, dynamic>{
        'sessionId': 'sess-forked',
        '_meta': {'forkedFrom': 'sess-original'},
      };
      expectRoundTrip(ForkSessionResponse.fromJson, (r) => r.toJson(), json);
    });

    // -- Implementation Info --

    test('ImplementationInfo', () {
      final json = <String, dynamic>{
        'name': 'my-agent',
        'version': '1.2.3',
        '_meta': {'build': 'release'},
      };
      expectRoundTrip(ImplementationInfo.fromJson, (r) => r.toJson(), json);
    });

    test('ImplementationInfo with title', () {
      final json = <String, dynamic>{
        'name': 'my-agent',
        'title': 'My Agent',
        'version': '1.2.3',
      };
      expectRoundTrip(ImplementationInfo.fromJson, (r) => r.toJson(), json);
    });
  });
}
