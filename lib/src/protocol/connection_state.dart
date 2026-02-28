/// The lifecycle state of a connection.
///
/// Connections follow a strict state machine:
/// [idle] → [opening] → [open] → [closing] → [closed].
enum ConnectionState {
  /// Constructed but not started; no read/write activity.
  idle,

  /// Receive loop started; initialize handshake may be in progress.
  opening,

  /// Normal operation; requests and notifications flow.
  open,

  /// Close called; draining write queue; rejecting new sends.
  closing,

  /// Terminal state; all streams completed; all pending requests failed.
  closed,
}
