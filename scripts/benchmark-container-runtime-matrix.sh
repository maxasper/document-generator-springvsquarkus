#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/container-runtime-matrix-common.sh"

compose_runtime_require_binary jq

output_dir="$(container_runtime_matrix_prepare_output_dir matrix)"
report_file="$output_dir/report.json"
summary_file="$output_dir/summary.txt"

mapfile -t scenarios < <(
    jq -r '.scenarios[] | "\(.runtime) \(.mode)"' "$container_runtime_matrix_workload_file"
)

for scenario in "${scenarios[@]}"; do
    runtime="${scenario%% *}"
    mode="${scenario##* }"
    scenario_name="$(compose_runtime_scenario_name "$runtime" "$mode")"
    scenario_output_dir="$output_dir/$scenario_name"
    "$script_dir/benchmark-container-runtime-scenario.sh" "$runtime" "$mode" "$scenario_output_dir"
done

jq -s \
    --arg generated_at "$(compose_runtime_now_utc)" \
    --arg workload_file "benchmarks/container-runtime-matrix-workload.json" \
    --arg load_test_workload_file "benchmarks/runtime-load-testing-workload.json" \
    --arg cpus "$(compose_runtime_configured_cpus)" \
    --arg memory "$(compose_runtime_configured_memory)" \
    --arg jvm_max_ram_percentage "$(compose_runtime_configured_max_ram_percentage)" \
    --arg vus "$(compose_runtime_configured_vus)" \
    --arg duration "$(compose_runtime_configured_duration)" \
    --argjson environment "$(benchmark_environment_json)" \
    --argjson pids_limit "$(compose_runtime_configured_pids_limit)" \
    '{
        schemaVersion: 1,
        benchmarkName: "container-runtime-matrix",
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
        runs: map(.run)
    }' "$output_dir"/*/report.json >"$report_file"

{
    echo "Container runtime matrix summary"
    printf "%-15s %-10s %-12s %-13s %-12s %-8s %-10s %-10s\n" "scenario" "build(ms)" "startup(ms)" "memory(bytes)" "cpu(%)" "reqs" "failed" "p95(ms)"
    jq -r '
        .runs[]
        | [
            .scenario,
            (.buildDurationMs | tostring),
            (.startupDurationMs | tostring),
            (.containerObservation.memoryBytes | tostring),
            (.containerObservation.cpuPercent | tostring),
            (.loadTest.httpReqs | tostring),
            (.loadTest.httpReqFailedRate | tostring),
            (.loadTest.p95DurationMs | tostring)
        ]
        | @tsv
    ' "$report_file" | while IFS=$'\t' read -r scenario build startup memory_bytes cpu reqs failed p95; do
        printf "%-15s %-10s %-12s %-13s %-12s %-8s %-10s %-10s\n" \
            "$scenario" "$build" "$startup" "$memory_bytes" "$cpu" "$reqs" "$failed" "$p95"
    done
} >"$summary_file"

echo "Container runtime matrix report: $report_file"
echo "Container runtime matrix summary: $summary_file"
