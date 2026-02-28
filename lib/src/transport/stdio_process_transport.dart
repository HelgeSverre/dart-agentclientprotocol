import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.transport.stdio_process');

/// A transport that spawns an agent subprocess and communicates via
/// NDJSON over its stdin/stdout.
///
/// Use [StdioProcessTransport.start] to spawn a process and obtain a
/// transport connected to it. This is the standard way for clients to
/// launch a local agent.
///
/// Stderr output from the subprocess is forwarded to the logger.
///
/// On [close], the transport sends SIGTERM to the process, waits up to
/// [_killTimeout] for it to exit, then sends SIGKILL if necessary.
///
/// This transport is only available on `dart:io` platforms.
final class StdioProcessTransport implements AcpTransport {
  final Process _process;
  final StreamController<JsonRpcMessage> _controller =
      StreamController<JsonRpcMessage>();
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  final Completer<void> _stdoutDone = Completer<void>();
  final Completer<void> _stderrDone = Completer<void>();
  bool _closed = false;

  static const Duration _killTimeout = Duration(seconds: 5);

  StdioProcessTransport._(this._process);

  /// Spawns an agent process and returns a transport connected to its stdio.
  ///
  /// [executable] is the path to the agent executable.
  /// [arguments] are the command-line arguments to pass.
  /// [workingDirectory] sets the working directory for the process.
  /// [environment] sets additional environment variables.
  static Future<StdioProcessTransport> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
    final transport = StdioProcessTransport._(process);
    transport._startListening();
    return transport;
  }

  /// The underlying process.
  ///
  /// Use for advanced lifecycle control (e.g. checking [Process.exitCode]).
  Process get process => _process;

  /// The exit code of the process, available after the process exits.
  Future<int> get exitCode => _process.exitCode;

  void _startListening() {
    _stdoutSubscription = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .where((line) => line.trim().isNotEmpty)
        .listen(
          _handleLine,
          onError: (Object error, StackTrace stack) {
            _log.severe('Process stdout read error', error, stack);
            _controller.addError(error, stack);
          },
          onDone: () {
            _log.fine('Process stdout ended');
            _stdoutDone.complete();
            close();
          },
        );

    _stderrSubscription = _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            _log.info('[agent stderr] $line');
          },
          onError: (Object error, StackTrace stack) {
            _log.warning('Process stderr read error', error, stack);
          },
          onDone: () {
            _stderrDone.complete();
          },
        );
  }

  void _handleLine(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      final message = JsonRpcMessage.fromJson(json);
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
    _process.stdin.writeln(line);
    await _process.stdin.flush();
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    // Try graceful shutdown, then force kill.
    _process.kill(ProcessSignal.sigterm);
    final exited = await _process.exitCode.timeout(
      _killTimeout,
      onTimeout: () {
        _log.warning('Process did not exit after SIGTERM, sending SIGKILL');
        _process.kill(ProcessSignal.sigkill);
        return _process.exitCode;
      },
    );
    _log.fine('Process exited with code $exited');

    // Wait for stream subscriptions to finish draining, then clean up.
    await Future.wait([_stdoutDone.future, _stderrDone.future]);
    await _stdoutSubscription?.cancel();
    _stdoutSubscription = null;
    await _stderrSubscription?.cancel();
    _stderrSubscription = null;

    // Do not await: StreamController.close() only completes when a listener
    // has received the done event. If no one ever listened, awaiting would
    // hang indefinitely.
    unawaited(_controller.close());
  }
}
