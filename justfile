set shell := ["bash", "-cu"]

[private]
default:
    just --list

dev: format analyze test example

build: deps generate format-check analyze test example

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

sync-schema version="v0.12.0":
    dart run -DACP_SCHEMA_VERSION={{version}} tool/schema_sync/sync.dart
    dart run tool/generate/generate.dart

# Runs every self-contained example. `basic_agent.dart` is excluded because
# it reads stdin as a spawned subprocess and blocks when run directly.
example:
    dart run example/basic_client.dart
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
