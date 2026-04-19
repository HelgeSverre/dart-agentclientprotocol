set shell := ["bash", "-cu"]

[group('main')]
default:
    just --list

[group('main')]
dev: format analyze test example

[group('main')]
build: deps generate format-check analyze test example

[group('setup')]
deps:
    dart pub get

[group('quality')]
analyze:
    dart analyze

[group('quality')]
format:
    dart format .

[group('quality')]
format-check:
    dart format --set-exit-if-changed .

[group('test')]
test:
    dart test

[group('test')]
test-unit:
    dart test -t unit

[group('test')]
test-integration:
    dart test -t integration

[group('test')]
test-compliance:
    dart test -t compliance

[group('schema')]
generate:
    dart run tool/generate/generate.dart

[group('schema')]
sync-schema version="v0.12.0":
    dart run -DACP_SCHEMA_VERSION={{version}} tool/schema_sync/sync.dart
    dart run tool/generate/generate.dart

[group('examples')]
example:
    dart run example/project_assistant.dart

[group('maintenance')]
clean:
    rm -rf .dart_tool build coverage
