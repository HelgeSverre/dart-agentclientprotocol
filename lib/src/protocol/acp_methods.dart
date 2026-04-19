/// ACP JSON-RPC method name constants.
///
/// These constants define the wire-format method strings for all ACP
/// protocol methods and notifications as of schema v0.12.0.
abstract final class AcpMethods {
  // -- Agent-side methods (client → agent requests) --

  /// Version negotiation and capability exchange.
  static const String initialize = 'initialize';

  /// Authentication handshake.
  static const String authenticate = 'authenticate';

  /// Create a new session.
  static const String sessionNew = 'session/new';

  /// Resume an existing session (requires `loadSession` capability).
  static const String sessionLoad = 'session/load';

  /// Send a user prompt.
  static const String sessionPrompt = 'session/prompt';

  /// Switch agent operating mode.
  static const String sessionSetMode = 'session/set_mode';

  /// Update session configuration.
  static const String sessionSetConfigOption = 'session/set_config_option';

  // -- Agent-side notifications (client → agent) --

  /// Cancel ongoing operations.
  static const String sessionCancel = 'session/cancel';

  // -- Client-side methods (agent → client requests) --

  /// Request user authorization for tool calls.
  static const String sessionRequestPermission = 'session/request_permission';

  /// Read file contents.
  static const String fsReadTextFile = 'fs/read_text_file';

  /// Write file contents.
  static const String fsWriteTextFile = 'fs/write_text_file';

  /// Create a terminal.
  static const String terminalCreate = 'terminal/create';

  /// Get terminal output.
  static const String terminalOutput = 'terminal/output';

  /// Release a terminal.
  static const String terminalRelease = 'terminal/release';

  /// Wait for terminal exit.
  static const String terminalWaitForExit = 'terminal/wait_for_exit';

  /// Kill a terminal command.
  static const String terminalKill = 'terminal/kill';

  // -- Client-side notifications (agent → client) --

  /// Streaming session updates.
  static const String sessionUpdate = 'session/update';

  // -- Stable optional methods --

  /// List existing sessions.
  static const String sessionList = 'session/list';

  // -- Unstable methods --

  /// Fork an existing session (unstable).
  static const String sessionFork = 'session/fork';

  // -- Meta --

  /// Cancel a pending request (JSON-RPC extension).
  static const String cancelRequest = r'$/cancel_request';

  /// Keepalive ping (JSON-RPC extension notification).
  static const String ping = r'$/ping';

  /// Keepalive pong response (JSON-RPC extension notification).
  static const String pong = r'$/pong';
}
