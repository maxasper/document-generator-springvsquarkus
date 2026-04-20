#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <base-url>" >&2
}

base_url="${1:-}"
if [[ -z "$base_url" ]]; then
    usage
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

cd "$repo_root"

echo "Running shared contract tests against $base_url"
./mvnw -q -pl document-generator-contract-tests test "-Ddocument.generator.base-url=$base_url"
