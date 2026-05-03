#!/usr/bin/env bash
set -euo pipefail

compose_runtime_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
compose_runtime_repo_root="$(cd -- "$compose_runtime_script_dir/.." && pwd)"
compose_runtime_compose_file="$compose_runtime_repo_root/compose.runtime-inspection.yml"
compose_runtime_load_workload_file="$compose_runtime_repo_root/benchmarks/runtime-load-testing-workload.json"

compose_runtime_require_binary() {
    local binary="$1"
    if ! command -v "$binary" >/dev/null 2>&1; then
        echo "Required binary is missing: $binary" >&2
        return 1
    fi
}

compose_runtime_load_test_value() {
    local jq_filter="$1"
    jq --raw-output "$jq_filter" "$compose_runtime_load_workload_file"
}

compose_runtime_now_utc() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

compose_runtime_prepare_load_test_output_dir() {
    local runtime="$1"
    local output_root
    local latest_name
    local timestamp
    local run_dir

    output_root="$compose_runtime_repo_root/$(compose_runtime_load_test_value '.output.rootDirectory')"
    latest_name="$(compose_runtime_load_test_value '.output.latestSymlinkName')"
    timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
    run_dir="$output_root/${timestamp}-${runtime}"

    mkdir -p "$run_dir"
    ln -sfn "$run_dir" "$output_root/$latest_name"
    echo "$run_dir"
}

compose_runtime_runtime_name() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "Spring Boot"
            ;;
        quarkus)
            echo "Quarkus"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_module() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "document-generator-app-spring"
            ;;
        quarkus)
            echo "document-generator-app-quarkus"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_service_name() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "spring-jvm"
            ;;
        quarkus)
            echo "quarkus-jvm"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_image_reference() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "document-generator-spring-jvm-inspection:latest"
            ;;
        quarkus)
            echo "document-generator-quarkus-jvm-inspection:latest"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_host_base_url() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "http://localhost:18080"
            ;;
        quarkus)
            echo "http://localhost:18081"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_network_base_url() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "http://spring-jvm:8080"
            ;;
        quarkus)
            echo "http://quarkus-jvm:8081"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_host_jmx_port() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "${DG_SPRING_JMX_PORT:-9010}"
            ;;
        quarkus)
            echo "${DG_QUARKUS_JMX_PORT:-9011}"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_host_jmx_url() {
    local runtime="$1"
    local port

    port="$(compose_runtime_host_jmx_port "$runtime")"
    echo "service:jmx:rmi:///jndi/rmi://127.0.0.1:${port}/jmxrmi"
}

compose_runtime_service_container_id() {
    local service="$1"
    docker compose -f "$compose_runtime_compose_file" ps -q "$service"
}

compose_runtime_service_is_running() {
    local service="$1"
    local container_id
    local status

    container_id="$(compose_runtime_service_container_id "$service")"
    if [[ -z "$container_id" ]]; then
        return 1
    fi

    status="$(docker inspect --format '{{.State.Status}}' "$container_id" 2>/dev/null || true)"
    [[ "$status" == "running" ]]
}

compose_runtime_wait_for_postgres() {
    local timeout_seconds="$1"
    local start_time=$SECONDS
    local container_id=""

    while (( SECONDS - start_time < timeout_seconds )); do
        container_id="$(compose_runtime_service_container_id postgres)"
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

    echo "Timed out waiting for PostgreSQL runtime-inspection container to become healthy." >&2
    return 1
}

compose_runtime_wait_for_http() {
    local runtime="$1"
    local timeout_seconds="$2"
    local base_url
    local service
    local start_time=$SECONDS

    base_url="$(compose_runtime_host_base_url "$runtime")"
    service="$(compose_runtime_service_name "$runtime")"

    while (( SECONDS - start_time < timeout_seconds )); do
        if ! compose_runtime_service_is_running "$service"; then
            echo "$(compose_runtime_runtime_name "$runtime") exited before it became ready." >&2
            return 1
        fi

        local status
        status="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 2 "$base_url/api/v1/document-generations" || true)"
        if [[ "$status" == "200" ]]; then
            return 0
        fi

        sleep 1
    done

    echo "Timed out waiting for $(compose_runtime_runtime_name "$runtime") at $base_url" >&2
    return 1
}
