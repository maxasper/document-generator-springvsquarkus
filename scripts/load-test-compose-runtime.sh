#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus> [output-dir]" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/compose-runtime-inspection-common.sh"

compose_runtime_require_binary docker
compose_runtime_require_binary jq

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

if ! compose_runtime_service_is_running "$service"; then
    echo "$(compose_runtime_runtime_name "$runtime") is not running." >&2
    echo "Start it first with: ./scripts/compose-runtime-up.sh $runtime" >&2
    exit 1
fi

output_dir="${2:-}"
if [[ -z "$output_dir" ]]; then
    output_dir="$(compose_runtime_prepare_load_test_output_dir "$runtime")"
else
    case "$output_dir" in
        "$repo_root"/target/runtime-load-testing/*)
            ;;
        *)
            echo "Custom output directories must be under $repo_root/target/runtime-load-testing" >&2
            exit 1
            ;;
    esac
    mkdir -p "$output_dir"
fi

summary_file="$output_dir/summary.json"
summary_text_file="$output_dir/summary.txt"
log_file="$output_dir/k6.log"
base_url="$(compose_runtime_network_base_url "$runtime")"
vus="${LOAD_TEST_VUS:-$(compose_runtime_load_test_value '.loadProfile.vus')}"
duration="${LOAD_TEST_DURATION:-$(compose_runtime_load_test_value '.loadProfile.duration')}"

mkdir -p "$output_dir"
mkdir -p "$repo_root/target/runtime-load-testing"

cd "$repo_root"

docker compose -f "$compose_runtime_compose_file" run --rm -T --no-deps \
    -e "BASE_URL=$base_url" \
    -e "LOAD_TEST_VUS=$vus" \
    -e "LOAD_TEST_DURATION=$duration" \
    k6 run /workspace/scripts/runtime-load-test.js \
    --summary-export "/results/${output_dir##*/}/summary.json" >"$log_file" 2>&1

jq -r \
    --arg runtime "$runtime" \
    --arg base_url "$base_url" \
    --arg vus "$vus" \
    --arg duration "$duration" \
    '[
        "Runtime load test summary",
        "runtime=\($runtime)",
        "baseUrl=\($base_url)",
        "vus=\($vus)",
        "duration=\($duration)",
        "iterations=\(.metrics.iterations.count // 0)",
        "http_reqs=\(.metrics.http_reqs.count // 0)",
        "http_req_failed(rate)=\(.metrics.http_req_failed.value // 0)",
        "http_req_duration(avg)=\(.metrics.http_req_duration.avg // 0)ms",
        "http_req_duration(p95)=\(.metrics.http_req_duration["p(95)"] // 0)ms"
    ] | .[]' "$summary_file" >"$summary_text_file"

echo "Load test complete for $(compose_runtime_runtime_name "$runtime")"
echo "Summary JSON: $summary_file"
echo "Summary text: $summary_text_file"
echo "k6 log: $log_file"
