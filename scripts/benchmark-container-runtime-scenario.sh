#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus> <jvm|native> [output-dir]" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/container-runtime-matrix-common.sh"

compose_runtime_require_binary docker
compose_runtime_require_binary jq

runtime="${1:-}"
mode="${2:-}"
output_dir="${3:-}"

if [[ -z "$runtime" || -z "$mode" ]]; then
    usage
    exit 1
fi

compose_runtime_validate_runtime "$runtime" >/dev/null || {
    usage
    exit 1
}
compose_runtime_validate_mode "$mode" >/dev/null || {
    usage
    exit 1
}

scenario_name="$(compose_runtime_scenario_name "$runtime" "$mode")"
display_name="$(compose_runtime_scenario_display_name "$runtime" "$mode")"
service_name="$(compose_runtime_service_name "$runtime" "$mode")"
image_reference="$(compose_runtime_image_reference "$runtime" "$mode")"

if [[ -z "$output_dir" ]]; then
    output_dir="$(container_runtime_matrix_prepare_output_dir "$scenario_name")"
else
    case "$output_dir" in
        "$repo_root"/target/*)
            ;;
        *)
            echo "Custom output directories must be under $repo_root/target" >&2
            exit 1
            ;;
    esac
    mkdir -p "$output_dir"
fi

startup_log_file="$output_dir/startup.log"
runtime_log_file="$output_dir/runtime.log"
report_file="$output_dir/report.json"
load_test_output_dir="$output_dir/load-test"

build_duration_ms=0
startup_duration_ms=0
image_size_bytes=0
memory_bytes=0
cpu_percent=0
startup_memory_bytes=0
startup_cpu_percent=0
post_load_memory_bytes=0
post_load_cpu_percent=0

cleanup() {
    local exit_code=$?

    mkdir -p "$output_dir"
    compose_runtime_capture_service_logs "$service_name" "$runtime_log_file"
    "$script_dir/compose-runtime-down.sh" >/dev/null 2>&1 || true

    if [[ $exit_code -ne 0 ]]; then
        echo "$display_name container runtime scenario failed. Output directory: $output_dir" >&2
        echo "--- $display_name startup log ---" >&2
        tail -n 200 "$startup_log_file" >&2 || true
        echo "--- $display_name runtime log ---" >&2
        tail -n 200 "$runtime_log_file" >&2 || true
    fi
}

trap cleanup EXIT

mkdir -p "$output_dir"
cd "$repo_root"

build_start_ms="$(compose_runtime_epoch_ms)"
"$script_dir/build-compose-runtime-image.sh" "$runtime" "$mode"
build_end_ms="$(compose_runtime_epoch_ms)"
build_duration_ms="$(compose_runtime_duration_ms "$build_start_ms" "$build_end_ms")"
image_size_bytes="$(compose_runtime_image_size_bytes "$image_reference")"

startup_start_ms="$(compose_runtime_epoch_ms)"
"$script_dir/compose-runtime-up.sh" "$runtime" "$mode" >"$startup_log_file"
startup_end_ms="$(compose_runtime_epoch_ms)"
startup_duration_ms="$(compose_runtime_duration_ms "$startup_start_ms" "$startup_end_ms")"

runtime_container_id="$(compose_runtime_service_container_id "$service_name")"
if [[ -z "$runtime_container_id" ]]; then
    echo "Failed to resolve running container for $service_name" >&2
    exit 1
fi

startup_memory_bytes="$(compose_runtime_container_memory_bytes "$runtime_container_id")"
startup_cpu_percent="$(compose_runtime_container_cpu_percent "$runtime_container_id")"

"$script_dir/load-test-compose-runtime.sh" "$runtime" "$mode" "$load_test_output_dir"

post_load_memory_bytes="$(compose_runtime_container_memory_bytes "$runtime_container_id")"
post_load_cpu_percent="$(compose_runtime_container_cpu_percent "$runtime_container_id")"
memory_bytes="$post_load_memory_bytes"
cpu_percent="$post_load_cpu_percent"

if [[ "$memory_bytes" -eq 0 && "$startup_memory_bytes" -gt 0 ]]; then
    memory_bytes="$startup_memory_bytes"
fi

if [[ "$cpu_percent" == "0" || "$cpu_percent" == "0.00" ]]; then
    cpu_percent="$startup_cpu_percent"
fi

load_test_summary_file="$load_test_output_dir/summary.json"
if [[ ! -f "$load_test_summary_file" ]]; then
    echo "Missing load-test summary: $load_test_summary_file" >&2
    exit 1
fi

jq -n \
    --arg generated_at "$(compose_runtime_now_utc)" \
    --arg workload_file "benchmarks/container-runtime-matrix-workload.json" \
    --arg load_test_workload_file "benchmarks/runtime-load-testing-workload.json" \
    --arg scenario "$scenario_name" \
    --arg runtime "$runtime" \
    --arg mode "$mode" \
    --arg display_name "$display_name" \
    --arg strategy_kind "$(compose_runtime_build_strategy_kind "$runtime" "$mode")" \
    --arg image_reference "$image_reference" \
    --arg startup_log_file "$startup_log_file" \
    --arg runtime_log_file "$runtime_log_file" \
    --arg output_dir "$load_test_output_dir" \
    --arg cpus "$(compose_runtime_configured_cpus)" \
    --arg memory "$(compose_runtime_configured_memory)" \
    --arg jvm_max_ram_percentage "$(compose_runtime_configured_max_ram_percentage)" \
    --arg vus "$(compose_runtime_configured_vus)" \
    --arg duration "$(compose_runtime_configured_duration)" \
    --argjson environment "$(benchmark_environment_json)" \
    --argjson build_duration_ms "$build_duration_ms" \
    --argjson startup_duration_ms "$startup_duration_ms" \
    --argjson image_size_bytes "$image_size_bytes" \
    --argjson pids_limit "$(compose_runtime_configured_pids_limit)" \
    --argjson memory_bytes "$memory_bytes" \
    --argjson cpu_percent "${cpu_percent:-0}" \
    --argjson startup_memory_bytes "$startup_memory_bytes" \
    --argjson startup_cpu_percent "${startup_cpu_percent:-0}" \
    --argjson post_load_memory_bytes "$post_load_memory_bytes" \
    --argjson post_load_cpu_percent "${post_load_cpu_percent:-0}" \
    --slurpfile load_summary "$load_test_summary_file" \
    '{
        schemaVersion: 1,
        benchmarkName: "container-runtime-scenario",
        generatedAtUtc: $generated_at,
        workloadFile: $workload_file,
        loadTestWorkloadFile: $load_test_workload_file,
        environment: $environment,
        configuredLimits: {
            cpus: $cpus,
            memory: $memory,
            pidsLimit: $pids_limit,
            jvmMaxRamPercentage: $jvm_max_ram_percentage
        },
        configuredLoadProfile: {
            vus: ($vus | tonumber),
            duration: $duration
        },
        run: {
            scenario: $scenario,
            runtime: $runtime,
            mode: $mode,
            displayName: $display_name,
            buildStrategy: {
                kind: $strategy_kind
            },
            image: {
                reference: $image_reference,
                sizeBytes: $image_size_bytes
            },
            buildDurationMs: $build_duration_ms,
            startupDurationMs: $startup_duration_ms,
            startupLog: $startup_log_file,
            runtimeLog: $runtime_log_file,
            containerObservation: {
                memoryBytes: $memory_bytes,
                cpuPercent: $cpu_percent,
                startupMemoryBytes: $startup_memory_bytes,
                startupCpuPercent: $startup_cpu_percent,
                postLoadMemoryBytes: $post_load_memory_bytes,
                postLoadCpuPercent: $post_load_cpu_percent
            },
            loadTest: {
                outputDir: $output_dir,
                iterations: ($load_summary[0].metrics.iterations.count // 0),
                httpReqs: ($load_summary[0].metrics.http_reqs.count // 0),
                httpReqFailedRate: ($load_summary[0].metrics.http_req_failed.value // 0),
                avgDurationMs: ($load_summary[0].metrics.http_req_duration.avg // 0),
                p95DurationMs: ($load_summary[0].metrics.http_req_duration["p(95)"] // 0),
                successfulAvgDurationMs: ($load_summary[0].metrics["http_req_duration{expected_response:true}"].avg // 0),
                successfulP95DurationMs: ($load_summary[0].metrics["http_req_duration{expected_response:true}"]["p(95)"] // 0),
                summaryFile: ($output_dir + "/summary.json"),
                summaryTextFile: ($output_dir + "/summary.txt"),
                logFile: ($output_dir + "/k6.log")
            }
        }
    }' >"$report_file"

echo "Container runtime scenario complete: $display_name"
echo "Report: $report_file"
