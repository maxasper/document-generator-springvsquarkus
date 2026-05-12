#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus> <jvm|native> [output-dir]" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/container-runtime-matrix-common.sh"

compose_runtime_require_binary curl
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

report_file="$output_dir/report.json"
load_test_output_dir="$output_dir/load-test"
case_entries_file="$output_dir/load-test-cases.jsonl"
seed_rows="$(compose_runtime_configured_get_seed_rows)"
build_duration_ms=0
image_size_bytes=0
current_case=""
current_startup_log_file=""
current_runtime_log_file=""

if ! [[ "$seed_rows" =~ ^[0-9]+$ ]]; then
    echo "LOAD_TEST_GET_SEED_ROWS must be a non-negative integer: $seed_rows" >&2
    exit 1
fi

if [[ -n "${LOAD_TEST_CASE:-}" ]]; then
    load_test_cases=("$LOAD_TEST_CASE")
else
    IFS=',' read -r -a load_test_cases <<<"$(compose_runtime_configured_load_cases)"
fi

if [[ ${#load_test_cases[@]} -eq 0 ]]; then
    echo "At least one load-test case is required." >&2
    exit 1
fi

for load_test_case in "${load_test_cases[@]}"; do
    compose_runtime_validate_load_case "$load_test_case" >/dev/null
done

cleanup() {
    local exit_code=$?

    if [[ -n "$current_case" && -n "$current_runtime_log_file" ]]; then
        mkdir -p "$(dirname "$current_runtime_log_file")"
        compose_runtime_capture_service_logs "$service_name" "$current_runtime_log_file"
    fi

    "$script_dir/compose-runtime-down.sh" >/dev/null 2>&1 || true

    if [[ $exit_code -ne 0 ]]; then
        echo "$display_name container runtime scenario failed. Output directory: $output_dir" >&2
        if [[ -n "$current_case" ]]; then
            echo "Failed load-test case: $current_case" >&2
        fi
        if [[ -n "$current_startup_log_file" && -f "$current_startup_log_file" ]]; then
            echo "--- $display_name startup log ($current_case) ---" >&2
            tail -n 200 "$current_startup_log_file" >&2 || true
        fi
        if [[ -n "$current_runtime_log_file" && -f "$current_runtime_log_file" ]]; then
            echo "--- $display_name runtime log ($current_case) ---" >&2
            tail -n 200 "$current_runtime_log_file" >&2 || true
        fi
    fi
}

trap cleanup EXIT

seed_get_history() {
    local base_url="$1"
    local count="$2"
    local index
    local suffix
    local payload
    local status

    if [[ "$count" -eq 0 ]]; then
        return 0
    fi

    for ((index = 1; index <= count; index += 1)); do
        suffix="get-seed-${scenario_name}-${index}"
        payload="$(
            jq -n \
                --arg suffix "$suffix" \
                '{
                    documentFormat: "PDF",
                    templateType: "INVOICE",
                    documentName: ("compose-load-test-document-" + $suffix),
                    parameters: {
                        customerName: "Load Test Customer",
                        invoiceNumber: ("INV-" + $suffix),
                        amount: "123.45"
                    }
                }'
        )"
        status="$(
            curl --silent --output /dev/null --write-out '%{http_code}' --max-time 10 \
                -H "Content-Type: application/json" \
                -d "$payload" \
                "$(compose_runtime_host_base_url "$runtime" "$mode")/api/v1/document-generations" || true
        )"

        if [[ "$status" != "200" ]]; then
            echo "Failed to seed get workload history row $index/$count: HTTP $status" >&2
            return 1
        fi
    done
}

case_metadata_json() {
    local load_test_case="$1"
    local startup_duration_ms="$2"
    local startup_log_file="$3"
    local runtime_log_file="$4"
    local summary_file="$5"

    jq -n \
        --arg key "$load_test_case" \
        --arg startup_log_file "$startup_log_file" \
        --arg runtime_log_file "$runtime_log_file" \
        --arg summary_file "$summary_file" \
        --argjson startup_duration_ms "$startup_duration_ms" \
        --slurpfile load_summary "$summary_file" \
        '
            $load_summary[0].cases[$key] as $case_summary
            | $case_summary.metrics as $metrics
            | ($metrics["http_req_duration{expected_response:true}"] // null) as $successful
            | {
                key: $key,
                value: {
                    startupDurationMs: $startup_duration_ms,
                    startupLog: $startup_log_file,
                    runtimeLog: $runtime_log_file,
                    outputDir: ($summary_file | sub("/summary[.]json$"; "")),
                    iterations: ($metrics.iterations.count // 0),
                    httpReqs: ($metrics.http_reqs.count // 0),
                    httpReqFailedRate: ($metrics.http_req_failed.value // null),
                    avgDurationMs: ($metrics.http_req_duration.avg // null),
                    p95DurationMs: ($metrics.http_req_duration["p(95)"] // null),
                    successfulAvgDurationMs: ($successful.avg // null),
                    successfulP95DurationMs: ($successful["p(95)"] // null),
                    containerObservation: ($case_summary.containerObservation // {}),
                    summaryFile: $case_summary.summaryFile,
                    logFile: $case_summary.logFile
                }
            }
        '
}

mkdir -p "$output_dir" "$load_test_output_dir"
: >"$case_entries_file"
cd "$repo_root"

build_start_ms="$(compose_runtime_epoch_ms)"
"$script_dir/build-compose-runtime-image.sh" "$runtime" "$mode"
build_end_ms="$(compose_runtime_epoch_ms)"
build_duration_ms="$(compose_runtime_duration_ms "$build_start_ms" "$build_end_ms")"
image_size_bytes="$(compose_runtime_image_size_bytes "$image_reference")"

for load_test_case in "${load_test_cases[@]}"; do
    current_case="$load_test_case"
    case_output_dir="$load_test_output_dir/$load_test_case"
    current_startup_log_file="$case_output_dir/startup.log"
    current_runtime_log_file="$case_output_dir/runtime.log"
    case_summary_file="$case_output_dir/summary.json"

    mkdir -p "$case_output_dir"

    startup_start_ms="$(compose_runtime_epoch_ms)"
    "$script_dir/compose-runtime-up.sh" "$runtime" "$mode" >"$current_startup_log_file"
    startup_end_ms="$(compose_runtime_epoch_ms)"
    startup_duration_ms="$(compose_runtime_duration_ms "$startup_start_ms" "$startup_end_ms")"

    if [[ "$load_test_case" == "get" ]]; then
        seed_get_history "$(compose_runtime_host_base_url "$runtime" "$mode")" "$seed_rows"
    fi

    LOAD_TEST_CASE="$load_test_case" "$script_dir/load-test-compose-runtime.sh" "$runtime" "$mode" "$case_output_dir"
    compose_runtime_capture_service_logs "$service_name" "$current_runtime_log_file"
    case_metadata_json "$load_test_case" "$startup_duration_ms" "$current_startup_log_file" "$current_runtime_log_file" "$case_summary_file" >>"$case_entries_file"

    "$script_dir/compose-runtime-down.sh" >/dev/null 2>&1 || true
    current_case=""
    current_startup_log_file=""
    current_runtime_log_file=""
done

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
    --arg output_dir "$load_test_output_dir" \
    --arg cpus "$(compose_runtime_configured_cpus)" \
    --arg memory "$(compose_runtime_configured_memory)" \
    --arg jvm_max_ram_percentage "$(compose_runtime_configured_max_ram_percentage)" \
    --arg vus "$(compose_runtime_configured_vus)" \
    --arg duration "$(compose_runtime_configured_duration)" \
    --arg load_cases "$(IFS=','; echo "${load_test_cases[*]}")" \
    --argjson environment "$(benchmark_environment_json)" \
    --argjson build_duration_ms "$build_duration_ms" \
    --argjson image_size_bytes "$image_size_bytes" \
    --argjson pids_limit "$(compose_runtime_configured_pids_limit)" \
    --argjson get_seed_rows "$seed_rows" \
    --slurpfile case_entries "$case_entries_file" \
    '
        ($case_entries | map({(.key): .value}) | add) as $cases
        | ($cases.mixed // ($cases | to_entries | .[-1].value)) as $primary_case
        | {
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
                duration: $duration,
                cases: ($load_cases | split(",")),
                getSeedRows: $get_seed_rows
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
                startupDurationMs: ($primary_case.startupDurationMs // 0),
                containerObservation: {
                    memoryBytes: ($primary_case.containerObservation.memoryBytes // null),
                    cpuPercent: ($primary_case.containerObservation.cpuAvgPercent // null),
                    sampledMemoryBytes: ($primary_case.containerObservation.memoryBytes // null),
                    sampledCpuPercent: ($primary_case.containerObservation.cpuAvgPercent // null),
                    sampledCpuMaxPercent: ($primary_case.containerObservation.cpuMaxPercent // null)
                },
                loadTest: {
                    outputDir: $output_dir,
                    cases: $cases,
                    iterations: ($primary_case.iterations // 0),
                    httpReqs: ($primary_case.httpReqs // 0),
                    httpReqFailedRate: ($primary_case.httpReqFailedRate // null),
                    avgDurationMs: ($primary_case.avgDurationMs // null),
                    p95DurationMs: ($primary_case.p95DurationMs // null),
                    successfulAvgDurationMs: ($primary_case.successfulAvgDurationMs // null),
                    successfulP95DurationMs: ($primary_case.successfulP95DurationMs // null),
                    summaryFile: ($output_dir + "/summary.json"),
                    summaryTextFile: ($output_dir + "/summary.txt"),
                    logFile: ($primary_case.logFile // null)
                }
            }
        }
    ' >"$report_file"

jq -s \
    '{
        schemaVersion: 1,
        cases: (map({(.key): .value}) | add)
    }' "$case_entries_file" >"$load_test_output_dir/summary.json"

jq -r '
    def round_to($scale): (. * $scale | round) / $scale;
    def display_number($scale):
        if . == null then "n/a" else (round_to($scale) | tostring) end;
    [
        "Runtime load test summary",
        "case           cpu_avg(%) cpu_max(%) iterations reqs     failed     avg(ms)    p95(ms)    p95_ok(ms)",
        (
            .cases
            | to_entries[]
            | .key as $case
            | .value as $load_case
            | [
                $case,
                (($load_case.containerObservation.cpuAvgPercent // null) | display_number(100)),
                (($load_case.containerObservation.cpuMaxPercent // null) | display_number(100)),
                ($load_case.iterations // 0 | tostring),
                ($load_case.httpReqs // 0 | tostring),
                (($load_case.httpReqFailedRate // null) | display_number(10000)),
                (($load_case.avgDurationMs // null) | display_number(10)),
                (($load_case.p95DurationMs // null) | display_number(10)),
                (($load_case.successfulP95DurationMs // null) | display_number(10))
            ]
            | @tsv
        )
    ] | .[]' "$load_test_output_dir/summary.json" | while IFS=$'\t' read -r case_name cpu_avg cpu_max iterations reqs failed avg p95 successful_p95; do
        if [[ -z "${iterations:-}" ]]; then
            echo "$case_name"
        else
            printf "%-14s %-10s %-10s %-10s %-8s %-10s %-10s %-10s %-10s\n" \
                "$case_name" "$cpu_avg" "$cpu_max" "$iterations" "$reqs" "$failed" "$avg" "$p95" "$successful_p95"
        fi
    done >"$load_test_output_dir/summary.txt"

echo "Container runtime scenario complete: $display_name"
echo "Report: $report_file"
