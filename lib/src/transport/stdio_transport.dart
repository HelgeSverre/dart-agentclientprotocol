import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.transport.stdio');

/// A transport that communicates via NDJSON (newline-delimited JSON) over
/// stdin and stdout.
///
/// Each JSON-RPC message is encoded as a single line of JSON followed by
/// a newline character. This is the standard transport for local agent
/// processes communicating over stdio.
///
/// This transport reads from [input] and writes to [output], which default
/// to [stdin] and [stdout] respectively.
final class StdioTransport implements AcpTransport {
  final Stream<List<int>> _input;
  final IOSink _output;
  late final StreamController<JsonRpcMessage> _controller =
      StreamController<JsonRpcMessage>(onListen: _startReading);
  StreamSubscription<String>? _subscription;
  bool _closed = false;

  /// Creates a stdio transport.
  ///
  /// [input] defaults to [stdin] and [output] defaults to [stdout].
  StdioTransport({Stream<List<int>>? input, IOSink? output})
    : _input = input ?? stdin,
      _output = output ?? stdout;

  /// Starts reading from the input stream.
  ///
  /// Calling this is optional — the transport also auto-starts on the first
  /// subscription to [messages]. Calling this after the transport has already
  /// started throws [StateError].
  void start() {
    if (_subscription != null) {
      throw StateError('StdioTransport already started');
    }
    _startReading();
  }

  void _startReading() {
    if (_subscription != null) return;
    _subscription = _input
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.trim().isNotEmpty)
        .listen(
          _handleLine,
          onError: (Object error, StackTrace stack) {
            _log.severe('Transport read error', error, stack);
            _controller.addError(error, stack);
            close();
          },
          onDone: () {
            _log.fine('Transport input stream ended');
            close();
          },
        );
  }

  void _handleLine(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is List) {
        // JSON-RPC 2.0 batches are not supported over NDJSON.
        _log.warning(
          'Received JSON-RPC batch (${decoded.length} items); '
          'batches are not supported, skipping',
        );
        return;
      }
      if (decoded is! Map<String, dynamic>) {
        throw FormatException(
          'Expected JSON object, got ${decoded.runtimeType}',
        );
      }
      final message = JsonRpcMessage.fromJson(decoded);
      _controller.add(message);
    } on FormatException catch (e, stack) {
      _log.warning('Failed to parse incoming message: $e');
      _controller.addError(e, stack);
    }
  }

  @override
  Stream<JsonRpcMessage> get messages => _controller.stream;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) {
      throw StateError('Cannot send on a closed transport');
    }
    final line = jsonEncode(message.toJson());
    _output.writeln(line);
    await _output.flush();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
  }
}
