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
    --arg load_cases "$(compose_runtime_configured_load_cases)" \
    --argjson environment "$(benchmark_environment_json)" \
    --argjson pids_limit "$(compose_runtime_configured_pids_limit)" \
    --argjson get_seed_rows "$(compose_runtime_configured_get_seed_rows)" \
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
            duration: $duration,
            cases: ($load_cases | split(",")),
            getSeedRows: $get_seed_rows
        },
        runs: map(.run)
    }' "$output_dir"/*/report.json >"$report_file"

{
    echo "Container runtime matrix summary"
    printf "%-15s %-7s %-10s %-12s %-13s %-12s %-12s %-8s %-10s %-10s %-10s\n" "scenario" "case" "build(ms)" "startup(ms)" "memory(bytes)" "cpu_avg(%)" "cpu_max(%)" "reqs" "failed" "p95(ms)" "p95_ok(ms)"
    jq -r '
        def round_to($scale): (. * $scale | round) / $scale;
        def display_number($scale):
            if . == null then "n/a" else (round_to($scale) | tostring) end;
        def display_raw:
            if . == null then "n/a" else tostring end;
        .runs[]
        | . as $run
        | ($run.loadTest.cases | to_entries[])
        | .key as $case
        | .value as $load_case
        | ($load_case.containerObservation // {}) as $container
        | [
            $run.scenario,
            $case,
            ($run.buildDurationMs | tostring),
            ($load_case.startupDurationMs // $run.startupDurationMs | tostring),
            (($container.memoryBytes // $run.containerObservation.memoryBytes // null) | display_raw),
            (($container.cpuAvgPercent // $run.containerObservation.cpuPercent // null) | display_number(100)),
            (($container.cpuMaxPercent // $run.containerObservation.sampledCpuMaxPercent // $run.containerObservation.cpuPercent // null) | display_number(100)),
            ($load_case.httpReqs | tostring),
            (($load_case.httpReqFailedRate // null) | display_number(10000)),
            (($load_case.p95DurationMs // null) | display_number(10)),
            (($load_case.successfulP95DurationMs // null) | display_number(10))
        ]
        | @tsv
    ' "$report_file" | while IFS=$'\t' read -r scenario load_case build startup memory_bytes cpu_avg cpu_max reqs failed p95 successful_p95; do
        printf "%-15s %-7s %-10s %-12s %-13s %-12s %-12s %-8s %-10s %-10s %-10s\n" \
            "$scenario" "$load_case" "$build" "$startup" "$memory_bytes" "$cpu_avg" "$cpu_max" "$reqs" "$failed" "$p95" "$successful_p95"
    done
} >"$summary_file"

echo "Container runtime matrix report: $report_file"
echo "Container runtime matrix summary: $summary_file"
