#!/usr/bin/env bash
set -euo pipefail

native_benchmark_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$native_benchmark_script_dir/jvm-benchmark-common.sh"

benchmark_workload_file="$benchmark_repo_root/benchmarks/native-image-comparison-workload.json"
benchmark_report_schema_file="$benchmark_repo_root/benchmarks/native-image-comparison-report.schema.json"

native_benchmark_image_size_bytes() {
    local image_reference="$1"
    docker image inspect "$image_reference" --format '{{.Size}}'
}

native_benchmark_postgres_container_id() {
    local compose_file="$1"
    docker compose -f "$compose_file" ps -q postgres
}

native_benchmark_postgres_network_name() {
    local compose_file="$1"
    local container_id

    container_id="$(native_benchmark_postgres_container_id "$compose_file")"
    if [[ -z "$container_id" ]]; then
        echo ""
        return 0
    fi

    docker inspect \
        --format '{{range $name, $details := .NetworkSettings.Networks}}{{println $name}}{{end}}' \
        "$container_id" | head -n 1 | tr -d '[:space:]'
}

native_benchmark_container_is_running() {
    local container_name="$1"
    local status

    status="$(docker inspect --format '{{.State.Status}}' "$container_name" 2>/dev/null || true)"
    [[ "$status" == "running" ]]
}

native_benchmark_capture_container_logs() {
    local container_name="$1"
    local output_file="$2"

    docker logs "$container_name" >"$output_file" 2>&1 || true
}

native_benchmark_remove_container_if_present() {
    local container_name="$1"
    docker rm -f "$container_name" >/dev/null 2>&1 || true
}

native_benchmark_parse_human_size_to_bytes() {
    local value="$1"

    awk -v raw="$value" '
        function unit_multiplier(unit) {
            if (unit == "B") return 1;
            if (unit == "kB") return 1000;
            if (unit == "KB") return 1000;
            if (unit == "KiB") return 1024;
            if (unit == "MB") return 1000 * 1000;
            if (unit == "MiB") return 1024 * 1024;
            if (unit == "GB") return 1000 * 1000 * 1000;
            if (unit == "GiB") return 1024 * 1024 * 1024;
            if (unit == "TB") return 1000 * 1000 * 1000 * 1000;
            if (unit == "TiB") return 1024 * 1024 * 1024 * 1024;
            return 1;
        }
        BEGIN {
            match(raw, /^([0-9.]+)([[:alpha:]]+)$/, parts);
            if (parts[1] == "") {
                print 0;
                exit;
            }
            printf "%d\n", (parts[1] * unit_multiplier(parts[2])) + 0.5;
        }
    '
}

native_benchmark_container_memory_bytes() {
    local container_name="$1"
    local mem_usage
    local current_usage

    mem_usage="$(docker stats --no-stream --format '{{.MemUsage}}' "$container_name" 2>/dev/null | head -n 1)"
    current_usage="${mem_usage%% / *}"

    if [[ -z "$current_usage" ]]; then
        echo 0
        return 0
    fi

    native_benchmark_parse_human_size_to_bytes "$current_usage"
}
