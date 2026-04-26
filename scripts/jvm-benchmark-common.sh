#!/usr/bin/env bash
set -euo pipefail

benchmark_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
benchmark_repo_root="$(cd -- "$benchmark_script_dir/.." && pwd)"
benchmark_workload_file="$benchmark_repo_root/benchmarks/jvm-runtime-comparison-workload.json"
benchmark_report_schema_file="$benchmark_repo_root/benchmarks/jvm-runtime-comparison-report.schema.json"

benchmark_require_binary() {
    local binary="$1"
    if ! command -v "$binary" >/dev/null 2>&1; then
        echo "Required binary is missing: $binary" >&2
        return 1
    fi
}

benchmark_load_workload_value() {
    local jq_filter="$1"
    jq --raw-output "$jq_filter" "$benchmark_workload_file"
}

benchmark_now_utc() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

benchmark_epoch_ms() {
    date +%s%3N
}

benchmark_duration_ms() {
    local start_ms="$1"
    local end_ms="$2"
    echo $(( end_ms - start_ms ))
}

benchmark_measure_artifact_size_bytes() {
    local artifact_path="$1"
    if [[ -d "$artifact_path" ]]; then
        du -sb "$artifact_path" | awk '{print $1}'
    else
        stat -c "%s" "$artifact_path"
    fi
}

benchmark_measure_rss_kb() {
    local pid="$1"
    ps -o rss= -p "$pid" | tr -d "[:space:]"
}

benchmark_output_root() {
    local relative_root
    relative_root="$(benchmark_load_workload_value '.output.rootDirectory')"
    echo "$benchmark_repo_root/$relative_root"
}

benchmark_prepare_output_dir() {
    local label="$1"
    local output_root
    local latest_name
    local timestamp
    local run_dir

    output_root="$(benchmark_output_root)"
    latest_name="$(benchmark_load_workload_value '.output.latestSymlinkName')"
    timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
    run_dir="$output_root/${timestamp}-${label}"

    mkdir -p "$run_dir"
    ln -sfn "$run_dir" "$output_root/$latest_name"
    echo "$run_dir"
}

benchmark_os_name() {
    uname -s
}

benchmark_os_version() {
    uname -r
}

benchmark_architecture() {
    uname -m
}

benchmark_available_processors() {
    getconf _NPROCESSORS_ONLN
}

benchmark_total_memory_kb() {
    awk '/MemTotal:/ {print $2; exit}' /proc/meminfo
}

benchmark_java_version() {
    java -version 2>&1 | awk 'NR == 1 {gsub(/"/, "", $3); print $3}'
}

benchmark_docker_version() {
    if command -v docker >/dev/null 2>&1; then
        docker --version 2>/dev/null | sed 's/^Docker version //; s/,.*$//'
    else
        echo "unavailable"
    fi
}

benchmark_environment_json() {
    jq -n \
        --arg os_name "$(benchmark_os_name)" \
        --arg os_version "$(benchmark_os_version)" \
        --arg architecture "$(benchmark_architecture)" \
        --arg java_version "$(benchmark_java_version)" \
        --arg docker_version "$(benchmark_docker_version)" \
        --argjson available_processors "$(benchmark_available_processors)" \
        --argjson total_memory_kb "$(benchmark_total_memory_kb)" \
        '{
            osName: $os_name,
            osVersion: $os_version,
            architecture: $architecture,
            javaVersion: $java_version,
            availableProcessors: $available_processors,
            totalMemoryKb: $total_memory_kb,
            dockerVersion: $docker_version
        }'
}

benchmark_latency_summary_json() {
    if [[ $# -eq 0 ]]; then
        jq -n '{count: 0, min: 0, max: 0, avg: 0}'
        return 0
    fi

    printf '%s\n' "$@" | awk '
        NR == 1 {
            min = $1
            max = $1
        }
        {
            if ($1 < min) {
                min = $1
            }
            if ($1 > max) {
                max = $1
            }
            sum += $1
        }
        END {
            printf("{\"count\":%d,\"min\":%d,\"max\":%d,\"avg\":%.2f}\n", NR, min, max, sum / NR)
        }
    '
}
