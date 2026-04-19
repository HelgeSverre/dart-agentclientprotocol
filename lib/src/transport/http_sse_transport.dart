import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.transport.http_sse');

/// A transport that communicates via HTTP POST (outgoing) and SSE (incoming).
///
/// Use [HttpSseTransport.connect] to establish a connection to a remote
/// ACP agent. The transport POSTs JSON-RPC messages to [messageUri] and
/// receives messages via Server-Sent Events from [sseUri].
///
/// This transport is only available on `dart:io` platforms.
final class HttpSseTransport implements AcpTransport {
  /// Default cap on the size of a single SSE event's `data:` payload. A
  /// malicious or buggy server that streams `data:` lines without ever
  /// terminating an event would otherwise OOM the process.
  static const int defaultMaxMessageBytes = 16 * 1024 * 1024;

  final Uri _sseUri;
  final Uri _messageUri;
  final Map<String, String>? _headers;
  final HttpClient _httpClient;
  final int _maxMessageBytes;
  final StreamController<JsonRpcMessage> _controller =
      StreamController<JsonRpcMessage>();
  final HttpClientResponse _sseResponse;
  StreamSubscription<String>? _sseSubscription;
  bool _closed = false;

  /// The last SSE event ID received, used for reconnection.
  String? lastEventId;

  HttpSseTransport._({
    required Uri sseUri,
    required Uri messageUri,
    required Map<String, String>? headers,
    required HttpClient httpClient,
    required HttpClientResponse sseResponse,
    required int maxMessageBytes,
  }) : _sseUri = sseUri,
       _messageUri = messageUri,
       _headers = headers,
       _httpClient = httpClient,
       _sseResponse = sseResponse,
       _maxMessageBytes = maxMessageBytes;

  /// Connects to a remote ACP agent.
  ///
  /// [sseUri] is the SSE endpoint for incoming messages.
  /// [messageUri] is the HTTP endpoint for outgoing messages.
  /// [headers] are optional additional HTTP headers (e.g. for auth).
  static Future<HttpSseTransport> connect(
    Uri sseUri,
    Uri messageUri, {
    Map<String, String>? headers,
    int maxMessageBytes = defaultMaxMessageBytes,
  }) async {
    final httpClient = HttpClient();
    final request = await httpClient.getUrl(sseUri);
    request.headers.set('Accept', 'text/event-stream');
    request.headers.set('Cache-Control', 'no-cache');
    if (headers != null) {
      for (final entry in headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
    }

    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      httpClient.close();
      throw HttpException(
        'SSE connection failed with status ${response.statusCode}',
        uri: sseUri,
      );
    }

    _log.fine('SSE connection established to $sseUri');

    final transport = HttpSseTransport._(
      sseUri: sseUri,
      messageUri: messageUri,
      headers: headers,
      httpClient: httpClient,
      sseResponse: response,
      maxMessageBytes: maxMessageBytes,
    );
    transport._startListening();
    return transport;
  }

  void _startListening() {
    _sseSubscription = _sseResponse
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          _handleSseLine,
          onError: (Object error, StackTrace stack) {
            // Suppress errors during shutdown — force-closing the HTTP
            // client triggers an HttpException on the SSE stream.
            if (_closed) return;
            _log.severe('SSE stream error', error, stack);
            _controller.addError(error, stack);
            unawaited(close());
          },
          onDone: () {
            _log.fine('SSE stream ended');
            if (!_closed) unawaited(close());
          },
        );
  }

  final StringBuffer _dataBuffer = StringBuffer();
  String? _eventId;

  void _handleSseLine(String line) {
    if (line.startsWith(':')) {
      // Comment line, ignore.
      return;
    }

    if (line.isEmpty) {
      // Empty line signals end of an event.
      _dispatchEvent();
      return;
    }

    final colonIndex = line.indexOf(':');
    String field;
    String value;
    if (colonIndex == -1) {
      field = line;
      value = '';
    } else {
      field = line.substring(0, colonIndex);
      // Skip optional space after colon.
      final valueStart = colonIndex + 1;
      if (valueStart < line.length && line[valueStart] == ' ') {
        value = line.substring(valueStart + 1);
      } else {
        value = line.substring(valueStart);
      }
    }

    switch (field) {
      case 'data':
        if (_dataBuffer.length + value.length + 1 > _maxMessageBytes) {
          _log.warning(
            'SSE event exceeds ${_maxMessageBytes}B size limit; dropping',
          );
          _dataBuffer.clear();
          _eventId = null;
          return;
        }
        if (_dataBuffer.isNotEmpty) {
          _dataBuffer.write('\n');
        }
        _dataBuffer.write(value);
      case 'event':
        // Event type field; stored but not currently used.
        break;
      case 'id':
        _eventId = value;
      case 'retry':
        // Retry field is not used in this implementation.
        break;
      default:
        _log.fine('Ignoring unknown SSE field: $field');
    }
  }

  void _dispatchEvent() {
    if (_dataBuffer.isEmpty) {
      _eventId = null;
      return;
    }

    final data = _dataBuffer.toString();
    _dataBuffer.clear();

    if (_eventId != null) {
      lastEventId = _eventId;
    }
    _eventId = null;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final message = JsonRpcMessage.fromJson(json);
      _controller.add(message);
    } on FormatException catch (e, stack) {
      _log.warning('Failed to parse SSE message: $e');
      _controller.addError(e, stack);
    }
  }

  /// The SSE endpoint URI for incoming messages.
  Uri get sseUri => _sseUri;

  /// The HTTP endpoint URI for outgoing messages.
  Uri get messageUri => _messageUri;

  @override
  Stream<JsonRpcMessage> get messages => _controller.stream;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) {
      throw StateError('Cannot send on a closed transport');
    }

    final body = jsonEncode(message.toJson());
    final request = await _httpClient.postUrl(_messageUri);
    request.headers.set('Content-Type', 'application/json');
    if (_headers != null) {
      for (final entry in _headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
    }
    request.write(body);

    final response = await request.close();
    // Drain the response body to free resources.
    await response.drain<void>();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'POST to $_messageUri failed with status ${response.statusCode}',
        uri: _messageUri,
      );
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    // Force-close the HTTP client first to terminate the SSE connection,
    // then cancel the subscription (which would otherwise block waiting
    // for the long-lived SSE stream to end).
    try {
      _httpClient.close(force: true);
    } on Object {
      // Connection may already be closed by the remote side.
    }
    // Cancel the SSE subscription with a timeout — it may block if the
    // underlying HTTP stream is in an intermediate state.
    if (_sseSubscription != null) {
      await _sseSubscription!.cancel().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
      _sseSubscription = null;
    }
    unawaited(_controller.close());
    _log.fine('Transport closed');
  }
}
