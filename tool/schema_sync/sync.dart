/// Downloads ACP schema files from the official GitHub repository.
///
/// Run with: `dart run tool/schema_sync/sync.dart`
///
/// Override the tag with:
/// `dart run -DACP_SCHEMA_VERSION=v0.12.0 tool/schema_sync/sync.dart`
library;

import 'dart:io';

const _schemaVersion = String.fromEnvironment(
  'ACP_SCHEMA_VERSION',
  defaultValue: 'v0.12.0',
);

const _files = [
  'schema.json',
  'schema.unstable.json',
  'meta.json',
  'meta.unstable.json',
];

Future<void> main() async {
  final baseUrl = Uri.parse(
    'https://raw.githubusercontent.com/agentclientprotocol/'
    'agent-client-protocol/$_schemaVersion/schema/',
  );
  final outDir = Directory('tool/upstream/schema');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  final client = HttpClient();
  try {
    for (final file in _files) {
      final url = baseUrl.resolve(file);
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

  stdout.writeln(
    'Done. ACP $_schemaVersion schema files written to ${outDir.path}/',
  );
}
