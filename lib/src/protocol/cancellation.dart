import 'dart:async';

/// A token that can be observed to detect cancellation.
///
/// Cancellation tokens are used to cooperatively cancel long-running
/// operations such as pending RPC requests and handler invocations.
abstract interface class AcpCancellationToken {
  /// Whether this token has been canceled.
  bool get isCanceled;

  /// A future that completes when this token is canceled.
  ///
  /// The future completes with the cancellation reason if one was provided,
  /// otherwise completes with `null`.
  Future<void> get whenCanceled;

  /// Throws [CanceledException] if this token has been canceled.
  void throwIfCanceled();
}

/// A source that controls a [AcpCancellationToken].
///
/// Create a source to obtain a token, pass the token to operations that
/// should be cancelable, and call [cancel] when the operation should stop.
final class AcpCancellationSource {
  final Completer<void> _completer = Completer<void>();
  bool _isCanceled = false;
  Object? _reason;

  /// The token controlled by this source.
  late final AcpCancellationToken token = _Token(this);

  /// Cancels the token with an optional [reason].
  ///
  /// Subsequent calls after the first are ignored.
  void cancel([Object? reason]) {
    if (_isCanceled) return;
    _isCanceled = true;
    _reason = reason;
    _completer.complete();
  }
}

/// Thrown when [AcpCancellationToken.throwIfCanceled] is called on a
/// canceled token.
class CanceledException implements Exception {
  /// Optional reason for cancellation.
  final Object? reason;

  /// Creates a [CanceledException] with an optional [reason].
  CanceledException([this.reason]);

  @override
  String toString() => 'CanceledException${reason != null ? ': $reason' : ''}';
}

final class _Token implements AcpCancellationToken {
  final AcpCancellationSource _source;

  _Token(this._source);

  @override
  bool get isCanceled => _source._isCanceled;

  @override
  Future<void> get whenCanceled => _source._completer.future;

  @override
  void throwIfCanceled() {
    if (_source._isCanceled) {
      throw CanceledException(_source._reason);
    }
  }
}
