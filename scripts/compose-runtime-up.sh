#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus>" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/compose-runtime-inspection-common.sh"

compose_runtime_require_binary docker
compose_runtime_require_binary curl

runtime="${1:-}"
if [[ -z "$runtime" ]]; then
    usage
    exit 1
fi

case "$runtime" in
    spring|quarkus)
        ;;
    *)
        usage
        exit 1
        ;;
esac

service="$(compose_runtime_service_name "$runtime")"
image_reference="$(compose_runtime_image_reference "$runtime")"
base_url="$(compose_runtime_host_base_url "$runtime")"
jmx_url="$(compose_runtime_host_jmx_url "$runtime")"
jmx_port="$(compose_runtime_host_jmx_port "$runtime")"
postgres_container_name="document-generator-postgres-runtime-inspection"
runtime_container_id=""

cd "$repo_root"

if ! docker image inspect "$image_reference" >/dev/null 2>&1; then
    echo "Missing runtime image: $image_reference" >&2
    echo "Build it first with: ./scripts/build-compose-runtime-image.sh $runtime" >&2
    exit 1
fi

echo "Resetting runtime-inspection environment"
docker compose -f "$compose_runtime_compose_file" down -v --remove-orphans >/dev/null 2>&1 || true

echo "Starting PostgreSQL and $(compose_runtime_runtime_name "$runtime")"
docker compose -f "$compose_runtime_compose_file" up -d postgres "$service"
compose_runtime_wait_for_postgres 60
compose_runtime_wait_for_http "$runtime" 60
runtime_container_id="$(compose_runtime_service_container_id "$service")"

echo "$(compose_runtime_runtime_name "$runtime") is ready"
echo "HTTP base URL: $base_url"
echo "JMX port: $jmx_port"
echo "JMX service URL: $jmx_url"
echo "Example tools: VisualVM or JDK Mission Control"
echo "Container-level resource view: docker stats $postgres_container_name $runtime_container_id"
echo "Stop the environment with: ./scripts/compose-runtime-down.sh"
