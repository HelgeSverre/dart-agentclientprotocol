/// Allocates unique, monotonically increasing request IDs for JSON-RPC
/// messages.
///
/// Each [Connection] should use its own allocator instance to ensure IDs
/// are unique within that connection's lifetime.
final class RequestIdAllocator {
  int _next;

  /// Creates an allocator starting from [start].
  RequestIdAllocator({int start = 1}) : _next = start;

  /// Returns the next unique request ID.
  int next() => _next++;
}
