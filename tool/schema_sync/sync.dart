/// Downloads the latest ACP schema files from the official GitHub repository.
///
/// Run with: `dart run tool/schema_sync/sync.dart`
library;

import 'dart:io';

const _baseUrl =
    'https://raw.githubusercontent.com/agentclientprotocol/agent-client-protocol/main/schema';

const _files = [
  'schema.json',
  'schema.unstable.json',
  'meta.json',
  'meta.unstable.json',
];

Future<void> main() async {
  final outDir = Directory('tool/upstream/schema');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final client = HttpClient();
  try {
    for (final file in _files) {
      final url = Uri.parse('$_baseUrl/$file');
      stdout.write('Downloading $file ... ');
      final request = await client.getUrl(url);
      final response = await request.close();
      if (response.statusCode != 200) {
        stderr.writeln('FAILED (HTTP ${response.statusCode})');
        await response.drain<void>();
        continue;
      }
      final outFile = File('${outDir.path}/$file');
      final sink = outFile.openWrite();
      await response.pipe(sink);
      stdout.writeln('OK (${outFile.lengthSync()} bytes)');
    }
  } finally {
    client.close();
  }

  stdout.writeln('Done. Schema files written to ${outDir.path}/');
}
