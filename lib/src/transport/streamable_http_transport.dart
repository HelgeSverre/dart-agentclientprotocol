import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.transport.streamable_http');

/// A transport using the Streamable HTTP protocol.
///
/// Implements the MCP Streamable HTTP transport specification:
/// - Outgoing messages are sent as HTTP POST to a single endpoint.
/// - The server may respond with JSON or an SSE stream.
/// - An optional GET-based SSE stream receives server-initiated messages.
/// - Session IDs are tracked automatically via the `Mcp-Session-Id` header.
///
/// This transport is only available on `dart:io` platforms.
final class StreamableHttpTransport implements AcpTransport {
  final Uri _endpoint;
  final Map<String, String>? _headers;
  final HttpClient _httpClient;
  final StreamController<JsonRpcMessage> _controller =
      StreamController<JsonRpcMessage>();
  bool _closed = false;
  String? _sessionId;

  // Optional GET SSE stream for server-initiated messages.
  StreamSubscription<String>? _sseSubscription;

  /// The last SSE event ID received, for resumability.
  String? lastEventId;

  /// Creates a Streamable HTTP transport to [endpoint].
  ///
  /// [headers] are optional additional HTTP headers (e.g. for auth).
  StreamableHttpTransport(
    this._endpoint, {
    Map<String, String>? headers,
    HttpClient? httpClient,
  }) : _headers = headers,
       _httpClient = httpClient ?? HttpClient();

  /// The session ID assigned by the server, if any.
  String? get sessionId => _sessionId;

  @override
  Stream<JsonRpcMessage> get messages => _controller.stream;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) throw StateError('Cannot send on a closed transport');

    final body = jsonEncode(message.toJson());
    final request = await _httpClient.postUrl(_endpoint);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json, text/event-stream');
    _applyHeaders(request);
    if (_sessionId != null) {
      request.headers.set('Mcp-Session-Id', _sessionId!);
    }
    request.write(body);

    final response = await request.close();

    // Capture session ID from server.
    final newSessionId = response.headers.value('Mcp-Session-Id');
    if (newSessionId != null) {
      _sessionId = newSessionId;
    }

    if (response.statusCode == 202) {
      // Accepted — no body expected (notifications/responses).
      await response.drain<void>();
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorBody = await utf8.decoder.bind(response).join();
      throw HttpException(
        'POST to $_endpoint failed: ${response.statusCode} $errorBody',
        uri: _endpoint,
      );
    }

    final contentType = response.headers.contentType?.mimeType;

    if (contentType == 'text/event-stream') {
      // SSE response — parse and emit messages.
      await _consumeSseResponse(response);
    } else {
      // JSON response.
      final responseBody = await utf8.decoder.bind(response).join();
      _parseAndEmit(responseBody);
    }
  }

  /// Opens a GET-based SSE stream for server-initiated messages.
  ///
  /// Call this after initialization if you want to receive server-initiated
  /// requests and notifications outside of POST response streams.
  Future<void> openSseStream() async {
    if (_closed) throw StateError('Transport is closed');

    final request = await _httpClient.getUrl(_endpoint);
    request.headers.set('Accept', 'text/event-stream');
    request.headers.set('Cache-Control', 'no-cache');
    _applyHeaders(request);
    if (_sessionId != null) {
      request.headers.set('Mcp-Session-Id', _sessionId!);
    }
    if (lastEventId != null) {
      request.headers.set('Last-Event-ID', lastEventId!);
    }

    final response = await request.close();

    if (response.statusCode == 405) {
      await response.drain<void>();
      _log.fine('Server does not support GET SSE stream');
      return;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await response.drain<void>();
      throw HttpException(
        'GET SSE failed: ${response.statusCode}',
        uri: _endpoint,
      );
    }

    _startSseListening(response);
    _log.fine('SSE stream opened to $_endpoint');
  }

  /// Sends an HTTP DELETE to terminate the session.
  Future<void> terminateSession() async {
    if (_sessionId == null) return;

    try {
      final request = await _httpClient.deleteUrl(_endpoint);
      _applyHeaders(request);
      request.headers.set('Mcp-Session-Id', _sessionId!);
      final response = await request.close();
      await response.drain<void>();
      _log.fine('Session terminated (status: ${response.statusCode})');
    } on Object catch (e) {
      _log.fine('Error terminating session: $e');
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    if (_sseSubscription != null) {
      await _sseSubscription!.cancel().timeout(
        const Duration(seconds: 1),
        onTimeout: () {},
      );
      _sseSubscription = null;
    }

    try {
      _httpClient.close(force: true);
    } on Object {
      // Best effort.
    }

    unawaited(_controller.close());
    _log.fine('Transport closed');
  }

  void _applyHeaders(HttpClientRequest request) {
    if (_headers != null) {
      for (final entry in _headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
    }
  }

  Future<void> _consumeSseResponse(HttpClientResponse response) async {
    final lines = response
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    final dataBuffer = StringBuffer();
    String? eventId;

    await for (final line in lines) {
      if (_closed) break;

      if (line.startsWith(':')) continue; // Comment.

      if (line.isEmpty) {
        // End of event.
        if (dataBuffer.isNotEmpty) {
          final data = dataBuffer.toString();
          dataBuffer.clear();
          if (eventId != null) lastEventId = eventId;
          eventId = null;
          _parseAndEmit(data);
        }
        continue;
      }

      final colonIndex = line.indexOf(':');
      String field;
      String value;
      if (colonIndex == -1) {
        field = line;
        value = '';
      } else {
        field = line.substring(0, colonIndex);
        final valueStart = colonIndex + 1;
        if (valueStart < line.length && line[valueStart] == ' ') {
          value = line.substring(valueStart + 1);
        } else {
          value = line.substring(valueStart);
        }
      }

      switch (field) {
        case 'data':
          if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
          dataBuffer.write(value);
        case 'id':
          eventId = value;
        case 'event':
        case 'retry':
          break;
        default:
          _log.fine('Ignoring unknown SSE field: $field');
      }
    }
  }

  void _startSseListening(HttpClientResponse response) {
    final dataBuffer = StringBuffer();
    String? eventId;

    _sseSubscription = response
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (String line) {
            if (line.startsWith(':')) return; // Comment.

            if (line.isEmpty) {
              if (dataBuffer.isNotEmpty) {
                final data = dataBuffer.toString();
                dataBuffer.clear();
                if (eventId != null) lastEventId = eventId;
                eventId = null;
                _parseAndEmit(data);
              }
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
              final valueStart = colonIndex + 1;
              if (valueStart < line.length && line[valueStart] == ' ') {
                value = line.substring(valueStart + 1);
              } else {
                value = line.substring(valueStart);
              }
            }

            switch (field) {
              case 'data':
                if (dataBuffer.isNotEmpty) dataBuffer.write('\n');
                dataBuffer.write(value);
              case 'id':
                eventId = value;
              case 'event':
              case 'retry':
                break;
              default:
                _log.fine('Ignoring unknown SSE field: $field');
            }
          },
          onError: (Object error, StackTrace stack) {
            if (_closed) return;
            _log.severe('SSE stream error', error, stack);
            _controller.addError(error, stack);
          },
          onDone: () {
            _log.fine('SSE stream ended');
          },
        );
  }

  void _parseAndEmit(String data) {
    try {
      final json = jsonDecode(data);
      if (json is Map<String, dynamic>) {
        _controller.add(JsonRpcMessage.fromJson(json));
      } else if (json is List) {
        // Batch response.
        for (final item in json) {
          if (item is Map<String, dynamic>) {
            _controller.add(JsonRpcMessage.fromJson(item));
          }
        }
      }
    } on FormatException catch (e, stack) {
      _log.warning('Failed to parse message: $e');
      _controller.addError(e, stack);
    }
  }
}
