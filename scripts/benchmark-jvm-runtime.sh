#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus> [output-dir]" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
compose_file="$repo_root/compose.postgres-verification.yml"

source "$script_dir/jvm-benchmark-common.sh"

benchmark_require_binary jq
benchmark_require_binary curl
benchmark_require_binary docker
benchmark_require_binary java

runtime="${1:-}"
if [[ -z "$runtime" ]]; then
    usage
    exit 1
fi

runtime_name=""
module=""
base_url=""
launch_artifact=""
reported_artifact_path=""
java_opts=()
app_args=()
runtime_env=(
    DOCUMENT_GENERATOR_POSTGRES_HOST=localhost
    DOCUMENT_GENERATOR_POSTGRES_PORT=55432
    DOCUMENT_GENERATOR_POSTGRES_DATABASE=document_generator
    DOCUMENT_GENERATOR_POSTGRES_USER=document_generator
    DOCUMENT_GENERATOR_POSTGRES_PASSWORD=document_generator
)

case "$runtime" in
    spring)
        runtime_name="Spring Boot"
        module="document-generator-app-spring"
        base_url="http://localhost:18080"
        app_args+=(--spring.profiles.active=postgres)
        app_args+=(--server.port=18080)
        ;;
    quarkus)
        runtime_name="Quarkus"
        module="document-generator-app-quarkus"
        base_url="http://localhost:18081"
        launch_artifact="$repo_root/$module/target/quarkus-app/quarkus-run.jar"
        reported_artifact_path="$repo_root/$module/target/quarkus-app"
        java_opts+=(-Dquarkus.profile=postgres)
        java_opts+=(-Dquarkus.http.port=18081)
        ;;
    *)
        usage
        exit 1
        ;;
esac

output_dir="${2:-}"
if [[ -z "$output_dir" ]]; then
    output_dir="$(benchmark_prepare_output_dir "$runtime")"
else
    mkdir -p "$output_dir"
fi

log_file="$(mktemp "/tmp/${runtime}-jvm-benchmark.XXXX.log")"
app_pid=""

cleanup() {
    local exit_code=$?

    if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi

    docker compose -f "$compose_file" down -v --remove-orphans >/dev/null 2>&1 || true

    mkdir -p "$output_dir"
    mv "$log_file" "$output_dir/runtime.log" 2>/dev/null || true

    if [[ $exit_code -ne 0 ]]; then
        echo "$runtime_name JVM benchmark failed. Output directory: $output_dir" >&2
        echo "--- $runtime_name benchmark log ---" >&2
        tail -n 200 "$output_dir/runtime.log" >&2 || true
    fi
}

wait_for_runtime() {
    local health_url="$1"
    local timeout_seconds="$2"
    local start_time=$SECONDS

    while (( SECONDS - start_time < timeout_seconds )); do
        if ! kill -0 "$app_pid" 2>/dev/null; then
            echo "$runtime_name exited before it became ready." >&2
            return 1
        fi

        local status
        status="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 2 "$health_url" || true)"
        if [[ "$status" == "200" ]]; then
            return 0
        fi

        sleep 1
    done

    echo "Timed out waiting for $runtime_name at $health_url" >&2
    return 1
}

wait_for_postgres() {
    local timeout_seconds="$1"
    local start_time=$SECONDS
    local container_id=""

    while (( SECONDS - start_time < timeout_seconds )); do
        container_id="$(docker compose -f "$compose_file" ps -q postgres)"
        if [[ -n "$container_id" ]]; then
            local status
            status="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$container_id" 2>/dev/null || true)"
            case "$status" in
                healthy)
                    return 0
                    ;;
                exited|dead)
                    echo "PostgreSQL container exited before becoming healthy." >&2
                    return 1
                    ;;
            esac
        fi
        sleep 1
    done

    echo "Timed out waiting for PostgreSQL benchmark container to become healthy." >&2
    return 1
}

build_generate_request_body() {
    local request_id="$1"
    local document_format
    local template_type
    local document_name_prefix
    local customer_name
    local invoice_number_prefix
    local amount

    document_format="$(benchmark_load_workload_value '.requestTemplate.documentFormat')"
    template_type="$(benchmark_load_workload_value '.requestTemplate.templateType')"
    document_name_prefix="$(benchmark_load_workload_value '.requestTemplate.documentNamePrefix')"
    customer_name="$(benchmark_load_workload_value '.requestTemplate.parameters.customerName')"
    invoice_number_prefix="$(benchmark_load_workload_value '.requestTemplate.parameters.invoiceNumberPrefix')"
    amount="$(benchmark_load_workload_value '.requestTemplate.parameters.amount')"

    jq -n \
        --arg document_format "$document_format" \
        --arg template_type "$template_type" \
        --arg document_name "${document_name_prefix}-${runtime}-${request_id}" \
        --arg customer_name "$customer_name" \
        --arg invoice_number "${invoice_number_prefix}-${runtime}-${request_id}" \
        --arg amount "$amount" \
        '{
            documentFormat: $document_format,
            templateType: $template_type,
            documentName: $document_name,
            parameters: {
                customerName: $customer_name,
                invoiceNumber: $invoice_number,
                amount: $amount
            }
        }'
}

record_generate_latency_ms() {
    local request_id="$1"
    local response_file
    local curl_output
    local status_code
    local duration_seconds
    local duration_ms
    local generate_path
    local request_body

    response_file="$(mktemp "/tmp/${runtime}-generate-response.XXXX.json")"
    generate_path="$(benchmark_load_workload_value '.endpoints.generate.path')"
    request_body="$(build_generate_request_body "$request_id")"

    curl_output="$(curl \
        --silent \
        --show-error \
        --output "$response_file" \
        --write-out '%{http_code} %{time_total}' \
        --max-time 15 \
        --header 'Content-Type: application/json' \
        --request POST \
        --data "$request_body" \
        "$base_url$generate_path"
    )"

    status_code="${curl_output%% *}"
    duration_seconds="${curl_output##* }"

    if [[ "$status_code" != "200" ]]; then
        echo "Unexpected generate status: $status_code" >&2
        cat "$response_file" >&2
        rm -f "$response_file"
        return 1
    fi

    duration_ms="$(awk -v value="$duration_seconds" 'BEGIN { printf "%d", (value * 1000) + 0.5 }')"
    rm -f "$response_file"
    echo "$duration_ms"
}

record_history_latency_ms() {
    local response_file
    local curl_output
    local status_code
    local duration_seconds
    local duration_ms
    local history_path

    response_file="$(mktemp "/tmp/${runtime}-history-response.XXXX.json")"
    history_path="$(benchmark_load_workload_value '.endpoints.history.path')"

    curl_output="$(curl \
        --silent \
        --show-error \
        --output "$response_file" \
        --write-out '%{http_code} %{time_total}' \
        --max-time 15 \
        "$base_url$history_path"
    )"

    status_code="${curl_output%% *}"
    duration_seconds="${curl_output##* }"

    if [[ "$status_code" != "200" ]]; then
        echo "Unexpected history status: $status_code" >&2
        cat "$response_file" >&2
        rm -f "$response_file"
        return 1
    fi

    duration_ms="$(awk -v value="$duration_seconds" 'BEGIN { printf "%d", (value * 1000) + 0.5 }')"
    rm -f "$response_file"
    echo "$duration_ms"
}

write_runtime_report() {
    local report_file="$1"
    local artifact_path="$2"
    local build_duration_ms="$3"
    local artifact_size_bytes="$4"
    local startup_duration_ms="$5"
    local steady_state_rss_kb="$6"
    local generate_summary_json="$7"
    local history_summary_json="$8"
    local environment_json

    environment_json="$(benchmark_environment_json)"

    jq -n \
        --arg generated_at "$(benchmark_now_utc)" \
        --arg workload_file "benchmarks/jvm-runtime-comparison-workload.json" \
        --arg runtime "$runtime" \
        --arg mode "$(benchmark_load_workload_value '.runtimeMode')" \
        --arg base_url "$base_url" \
        --arg artifact_path "$artifact_path" \
        --arg output_directory "$output_dir" \
        --argjson build_duration_ms "$build_duration_ms" \
        --argjson artifact_size_bytes "$artifact_size_bytes" \
        --argjson startup_duration_ms "$startup_duration_ms" \
        --argjson steady_state_rss_kb "$steady_state_rss_kb" \
        --argjson environment "$environment_json" \
        --argjson generate_latency "$generate_summary_json" \
        --argjson history_latency "$history_summary_json" \
        '{
            schemaVersion: 1,
            benchmarkName: "jvm-runtime-comparison",
            generatedAtUtc: $generated_at,
            workloadFile: $workload_file,
            environment: $environment,
            runs: [
                {
                    runtime: $runtime,
                    mode: $mode,
                    baseUrl: $base_url,
                    artifactPath: $artifact_path,
                    outputDirectory: $output_directory,
                    buildDurationMs: $build_duration_ms,
                    artifactSizeBytes: $artifact_size_bytes,
                    startupDurationMs: $startup_duration_ms,
                    steadyStateRssKb: $steady_state_rss_kb,
                    generateLatencyMs: $generate_latency,
                    historyLatencyMs: $history_latency
                }
            ]
        }' >"$report_file"
}

trap cleanup EXIT

cd "$repo_root"
mkdir -p "$output_dir"

echo "Packaging $runtime_name runtime"
build_start_ms="$(benchmark_epoch_ms)"
./mvnw -q -Dmaven.repo.local=.mvn/repository -pl "$module" -am package -DskipTests
build_end_ms="$(benchmark_epoch_ms)"
build_duration_ms="$(benchmark_duration_ms "$build_start_ms" "$build_end_ms")"

if [[ "$runtime" == "spring" ]]; then
    launch_artifact="$(find "$repo_root/$module/target" -maxdepth 1 -type f -name '*.jar' ! -name '*original' | sort | head -n 1)"
    reported_artifact_path="$launch_artifact"
fi

if [[ -z "$launch_artifact" || ! -f "$launch_artifact" ]]; then
    echo "Expected runtime launch artifact is missing: $launch_artifact" >&2
    exit 1
fi

if [[ -z "$reported_artifact_path" || ! -e "$reported_artifact_path" ]]; then
    echo "Expected packaged runtime artifact is missing: $reported_artifact_path" >&2
    exit 1
fi

artifact_size_bytes="$(benchmark_measure_artifact_size_bytes "$reported_artifact_path")"

echo "Starting PostgreSQL benchmark environment"
docker compose -f "$compose_file" down -v --remove-orphans >/dev/null 2>&1 || true
docker compose -f "$compose_file" up -d
wait_for_postgres "$(benchmark_load_workload_value '.readiness.timeoutSeconds')"

echo "Starting $runtime_name on $base_url"
startup_begin_ms="$(benchmark_epoch_ms)"
env "${runtime_env[@]}" java "${java_opts[@]}" -jar "$launch_artifact" "${app_args[@]}" >"$log_file" 2>&1 &
app_pid=$!
wait_for_runtime \
    "$base_url$(benchmark_load_workload_value '.readiness.path')" \
    "$(benchmark_load_workload_value '.readiness.timeoutSeconds')"
startup_end_ms="$(benchmark_epoch_ms)"
startup_duration_ms="$(benchmark_duration_ms "$startup_begin_ms" "$startup_end_ms")"

warmup_generate_iterations="$(benchmark_load_workload_value '.warmup.generateIterations')"
warmup_history_iterations="$(benchmark_load_workload_value '.warmup.historyIterations')"
measurement_generate_iterations="$(benchmark_load_workload_value '.measurement.generateIterations')"
measurement_history_iterations="$(benchmark_load_workload_value '.measurement.historyIterations')"

echo "Running warmup requests for $runtime_name"
for iteration in $(seq 1 "$warmup_generate_iterations"); do
    record_generate_latency_ms "warmup-$iteration" >/dev/null
done
for iteration in $(seq 1 "$warmup_history_iterations"); do
    record_history_latency_ms >/dev/null
done

echo "Running measured requests for $runtime_name"
generate_durations=()
history_durations=()

for iteration in $(seq 1 "$measurement_generate_iterations"); do
    generate_durations+=("$(record_generate_latency_ms "measure-$iteration")")
done
for iteration in $(seq 1 "$measurement_history_iterations"); do
    history_durations+=("$(record_history_latency_ms)")
done

steady_state_rss_kb="$(benchmark_measure_rss_kb "$app_pid")"
generate_summary_json="$(benchmark_latency_summary_json "${generate_durations[@]}")"
history_summary_json="$(benchmark_latency_summary_json "${history_durations[@]}")"

write_runtime_report \
    "$output_dir/report.json" \
    "$reported_artifact_path" \
    "$build_duration_ms" \
    "$artifact_size_bytes" \
    "$startup_duration_ms" \
    "$steady_state_rss_kb" \
    "$generate_summary_json" \
    "$history_summary_json"

echo "$runtime_name JVM benchmark complete"
echo "Report: $output_dir/report.json"
