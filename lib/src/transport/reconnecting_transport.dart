import 'dart:async';
import 'dart:math';

import 'package:acp/src/protocol/json_rpc_message.dart';
import 'package:acp/src/transport/acp_transport.dart';
import 'package:logging/logging.dart';

final _log = Logger('acp.transport.reconnecting');
final _random = Random();

/// An event emitted by [ReconnectingTransport] to report connection state
/// changes.
sealed class ReconnectionEvent {
  /// Creates a reconnection event.
  const ReconnectionEvent();
}

/// The transport has successfully connected (or reconnected).
final class Connected extends ReconnectionEvent {
  /// Creates a [Connected] event.
  const Connected();
}

/// The underlying transport disconnected.
final class Disconnected extends ReconnectionEvent {
  /// The error that caused the disconnection, if any.
  final Object? error;

  /// Creates a [Disconnected] event.
  const Disconnected({this.error});
}

/// The transport is attempting to reconnect.
final class Reconnecting extends ReconnectionEvent {
  /// The current attempt number (1-based).
  final int attempt;

  /// The delay before the reconnection attempt.
  final Duration delay;

  /// Creates a [Reconnecting] event.
  const Reconnecting({required this.attempt, required this.delay});
}

/// The transport has given up reconnecting after [attempts] consecutive
/// failures.
final class ReconnectionFailed extends ReconnectionEvent {
  /// The total number of consecutive failed attempts.
  final int attempts;

  /// Creates a [ReconnectionFailed] event.
  const ReconnectionFailed({required this.attempts});
}

/// A transport wrapper that automatically reconnects when the underlying
/// transport fails or disconnects.
///
/// Wraps a [transportFactory] that creates new transport instances on demand.
/// When the current transport's message stream ends or errors, the wrapper
/// creates a new transport after a configurable delay and resumes message
/// delivery through a single unified [messages] stream.
///
/// The reconnection uses exponential backoff with jitter, capped at
/// [maxDelay]. After [maxAttempts] consecutive failures, the transport
/// gives up and closes.
///
/// This transport is useful for long-lived client connections to remote
/// agents where network interruptions are expected.
final class ReconnectingTransport implements AcpTransport {
  final Future<AcpTransport> Function() _transportFactory;
  final Duration _initialDelay;
  final Duration _maxDelay;
  final int _maxAttempts;

  // Single-subscription so each message is delivered exactly once. A
  // broadcast controller would silently drop messages emitted before the
  // first subscription or between subscriptions, contradicting this
  // transport's stated reliability purpose.
  final StreamController<JsonRpcMessage> _messageController =
      StreamController<JsonRpcMessage>();
  final StreamController<ReconnectionEvent> _eventController =
      StreamController<ReconnectionEvent>.broadcast();

  AcpTransport? _current;
  StreamSubscription<JsonRpcMessage>? _subscription;
  bool _closed = false;
  int _consecutiveFailures = 0;
  bool _connecting = false;

  /// Creates a reconnecting transport.
  ///
  /// [transportFactory] creates new transport instances. It is called
  /// once immediately and again on each reconnection attempt.
  ///
  /// [initialDelay] is the first backoff delay (default: 1 second).
  /// [maxDelay] caps the exponential backoff (default: 30 seconds).
  /// [maxAttempts] limits consecutive reconnection attempts before giving
  /// up (default: 10). Set to 0 for unlimited attempts.
  ReconnectingTransport({
    required Future<AcpTransport> Function() transportFactory,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 30),
    int maxAttempts = 10,
  }) : _transportFactory = transportFactory,
       _initialDelay = initialDelay,
       _maxDelay = maxDelay,
       _maxAttempts = maxAttempts {
    unawaited(_connect());
  }

  @override
  Stream<JsonRpcMessage> get messages => _messageController.stream;

  /// A stream of [ReconnectionEvent]s for observability.
  Stream<ReconnectionEvent> get events => _eventController.stream;

  @override
  Future<void> send(JsonRpcMessage message) async {
    if (_closed) {
      throw StateError('Cannot send on a closed transport');
    }
    final transport = _current;
    if (transport == null || _connecting) {
      throw StateError('Transport is not connected');
    }
    await transport.send(message);
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    _subscription = null;
    await _current?.close();
    _current = null;
    // Don't await: a single-subscription controller's close() blocks until
    // a listener has drained queued events — if no consumer ever subscribed
    // to `messages`, the await would hang indefinitely.
    unawaited(_messageController.close());
    await _eventController.close();
  }

  Future<void> _connect() async {
    if (_closed) return;
    _connecting = true;
    try {
      final transport = await _transportFactory();
      if (_closed) {
        await transport.close();
        return;
      }
      _current = transport;
      _connecting = false;
      _consecutiveFailures = 0;
      _eventController.add(const Connected());
      _log.info('Connected');
      _subscription = transport.messages.listen(
        _messageController.add,
        onError: (Object error, StackTrace stack) {
          _log.warning('Transport error', error, stack);
          _handleDisconnection(error);
        },
        onDone: () {
          _log.info('Transport stream ended');
          _handleDisconnection(null);
        },
      );
    } on Object catch (error, stack) {
      _log.warning('Connection attempt failed', error, stack);
      _connecting = false;
      _handleDisconnection(error);
    }
  }

  void _handleDisconnection(Object? error) {
    if (_closed) return;
    _subscription = null;
    _current = null;
    _consecutiveFailures++;
    _eventController.add(Disconnected(error: error));

    if (_maxAttempts > 0 && _consecutiveFailures >= _maxAttempts) {
      _log.severe('Giving up after $_consecutiveFailures consecutive failures');
      _eventController.add(ReconnectionFailed(attempts: _consecutiveFailures));
      unawaited(close());
      return;
    }

    unawaited(_reconnect());
  }

  Future<void> _reconnect() async {
    if (_closed) return;

    final delay = _calculateDelay(_consecutiveFailures);
    _log.info(
      'Reconnecting in ${delay.inMilliseconds}ms '
      '(attempt $_consecutiveFailures)',
    );
    _eventController.add(
      Reconnecting(attempt: _consecutiveFailures, delay: delay),
    );

    await Future<void>.delayed(delay);
    if (_closed) return;

    await _connect();
  }

  Duration _calculateDelay(int attempt) {
    // Exponential backoff: initialDelay * 2^(attempt-1), capped at maxDelay.
    final baseMs = _initialDelay.inMicroseconds * pow(2, attempt - 1).toInt();
    final cappedMs = min(baseMs, _maxDelay.inMicroseconds);

    // Apply ±25% jitter.
    final jitterFactor = 0.75 + _random.nextDouble() * 0.5;
    final jitteredMs = (cappedMs * jitterFactor).toInt();

    return Duration(microseconds: jitteredMs);
  }
}
