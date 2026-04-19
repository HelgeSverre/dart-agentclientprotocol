/// ACP transport layer — [AcpTransport] interface and built-in
/// implementations.
library;

export 'src/protocol/json_rpc_message.dart';
export 'src/transport/acp_transport.dart';

// Platform-specific transports
export 'src/transport/browser_web_socket_transport_stub.dart'
    if (dart.library.js_interop) 'src/transport/browser_web_socket_transport.dart'
    if (dart.library.html) 'src/transport/browser_web_socket_transport.dart';
export 'src/transport/http_sse_transport_stub.dart'
    if (dart.library.io) 'src/transport/http_sse_transport.dart';
export 'src/transport/reconnecting_transport.dart';
export 'src/transport/stdio_process_transport_stub.dart'
    if (dart.library.io) 'src/transport/stdio_process_transport.dart';
export 'src/transport/stdio_transport_stub.dart'
    if (dart.library.io) 'src/transport/stdio_transport.dart';
export 'src/transport/streamable_http_transport_stub.dart'
    if (dart.library.io) 'src/transport/streamable_http_transport.dart';
export 'src/transport/web_socket_transport_stub.dart'
    if (dart.library.io) 'src/transport/web_socket_transport.dart';
