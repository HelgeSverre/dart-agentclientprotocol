# WebSocket Transport, Request Batching & Connection Keepalive

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add WebSocket transport, JSON-RPC 2.0 batch support, and connection keepalive/heartbeat mechanism.

**Architecture:** Three independent features layered on the existing codebase. WebSocket transport implements `AcpTransport` using `dart:io` `WebSocket`. Batching extends `JsonRpcMessage` parsing and `Connection` dispatch to handle arrays. Keepalive adds periodic ping/pong via `$/ping` notifications inside `Connection`.

**Tech Stack:** Dart 3.7, `dart:io` WebSocket, `package:test`, `package:logging`

---

### Task 1: WebSocket Transport — Implementation

**Files:**

- Create: `lib/src/transport/web_socket_transport.dart`
- Modify: `lib/transport.dart` (add export)

**Step 1: Create `WebSocketTransport`**

Create `lib/src/transport/web_socket_transport.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.transport.web_socket');

/// A transport that communicates via WebSocket.
///
/// Messages are sent and received as JSON text frames. Each frame contains
/// a single JSON-RPC message (or a JSON-RPC batch array).
///
/// Use [WebSocketTransport.connect] to connect to a remote agent, or
/// construct directly with an existing [WebSocket] (e.g. from a server
/// upgrade).
final class WebSocketTransport implements AcpTransport {
  final WebSocket _socket;
  final StreamController<JsonRpcMessage> _controller =
      StreamController<JsonRpcMessage>();
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;

  /// Creates a transport wrapping an already-connected [socket].
  ///
  /// The caller is responsible for ensuring the socket is in the
  /// [WebSocket.open] state.
  WebSocketTransport(this._socket) {
    _startListening();
  }

  /// Connects to a remote WebSocket endpoint at [url].
  ///
  /// Optional [headers] are passed to the WebSocket handshake (e.g. for
  /// authentication). Optional [protocols] specifies the WebSocket
  /// sub-protocols to request.
  static Future<WebSocketTransport> connect(
    Uri url, {
    Map<String, String>? headers,
    Iterable<String>? protocols,
  }) async {
    final socket = await WebSocket.connect(
      url.toString(),
      headers: headers,
      protocols: protocols,
    );
    _log.fine('WebSocket connected to $url');
    return WebSocketTransport(socket);
  }

  void _startListening() {
    _subscription = _socket.listen(
      _handleData,
      onError: (Object error, StackTrace stack) {
        if (_closed) return;
        _log.severe('WebSocket error', error, stack);
        _controller.addError(error, stack);
        unawaited(close());
      },
      onDone: () {
        _log.fine(
          'WebSocket closed (code: ${_socket.closeCode}, '
          'reason: ${_socket.closeReason})',
        );
        if (!_closed) unawaited(close());
      },
    );
  }

  void _handleData(dynamic data) {
    if (data is! String) {
      _log.warning('Ignoring non-text WebSocket frame');
      return;
    }

    try {
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) {
        _controller.add(JsonRpcMessage.fromJson(json));
      } else if (json is List) {
        // Batch: emit each message individually
        for (final item in json) {
          if (item is Map<String, dynamic>) {
            _controller.add(JsonRpcMessage.fromJson(item));
          }
        }
      } else {
        _log.warning('Unexpected JSON type: ${json.runtimeType}');
      }
    } on FormatException catch (e, stack) {
      _log.warning('Failed to parse WebSocket message: $e');
      _controller.addError(e, stack);
    }
  }

  /// The WebSocket close code, available after the socket has closed.
  int? get closeCode => _socket.closeCode;

  /// The WebSocket close reason, available after the socket has closed.
  String? get closeReason => _socket.closeReason;

  @override
  Stream<JsonRpcMessage> get messages => _controller.stream;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) {
      throw StateError('Cannot send on a closed transport');
    }
    _socket.add(jsonEncode(message.toJson()));
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _socket.close();
    } on Object catch (e) {
      _log.fine('Error closing WebSocket: $e');
    }
    if (_subscription != null) {
      await _subscription!.cancel().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
      _subscription = null;
    }
    unawaited(_controller.close());
    _log.fine('WebSocket transport closed');
  }
}
```

**Step 2: Add export to `lib/transport.dart`**

Add this line to `lib/transport.dart`:

```dart
export 'src/transport/web_socket_transport.dart';
```

**Step 3: Run analyzer**

Run: `dart analyze lib/src/transport/web_socket_transport.dart`
Expected: No issues found

---

### Task 2: WebSocket Transport — Unit Tests

**Files:**

- Create: `test/unit/web_socket_transport_test.dart`

**Step 1: Write unit tests**

Create `test/unit/web_socket_transport_test.dart` modelled after `test/unit/http_sse_transport_test.dart`. Use a local `HttpServer` that upgrades to WebSocket:

```dart
@TestOn('vm')
@Timeout(Duration(seconds: 30))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/web_socket_transport.dart';
import 'package:test/test.dart';

Future<_WsFixture> _startFixture() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final serverSockets = <WebSocket>[];

  server.listen((HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then(serverSockets.add);
    } else {
      request.response.statusCode = HttpStatus.notFound;
      unawaited(request.response.close());
    }
  });

  final uri = Uri.parse('ws://localhost:${server.port}');
  final transport = await WebSocketTransport.connect(uri);

  // Wait for server side socket to be ready
  for (var i = 0; i < 100 && serverSockets.isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }

  return _WsFixture._(
    server: server,
    transport: transport,
    serverSocket: serverSockets.first,
  );
}

class _WsFixture {
  final HttpServer server;
  final WebSocketTransport transport;
  final WebSocket serverSocket;

  _WsFixture._({
    required this.server,
    required this.transport,
    required this.serverSocket,
  });

  Future<void> close() async {
    try { await serverSocket.close(); } on Object { /* best effort */ }
    try { await transport.close(); } on Object { /* best effort */ }
    try { await server.close(force: true); } on Object { /* best effort */ }
  }
}

void main() {
  group('WebSocketTransport', () {
    // Test cases:
    // 1. receives a message from server
    // 2. sends a message to server
    // 3. receives multiple messages in sequence
    // 4. send after close throws StateError
    // 5. close is idempotent
    // 6. close completes the message stream
    // 7. server disconnect closes transport
    // 8. ignores non-text frames
    // 9. handles malformed JSON gracefully (emits error on stream)
    // 10. exposes closeCode/closeReason after close
  });
}
```

Fill in each test following the pattern from `http_sse_transport_test.dart`. Key pattern: send JSON text via `serverSocket.add(jsonEncode(msg))`, listen on `transport.messages`.

**Step 2: Run tests**

Run: `dart test test/unit/web_socket_transport_test.dart -r compact`
Expected: All tests pass

**Step 3: Run analyzer on test file**

Run: `dart analyze test/unit/web_socket_transport_test.dart`
Expected: No issues found

---

### Task 3: JSON-RPC Batch Parsing

**Files:**

- Modify: `lib/src/protocol/json_rpc_message.dart` (add batch parsing helper)
- Create: No new files — add tests to existing test file

**Step 1: Add batch parsing static method to `JsonRpcMessage`**

Add to `lib/src/protocol/json_rpc_message.dart`:

```dart
/// Parses a JSON value that may be a single message or a batch array.
///
/// Returns a list of [JsonRpcMessage] objects. A single message object
/// returns a list with one element. A batch array returns one element
/// per valid message in the array.
///
/// Throws [FormatException] if [json] is neither a Map nor a List.
static List<JsonRpcMessage> parseBatch(Object json) {
  if (json is Map<String, dynamic>) {
    return [JsonRpcMessage.fromJson(json)];
  }
  if (json is List) {
    if (json.isEmpty) {
      throw const FormatException('Empty JSON-RPC batch array');
    }
    return [
      for (final item in json)
        if (item is Map<String, dynamic>) JsonRpcMessage.fromJson(item),
    ];
  }
  throw FormatException(
    'Expected JSON object or array, got ${json.runtimeType}',
  );
}
```

**Step 2: Add tests for batch parsing**

Add to `test/unit/json_rpc_message_test.dart` a new group `'batch parsing'`:

- `parseBatch with single object returns single-element list`
- `parseBatch with array returns multiple messages`
- `parseBatch with empty array throws FormatException`
- `parseBatch with non-object/array throws FormatException`
- `parseBatch skips non-map items in array`
- `parseBatch handles mixed request/notification/response array`

**Step 3: Run tests**

Run: `dart test test/unit/json_rpc_message_test.dart -r compact`
Expected: All tests pass

---

### Task 4: Connection Keepalive — Implementation

**Files:**

- Modify: `lib/src/protocol/connection.dart` (add keepalive timer and ping/pong handling)
- Modify: `lib/src/protocol/acp_methods.dart` (add `$/ping` and `$/pong` constants)

**Step 1: Add ping/pong method constants to `AcpMethods`**

Add to `lib/src/protocol/acp_methods.dart`:

```dart
/// Keepalive ping (JSON-RPC extension notification).
static const String ping = r'$/ping';

/// Keepalive pong response (JSON-RPC extension notification).
static const String pong = r'$/pong';
```

**Step 2: Add keepalive to `Connection`**

Add to `Connection`:

- A `Timer? _keepaliveTimer` field.
- A `Duration? _keepaliveInterval` constructor parameter (nullable, disabled by default).
- A `_startKeepalive()` method called from `markOpen()` that schedules periodic `$/ping` notifications.
- A `_stopKeepalive()` method called from `_cleanup()`.
- Auto-register a notification handler for `$/ping` that responds with `$/pong`.
- Auto-register a notification handler for `$/pong` that resets a "last seen" timestamp.
- A `Duration? _keepaliveTimeout` parameter: if set and no pong arrives within this duration after a ping, close the connection.

Implementation approach — add these fields:

```dart
final Duration? _keepaliveInterval;
final Duration? _keepaliveTimeout;
Timer? _keepaliveTimer;
DateTime? _lastPong;
Timer? _keepaliveTimeoutTimer;
```

Add to constructor signature:

```dart
Connection(
  this._transport, {
  Duration defaultTimeout = const Duration(seconds: 60),
  Duration? keepaliveInterval,
  Duration? keepaliveTimeout,
}) : _defaultTimeout = defaultTimeout,
     _keepaliveInterval = keepaliveInterval,
     _keepaliveTimeout = keepaliveTimeout;
```

In `markOpen()` after `_transition(ConnectionState.open)`, call `_startKeepalive()`.

In constructor body, register the built-in handlers:

```dart
_notificationHandlers[AcpMethods.ping] = _handlePing;
_notificationHandlers[AcpMethods.pong] = _handlePong;
```

Implementation of `_startKeepalive`, `_stopKeepalive`, `_handlePing`, `_handlePong`:

```dart
void _startKeepalive() {
  final interval = _keepaliveInterval;
  if (interval == null) return;
  _keepaliveTimer = Timer.periodic(interval, (_) {
    if (_state != ConnectionState.open) return;
    unawaited(notify(AcpMethods.ping));
    _startKeepaliveTimeout();
  });
}

void _startKeepaliveTimeout() {
  final timeout = _keepaliveTimeout;
  if (timeout == null) return;
  _keepaliveTimeoutTimer?.cancel();
  _keepaliveTimeoutTimer = Timer(timeout, () {
    _log.warning('Keepalive timeout — no pong received');
    unawaited(_cleanup());
  });
}

void _stopKeepalive() {
  _keepaliveTimer?.cancel();
  _keepaliveTimer = null;
  _keepaliveTimeoutTimer?.cancel();
  _keepaliveTimeoutTimer = null;
}

Future<void> _handlePing(JsonRpcNotification notification) async {
  await notify(AcpMethods.pong);
}

Future<void> _handlePong(JsonRpcNotification notification) async {
  _lastPong = DateTime.now();
  _keepaliveTimeoutTimer?.cancel();
  _keepaliveTimeoutTimer = null;
}
```

Call `_stopKeepalive()` at the beginning of `_cleanup()`.

**Step 3: Run analyzer**

Run: `dart analyze lib/src/protocol/connection.dart lib/src/protocol/acp_methods.dart`
Expected: No issues found

---

### Task 5: Connection Keepalive — Unit Tests

**Files:**

- Modify: `test/unit/connection_test.dart` (add keepalive test group)

**Step 1: Add keepalive tests**

Add a new group `'Keepalive'` to `test/unit/connection_test.dart`:

- `sends $/ping at keepalive interval`: Create connection with `keepaliveInterval: Duration(milliseconds: 50)`, verify ping notifications appear in `transport.sent`.
- `responds to incoming $/ping with $/pong`: Send a `$/ping` notification via `transport.receive()`, verify a `$/pong` notification is sent.
- `resets keepalive timeout on pong`: Create connection with both interval and timeout, simulate pong response, verify connection stays open.
- `closes connection on keepalive timeout`: Create connection with `keepaliveInterval: 50ms` and `keepaliveTimeout: 100ms`, don't respond to pings, verify connection transitions to closed.
- `keepalive does not start when interval is null` (default behavior): Create connection without keepalive, verify no pings sent.
- `keepalive stops on close`: Create connection with keepalive, close it, verify no more pings.

**Step 2: Run tests**

Run: `dart test test/unit/connection_test.dart -r compact`
Expected: All tests pass

**Step 3: Run full test suite**

Run: `dart test -r compact`
Expected: All 300+ tests pass (no regressions)

---

### Task 6: Final Verification & Cleanup

**Step 1: Run full analyzer**

Run: `dart analyze`
Expected: No issues found

**Step 2: Run full test suite**

Run: `dart test -r compact`
Expected: All tests pass

**Step 3: Check formatting**

Run: `dart format --set-exit-if-changed lib/ test/`
Expected: No formatting changes needed
