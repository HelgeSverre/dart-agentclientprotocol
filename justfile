set shell := ["bash", "-cu"]

[private]
default:
    just --list

dev: format analyze test example

build: deps generate format-check analyze test example

# Verifies the package as it would be uploaded to pub.dev. Run before
# tagging a release; expects a clean git state.
release-check: build dry-run

deps:
    dart pub get

analyze:
    dart analyze

format:
    dart format .

format-check:
    dart format --set-exit-if-changed .

test:
    dart test

generate:
    dart run tool/generate/generate.dart
    dart format lib/src/schema/

sync-schema version="v0.12.0":
    dart run -DACP_SCHEMA_VERSION={{version}} tool/schema_sync/sync.dart
    dart run tool/generate/generate.dart

dry-run:
    dart pub publish --dry-run

# Runs every self-contained example. `main.dart` is excluded because
# it's designed to be spawned by another process — `subprocess_client.dart`
# launches and drives it, so it's exercised there.
example:
    dart run example/subprocess_client.dart
    dart run example/streaming_agent.dart
    dart run example/project_assistant.dart

website:
    rm -rf website/docs
    dart doc --output website/docs --validate-links

website-dev: website
    open website/index.html

website-deploy: website
    cd website && vc --prod

clean:
    rm -rf .dart_tool build coverage website/docs
