# ACP Web Explorer

A sleek, browser-based explorer for the Agent Client Protocol (ACP). Connect to any ACP agent over WebSocket and interact with it directly from your browser.

## Features

- **Dynamic Configuration**: Connect to any arbitrary agent by providing its WebSocket URL.
- **Full Protocol Support**: Implements the ACP client-side protocol including session management, prompts, and agent-to-client requests.
- **Sleek Interface**: Modern, clean UI built with vanilla CSS.
- **Capability Discovery**: Automatically discovers and displays agent capabilities upon connection.
- **Real-time Interaction**: Send prompts and receive agent messages and tool calls in real-time.

## Running the Explorer

To run the explorer, you need to compile the Dart code to JavaScript using `dart2js`.

### 1. Install Dependencies

Ensure you have the dependencies installed:

```bash
dart pub get
```

### 2. Compile to JavaScript

From the project root:

```bash
dart compile js examples/webui/main.dart -o examples/webui/main.dart.js
```

### 3. Serve the Files

You can use any local HTTP server to serve the `examples/webui` directory. For example, using Python:

```bash
cd examples/webui
python3 -m http.server 8000
```

Then open `http://localhost:8000` in your browser.

## Web Compatibility

This example uses the `BrowserWebSocketTransport` implemented in the `acp` library, which utilizes `package:web` for modern browser compatibility (including `dart2js` and `dart2wasm`).
