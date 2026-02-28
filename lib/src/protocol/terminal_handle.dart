import 'package:acp/src/protocol/agent_side_connection.dart';
import 'package:acp/src/protocol/cancellation.dart';
import 'package:acp/src/schema/client_methods.dart';

/// Ergonomic wrapper around a terminal ID for agent-side code.
///
/// Provides convenient methods for terminal lifecycle operations
/// (output, kill, wait-for-exit, release) and a [dispose] method
/// that releases the terminal.
///
/// Usage:
/// ```dart
/// final terminal = TerminalHandle(
///   connection: agentConn,
///   sessionId: 'sess-1',
///   terminalId: 'term-1',
/// );
/// try {
///   final output = await terminal.output();
///   await terminal.kill();
///   final exit = await terminal.waitForExit();
/// } finally {
///   await terminal.dispose();
/// }
/// ```
final class TerminalHandle {
  final AgentSideConnection _connection;

  /// The session this terminal belongs to.
  final String sessionId;

  /// The unique terminal identifier.
  final String terminalId;

  bool _disposed = false;

  /// Creates a [TerminalHandle].
  TerminalHandle({
    required AgentSideConnection connection,
    required this.sessionId,
    required this.terminalId,
  }) : _connection = connection;

  /// Whether this handle has been disposed.
  bool get isDisposed => _disposed;

  /// Gets the terminal output.
  ///
  /// Throws [StateError] if disposed.
  Future<TerminalOutputResponse> output({AcpCancellationToken? cancelToken}) {
    _ensureNotDisposed();
    return _connection.sendTerminalOutput(
      sessionId: sessionId,
      terminalId: terminalId,
      cancelToken: cancelToken,
    );
  }

  /// Kills the terminal command.
  ///
  /// Throws [StateError] if disposed.
  Future<void> kill({AcpCancellationToken? cancelToken}) {
    _ensureNotDisposed();
    return _connection.sendKillTerminal(
      sessionId: sessionId,
      terminalId: terminalId,
      cancelToken: cancelToken,
    );
  }

  /// Waits for the terminal process to exit.
  ///
  /// Returns the exit response including exit code and signal.
  ///
  /// Throws [StateError] if disposed.
  Future<WaitForTerminalExitResponse> waitForExit({
    AcpCancellationToken? cancelToken,
  }) {
    _ensureNotDisposed();
    return _connection.sendWaitForTerminalExit(
      sessionId: sessionId,
      terminalId: terminalId,
      cancelToken: cancelToken,
    );
  }

  /// Releases the terminal.
  ///
  /// Throws [StateError] if disposed.
  Future<void> release({AcpCancellationToken? cancelToken}) {
    _ensureNotDisposed();
    return _connection.sendReleaseTerminal(
      sessionId: sessionId,
      terminalId: terminalId,
      cancelToken: cancelToken,
    );
  }

  /// Releases the terminal and marks this handle as disposed.
  ///
  /// Calling [dispose] more than once is a no-op.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _connection.sendReleaseTerminal(
        sessionId: sessionId,
        terminalId: terminalId,
      );
    } on Object {
      // Best-effort release — connection may already be closed.
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw StateError('TerminalHandle has been disposed');
    }
  }
}
