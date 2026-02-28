/// Exception type hierarchy for the Agent Client Protocol (ACP) Dart library.
///
/// All ACP exceptions extend [AcpException], which implements [Exception].
/// This allows callers to catch broad categories of errors or specific
/// subtypes as needed.
library;

/// Base exception for all ACP-related errors.
///
/// Every exception thrown by the ACP library is a subtype of [AcpException],
/// so catching this type will handle any ACP error.
class AcpException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// Creates an [AcpException] with the given [message].
  AcpException(this.message);

  @override
  String toString() => 'AcpException: $message';
}

/// Malformed message structure detected during inbound parsing.
///
/// Thrown when an incoming JSON-RPC message does not conform to the
/// expected schema — for example, a missing `jsonrpc` field or an
/// unrecognised message shape.
class ProtocolValidationException extends AcpException {
  /// Creates a [ProtocolValidationException] with the given [message].
  ProtocolValidationException(super.message);

  @override
  String toString() => 'ProtocolValidationException: $message';
}

/// JSON-RPC error response with standard error code, message, and optional
/// data.
///
/// Wraps the `error` object from a JSON-RPC error response into a throwable
/// exception. Factory constructors are provided for the standard JSON-RPC
/// error codes as well as ACP-specific codes.
class RpcErrorException extends AcpException {
  /// The JSON-RPC error code.
  final int code;

  /// Optional structured error data attached to the JSON-RPC error.
  final Object? data;

  /// Creates an [RpcErrorException] with the given [code], [message], and
  /// optional [data].
  RpcErrorException(this.code, String message, [this.data]) : super(message);

  /// Invalid JSON was received by the server (`-32700`).
  factory RpcErrorException.parseError([String? message, Object? data]) =>
      RpcErrorException(-32700, message ?? 'Parse error', data);

  /// The JSON sent is not a valid JSON-RPC request (`-32600`).
  factory RpcErrorException.invalidRequest([String? message, Object? data]) =>
      RpcErrorException(-32600, message ?? 'Invalid request', data);

  /// The method does not exist or is not available (`-32601`).
  factory RpcErrorException.methodNotFound([String? message, Object? data]) =>
      RpcErrorException(-32601, message ?? 'Method not found', data);

  /// Invalid method parameters (`-32602`).
  factory RpcErrorException.invalidParams([String? message, Object? data]) =>
      RpcErrorException(-32602, message ?? 'Invalid params', data);

  /// Internal JSON-RPC error (`-32603`).
  factory RpcErrorException.internalError([String? message, Object? data]) =>
      RpcErrorException(-32603, message ?? 'Internal error', data);

  /// ACP authentication required (`-32000`).
  factory RpcErrorException.authRequired([String? message, Object? data]) =>
      RpcErrorException(-32000, message ?? 'Authentication required', data);

  /// The requested resource was not found (`-32002`).
  factory RpcErrorException.resourceNotFound([String? message, Object? data]) =>
      RpcErrorException(-32002, message ?? 'Resource not found', data);

  @override
  String toString() => 'RpcErrorException($code): $message';
}

/// Raised when authentication fails or the server responds with
/// `auth_required` during session initialisation.
class AuthenticationException extends AcpException {
  /// Creates an [AuthenticationException] with the given [message].
  AuthenticationException(super.message);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Transport-level read/write failure.
///
/// Thrown when the underlying transport (HTTP, SSE, stdio, etc.) encounters
/// an I/O error. The original error, if available, is stored in [cause].
class TransportException extends AcpException {
  /// The underlying cause of the transport failure, if available.
  final Object? cause;

  /// Creates a [TransportException] with the given [message] and optional
  /// [cause].
  TransportException(super.message, [this.cause]);

  @override
  String toString() =>
      'TransportException: $message${cause != null ? ' (cause: $cause)' : ''}';
}

/// Request deadline exceeded.
///
/// Thrown when a JSON-RPC request does not receive a response within the
/// configured [timeout] duration.
class RequestTimeoutException extends AcpException {
  /// The request ID that timed out.
  final Object requestId;

  /// The timeout duration that was exceeded.
  final Duration timeout;

  /// Creates a [RequestTimeoutException] for the given [requestId] and
  /// [timeout].
  RequestTimeoutException(this.requestId, this.timeout)
    : super('Request $requestId timed out after $timeout');

  @override
  String toString() => 'RequestTimeoutException: $message';
}

/// Request cancelled via [AcpCancellationToken].
///
/// Thrown when a pending request is explicitly cancelled before a response
/// is received.
class RequestCanceledException extends AcpException {
  /// The request ID that was cancelled.
  final Object requestId;

  /// Optional reason for the cancellation.
  final Object? reason;

  /// Creates a [RequestCanceledException] for the given [requestId] and
  /// optional [reason].
  RequestCanceledException(this.requestId, [this.reason])
    : super(
        'Request $requestId was canceled${reason != null ? ': $reason' : ''}',
      );

  @override
  String toString() => 'RequestCanceledException: $message';
}

/// Operation attempted on a closed connection.
///
/// Thrown when a send or receive operation is attempted after the underlying
/// connection has been closed.
class ConnectionClosedException extends AcpException {
  /// Creates a [ConnectionClosedException] with an optional [message].
  ConnectionClosedException([String? message])
    : super(message ?? 'Connection is closed');

  @override
  String toString() => 'ConnectionClosedException: $message';
}

/// Request requires a capability the peer did not advertise (strict mode).
///
/// Thrown when the client attempts to call a [method] that requires a
/// [requiredCapability] that the server did not declare during
/// initialisation.
class CapabilityException extends AcpException {
  /// The method that requires the missing capability.
  final String method;

  /// The capability that is required but was not advertised by the peer.
  final String requiredCapability;

  /// Creates a [CapabilityException] for the given [method] and
  /// [requiredCapability].
  CapabilityException(this.method, this.requiredCapability)
    : super(
        'Method "$method" requires capability "$requiredCapability" '
        'which the peer did not advertise',
      );

  @override
  String toString() => 'CapabilityException: $message';
}
