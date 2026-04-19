import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';
import 'package:web/web.dart' as web;

final _log = Logger('acp.transport.browser_web_socket');

/// A transport that communicates via browser WebSockets.
///
/// This implementation uses `package:web` and is suitable for
/// browser-based applications compiled with `dart2js` or `dart2wasm`.
final class BrowserWebSocketTransport implements AcpTransport {
  final web.WebSocket _socket;
  final StreamController<JsonRpcMessage> _controller =
      StreamController<JsonRpcMessage>();
  bool _closed = false;

  BrowserWebSocketTransport._(this._socket) {
    _socket.onMessage.listen((web.MessageEvent event) {
      final data = event.data;
      if (data.isA<JSString>()) {
        try {
          final json =
              jsonDecode((data as JSString).toDart) as Map<String, dynamic>;
          final message = JsonRpcMessage.fromJson(json);
          _controller.add(message);
        } catch (e, stack) {
          _log.warning('Failed to parse message: $e', e, stack);
        }
      }
    });

    _socket.onClose.listen((web.CloseEvent event) {
      _log.fine('WebSocket closed: ${event.code} ${event.reason}');
      if (!_closed) unawaited(close());
    });

    _socket.onError.listen((web.Event event) {
      if (!_closed) {
        _log.severe('WebSocket error');
        _controller.addError(Exception('WebSocket error'));
        unawaited(close());
      }
    });
  }

  /// Connects to a remote ACP agent over WebSocket.
  static Future<BrowserWebSocketTransport> connect(Uri url) async {
    final completer = Completer<BrowserWebSocketTransport>();
    final socket = web.WebSocket(url.toString());

    StreamSubscription<web.Event>? openSub;
    StreamSubscription<web.Event>? errorSub;

    openSub = socket.onOpen.listen((_) {
      openSub?.cancel();
      errorSub?.cancel();
      completer.complete(BrowserWebSocketTransport._(socket));
    });

    errorSub = socket.onError.listen((_) {
      openSub?.cancel();
      errorSub?.cancel();
      completer.completeError(
        Exception('Failed to connect to WebSocket at $url'),
      );
    });

    return completer.future;
  }

  @override
  Stream<JsonRpcMessage> get messages => _controller.stream;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) {
      throw StateError('Cannot send on a closed transport');
    }
    final body = jsonEncode(message.toJson());
    _socket.send(body.toJS);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _socket.close();
    unawaited(_controller.close());
    _log.fine('Browser transport closed');
  }
}
