#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus> [jvm|native] [output-dir]" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/compose-runtime-inspection-common.sh"

compose_runtime_require_binary docker
compose_runtime_require_binary jq

runtime="${1:-}"
shift || true

if [[ -z "$runtime" ]]; then
    usage
    exit 1
fi

compose_runtime_validate_runtime "$runtime" >/dev/null || {
    usage
    exit 1
}

mode="$(compose_runtime_default_mode)"
if [[ $# -gt 0 ]]; then
    case "$1" in
        jvm|native)
            mode="$1"
            shift
            ;;
    esac
fi

compose_runtime_validate_mode "$mode" >/dev/null || {
    usage
    exit 1
}

if [[ $# -gt 1 ]]; then
    usage
    exit 1
fi

service="$(compose_runtime_service_name "$runtime" "$mode")"

if ! compose_runtime_service_is_running "$service"; then
    echo "$(compose_runtime_scenario_display_name "$runtime" "$mode") is not running." >&2
    echo "Start it first with: ./scripts/compose-runtime-up.sh $runtime $mode" >&2
    exit 1
fi

output_dir="${1:-}"
if [[ -z "$output_dir" ]]; then
    output_dir="$(compose_runtime_prepare_load_test_output_dir "$runtime" "$mode")"
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

summary_file="$output_dir/summary.json"
summary_text_file="$output_dir/summary.txt"
case_entries_file="$output_dir/cases.jsonl"
base_url="$(compose_runtime_network_base_url "$runtime" "$mode")"
scenario_name="$(compose_runtime_scenario_name "$runtime" "$mode")"
vus="$(compose_runtime_configured_vus)"
duration="$(compose_runtime_configured_duration)"

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

mkdir -p "$output_dir"
mkdir -p "$repo_root/target"
: >"$case_entries_file"

cd "$repo_root"

stop_case_stats_sampling() {
    local stats_pid="$1"

    if [[ -n "$stats_pid" ]] && kill -0 "$stats_pid" >/dev/null 2>&1; then
        kill "$stats_pid" >/dev/null 2>&1 || true
        wait "$stats_pid" >/dev/null 2>&1 || true
    fi
}

sample_case_stats() {
    local container_id="$1"
    local output_file="$2"

    docker stats --format '{{.CPUPerc}} {{.MemUsage}}' "$container_id" >"$output_file" 2>/dev/null &
    echo "$!"
}

sampled_case_cpu_avg_percent() {
    local stats_file="$1"

    awk '
        NF >= 1 {
            cpu = $1
            gsub(/\033\[[0-9;]*[[:alpha:]]/, "", cpu)
            gsub(/%/, "", cpu)
            if (cpu != "") {
                cpu += 0
                total += cpu
                count += 1
            }
        }
        END {
            if (count == 0) {
                print "null"
            } else {
                printf "%.2f\n", total / count
            }
        }
    ' "$stats_file"
}

sampled_case_cpu_max_percent() {
    local stats_file="$1"

    awk '
        NF >= 1 {
            cpu = $1
            gsub(/\033\[[0-9;]*[[:alpha:]]/, "", cpu)
            gsub(/%/, "", cpu)
            if (cpu != "") {
                cpu += 0
                if (count == 0 || cpu > max) {
                    max = cpu
                }
                count += 1
            }
        }
        END {
            if (count == 0) {
                print "null"
            } else {
                printf "%.2f\n", max
            }
        }
    ' "$stats_file"
}

sampled_case_memory_max_bytes() {
    local stats_file="$1"

    awk '
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
        NF >= 2 {
            raw = $2
            match(raw, /^([0-9.]+)([[:alpha:]]+)$/, parts)
            if (parts[1] != "") {
                bytes = parts[1] * unit_multiplier(parts[2])
                if (bytes > max) {
                    max = bytes
                    count += 1
                }
            }
        }
        END {
            if (count == 0) {
                print "null"
            } else {
                printf "%d\n", max + 0.5
            }
        }
    ' "$stats_file"
}

case_output_dir() {
    local load_test_case="$1"

    if [[ -n "${LOAD_TEST_CASE:-}" ]]; then
        echo "$output_dir"
    else
        echo "$output_dir/$load_test_case"
    fi
}

for load_test_case in "${load_test_cases[@]}"; do
    current_case_output_dir="$(case_output_dir "$load_test_case")"
    case_results_relative_path="${current_case_output_dir#"$repo_root/target/"}"
    case_summary_file="$current_case_output_dir/k6-summary.json"
    case_log_file="$current_case_output_dir/k6.log"
    case_stats_file="$current_case_output_dir/container-stats.log"
    case_observation_file="$current_case_output_dir/container-observation.json"
    runtime_container_id="$(compose_runtime_service_container_id "$service")"
    stats_pid=""

    mkdir -p "$current_case_output_dir"
    : >"$case_stats_file"

    if [[ -n "$runtime_container_id" ]]; then
        stats_pid="$(sample_case_stats "$runtime_container_id" "$case_stats_file")"
    fi

    set +e
    docker compose -f "$compose_runtime_compose_file" run --rm -T --no-deps \
        -e "BASE_URL=$base_url" \
        -e "LOAD_TEST_VUS=$vus" \
        -e "LOAD_TEST_DURATION=$duration" \
        -e "LOAD_TEST_CASE=$load_test_case" \
        k6 run /workspace/scripts/runtime-load-test.js \
        --summary-export "/results/${case_results_relative_path}/k6-summary.json" >"$case_log_file" 2>&1
    k6_exit_code=$?
    set -e
    stop_case_stats_sampling "$stats_pid"

    jq -n \
        --arg stats_file "$case_stats_file" \
        --argjson memory_bytes "$(sampled_case_memory_max_bytes "$case_stats_file")" \
        --argjson cpu_avg_percent "$(sampled_case_cpu_avg_percent "$case_stats_file")" \
        --argjson cpu_max_percent "$(sampled_case_cpu_max_percent "$case_stats_file")" \
        '{
            statsFile: $stats_file,
            memoryBytes: $memory_bytes,
            cpuAvgPercent: $cpu_avg_percent,
            cpuMaxPercent: $cpu_max_percent
        }' >"$case_observation_file"

    if [[ $k6_exit_code -ne 0 ]]; then
        if [[ -f "$case_summary_file" ]] && grep -q "thresholds on metrics .* have been crossed" "$case_log_file"; then
            echo "k6 thresholds were crossed; preserving benchmark summary and continuing." >>"$case_log_file"
        else
            exit "$k6_exit_code"
        fi
    fi

    jq -n \
        --arg key "$load_test_case" \
        --arg summary_file "$case_summary_file" \
        --arg log_file "$case_log_file" \
        --slurpfile summary "$case_summary_file" \
        --slurpfile observation "$case_observation_file" \
        '{
            key: $key,
            value: {
                summaryFile: $summary_file,
                logFile: $log_file,
                containerObservation: $observation[0],
                metrics: $summary[0].metrics,
                checks: ($summary[0].root_group.checks // [])
            }
        }' >>"$case_entries_file"
done

jq -s \
    '{
        schemaVersion: 1,
        cases: (map({(.key): .value}) | add)
    }' "$case_entries_file" >"$summary_file"

jq -r \
    --arg runtime "$runtime" \
    --arg mode "$mode" \
    --arg scenario "$scenario_name" \
    --arg base_url "$base_url" \
    --arg vus "$vus" \
    --arg duration "$duration" \
    '
    def round_to($scale): (. * $scale | round) / $scale;
    def display_number($scale):
        if . == null then "n/a" else (round_to($scale) | tostring) end;
    [
        "Runtime load test summary",
        "runtime=\($runtime)",
        "mode=\($mode)",
        "scenario=\($scenario)",
        "baseUrl=\($base_url)",
        "vus=\($vus)",
        "duration_per_case=\($duration)",
        "",
        "case           cpu_avg(%) cpu_max(%) iterations reqs     failed     avg(ms)    p95(ms)    p95_ok(ms)",
        (
            .cases
            | to_entries[]
            | .key as $case
            | .value.containerObservation as $container
            | .value.metrics as $metrics
            | ($metrics["http_req_duration{expected_response:true}"] // null) as $successful
            | [
                $case,
                (($container.cpuAvgPercent // null) | display_number(100)),
                (($container.cpuMaxPercent // null) | display_number(100)),
                ($metrics.iterations.count // 0 | tostring),
                ($metrics.http_reqs.count // 0 | tostring),
                (($metrics.http_req_failed.value // null) | display_number(10000)),
                (($metrics.http_req_duration.avg // null) | display_number(10)),
                (($metrics.http_req_duration["p(95)"] // null) | display_number(10)),
                (($successful["p(95)"] // null) | display_number(10))
            ]
            | @tsv
        )
    ] | .[]' "$summary_file" | while IFS=$'\t' read -r case_name cpu_avg cpu_max iterations reqs failed avg p95 successful_p95; do
        if [[ -z "${iterations:-}" ]]; then
            echo "$case_name"
        else
            printf "%-14s %-10s %-10s %-10s %-8s %-10s %-10s %-10s %-10s\n" \
                "$case_name" "$cpu_avg" "$cpu_max" "$iterations" "$reqs" "$failed" "$avg" "$p95" "$successful_p95"
        fi
    done >"$summary_text_file"

echo "Load test complete for $(compose_runtime_scenario_display_name "$runtime" "$mode")"
echo "Summary JSON: $summary_file"
echo "Summary text: $summary_text_file"
echo "k6 logs: $output_dir"
