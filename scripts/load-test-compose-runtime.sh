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
log_file="$output_dir/k6.log"
base_url="$(compose_runtime_network_base_url "$runtime" "$mode")"
scenario_name="$(compose_runtime_scenario_name "$runtime" "$mode")"
results_relative_path="${output_dir#"$repo_root/target/"}"
vus="$(compose_runtime_configured_vus)"
duration="$(compose_runtime_configured_duration)"

mkdir -p "$output_dir"
mkdir -p "$repo_root/target"

cd "$repo_root"

set +e
docker compose -f "$compose_runtime_compose_file" run --rm -T --no-deps \
    -e "BASE_URL=$base_url" \
    -e "LOAD_TEST_VUS=$vus" \
    -e "LOAD_TEST_DURATION=$duration" \
    k6 run /workspace/scripts/runtime-load-test.js \
    --summary-export "/results/${results_relative_path}/summary.json" >"$log_file" 2>&1
k6_exit_code=$?
set -e

if [[ $k6_exit_code -ne 0 ]]; then
    if [[ -f "$summary_file" ]] && grep -q "thresholds on metrics .* have been crossed" "$log_file"; then
        echo "k6 thresholds were crossed; preserving benchmark summary and continuing." >>"$log_file"
    else
        exit "$k6_exit_code"
    fi
fi

jq -r \
    --arg runtime "$runtime" \
    --arg mode "$mode" \
    --arg scenario "$scenario_name" \
    --arg base_url "$base_url" \
    --arg vus "$vus" \
    --arg duration "$duration" \
    '[
        "Runtime load test summary",
        "runtime=\($runtime)",
        "mode=\($mode)",
        "scenario=\($scenario)",
        "baseUrl=\($base_url)",
        "vus=\($vus)",
        "duration=\($duration)",
        "iterations=\(.metrics.iterations.count // 0)",
        "http_reqs=\(.metrics.http_reqs.count // 0)",
        "http_req_failed(rate)=\(.metrics.http_req_failed.value // 0)",
        "http_req_duration(avg)=\(.metrics.http_req_duration.avg // 0)ms",
        "http_req_duration(p95)=\(.metrics.http_req_duration["p(95)"] // 0)ms",
        "http_req_duration_successful(avg)=\(.metrics["http_req_duration{expected_response:true}"].avg // 0)ms",
        "http_req_duration_successful(p95)=\(.metrics["http_req_duration{expected_response:true}"]["p(95)"] // 0)ms"
    ] | .[]' "$summary_file" >"$summary_text_file"

echo "Load test complete for $(compose_runtime_scenario_display_name "$runtime" "$mode")"
echo "Summary JSON: $summary_file"
echo "Summary text: $summary_text_file"
echo "k6 log: $log_file"
