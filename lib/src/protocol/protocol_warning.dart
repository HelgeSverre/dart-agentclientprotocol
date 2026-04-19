/// A non-fatal protocol compatibility event.
///
/// Protocol warnings are emitted when the library encounters situations
/// that don't prevent operation but may indicate compatibility issues.
sealed class ProtocolWarning {
  /// A human-readable description of the warning.
  final String message;

  /// Creates a [ProtocolWarning] with the given [message].
  ProtocolWarning(this.message);

  /// A response arrived for a request that was already timed out or canceled.
  factory ProtocolWarning.lateResponse(Object requestId) = LateResponseWarning;

  /// An unknown configuration option ID was received.
  factory ProtocolWarning.unknownConfigOption(String optionId) =
      UnknownConfigOptionWarning;

  @override
  String toString() => 'ProtocolWarning: $message';
}

/// A response arrived after the request was timed out or canceled.
final class LateResponseWarning extends ProtocolWarning {
  /// The request ID of the late response.
  final Object requestId;

  /// Creates a [LateResponseWarning] for the given [requestId].
  LateResponseWarning(this.requestId)
    : super('Late response received for request $requestId');
}

/// An unknown session configuration option ID was received.
///
/// Reserved for future use: emitted when a `session/setSessionConfigOption`
/// notification references a config ID the local side doesn't recognize.
/// Listeners on [Connection.warnings] can surface this to users to flag
/// peer/version skew without aborting the session.
final class UnknownConfigOptionWarning extends ProtocolWarning {
  /// The unrecognized option ID.
  final String optionId;

  /// Creates an [UnknownConfigOptionWarning] for the given [optionId].
  UnknownConfigOptionWarning(this.optionId)
    : super('Unknown config option: $optionId');
}
