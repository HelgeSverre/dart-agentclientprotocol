import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/schema/capabilities.dart';
import 'package:acp/src/schema/content_block.dart';

/// Validates that [path] is an absolute filesystem path.
void validateAbsolutePath(String path, String fieldName) {
  if (_isAbsolutePath(path)) return;
  throw ProtocolValidationException(
    '$fieldName must be an absolute path (got: "$path")',
  );
}

/// Validates [path] when it is present.
void validateOptionalAbsolutePath(String? path, String fieldName) {
  if (path == null) return;
  validateAbsolutePath(path, fieldName);
}

/// Validates prompt content blocks against advertised agent capabilities.
void validatePromptCapabilities({
  required String method,
  required List<ContentBlock> prompt,
  required PromptCapabilities capabilities,
  required bool strict,
}) {
  if (!strict) return;

  for (final block in prompt) {
    switch (block) {
      case ImageContent():
        if (!capabilities.image) {
          throw CapabilityException(method, 'promptCapabilities.image');
        }
      case AudioContent():
        if (!capabilities.audio) {
          throw CapabilityException(method, 'promptCapabilities.audio');
        }
      case EmbeddedResource():
        if (!capabilities.embeddedContext) {
          throw CapabilityException(
            method,
            'promptCapabilities.embeddedContext',
          );
        }
      case TextContent() || ResourceLink() || UnknownContentBlock():
        break;
    }
  }
}

// Accepts POSIX (/x), UNC (\\server\share), and Windows drive-letter (C:\ or
// C:/) forms regardless of host OS, since the peer may run on a different
// platform than this process.
bool _isAbsolutePath(String path) {
  if (path.isEmpty) return false;

  if (path.startsWith('/')) return true;
  if (path.startsWith(r'\\')) return true;

  if (path.length >= 3) {
    final first = path.codeUnitAt(0);
    final second = path.codeUnitAt(1);
    final third = path.codeUnitAt(2);
    final isDriveLetter =
        (first >= 65 && first <= 90) || (first >= 97 && first <= 122);
    final isSeparator = third == 47 || third == 92;
    return isDriveLetter && second == 58 && isSeparator;
  }

  return false;
}
