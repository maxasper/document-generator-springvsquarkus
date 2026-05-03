#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/compose-runtime-inspection-common.sh"

compose_runtime_require_binary docker

cd "$repo_root"

docker compose -f "$compose_runtime_compose_file" down -v --remove-orphans
