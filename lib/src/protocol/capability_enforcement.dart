/// Controls whether outgoing requests are checked against peer-advertised
/// capabilities before sending.
enum CapabilityEnforcement {
  /// Throw [CapabilityException] if the peer did not advertise the required
  /// capability. This is the default.
  strict,

  /// Send the request regardless of peer capabilities.
  permissive,
}
