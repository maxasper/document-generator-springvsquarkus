#!/usr/bin/env bash
set -euo pipefail

container_runtime_matrix_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
container_runtime_matrix_repo_root="$(cd -- "$container_runtime_matrix_script_dir/.." && pwd)"
container_runtime_matrix_workload_file="$container_runtime_matrix_repo_root/benchmarks/container-runtime-matrix-workload.json"
container_runtime_matrix_report_schema_file="$container_runtime_matrix_repo_root/benchmarks/container-runtime-matrix-report.schema.json"

source "$container_runtime_matrix_script_dir/compose-runtime-inspection-common.sh"
source "$container_runtime_matrix_script_dir/jvm-benchmark-common.sh"

container_runtime_matrix_load_value() {
    local jq_filter="$1"
    jq --raw-output "$jq_filter" "$container_runtime_matrix_workload_file"
}

container_runtime_matrix_output_root() {
    local relative_root
    relative_root="$(container_runtime_matrix_load_value '.output.rootDirectory')"
    echo "$container_runtime_matrix_repo_root/$relative_root"
}

container_runtime_matrix_prepare_output_dir() {
    local label="$1"
    local output_root
    local latest_name
    local timestamp
    local run_dir

    output_root="$(container_runtime_matrix_output_root)"
    latest_name="$(container_runtime_matrix_load_value '.output.latestSymlinkName')"
    timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
    run_dir="$output_root/${timestamp}-${label}"

    mkdir -p "$run_dir"
    ln -sfn "$run_dir" "$output_root/$latest_name"
    echo "$run_dir"
}
