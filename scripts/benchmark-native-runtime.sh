#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus> [output-dir]" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
compose_file="$repo_root/compose.postgres-verification.yml"

source "$script_dir/native-benchmark-common.sh"

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
runtime_env=()
runtime_port=""
image_reference=""
container_name=""
build_strategy_kind=""
builder_reference=""
runtime_base_image=""
build_command_string=""
artifact_type="$(benchmark_load_workload_value '.artifact.type')"

spring_builder_reference="paketobuildpacks/builder-noble-java-tiny:latest"
quarkus_builder_reference="quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-25"
quarkus_runtime_base_image="quay.io/quarkus/ubi9-quarkus-micro-image:2.0"

case "$runtime" in
    spring)
        runtime_name="Spring Boot"
        module="document-generator-app-spring"
        base_url="http://localhost:18080"
        runtime_port="8080"
        image_reference="document-generator-spring-native-benchmark:latest"
        container_name="document-generator-spring-native-benchmark"
        build_strategy_kind="spring-boot-buildpacks"
        builder_reference="$spring_builder_reference"
        runtime_base_image="builder-managed"
        runtime_env+=(
            SPRING_PROFILES_ACTIVE=postgres
            DOCUMENT_GENERATOR_POSTGRES_HOST=postgres
            DOCUMENT_GENERATOR_POSTGRES_PORT=5432
            DOCUMENT_GENERATOR_POSTGRES_DATABASE=document_generator
            DOCUMENT_GENERATOR_POSTGRES_USER=document_generator
            DOCUMENT_GENERATOR_POSTGRES_PASSWORD=document_generator
        )
        build_command_string="./mvnw -q -Dmaven.repo.local=.mvn/repository -pl $module -am -DskipTests install -Pnative && ./mvnw -q -Dmaven.repo.local=.mvn/repository -pl $module -DskipTests -Pnative spring-boot:build-image -Dspring-boot.build-image.imageName=$image_reference -Dspring-boot.build-image.builder=$builder_reference -Dspring-boot.build-image.pullPolicy=IF_NOT_PRESENT"
        ;;
    quarkus)
        runtime_name="Quarkus"
        module="document-generator-app-quarkus"
        base_url="http://localhost:18081"
        runtime_port="8081"
        image_reference="document-generator-quarkus-native-benchmark:latest"
        container_name="document-generator-quarkus-native-benchmark"
        build_strategy_kind="quarkus-native-container-build"
        builder_reference="$quarkus_builder_reference"
        runtime_base_image="$quarkus_runtime_base_image"
        runtime_env+=(
            QUARKUS_PROFILE=postgres
            DOCUMENT_GENERATOR_POSTGRES_HOST=postgres
            DOCUMENT_GENERATOR_POSTGRES_PORT=5432
            DOCUMENT_GENERATOR_POSTGRES_DATABASE=document_generator
            DOCUMENT_GENERATOR_POSTGRES_USER=document_generator
            DOCUMENT_GENERATOR_POSTGRES_PASSWORD=document_generator
        )
        build_command_string="./mvnw -q -Dmaven.repo.local=.mvn/repository -pl $module -am -DskipTests package -Dquarkus.profile=postgres -Dquarkus.native.enabled=true -Dquarkus.native.container-build=true -Dquarkus.native.container-runtime=docker -Dquarkus.native.builder-image=$builder_reference && docker build -f src/main/docker/Dockerfile.native-micro -t $image_reference ."
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

log_file="$(mktemp "/tmp/${runtime}-native-benchmark.XXXX.log")"
postgres_network_name=""

cleanup() {
    local exit_code=$?
    mkdir -p "$output_dir"
    native_benchmark_capture_container_logs "$container_name" "$output_dir/runtime.log"
    native_benchmark_remove_container_if_present "$container_name"

    docker compose -f "$compose_file" down -v --remove-orphans >/dev/null 2>&1 || true

    rm -f "$log_file"

    if [[ $exit_code -ne 0 ]]; then
        echo "$runtime_name native benchmark failed. Output directory: $output_dir" >&2
        echo "--- $runtime_name native benchmark log ---" >&2
        tail -n 200 "$output_dir/runtime.log" >&2 || true
    fi
}

wait_for_runtime() {
    local health_url="$1"
    local timeout_seconds="$2"
    local start_time=$SECONDS

    while (( SECONDS - start_time < timeout_seconds )); do
        if ! native_benchmark_container_is_running "$container_name"; then
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
        container_id="$(native_benchmark_postgres_container_id "$compose_file")"
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

    echo "Timed out waiting for PostgreSQL native benchmark container to become healthy." >&2
    return 1
}

build_runtime_artifact() {
    case "$runtime" in
        spring)
            ./mvnw \
                -q \
                -Dmaven.repo.local=.mvn/repository \
                -pl "$module" \
                -am \
                -DskipTests \
                install \
                -Pnative
            ./mvnw \
                -q \
                -Dmaven.repo.local=.mvn/repository \
                -pl "$module" \
                -DskipTests \
                -Pnative \
                spring-boot:build-image \
                "-Dspring-boot.build-image.imageName=$image_reference" \
                "-Dspring-boot.build-image.builder=$builder_reference" \
                -Dspring-boot.build-image.pullPolicy=IF_NOT_PRESENT
            ;;
        quarkus)
            ./mvnw \
                -q \
                -Dmaven.repo.local=.mvn/repository \
                -pl "$module" \
                -am \
                -DskipTests \
                package \
                -Dquarkus.profile=postgres \
                -Dquarkus.native.enabled=true \
                -Dquarkus.native.container-build=true \
                -Dquarkus.native.container-runtime=docker \
                "-Dquarkus.native.builder-image=$builder_reference"
            docker build \
                -f "$repo_root/$module/src/main/docker/Dockerfile.native-micro" \
                -t "$image_reference" \
                "$repo_root/$module"
            ;;
    esac
}

start_runtime_container() {
    local docker_args=(
        --detach
        --name "$container_name"
        --network "$postgres_network_name"
        --publish "${base_url##*:}:$runtime_port"
    )

    local env_var
    for env_var in "${runtime_env[@]}"; do
        docker_args+=(--env "$env_var")
    done

    native_benchmark_remove_container_if_present "$container_name"
    docker run "${docker_args[@]}" "$image_reference" >/dev/null
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

    response_file="$(mktemp "/tmp/${runtime}-native-generate-response.XXXX.json")"
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

    response_file="$(mktemp "/tmp/${runtime}-native-history-response.XXXX.json")"
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
    local contract_verification_duration_ms="$2"
    local build_duration_ms="$3"
    local artifact_size_bytes="$4"
    local startup_duration_ms="$5"
    local steady_state_memory_bytes="$6"
    local generate_summary_json="$7"
    local history_summary_json="$8"
    local environment_json
    local build_strategy_json

    environment_json="$(benchmark_environment_json)"
    build_strategy_json="$(jq -n \
        --arg kind "$build_strategy_kind" \
        --arg build_command "$build_command_string" \
        --arg builder_reference "$builder_reference" \
        --arg runtime_base_image "$runtime_base_image" \
        --arg artifact_type "$artifact_type" \
        --arg artifact_reference "$image_reference" \
        '{
            kind: $kind,
            buildCommand: $build_command,
            builderReference: $builder_reference,
            runtimeBaseImage: $runtime_base_image,
            artifactType: $artifact_type,
            artifactReference: $artifact_reference
        }'
    )"

    jq -n \
        --arg generated_at "$(benchmark_now_utc)" \
        --arg workload_file "benchmarks/native-image-comparison-workload.json" \
        --arg runtime "$runtime" \
        --arg mode "$(benchmark_load_workload_value '.runtimeMode')" \
        --arg base_url "$base_url" \
        --arg artifact_reference "$image_reference" \
        --arg output_directory "$output_dir" \
        --argjson contract_verification_duration_ms "$contract_verification_duration_ms" \
        --argjson build_duration_ms "$build_duration_ms" \
        --argjson artifact_size_bytes "$artifact_size_bytes" \
        --argjson startup_duration_ms "$startup_duration_ms" \
        --argjson steady_state_memory_bytes "$steady_state_memory_bytes" \
        --argjson environment "$environment_json" \
        --argjson build_strategy "$build_strategy_json" \
        --argjson generate_latency "$generate_summary_json" \
        --argjson history_latency "$history_summary_json" \
        '{
            schemaVersion: 1,
            benchmarkName: "native-image-comparison",
            generatedAtUtc: $generated_at,
            workloadFile: $workload_file,
            environment: $environment,
            runs: [
                {
                    runtime: $runtime,
                    mode: $mode,
                    baseUrl: $base_url,
                    artifactReference: $artifact_reference,
                    outputDirectory: $output_directory,
                    buildStrategy: $build_strategy,
                    contractVerification: {
                        passed: true,
                        durationMs: $contract_verification_duration_ms
                    },
                    buildDurationMs: $build_duration_ms,
                    artifactSizeBytes: $artifact_size_bytes,
                    startupDurationMs: $startup_duration_ms,
                    steadyStateMemoryBytes: $steady_state_memory_bytes,
                    generateLatencyMs: $generate_latency,
                    historyLatencyMs: $history_latency
                }
            ]
        }' >"$report_file"
}

trap cleanup EXIT

cd "$repo_root"
mkdir -p "$output_dir"

echo "Building $runtime_name native delivery artifact"
build_start_ms="$(benchmark_epoch_ms)"
build_runtime_artifact
build_end_ms="$(benchmark_epoch_ms)"
build_duration_ms="$(benchmark_duration_ms "$build_start_ms" "$build_end_ms")"
artifact_size_bytes="$(native_benchmark_image_size_bytes "$image_reference")"

echo "Starting PostgreSQL benchmark environment"
docker compose -f "$compose_file" down -v --remove-orphans >/dev/null 2>&1 || true
docker compose -f "$compose_file" up -d
wait_for_postgres "$(benchmark_load_workload_value '.readiness.timeoutSeconds')"
postgres_network_name="$(native_benchmark_postgres_network_name "$compose_file")"

if [[ -z "$postgres_network_name" ]]; then
    echo "Could not resolve PostgreSQL Docker network." >&2
    exit 1
fi

echo "Starting $runtime_name native runtime container on $base_url"
startup_begin_ms="$(benchmark_epoch_ms)"
start_runtime_container
wait_for_runtime \
    "$base_url$(benchmark_load_workload_value '.readiness.path')" \
    "$(benchmark_load_workload_value '.readiness.timeoutSeconds')"
startup_end_ms="$(benchmark_epoch_ms)"
startup_duration_ms="$(benchmark_duration_ms "$startup_begin_ms" "$startup_end_ms")"

echo "Running shared contract verification against $runtime_name"
contract_verification_start_ms="$(benchmark_epoch_ms)"
"$repo_root/scripts/run-contract-tests.sh" "$base_url"
contract_verification_end_ms="$(benchmark_epoch_ms)"
contract_verification_duration_ms="$(benchmark_duration_ms "$contract_verification_start_ms" "$contract_verification_end_ms")"

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

steady_state_memory_bytes="$(native_benchmark_container_memory_bytes "$container_name")"
generate_summary_json="$(benchmark_latency_summary_json "${generate_durations[@]}")"
history_summary_json="$(benchmark_latency_summary_json "${history_durations[@]}")"

write_runtime_report \
    "$output_dir/report.json" \
    "$contract_verification_duration_ms" \
    "$build_duration_ms" \
    "$artifact_size_bytes" \
    "$startup_duration_ms" \
    "$steady_state_memory_bytes" \
    "$generate_summary_json" \
    "$history_summary_json"

echo "$runtime_name native benchmark complete"
echo "Report: $output_dir/report.json"
