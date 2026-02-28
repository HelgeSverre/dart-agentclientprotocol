# Milestone 2: Typed Connection Facades & Handler Interfaces

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement `AgentHandler`, `ClientHandler`, `AgentSideConnection`, and `ClientSideConnection` with capability enforcement and unstable method gating, per SPEC §3.2, §4.3, §4.6, §5.5, §6.1.

**Architecture:** Two typed facades wrap `Connection`. `AgentSideConnection` registers request/notification handlers for all agent-side methods and delegates to an `AgentHandler`. `ClientSideConnection` provides typed send methods and registers handlers for client-side methods, delegating to `ClientHandler`. Capability enforcement (`strict`/`permissive`) gates outgoing requests based on peer-advertised capabilities.

**Tech Stack:** Dart 3.7, `package:logging`, `package:meta` (`@experimental`). No new dependencies.

---

## Conventions & Context

- **Mock transport**: `MockTransport` in `test/unit/connection_test.dart` — reuse this pattern in new tests.
- **Analyzer settings**: strict-casts, strict-inference, strict-raw-types all true. Lint rules include `avoid_dynamic_calls`, `unawaited_futures`, `always_use_package_imports`, `public_member_api_docs`.
- **Schema models**: All request/response types exist in `lib/src/schema/`. Every model has `fromJson`/`toJson`, `HasMeta`, `extensionData`.
- **Connection**: `lib/src/protocol/connection.dart` — `start()`, `markOpen()`, `sendRequest()`, `notify()`, `sendResponse()`, `close()`, `setRequestHandler()`, `setNotificationHandler()`, `setExtensionRequestHandler()`, `setExtensionNotificationHandler()`. State machine: idle→opening→open→closing→closed.
- **AcpMethods**: `lib/src/protocol/acp_methods.dart` — all method name constants.
- **Verify with**: `dart analyze && dart test` after each task.

---

### Task 1: CapabilityEnforcement Enum

**Files:**
- Create: `lib/src/protocol/capability_enforcement.dart`

**Step 1: Create the enum**

```dart
/// Controls whether outgoing requests are checked against peer-advertised
/// capabilities before sending.
enum CapabilityEnforcement {
  /// Throw [CapabilityException] if the peer did not advertise the required
  /// capability. This is the default.
  strict,

  /// Send the request regardless of peer capabilities.
  permissive,
}
```

**Step 2: Run analyzer**

Run: `dart analyze`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/src/protocol/capability_enforcement.dart
git commit -m "feat: add CapabilityEnforcement enum"
```

---

### Task 2: AgentHandler Interface

**Files:**
- Create: `lib/src/protocol/agent_handler.dart`
- Test: `test/unit/agent_handler_test.dart`

**Step 1: Write tests for default handler behavior**

```dart
import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:test/test.dart';

/// Minimal concrete handler — only required methods.
class MinimalAgentHandler implements AgentHandler {
  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const NewSessionResponse(sessionId: 'test-session');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const PromptResponse(stopReason: 'end_turn');
}

void main() {
  group('AgentHandler default methods', () {
    late MinimalAgentHandler handler;
    late AcpCancellationToken token;

    setUp(() {
      handler = MinimalAgentHandler();
      token = AcpCancellationSource().token;
    });

    test('authenticate throws methodNotFound by default', () async {
      await expectLater(
        handler.authenticate(
          const AuthenticateRequest(methodId: 'test'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('loadSession throws methodNotFound by default', () async {
      await expectLater(
        handler.loadSession(
          const LoadSessionRequest(sessionId: 's1', cwd: '/tmp'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('setMode throws methodNotFound by default', () async {
      await expectLater(
        handler.setMode(
          const SetSessionModeRequest(sessionId: 's1', modeId: 'fast'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('setConfigOption throws methodNotFound by default', () async {
      await expectLater(
        handler.setConfigOption(
          const SetSessionConfigOptionRequest(
            sessionId: 's1',
            configId: 'opt',
            value: 'v',
          ),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('cancel does nothing by default', () async {
      // Should not throw
      await handler.cancel(
        const CancelNotification(sessionId: 's1'),
      );
    });

    test('onExtMethod returns null by default', () async {
      final result = await handler.onExtMethod(
        '_vendor/test',
        {'data': 1},
        cancelToken: token,
      );
      expect(result, isNull);
    });

    test('onExtNotification does nothing by default', () async {
      // Should not throw
      await handler.onExtNotification('_vendor/event', {'data': 1});
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/unit/agent_handler_test.dart`
Expected: Compilation error — `AgentHandler` doesn't exist yet.

**Step 3: Implement AgentHandler**

```dart
import 'dart:async';

import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';

/// Handler interface for agent-side ACP method dispatch.
///
/// Implement this interface to handle client requests on the agent side.
/// Required methods ([initialize], [newSession], [prompt]) must be overridden.
/// Optional methods throw [RpcErrorException.methodNotFound] by default —
/// override them to enable the corresponding capabilities.
abstract interface class AgentHandler {
  // -- Required methods --

  /// Handles the `initialize` request.
  ///
  /// Negotiate protocol version and exchange capabilities.
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  });

  /// Handles the `session/new` request.
  ///
  /// Create a new session and return the session ID.
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  });

  /// Handles the `session/prompt` request.
  ///
  /// Process a user prompt within a session.
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  });

  // -- Optional methods (capability-gated) --

  /// Handles the `authenticate` request.
  ///
  /// Override to support authentication. Throws `-32601 methodNotFound`
  /// by default.
  Future<AuthenticateResponse> authenticate(
    AuthenticateRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound('authenticate not supported');

  /// Handles the `session/load` request.
  ///
  /// Override to support session resumption (requires `loadSession`
  /// capability). Throws `-32601 methodNotFound` by default.
  Future<LoadSessionResponse> loadSession(
    LoadSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound('session/load not supported');

  /// Handles the `session/set_mode` request.
  ///
  /// Override to support mode switching. Throws `-32601 methodNotFound`
  /// by default.
  Future<SetSessionModeResponse> setMode(
    SetSessionModeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound('session/set_mode not supported');

  /// Handles the `session/set_config_option` request.
  ///
  /// Override to support configuration updates. Throws `-32601 methodNotFound`
  /// by default.
  Future<SetSessionConfigOptionResponse> setConfigOption(
    SetSessionConfigOptionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'session/set_config_option not supported');

  // -- Notification handlers --

  /// Handles the `session/cancel` notification.
  ///
  /// Override to handle cancellation. Does nothing by default.
  Future<void> cancel(CancelNotification notification) async {}

  // -- Extension handlers --

  /// Handles an extension request (method starting with `_`).
  ///
  /// Return `null` to indicate the method is not handled (will result in
  /// `-32601 methodNotFound`). Return a map to send as the result.
  Future<Map<String, dynamic>?> onExtMethod(
    String method,
    Map<String, dynamic>? params, {
    required AcpCancellationToken cancelToken,
  }) async =>
      null;

  /// Handles an extension notification (method starting with `_`).
  ///
  /// Does nothing by default.
  Future<void> onExtNotification(
    String method,
    Map<String, dynamic>? params,
  ) async {}
}
```

**Step 4: Run tests to verify they pass**

Run: `dart analyze && dart test test/unit/agent_handler_test.dart`
Expected: All 7 tests pass, no analyzer issues.

**Step 5: Commit**

```bash
git add lib/src/protocol/agent_handler.dart test/unit/agent_handler_test.dart
git commit -m "feat: add AgentHandler interface with default method behavior"
```

---

### Task 3: ClientHandler Interface

**Files:**
- Create: `lib/src/protocol/client_handler.dart`
- Test: `test/unit/client_handler_test.dart`

**Step 1: Write tests for default handler behavior**

```dart
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

/// Empty concrete handler — all defaults.
class DefaultClientHandler implements ClientHandler {
  final List<SessionUpdate> receivedUpdates = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    receivedUpdates.add(update);
  }
}

void main() {
  group('ClientHandler default methods', () {
    late DefaultClientHandler handler;
    late AcpCancellationToken token;

    setUp(() {
      handler = DefaultClientHandler();
      token = AcpCancellationSource().token;
    });

    test('readTextFile throws methodNotFound by default', () async {
      await expectLater(
        handler.readTextFile(
          const ReadTextFileRequest(sessionId: 's1', path: '/tmp/f.txt'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('writeTextFile throws methodNotFound by default', () async {
      await expectLater(
        handler.writeTextFile(
          const WriteTextFileRequest(
            sessionId: 's1',
            path: '/tmp/f.txt',
            content: 'hi',
          ),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('createTerminal throws methodNotFound by default', () async {
      await expectLater(
        handler.createTerminal(
          const CreateTerminalRequest(sessionId: 's1', command: 'ls'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('terminalOutput throws methodNotFound by default', () async {
      await expectLater(
        handler.terminalOutput(
          const TerminalOutputRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('releaseTerminal throws methodNotFound by default', () async {
      await expectLater(
        handler.releaseTerminal(
          const ReleaseTerminalRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('killTerminal throws methodNotFound by default', () async {
      await expectLater(
        handler.killTerminal(
          const KillTerminalCommandRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('waitForTerminalExit throws methodNotFound by default', () async {
      await expectLater(
        handler.waitForTerminalExit(
          const WaitForTerminalExitRequest(sessionId: 's1', terminalId: 't1'),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('requestPermission throws methodNotFound by default', () async {
      await expectLater(
        handler.requestPermission(
          const RequestPermissionRequest(
            sessionId: 's1',
            toolCall: {'name': 'bash'},
            options: [],
          ),
          cancelToken: token,
        ),
        throwsA(
          isA<RpcErrorException>().having((e) => e.code, 'code', -32601),
        ),
      );
    });

    test('onSessionUpdate records updates', () {
      final update = AgentMessageChunk(
        content: {'type': 'text', 'text': 'hi'},
      );
      handler.onSessionUpdate('s1', update);
      expect(handler.receivedUpdates, [update]);
    });

    test('onExtMethod returns null by default', () async {
      final result = await handler.onExtMethod(
        '_vendor/test',
        {'data': 1},
        cancelToken: token,
      );
      expect(result, isNull);
    });

    test('onExtNotification does nothing by default', () async {
      await handler.onExtNotification('_vendor/event', {'data': 1});
    });
  });
}
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/unit/client_handler_test.dart`
Expected: Compilation error — `ClientHandler` doesn't exist yet.

**Step 3: Implement ClientHandler**

```dart
import 'dart:async';

import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/session_update.dart';

/// Handler interface for client-side ACP method dispatch.
///
/// Implement this interface to handle agent requests on the client side.
/// [onSessionUpdate] must be overridden to receive streaming updates.
/// All RPC method handlers throw [RpcErrorException.methodNotFound] by default —
/// override them to enable the corresponding capabilities.
abstract interface class ClientHandler {
  // -- Notification handler (required) --

  /// Called when a `session/update` notification is received.
  ///
  /// The [sessionId] identifies which session the [update] belongs to.
  void onSessionUpdate(String sessionId, SessionUpdate update);

  // -- File system methods (capability-gated) --

  /// Handles the `fs/read_text_file` request.
  ///
  /// Override to support file reading (requires `fs.readTextFile` capability).
  /// Throws `-32601 methodNotFound` by default.
  Future<ReadTextFileResponse> readTextFile(
    ReadTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'fs/read_text_file not supported');

  /// Handles the `fs/write_text_file` request.
  ///
  /// Override to support file writing (requires `fs.writeTextFile` capability).
  /// Throws `-32601 methodNotFound` by default.
  Future<WriteTextFileResponse> writeTextFile(
    WriteTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'fs/write_text_file not supported');

  // -- Terminal methods (capability-gated) --

  /// Handles the `terminal/create` request.
  ///
  /// Override to support terminal creation (requires `terminal` capability).
  /// Throws `-32601 methodNotFound` by default.
  Future<CreateTerminalResponse> createTerminal(
    CreateTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'terminal/create not supported');

  /// Handles the `terminal/output` request.
  ///
  /// Override to support terminal output retrieval.
  /// Throws `-32601 methodNotFound` by default.
  Future<TerminalOutputResponse> terminalOutput(
    TerminalOutputRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'terminal/output not supported');

  /// Handles the `terminal/release` request.
  ///
  /// Override to support terminal release.
  /// Throws `-32601 methodNotFound` by default.
  Future<void> releaseTerminal(
    ReleaseTerminalRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'terminal/release not supported');

  /// Handles the `terminal/kill` request.
  ///
  /// Override to support terminal kill.
  /// Throws `-32601 methodNotFound` by default.
  Future<void> killTerminal(
    KillTerminalCommandRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'terminal/kill not supported');

  /// Handles the `terminal/wait_for_exit` request.
  ///
  /// Override to support waiting for terminal exit.
  /// Throws `-32601 methodNotFound` by default.
  Future<WaitForTerminalExitResponse> waitForTerminalExit(
    WaitForTerminalExitRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'terminal/wait_for_exit not supported');

  // -- Permission --

  /// Handles the `session/request_permission` request.
  ///
  /// Override to support permission prompts.
  /// Throws `-32601 methodNotFound` by default.
  Future<RequestPermissionResponse> requestPermission(
    RequestPermissionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      throw RpcErrorException.methodNotFound(
          'session/request_permission not supported');

  // -- Extension handlers --

  /// Handles an extension request (method starting with `_`).
  ///
  /// Return `null` to indicate the method is not handled (will result in
  /// `-32601 methodNotFound`). Return a map to send as the result.
  Future<Map<String, dynamic>?> onExtMethod(
    String method,
    Map<String, dynamic>? params, {
    required AcpCancellationToken cancelToken,
  }) async =>
      null;

  /// Handles an extension notification (method starting with `_`).
  ///
  /// Does nothing by default.
  Future<void> onExtNotification(
    String method,
    Map<String, dynamic>? params,
  ) async {}
}
```

**Step 4: Run tests to verify they pass**

Run: `dart analyze && dart test test/unit/client_handler_test.dart`
Expected: All 11 tests pass, no analyzer issues.

**Step 5: Commit**

```bash
git add lib/src/protocol/client_handler.dart test/unit/client_handler_test.dart
git commit -m "feat: add ClientHandler interface with default method behavior"
```

---

### Task 4: AgentSideConnection

**Files:**
- Create: `lib/src/protocol/agent_side_connection.dart`
- Test: `test/unit/agent_side_connection_test.dart`

This is the largest task. `AgentSideConnection` wraps `Connection`, accepts a handler factory, registers all agent-side method handlers, and deserializes/serializes between raw JSON and typed schema objects.

**Step 1: Write tests**

Key tests to cover:
1. Constructor wires up handlers and starts connection.
2. `initialize` request dispatches to handler and stores capabilities.
3. `authenticate` request dispatches to handler.
4. `session/new` request dispatches to handler.
5. `session/prompt` request dispatches to handler.
6. `session/cancel` notification dispatches to handler.
7. Optional methods (loadSession, setMode, setConfigOption) return METHOD_NOT_FOUND with default handler.
8. `notifySessionUpdate` sends a `session/update` notification.
9. Extension method dispatch through `onExtMethod`.
10. Extension notification dispatch through `onExtNotification`.
11. `extMethod()` sends an extension request to the peer.
12. `extNotification()` sends an extension notification to the peer.
13. Agent can send client-side requests (`sendReadTextFile`, `sendCreateTerminal`, etc.) — capability enforcement in strict mode.
14. Permissive mode allows sending without capability check.
15. `markOpen()` is called after successful initialize.
16. Unstable method gating: `session/list` without `useUnstableProtocol` is rejected.

The test file should reuse `MockTransport` from `connection_test.dart`. Since both test files need it, first extract it:

**Step 1a: Extract MockTransport to shared test helper**

Create `test/helpers/mock_transport.dart`:

```dart
import 'dart:async';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// In-memory transport for testing.
class MockTransport implements AcpTransport {
  final StreamController<JsonRpcMessage> _inbound =
      StreamController<JsonRpcMessage>();
  final List<JsonRpcMessage> sent = [];
  bool closed = false;

  @override
  Stream<JsonRpcMessage> get messages => _inbound.stream;

  /// Simulates an incoming message from the remote side.
  void receive(JsonRpcMessage message) => _inbound.add(message);

  /// Simulates the remote side closing.
  Future<void> simulateClose() => _inbound.close();

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (closed) throw StateError('closed');
    sent.add(message);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _inbound.close();
  }
}
```

Then update `test/unit/connection_test.dart` to import from `test/helpers/mock_transport.dart` instead of defining `MockTransport` inline. Remove the `MockTransport` class definition from that file and add:
```dart
import 'package:acp/test/helpers/mock_transport.dart';
```

Wait — test helpers can't be imported via package imports. Use relative import instead:
```dart
import '../helpers/mock_transport.dart';
```

**Step 1b: Write agent_side_connection_test.dart**

```dart
import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

import '../helpers/mock_transport.dart';

class TestAgentHandler implements AgentHandler {
  InitializeRequest? lastInitRequest;
  NewSessionRequest? lastNewSessionRequest;
  PromptRequest? lastPromptRequest;
  CancelNotification? lastCancelNotification;

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    lastInitRequest = request;
    return const InitializeResponse(
      protocolVersion: 1,
      agentCapabilities: AgentCapabilities(loadSession: true),
    );
  }

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    lastNewSessionRequest = request;
    return const NewSessionResponse(sessionId: 'test-session-1');
  }

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    lastPromptRequest = request;
    return const PromptResponse(stopReason: 'end_turn');
  }

  @override
  Future<void> cancel(CancelNotification notification) async {
    lastCancelNotification = notification;
  }
}

void main() {
  group('AgentSideConnection', () {
    late MockTransport transport;
    late TestAgentHandler handler;
    late AgentSideConnection agentConn;

    setUp(() {
      transport = MockTransport();
      agentConn = AgentSideConnection(
        transport,
        handlerFactory: (conn) {
          handler = TestAgentHandler();
          return handler;
        },
      );
    });

    tearDown(() async {
      await agentConn.close();
    });

    test('starts in opening state after construction', () {
      // AgentSideConnection calls start() in constructor
      expect(agentConn.state, ConnectionState.opening);
    });

    test('dispatches initialize and transitions to open', () async {
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {
          'protocolVersion': 1,
          'clientCapabilities': {
            'fs': {'readTextFile': true, 'writeTextFile': false},
            'terminal': true,
          },
        },
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.lastInitRequest, isNotNull);
      expect(handler.lastInitRequest!.protocolVersion, 1);
      expect(agentConn.state, ConnectionState.open);

      // Check response was sent
      expect(transport.sent, hasLength(1));
      final resp = transport.sent.first as JsonRpcResponse;
      expect(resp.isSuccess, isTrue);
      final result = resp.result as Map<String, dynamic>;
      expect(result['protocolVersion'], 1);
    });

    test('stores remote capabilities after initialize', () async {
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {
          'protocolVersion': 1,
          'clientCapabilities': {
            'fs': {'readTextFile': true, 'writeTextFile': true},
            'terminal': true,
          },
        },
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(agentConn.remoteCapabilities, isNotNull);
      expect(agentConn.remoteCapabilities!.fs.readTextFile, isTrue);
      expect(agentConn.remoteCapabilities!.terminal, isTrue);
    });

    test('dispatches session/new to handler', () async {
      // Initialize first
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {'protocolVersion': 1},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      transport.receive(const JsonRpcRequest(
        id: 2,
        method: 'session/new',
        params: {'cwd': '/home/user'},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.lastNewSessionRequest, isNotNull);
      expect(handler.lastNewSessionRequest!.cwd, '/home/user');

      final resp = transport.sent.last as JsonRpcResponse;
      expect(resp.id, 2);
      expect(resp.isSuccess, isTrue);
    });

    test('dispatches session/cancel notification', () async {
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {'protocolVersion': 1},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      transport.receive(const JsonRpcNotification(
        method: 'session/cancel',
        params: {'sessionId': 's1'},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.lastCancelNotification, isNotNull);
      expect(handler.lastCancelNotification!.sessionId, 's1');
    });

    test('optional methods return METHOD_NOT_FOUND by default', () async {
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {'protocolVersion': 1},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      transport.receive(const JsonRpcRequest(
        id: 2,
        method: 'session/set_mode',
        params: {'sessionId': 's1', 'modeId': 'fast'},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resp = transport.sent.last as JsonRpcResponse;
      expect(resp.id, 2);
      expect(resp.isError, isTrue);
      expect(resp.error!.code, -32601);
    });

    test('notifySessionUpdate sends session/update notification', () async {
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {'protocolVersion': 1},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await agentConn.notifySessionUpdate(
        's1',
        AgentMessageChunk(content: {'type': 'text', 'text': 'hello'}),
      );

      // Find the notification (skip the initialize response)
      final notif = transport.sent
          .whereType<JsonRpcNotification>()
          .firstWhere((n) => n.method == 'session/update');
      expect(notif.params!['sessionId'], 's1');
    });

    test('sendReadTextFile sends fs/read_text_file request', () async {
      // Initialize with fs.readTextFile capability
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {
          'protocolVersion': 1,
          'clientCapabilities': {
            'fs': {'readTextFile': true},
          },
        },
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final future = agentConn.sendReadTextFile(
        sessionId: 's1',
        path: '/tmp/test.txt',
      );
      await Future<void>.delayed(Duration.zero);

      // Find the request
      final req = transport.sent
          .whereType<JsonRpcRequest>()
          .firstWhere((r) => r.method == 'fs/read_text_file');
      expect(req.params!['path'], '/tmp/test.txt');

      // Simulate response
      transport.receive(JsonRpcResponse(
        id: req.id,
        result: {'content': 'file contents'},
      ));

      final resp = await future;
      expect(resp.content, 'file contents');
    });

    test('strict capability enforcement blocks uncapable requests', () async {
      // Initialize without fs capability
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {
          'protocolVersion': 1,
          'clientCapabilities': {
            'fs': {'readTextFile': false},
          },
        },
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        () => agentConn.sendReadTextFile(
          sessionId: 's1',
          path: '/tmp/test.txt',
        ),
        throwsA(isA<CapabilityException>()),
      );
    });

    test('extMethod sends extension request', () async {
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {'protocolVersion': 1},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final future = agentConn.extMethod('_vendor/custom', {'data': 42});
      await Future<void>.delayed(Duration.zero);

      final req = transport.sent
          .whereType<JsonRpcRequest>()
          .firstWhere((r) => r.method == '_vendor/custom');
      transport.receive(JsonRpcResponse(
        id: req.id,
        result: {'ok': true},
      ));

      final result = await future;
      expect(result['ok'], true);
    });

    test('extNotification sends extension notification', () async {
      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {'protocolVersion': 1},
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await agentConn.extNotification('_vendor/event', {'data': 1});

      final notif = transport.sent
          .whereType<JsonRpcNotification>()
          .firstWhere((n) => n.method == '_vendor/event');
      expect(notif.params!['data'], 1);
    });
  });

  group('AgentSideConnection permissive mode', () {
    test('permissive mode allows sending without capability check', () async {
      final transport = MockTransport();
      final agentConn = AgentSideConnection(
        transport,
        capabilityEnforcement: CapabilityEnforcement.permissive,
        handlerFactory: (conn) => _PermissiveTestHandler(),
      );

      transport.receive(const JsonRpcRequest(
        id: 1,
        method: 'initialize',
        params: {
          'protocolVersion': 1,
          'clientCapabilities': {
            'fs': {'readTextFile': false},
          },
        },
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Should NOT throw despite readTextFile being false
      final future = agentConn.sendReadTextFile(
        sessionId: 's1',
        path: '/tmp/test.txt',
      );
      await Future<void>.delayed(Duration.zero);

      final req = transport.sent
          .whereType<JsonRpcRequest>()
          .firstWhere((r) => r.method == 'fs/read_text_file');
      transport.receive(JsonRpcResponse(
        id: req.id,
        result: {'content': 'data'},
      ));

      final resp = await future;
      expect(resp.content, 'data');

      await agentConn.close();
    });
  });
}

class _PermissiveTestHandler implements AgentHandler {
  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const NewSessionResponse(sessionId: 's1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const PromptResponse(stopReason: 'end_turn');
}
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/unit/agent_side_connection_test.dart`
Expected: Compilation error — `AgentSideConnection` doesn't exist yet.

**Step 3: Implement AgentSideConnection**

Create `lib/src/protocol/agent_side_connection.dart`. Key design:

- Constructor takes `AcpTransport`, `handlerFactory`, optional `capabilityEnforcement`, optional `useUnstableProtocol`, optional `defaultTimeout`.
- Creates `Connection(transport)`, calls `handlerFactory(this)` to get `AgentHandler`.
- Registers request handlers for: `initialize`, `authenticate`, `session/new`, `session/load`, `session/prompt`, `session/set_mode`, `session/set_config_option`.
- Registers notification handler for: `session/cancel`.
- Registers extension request/notification fallback handlers.
- `initialize` handler: deserializes `InitializeRequest`, calls `handler.initialize()`, stores `remoteCapabilities` (the `ClientCapabilities` from the request), serializes result, calls `_connection.markOpen()`.
- Each handler: deserializes params → typed request, creates `AcpCancellationSource`, calls handler method, serializes result.
- `notifySessionUpdate(sessionId, update)`: sends `session/update` notification with `SessionNotification` envelope.
- `sendReadTextFile(...)`, `sendWriteTextFile(...)`, `sendCreateTerminal(...)`, etc.: typed methods to send client-side requests TO the client. These check capability enforcement first.
- `extMethod(method, params)` / `extNotification(method, params)`: for sending extension messages.
- Delegates `state`, `onStateChange`, `warnings`, `close()`, `onSend`, `onReceive` to underlying `Connection`.
- Calls `_connection.start()` in constructor.

```dart
import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/acp_methods.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/capability_enforcement.dart';
import 'package:acp/src/protocol/connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/protocol/protocol_warning.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.protocol.agent_side');

/// Typed connection facade for agent implementers.
///
/// Wraps a [Connection] and provides typed dispatch for all agent-side
/// ACP methods. Incoming client requests are deserialized into typed schema
/// objects and routed to the [AgentHandler].
///
/// Constructor starts the connection immediately — call [close] when done.
final class AgentSideConnection {
  final Connection _connection;
  late final AgentHandler _handler;
  final CapabilityEnforcement _capabilityEnforcement;

  /// Capabilities advertised by the remote client (set after initialize).
  ClientCapabilities? _remoteCapabilities;

  /// Capabilities advertised by this agent (set after initialize).
  AgentCapabilities? _localCapabilities;

  /// Creates an agent-side connection over [transport].
  ///
  /// [handlerFactory] receives this connection and returns an [AgentHandler].
  /// This breaks circular dependencies between handler and connection.
  ///
  /// [capabilityEnforcement] controls whether outgoing requests are checked
  /// against peer-advertised capabilities (default: [CapabilityEnforcement.strict]).
  ///
  /// [useUnstableProtocol] enables unstable/experimental methods.
  AgentSideConnection(
    AcpTransport transport, {
    required AgentHandler Function(AgentSideConnection conn) handlerFactory,
    CapabilityEnforcement capabilityEnforcement = CapabilityEnforcement.strict,
    bool useUnstableProtocol = false,
    Duration defaultTimeout = const Duration(seconds: 60),
  })  : _capabilityEnforcement = capabilityEnforcement,
        _connection = Connection(transport, defaultTimeout: defaultTimeout) {
    _handler = handlerFactory(this);
    _registerHandlers();
    _connection.start();
  }

  // -- Delegated lifecycle --

  /// The current connection state.
  ConnectionState get state => _connection.state;

  /// Stream of connection state changes.
  Stream<ConnectionState> get onStateChange => _connection.onStateChange;

  /// Stream of non-fatal protocol warnings.
  Stream<ProtocolWarning> get warnings => _connection.warnings;

  /// Closes the connection.
  Future<void> close({
    Duration flushTimeout = const Duration(seconds: 5),
  }) =>
      _connection.close(flushTimeout: flushTimeout);

  /// Capabilities advertised by the remote client.
  ClientCapabilities? get remoteCapabilities => _remoteCapabilities;

  /// Capabilities advertised by this agent.
  AgentCapabilities? get localCapabilities => _localCapabilities;

  /// Optional callback invoked before each outgoing message is written.
  set onSend(void Function(Map<String, dynamic> message)? callback) =>
      _connection.onSend = callback;

  /// Optional callback invoked after each incoming message is read.
  set onReceive(void Function(Map<String, dynamic> message)? callback) =>
      _connection.onReceive = callback;

  // -- Agent → Client requests --

  /// Sends a `fs/read_text_file` request to the client.
  ///
  /// Requires the client to have advertised `fs.readTextFile` capability.
  Future<ReadTextFileResponse> sendReadTextFile({
    required String sessionId,
    required String path,
    int? line,
    int? limit,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.fsReadTextFile,
      'fs.readTextFile',
      _remoteCapabilities?.fs.readTextFile ?? false,
    );
    final params = ReadTextFileRequest(
      sessionId: sessionId,
      path: path,
      line: line,
      limit: limit,
    ).toJson();
    final result = await _connection.sendRequest(
      AcpMethods.fsReadTextFile,
      params,
      cancelToken: cancelToken,
    );
    return ReadTextFileResponse.fromJson(result);
  }

  /// Sends a `fs/write_text_file` request to the client.
  ///
  /// Requires the client to have advertised `fs.writeTextFile` capability.
  Future<WriteTextFileResponse> sendWriteTextFile({
    required String sessionId,
    required String path,
    required String content,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.fsWriteTextFile,
      'fs.writeTextFile',
      _remoteCapabilities?.fs.writeTextFile ?? false,
    );
    final params = WriteTextFileRequest(
      sessionId: sessionId,
      path: path,
      content: content,
    ).toJson();
    final result = await _connection.sendRequest(
      AcpMethods.fsWriteTextFile,
      params,
      cancelToken: cancelToken,
    );
    return WriteTextFileResponse.fromJson(result);
  }

  /// Sends a `terminal/create` request to the client.
  ///
  /// Requires the client to have advertised `terminal` capability.
  Future<CreateTerminalResponse> sendCreateTerminal({
    required String sessionId,
    required String command,
    List<String>? args,
    List<Map<String, dynamic>>? env,
    String? cwd,
    int? outputByteLimit,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalCreate,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final params = CreateTerminalRequest(
      sessionId: sessionId,
      command: command,
      args: args,
      env: env,
      cwd: cwd,
      outputByteLimit: outputByteLimit,
    ).toJson();
    final result = await _connection.sendRequest(
      AcpMethods.terminalCreate,
      params,
      cancelToken: cancelToken,
    );
    return CreateTerminalResponse.fromJson(result);
  }

  /// Sends a `terminal/output` request to the client.
  Future<TerminalOutputResponse> sendTerminalOutput({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalOutput,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final params = TerminalOutputRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    ).toJson();
    final result = await _connection.sendRequest(
      AcpMethods.terminalOutput,
      params,
      cancelToken: cancelToken,
    );
    return TerminalOutputResponse.fromJson(result);
  }

  /// Sends a `terminal/release` request to the client.
  Future<void> sendReleaseTerminal({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalRelease,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final params = ReleaseTerminalRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    ).toJson();
    await _connection.sendRequest(
      AcpMethods.terminalRelease,
      params,
      cancelToken: cancelToken,
    );
  }

  /// Sends a `terminal/kill` request to the client.
  Future<void> sendKillTerminal({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalKill,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final params = KillTerminalCommandRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    ).toJson();
    await _connection.sendRequest(
      AcpMethods.terminalKill,
      params,
      cancelToken: cancelToken,
    );
  }

  /// Sends a `terminal/wait_for_exit` request to the client.
  Future<WaitForTerminalExitResponse> sendWaitForTerminalExit({
    required String sessionId,
    required String terminalId,
    AcpCancellationToken? cancelToken,
  }) async {
    _enforceCapability(
      AcpMethods.terminalWaitForExit,
      'terminal',
      _remoteCapabilities?.terminal ?? false,
    );
    final params = WaitForTerminalExitRequest(
      sessionId: sessionId,
      terminalId: terminalId,
    ).toJson();
    final result = await _connection.sendRequest(
      AcpMethods.terminalWaitForExit,
      params,
      cancelToken: cancelToken,
    );
    return WaitForTerminalExitResponse.fromJson(result);
  }

  /// Sends a `session/request_permission` request to the client.
  Future<RequestPermissionResponse> sendRequestPermission({
    required String sessionId,
    required Map<String, dynamic> toolCall,
    required List<Map<String, dynamic>> options,
    AcpCancellationToken? cancelToken,
  }) async {
    final params = RequestPermissionRequest(
      sessionId: sessionId,
      toolCall: toolCall,
      options: options,
    ).toJson();
    final result = await _connection.sendRequest(
      AcpMethods.sessionRequestPermission,
      params,
      cancelToken: cancelToken,
    );
    return RequestPermissionResponse.fromJson(result);
  }

  // -- Agent → Client notifications --

  /// Sends a `session/update` notification to the client.
  Future<void> notifySessionUpdate(
    String sessionId,
    SessionUpdate update,
  ) async {
    await _connection.notify(AcpMethods.sessionUpdate, {
      'sessionId': sessionId,
      'update': update.toJson(),
    });
  }

  // -- Extension methods --

  /// Sends an extension request to the client.
  Future<Map<String, dynamic>> extMethod(
    String method,
    Map<String, dynamic>? params, {
    AcpCancellationToken? cancelToken,
  }) =>
      _connection.sendRequest(method, params, cancelToken: cancelToken);

  /// Sends an extension notification to the client.
  Future<void> extNotification(
    String method, [
    Map<String, dynamic>? params,
  ]) =>
      _connection.notify(method, params);

  // -- Internal handler registration --

  void _registerHandlers() {
    // Agent-side request handlers (client → agent)
    _connection.setRequestHandler(
      AcpMethods.initialize,
      _handleInitialize,
    );
    _connection.setRequestHandler(
      AcpMethods.authenticate,
      _handleAuthenticate,
    );
    _connection.setRequestHandler(
      AcpMethods.sessionNew,
      _handleNewSession,
    );
    _connection.setRequestHandler(
      AcpMethods.sessionLoad,
      _handleLoadSession,
    );
    _connection.setRequestHandler(
      AcpMethods.sessionPrompt,
      _handlePrompt,
    );
    _connection.setRequestHandler(
      AcpMethods.sessionSetMode,
      _handleSetMode,
    );
    _connection.setRequestHandler(
      AcpMethods.sessionSetConfigOption,
      _handleSetConfigOption,
    );

    // Agent-side notification handler (client → agent)
    _connection.setNotificationHandler(
      AcpMethods.sessionCancel,
      _handleCancel,
    );

    // Extension handlers
    _connection.setExtensionRequestHandler(_handleExtRequest);
    _connection.setExtensionNotificationHandler(_handleExtNotification);
  }

  Future<Map<String, dynamic>> _handleInitialize(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final initReq = InitializeRequest.fromJson(request.params ?? {});
    _remoteCapabilities = initReq.clientCapabilities;

    final response = await _handler.initialize(
      initReq,
      cancelToken: cancelToken,
    );
    _localCapabilities = response.agentCapabilities;

    // Transition to open after successful initialize
    _connection.markOpen();

    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleAuthenticate(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = AuthenticateRequest.fromJson(request.params ?? {});
    final response = await _handler.authenticate(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleNewSession(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = NewSessionRequest.fromJson(request.params ?? {});
    final response = await _handler.newSession(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleLoadSession(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = LoadSessionRequest.fromJson(request.params ?? {});
    final response = await _handler.loadSession(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handlePrompt(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = PromptRequest.fromJson(request.params ?? {});
    final response = await _handler.prompt(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleSetMode(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = SetSessionModeRequest.fromJson(request.params ?? {});
    final response = await _handler.setMode(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<Map<String, dynamic>> _handleSetConfigOption(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final req = SetSessionConfigOptionRequest.fromJson(request.params ?? {});
    final response = await _handler.setConfigOption(
      req,
      cancelToken: cancelToken,
    );
    return response.toJson();
  }

  Future<void> _handleCancel(JsonRpcNotification notification) async {
    final req = CancelNotification.fromJson(notification.params ?? {});
    await _handler.cancel(req);
  }

  Future<Map<String, dynamic>> _handleExtRequest(
    JsonRpcRequest request,
    AcpCancellationToken cancelToken,
  ) async {
    final result = await _handler.onExtMethod(
      request.method,
      request.params,
      cancelToken: cancelToken,
    );
    if (result == null) {
      throw RpcErrorException.methodNotFound(
        'Extension method not handled: ${request.method}',
      );
    }
    return result;
  }

  Future<void> _handleExtNotification(
    JsonRpcNotification notification,
  ) async {
    await _handler.onExtNotification(
      notification.method,
      notification.params,
    );
  }

  void _enforceCapability(
    String method,
    String capability,
    bool isAdvertised,
  ) {
    if (_capabilityEnforcement == CapabilityEnforcement.strict &&
        !isAdvertised) {
      throw CapabilityException(method, capability);
    }
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `dart analyze && dart test test/unit/agent_side_connection_test.dart`
Expected: All tests pass, no analyzer issues.

**Step 5: Commit**

```bash
git add lib/src/protocol/agent_side_connection.dart test/unit/agent_side_connection_test.dart test/helpers/mock_transport.dart
git commit -m "feat: add AgentSideConnection with typed dispatch and capability enforcement"
```

---

### Task 5: ClientSideConnection

**Files:**
- Create: `lib/src/protocol/client_side_connection.dart`
- Test: `test/unit/client_side_connection_test.dart`

**Step 1: Write tests**

Key tests:
1. `sendInitialize` sends initialize request and stores capabilities.
2. `sendAuthenticate` sends authenticate request.
3. `sendNewSession` sends session/new request.
4. `sendPrompt` sends session/prompt request.
5. `sendCancel` sends session/cancel notification.
6. `sendSetMode` sends session/set_mode request.
7. `sendSetConfigOption` sends session/set_config_option request.
8. Incoming `session/update` notification dispatches to handler's `onSessionUpdate`.
9. Incoming `fs/read_text_file` request dispatches to handler's `readTextFile`.
10. Incoming `terminal/create` request dispatches to handler's `createTerminal`.
11. Unimplemented client methods return METHOD_NOT_FOUND.
12. Strict capability enforcement for `sendLoadSession` when agent doesn't advertise `loadSession`.
13. `extMethod` / `extNotification` work.
14. Incoming extension method dispatches to handler's `onExtMethod`.
15. `sessionUpdates` stream emits parsed updates.

```dart
import 'dart:async';

import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

import '../helpers/mock_transport.dart';

class TestClientHandler implements ClientHandler {
  final List<(String, SessionUpdate)> receivedUpdates = [];

  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {
    receivedUpdates.add((sessionId, update));
  }

  @override
  Future<ReadTextFileResponse> readTextFile(
    ReadTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      ReadTextFileResponse(content: 'contents of ${request.path}');
}

void main() {
  group('ClientSideConnection', () {
    late MockTransport transport;
    late TestClientHandler handler;
    late ClientSideConnection clientConn;

    setUp(() {
      transport = MockTransport();
      handler = TestClientHandler();
      clientConn = ClientSideConnection(
        transport,
        handler: handler,
        clientCapabilities: const ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true),
          terminal: true,
        ),
      );
    });

    tearDown(() async {
      await clientConn.close();
    });

    test('sendInitialize sends request and stores capabilities', () async {
      final future = clientConn.sendInitialize(protocolVersion: 1);
      await Future<void>.delayed(Duration.zero);

      final req = transport.sent.first as JsonRpcRequest;
      expect(req.method, 'initialize');
      expect(req.params!['protocolVersion'], 1);

      transport.receive(JsonRpcResponse(
        id: req.id,
        result: {
          'protocolVersion': 1,
          'agentCapabilities': {
            'loadSession': true,
            'promptCapabilities': {'image': true},
          },
          'authMethods': [],
        },
      ));

      final resp = await future;
      expect(resp.protocolVersion, 1);
      expect(clientConn.state, ConnectionState.open);
      expect(clientConn.remoteCapabilities, isNotNull);
      expect(clientConn.remoteCapabilities!.loadSession, isTrue);
    });

    test('sendNewSession sends session/new request', () async {
      // Initialize first
      await _doInitialize(transport, clientConn);

      final future = clientConn.sendNewSession(cwd: '/home/user');
      await Future<void>.delayed(Duration.zero);

      final req = transport.sent
          .whereType<JsonRpcRequest>()
          .firstWhere((r) => r.method == 'session/new');
      transport.receive(JsonRpcResponse(
        id: req.id,
        result: {'sessionId': 'sess-1'},
      ));

      final resp = await future;
      expect(resp.sessionId, 'sess-1');
    });

    test('sendPrompt sends session/prompt request', () async {
      await _doInitialize(transport, clientConn);

      final future = clientConn.sendPrompt(
        sessionId: 'sess-1',
        prompt: [const TextContent(text: 'hello')],
      );
      await Future<void>.delayed(Duration.zero);

      final req = transport.sent
          .whereType<JsonRpcRequest>()
          .firstWhere((r) => r.method == 'session/prompt');
      transport.receive(JsonRpcResponse(
        id: req.id,
        result: {'stopReason': 'end_turn'},
      ));

      final resp = await future;
      expect(resp.stopReason, 'end_turn');
    });

    test('sendCancel sends session/cancel notification', () async {
      await _doInitialize(transport, clientConn);

      await clientConn.sendCancel(sessionId: 'sess-1');

      final notif = transport.sent
          .whereType<JsonRpcNotification>()
          .firstWhere((n) => n.method == 'session/cancel');
      expect(notif.params!['sessionId'], 'sess-1');
    });

    test('session/update notification dispatches to handler', () async {
      await _doInitialize(transport, clientConn);

      transport.receive(const JsonRpcNotification(
        method: 'session/update',
        params: {
          'sessionId': 'sess-1',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': {'type': 'text', 'text': 'hello'},
          },
        },
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(handler.receivedUpdates, hasLength(1));
      expect(handler.receivedUpdates.first.$1, 'sess-1');
      expect(handler.receivedUpdates.first.$2, isA<AgentMessageChunk>());
    });

    test('sessionUpdates stream emits parsed updates', () async {
      await _doInitialize(transport, clientConn);

      final updates = <SessionUpdate>[];
      clientConn.sessionUpdates.listen((event) => updates.add(event.update));

      transport.receive(const JsonRpcNotification(
        method: 'session/update',
        params: {
          'sessionId': 'sess-1',
          'update': {
            'sessionUpdate': 'agent_message_chunk',
            'content': {'type': 'text', 'text': 'hello'},
          },
        },
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(updates, hasLength(1));
      expect(updates.first, isA<AgentMessageChunk>());
    });

    test('incoming fs/read_text_file dispatches to handler', () async {
      await _doInitialize(transport, clientConn);

      transport.receive(const JsonRpcRequest(
        id: 100,
        method: 'fs/read_text_file',
        params: {
          'sessionId': 's1',
          'path': '/tmp/test.txt',
        },
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resp = transport.sent
          .whereType<JsonRpcResponse>()
          .firstWhere((r) => r.id == 100);
      expect(resp.isSuccess, isTrue);
      expect(
        (resp.result as Map<String, dynamic>)['content'],
        'contents of /tmp/test.txt',
      );
    });

    test('unimplemented client methods return METHOD_NOT_FOUND', () async {
      await _doInitialize(transport, clientConn);

      transport.receive(const JsonRpcRequest(
        id: 101,
        method: 'terminal/create',
        params: {'sessionId': 's1', 'command': 'ls'},
      ));

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final resp = transport.sent
          .whereType<JsonRpcResponse>()
          .firstWhere((r) => r.id == 101);
      expect(resp.isError, isTrue);
      expect(resp.error!.code, -32601);
    });

    test('strict capability enforcement blocks uncapable requests', () async {
      // Initialize with agent that does NOT advertise loadSession
      final future2 = clientConn.sendInitialize(protocolVersion: 1);
      await Future<void>.delayed(Duration.zero);
      final req = transport.sent.first as JsonRpcRequest;
      transport.receive(JsonRpcResponse(
        id: req.id,
        result: {
          'protocolVersion': 1,
          'agentCapabilities': {'loadSession': false},
          'authMethods': [],
        },
      ));
      await future2;

      expect(
        () => clientConn.sendLoadSession(
          sessionId: 'old',
          cwd: '/home',
        ),
        throwsA(isA<CapabilityException>()),
      );
    });
  });
}

Future<void> _doInitialize(
  MockTransport transport,
  ClientSideConnection clientConn,
) async {
  final future = clientConn.sendInitialize(protocolVersion: 1);
  await Future<void>.delayed(Duration.zero);
  final req = transport.sent.first as JsonRpcRequest;
  transport.receive(JsonRpcResponse(
    id: req.id,
    result: {
      'protocolVersion': 1,
      'agentCapabilities': {'loadSession': true},
      'authMethods': [],
    },
  ));
  await future;
}
```

**Step 2: Run tests to verify they fail**

Run: `dart test test/unit/client_side_connection_test.dart`
Expected: Compilation error — `ClientSideConnection` doesn't exist yet.

**Step 3: Implement ClientSideConnection**

Create `lib/src/protocol/client_side_connection.dart`. Key design:

- Constructor takes `AcpTransport`, `ClientHandler`, `ClientCapabilities`, optional `capabilityEnforcement`, optional `useUnstableProtocol`.
- Creates `Connection(transport)`, registers client-side request handlers for: `fs/read_text_file`, `fs/write_text_file`, `terminal/create`, `terminal/output`, `terminal/release`, `terminal/kill`, `terminal/wait_for_exit`, `session/request_permission`.
- Registers notification handler for `session/update` that parses `SessionNotification` → `SessionUpdate` and calls `handler.onSessionUpdate()`, also emits on `_sessionUpdateController`.
- Typed send methods: `sendInitialize()`, `sendAuthenticate()`, `sendNewSession()`, `sendLoadSession()`, `sendPrompt()`, `sendCancel()`, `sendSetMode()`, `sendSetConfigOption()`.
- `sendInitialize` stores remote capabilities (`AgentCapabilities`), calls `markOpen()`.
- `sessionUpdates` stream exposes parsed `SessionUpdateEvent` (sessionId + update).
- Calls `_connection.start()` in constructor.

The implementation follows the same pattern as `AgentSideConnection` but mirrored.

**Step 4: Run tests to verify they pass**

Run: `dart analyze && dart test test/unit/client_side_connection_test.dart`
Expected: All tests pass, no analyzer issues.

**Step 5: Commit**

```bash
git add lib/src/protocol/client_side_connection.dart test/unit/client_side_connection_test.dart
git commit -m "feat: add ClientSideConnection with typed send methods and handler dispatch"
```

---

### Task 6: Update Export Files

**Files:**
- Modify: `lib/agent.dart`
- Modify: `lib/client.dart`

**Step 1: Update lib/agent.dart**

Add exports for `AgentSideConnection`, `AgentHandler`, `CapabilityEnforcement`:

```dart
/// Agent-side ACP types and connection — for agent implementers.
library;

export 'src/protocol/acp_methods.dart';
export 'src/protocol/agent_handler.dart';
export 'src/protocol/agent_side_connection.dart';
export 'src/protocol/cancellation.dart';
export 'src/protocol/capability_enforcement.dart';
export 'src/protocol/connection_state.dart';
export 'src/protocol/exceptions.dart';
export 'src/protocol/protocol_warning.dart';
```

Remove `connection.dart` and `json_rpc_message.dart` exports (internal types; users interact via `AgentSideConnection`).

**Step 2: Update lib/client.dart**

```dart
/// Client-side ACP types and connection — for client implementers.
library;

export 'src/protocol/acp_methods.dart';
export 'src/protocol/cancellation.dart';
export 'src/protocol/capability_enforcement.dart';
export 'src/protocol/client_handler.dart';
export 'src/protocol/client_side_connection.dart';
export 'src/protocol/connection_state.dart';
export 'src/protocol/exceptions.dart';
export 'src/protocol/protocol_warning.dart';
```

**Step 3: Run full test suite**

Run: `dart analyze && dart test`
Expected: All tests pass, no analyzer issues.

**Step 4: Commit**

```bash
git add lib/agent.dart lib/client.dart
git commit -m "feat: update agent.dart and client.dart exports with typed connection facades"
```

---

### Task 7: Integration Test — Full Client↔Agent Exchange

**Files:**
- Create: `test/integration/client_agent_exchange_test.dart`

This test wires `ClientSideConnection` and `AgentSideConnection` together via a pair of in-memory transports (a "pipe" where one side's sends appear as the other's messages) and runs a full protocol exchange.

**Step 1: Create a linked transport pair helper**

Create `test/helpers/linked_transport.dart`:

```dart
import 'dart:async';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';

/// Creates a pair of linked in-memory transports.
///
/// Messages sent by one side are received by the other.
(AcpTransport, AcpTransport) createLinkedTransports() {
  final aToB = StreamController<JsonRpcMessage>();
  final bToA = StreamController<JsonRpcMessage>();

  final transportA = _LinkedTransport(
    inbound: bToA.stream,
    outboundSink: aToB,
  );
  final transportB = _LinkedTransport(
    inbound: aToB.stream,
    outboundSink: bToA,
  );

  return (transportA, transportB);
}

class _LinkedTransport implements AcpTransport {
  final Stream<JsonRpcMessage> _inbound;
  final StreamController<JsonRpcMessage> _outboundSink;
  bool _closed = false;

  _LinkedTransport({
    required Stream<JsonRpcMessage> inbound,
    required StreamController<JsonRpcMessage> outboundSink,
  })  : _inbound = inbound,
        _outboundSink = outboundSink;

  @override
  Stream<JsonRpcMessage> get messages => _inbound;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) throw StateError('closed');
    _outboundSink.add(message);
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _outboundSink.close();
  }
}
```

**Step 2: Write the integration test**

```dart
import 'dart:async';

import 'package:acp/src/protocol/agent_handler.dart';
import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/protocol/client_handler.dart';
import 'package:acp/src/protocol/client_side_connection.dart';
import 'package:acp/src/protocol/connection_state.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/client_methods.dart';
import 'package:acp/src/schema/content_block.dart';
import 'package:acp/src/schema/initialize.dart';
import 'package:acp/src/schema/session.dart';
import 'package:acp/src/schema/session_update.dart';
import 'package:test/test.dart';

import '../helpers/linked_transport.dart';

void main() {
  group('Client ↔ Agent full exchange', () {
    test('initialize → session/new → prompt with streaming updates', () async {
      final (clientTransport, agentTransport) = createLinkedTransports();

      // Set up agent
      late AgentSideConnection agentConn;
      agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _IntegrationAgentHandler(conn),
      );

      // Set up client
      final clientHandler = _IntegrationClientHandler();
      final clientConn = ClientSideConnection(
        clientTransport,
        handler: clientHandler,
        clientCapabilities: const ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true),
        ),
      );

      // Collect session updates
      final updates = <SessionUpdate>[];
      clientConn.sessionUpdates.listen((e) => updates.add(e.update));

      // 1. Initialize
      final initResp = await clientConn.sendInitialize(protocolVersion: 1);
      expect(initResp.protocolVersion, 1);
      expect(clientConn.state, ConnectionState.open);

      // 2. Create session
      final sessionResp = await clientConn.sendNewSession(cwd: '/home/user');
      expect(sessionResp.sessionId, isNotEmpty);

      // 3. Send prompt (agent handler will stream updates and then respond)
      final promptResp = await clientConn.sendPrompt(
        sessionId: sessionResp.sessionId,
        prompt: [const TextContent(text: 'What is 2+2?')],
      );
      expect(promptResp.stopReason, 'end_turn');

      // Allow time for updates to propagate
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Verify we received streaming updates
      expect(updates, isNotEmpty);
      expect(updates.first, isA<AgentMessageChunk>());

      // 4. Cancel
      await clientConn.sendCancel(sessionId: sessionResp.sessionId);

      // Cleanup
      await clientConn.close();
      await agentConn.close();
    });

    test('agent reads file from client via fs/read_text_file', () async {
      final (clientTransport, agentTransport) = createLinkedTransports();

      late AgentSideConnection agentConn;
      agentConn = AgentSideConnection(
        agentTransport,
        handlerFactory: (conn) => _FileReadingAgentHandler(conn),
      );

      final clientHandler = _FileServingClientHandler();
      final clientConn = ClientSideConnection(
        clientTransport,
        handler: clientHandler,
        clientCapabilities: const ClientCapabilities(
          fs: FileSystemCapability(readTextFile: true),
        ),
      );

      // Initialize
      await clientConn.sendInitialize(protocolVersion: 1);

      // Create session
      final sessionResp = await clientConn.sendNewSession(cwd: '/home');

      // Send prompt — agent will read a file and include content in response
      final promptResp = await clientConn.sendPrompt(
        sessionId: sessionResp.sessionId,
        prompt: [const TextContent(text: 'read /tmp/hello.txt')],
      );
      expect(promptResp.stopReason, 'end_turn');

      await clientConn.close();
      await agentConn.close();
    });
  });
}

class _IntegrationAgentHandler implements AgentHandler {
  final AgentSideConnection _conn;

  _IntegrationAgentHandler(this._conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const NewSessionResponse(sessionId: 'integration-session-1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    // Stream an update before responding
    await _conn.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(content: {'type': 'text', 'text': 'The answer is 4.'}),
    );
    return const PromptResponse(stopReason: 'end_turn');
  }
}

class _IntegrationClientHandler implements ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {}
}

class _FileReadingAgentHandler implements AgentHandler {
  final AgentSideConnection _conn;

  _FileReadingAgentHandler(this._conn);

  @override
  Future<InitializeResponse> initialize(
    InitializeRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const InitializeResponse(protocolVersion: 1);

  @override
  Future<NewSessionResponse> newSession(
    NewSessionRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      const NewSessionResponse(sessionId: 'file-session-1');

  @override
  Future<PromptResponse> prompt(
    PromptRequest request, {
    required AcpCancellationToken cancelToken,
  }) async {
    // Read a file from the client
    final fileResp = await _conn.sendReadTextFile(
      sessionId: request.sessionId,
      path: '/tmp/hello.txt',
    );

    // Stream the file contents back
    await _conn.notifySessionUpdate(
      request.sessionId,
      AgentMessageChunk(
        content: {'type': 'text', 'text': fileResp.content},
      ),
    );
    return const PromptResponse(stopReason: 'end_turn');
  }
}

class _FileServingClientHandler implements ClientHandler {
  @override
  void onSessionUpdate(String sessionId, SessionUpdate update) {}

  @override
  Future<ReadTextFileResponse> readTextFile(
    ReadTextFileRequest request, {
    required AcpCancellationToken cancelToken,
  }) async =>
      ReadTextFileResponse(content: 'Hello from ${request.path}');
}
```

**Step 3: Run the integration test**

Run: `dart analyze && dart test test/integration/client_agent_exchange_test.dart`
Expected: All tests pass.

**Step 4: Commit**

```bash
git add test/helpers/linked_transport.dart test/integration/client_agent_exchange_test.dart
git commit -m "test: add integration test for full client↔agent exchange"
```

---

### Task 8: Run Full Suite and Verify

**Step 1: Run analyzer**

Run: `dart analyze`
Expected: No issues found.

**Step 2: Run all tests**

Run: `dart test`
Expected: All tests pass (original 68 + new handler tests + connection tests + integration tests).

**Step 3: Commit final state**

```bash
git add -A
git commit -m "milestone 2: typed connection facades, handler interfaces, capability enforcement"
```

---

## Summary of files created/modified

| Action | File |
|--------|------|
| Create | `lib/src/protocol/capability_enforcement.dart` |
| Create | `lib/src/protocol/agent_handler.dart` |
| Create | `lib/src/protocol/client_handler.dart` |
| Create | `lib/src/protocol/agent_side_connection.dart` |
| Create | `lib/src/protocol/client_side_connection.dart` |
| Create | `test/helpers/mock_transport.dart` |
| Create | `test/helpers/linked_transport.dart` |
| Create | `test/unit/agent_handler_test.dart` |
| Create | `test/unit/client_handler_test.dart` |
| Create | `test/unit/agent_side_connection_test.dart` |
| Create | `test/unit/client_side_connection_test.dart` |
| Create | `test/integration/client_agent_exchange_test.dart` |
| Modify | `test/unit/connection_test.dart` (extract MockTransport) |
| Modify | `lib/agent.dart` (add new exports) |
| Modify | `lib/client.dart` (add new exports) |
