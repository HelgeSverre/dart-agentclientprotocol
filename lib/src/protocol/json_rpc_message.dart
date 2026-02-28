import 'dart:convert';

/// The JSON-RPC version string included in all messages.
const String jsonRpcVersion = '2.0';

/// A JSON-RPC 2.0 message.
///
/// All messages include `"jsonrpc": "2.0"`. Messages are one of three kinds:
/// - [JsonRpcRequest] — a method call expecting a response.
/// - [JsonRpcResponse] — a response to a request.
/// - [JsonRpcNotification] — a one-way message with no response.
sealed class JsonRpcMessage {
  const JsonRpcMessage();

  /// Deserializes a [JsonRpcMessage] from a JSON map.
  ///
  /// Throws [FormatException] if the map does not represent a valid
  /// JSON-RPC 2.0 message.
  factory JsonRpcMessage.fromJson(Map<String, dynamic> json) {
    final jsonrpc = json['jsonrpc'];
    if (jsonrpc != jsonRpcVersion) {
      throw FormatException(
        'Invalid or missing "jsonrpc" field: expected "$jsonRpcVersion", '
        'got ${jsonEncode(jsonrpc)}',
      );
    }

    // Response: has "id" and either "result" or "error" (but no "method")
    if (json.containsKey('result') || json.containsKey('error')) {
      return JsonRpcResponse.fromJson(json);
    }

    final method = json['method'];
    if (method is! String) {
      throw const FormatException(
        'JSON-RPC message has no "method" or "result"/"error" field',
      );
    }

    // Request vs Notification: requests have "id"
    if (json.containsKey('id')) {
      return JsonRpcRequest.fromJson(json);
    }

    return JsonRpcNotification.fromJson(json);
  }

  /// Serializes this message to a JSON map.
  Map<String, dynamic> toJson();
}

/// A JSON-RPC 2.0 request.
///
/// Requests include an [id] for response correlation and a [method] name
/// with optional [params].
final class JsonRpcRequest extends JsonRpcMessage {
  /// The request identifier used to correlate responses.
  final Object id;

  /// The method to invoke.
  final String method;

  /// Optional method parameters.
  final Map<String, dynamic>? params;

  const JsonRpcRequest({required this.id, required this.method, this.params});

  factory JsonRpcRequest.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String && id is! int) {
      throw FormatException(
        'JSON-RPC request "id" must be a string or integer, '
        'got ${id.runtimeType}',
      );
    }

    final method = json['method'];
    if (method is! String) {
      throw FormatException(
        'JSON-RPC request "method" must be a string, '
        'got ${method.runtimeType}',
      );
    }

    final params = json['params'];
    return JsonRpcRequest(
      id: id as Object,
      method: method,
      params: params is Map<String, dynamic> ? params : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonRpcVersion,
    'id': id,
    'method': method,
    if (params != null) 'params': params,
  };
}

/// A JSON-RPC 2.0 notification.
///
/// Notifications are one-way messages with no [id] and no response expected.
final class JsonRpcNotification extends JsonRpcMessage {
  /// The notification method name.
  final String method;

  /// Optional notification parameters.
  final Map<String, dynamic>? params;

  const JsonRpcNotification({required this.method, this.params});

  factory JsonRpcNotification.fromJson(Map<String, dynamic> json) {
    final method = json['method'] as String;
    final params = json['params'];
    return JsonRpcNotification(
      method: method,
      params: params is Map<String, dynamic> ? params : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonRpcVersion,
    'method': method,
    if (params != null) 'params': params,
  };
}

/// A JSON-RPC 2.0 error object within a response.
final class JsonRpcError {
  /// The error code.
  final int code;

  /// A short description of the error.
  final String message;

  /// Optional additional error data.
  final Object? data;

  const JsonRpcError({required this.code, required this.message, this.data});

  factory JsonRpcError.fromJson(Map<String, dynamic> json) {
    return JsonRpcError(
      code: json['code'] as int,
      message: json['message'] as String,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (data != null) 'data': data,
  };
}

/// A JSON-RPC 2.0 response.
///
/// A response contains either a [result] (success) or an [error] (failure),
/// correlated to the request by [id].
final class JsonRpcResponse extends JsonRpcMessage {
  /// The request identifier this response corresponds to.
  final Object? id;

  /// The result value on success. Mutually exclusive with [error].
  final Object? result;

  /// The error object on failure. Mutually exclusive with [result].
  final JsonRpcError? error;

  const JsonRpcResponse({required this.id, this.result, this.error});

  /// Whether this is a successful response.
  bool get isSuccess => error == null;

  /// Whether this is an error response.
  bool get isError => error != null;

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final error = json['error'];
    return JsonRpcResponse(
      id: id,
      result: json['result'],
      error:
          error is Map<String, dynamic> ? JsonRpcError.fromJson(error) : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'jsonrpc': jsonRpcVersion,
    'id': id,
    if (result != null) 'result': result,
    if (error != null) 'error': error!.toJson(),
  };
}
