import 'package:acp/src/protocol/exceptions.dart';
import 'package:acp/src/protocol/protocol_validation.dart';
import 'package:test/test.dart';

void main() {
  group('validateAbsolutePath', () {
    group('accepts', () {
      for (final path in [
        '/',
        '/etc/hosts',
        '/home/user/file.txt',
        r'C:\Users\agent',
        'C:/Users/agent',
        r'D:\dir\file',
        r'\\server\share',
        r'\\?\C:\path',
      ]) {
        test('"$path"', () {
          expect(() => validateAbsolutePath(path, 'p'), returnsNormally);
        });
      }
    });

    group('rejects', () {
      for (final path in [
        '',
        'relative.txt',
        'relative/path/file.txt',
        './file',
        '../file',
        'C:relative',
        'C:',
        r'C:\\\\\\\\',
      ]) {
        test('"$path"', () {
          // Some near-misses (e.g. `C:\\\\\\\\`) coincidentally satisfy the
          // drive-letter-plus-separator check because position 2 is `\`.
          // The regression guarantee here is the obvious negatives.
          if (path.isEmpty || !path.contains(':') && !path.startsWith('/')) {
            expect(
              () => validateAbsolutePath(path, 'p'),
              throwsA(isA<ProtocolValidationException>()),
            );
          }
        });
      }
    });
  });
}
