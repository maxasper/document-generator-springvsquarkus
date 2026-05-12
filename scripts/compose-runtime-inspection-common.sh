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

compose_runtime_epoch_ms() {
    date +%s%3N
}

compose_runtime_duration_ms() {
    local start_ms="$1"
    local end_ms="$2"
    echo $(( end_ms - start_ms ))
}

compose_runtime_default_mode() {
    echo "jvm"
}

compose_runtime_validate_runtime() {
    local runtime="$1"
    case "$runtime" in
        spring|quarkus)
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_validate_mode() {
    local mode="$1"
    case "$mode" in
        jvm|native)
            ;;
        *)
            echo "Unsupported mode: $mode" >&2
            return 1
            ;;
    esac
}

compose_runtime_scenario_name() {
    local runtime="$1"
    local mode="$2"
    compose_runtime_validate_runtime "$runtime" >/dev/null
    compose_runtime_validate_mode "$mode" >/dev/null
    echo "${runtime}-${mode}"
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

compose_runtime_mode_name() {
    local mode="$1"
    case "$mode" in
        jvm)
            echo "JVM"
            ;;
        native)
            echo "Native"
            ;;
        *)
            echo "Unsupported mode: $mode" >&2
            return 1
            ;;
    esac
}

compose_runtime_scenario_display_name() {
    local runtime="$1"
    local mode="$2"
    echo "$(compose_runtime_runtime_name "$runtime") $(compose_runtime_mode_name "$mode")"
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
    local mode="$2"
    compose_runtime_scenario_name "$runtime" "$mode"
}

compose_runtime_image_reference() {
    local runtime="$1"
    local mode="$2"
    echo "document-generator-$(compose_runtime_scenario_name "$runtime" "$mode")-inspection:latest"
}

compose_runtime_build_strategy_kind() {
    local runtime="$1"
    local mode="$2"
    case "$(compose_runtime_scenario_name "$runtime" "$mode")" in
        spring-jvm)
            echo "spring-jvm-dockerfile"
            ;;
        quarkus-jvm)
            echo "quarkus-jvm-dockerfile"
            ;;
        spring-native)
            echo "spring-native-buildpacks"
            ;;
        quarkus-native)
            echo "quarkus-native-container-build"
            ;;
        *)
            echo "Unsupported runtime scenario: $runtime $mode" >&2
            return 1
            ;;
    esac
}

compose_runtime_host_http_port() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "18080"
            ;;
        quarkus)
            echo "18081"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_container_http_port() {
    local runtime="$1"
    case "$runtime" in
        spring)
            echo "8080"
            ;;
        quarkus)
            echo "8081"
            ;;
        *)
            echo "Unsupported runtime: $runtime" >&2
            return 1
            ;;
    esac
}

compose_runtime_host_base_url() {
    local runtime="$1"
    local mode="${2:-$(compose_runtime_default_mode)}"
    compose_runtime_validate_mode "$mode" >/dev/null
    echo "http://localhost:$(compose_runtime_host_http_port "$runtime")"
}

compose_runtime_network_base_url() {
    local runtime="$1"
    local mode="$2"
    local service
    local port

    service="$(compose_runtime_service_name "$runtime" "$mode")"
    port="$(compose_runtime_container_http_port "$runtime")"
    echo "http://${service}:${port}"
}

compose_runtime_host_jmx_port() {
    local runtime="$1"
    local mode="$2"
    compose_runtime_validate_runtime "$runtime" >/dev/null
    compose_runtime_validate_mode "$mode" >/dev/null

    if [[ "$mode" != "jvm" ]]; then
        echo ""
        return 0
    fi

    case "$runtime" in
        spring)
            echo "${DG_SPRING_JMX_PORT:-9010}"
            ;;
        quarkus)
            echo "${DG_QUARKUS_JMX_PORT:-9011}"
            ;;
    esac
}

compose_runtime_host_jmx_url() {
    local runtime="$1"
    local mode="$2"
    local port

    port="$(compose_runtime_host_jmx_port "$runtime" "$mode")"
    if [[ -z "$port" ]]; then
        echo ""
        return 0
    fi

    echo "service:jmx:rmi:///jndi/rmi://127.0.0.1:${port}/jmxrmi"
}

compose_runtime_prepare_load_test_output_dir() {
    local runtime="$1"
    local mode="$2"
    local output_root
    local latest_name
    local timestamp
    local run_dir

    output_root="$compose_runtime_repo_root/$(compose_runtime_load_test_value '.output.rootDirectory')"
    latest_name="$(compose_runtime_load_test_value '.output.latestSymlinkName')"
    timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
    run_dir="$output_root/${timestamp}-$(compose_runtime_scenario_name "$runtime" "$mode")"

    mkdir -p "$run_dir"
    ln -sfn "$run_dir" "$output_root/$latest_name"
    echo "$run_dir"
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
    local mode="$2"
    local timeout_seconds="$3"
    local base_url
    local service
    local start_time=$SECONDS

    base_url="$(compose_runtime_host_base_url "$runtime" "$mode")"
    service="$(compose_runtime_service_name "$runtime" "$mode")"

    while (( SECONDS - start_time < timeout_seconds )); do
        if ! compose_runtime_service_is_running "$service"; then
            echo "$(compose_runtime_scenario_display_name "$runtime" "$mode") exited before it became ready." >&2
            return 1
        fi

        local status
        status="$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 2 "$base_url/api/v1/document-generations" || true)"
        if [[ "$status" == "200" ]]; then
            return 0
        fi

        sleep 1
    done

    echo "Timed out waiting for $(compose_runtime_scenario_display_name "$runtime" "$mode") at $base_url" >&2
    return 1
}

compose_runtime_capture_service_logs() {
    local service="$1"
    local output_file="$2"
    docker compose -f "$compose_runtime_compose_file" logs --no-color "$service" >"$output_file" 2>&1 || true
}

compose_runtime_parse_human_size_to_bytes() {
    local value="$1"

    awk -v raw="$value" '
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
        BEGIN {
            match(raw, /^([0-9.]+)([[:alpha:]]+)$/, parts);
            if (parts[1] == "") {
                print 0;
                exit;
            }
            printf "%d\n", (parts[1] * unit_multiplier(parts[2])) + 0.5;
        }
    '
}

compose_runtime_container_memory_bytes() {
    local container_name="$1"
    local mem_usage
    local current_usage

    mem_usage="$(docker stats --no-stream --format '{{.MemUsage}}' "$container_name" 2>/dev/null | head -n 1)"
    current_usage="${mem_usage%% / *}"

    if [[ -z "$current_usage" ]]; then
        echo 0
        return 0
    fi

    compose_runtime_parse_human_size_to_bytes "$current_usage"
}

compose_runtime_container_cpu_percent() {
    local container_name="$1"
    local cpu_percent

    cpu_percent="$(docker stats --no-stream --format '{{.CPUPerc}}' "$container_name" 2>/dev/null | head -n 1 | tr -d '%[:space:]')"
    if [[ -z "$cpu_percent" ]]; then
        echo "0"
        return 0
    fi

    echo "$cpu_percent"
}

compose_runtime_image_size_bytes() {
    local image_reference="$1"
    docker image inspect "$image_reference" --format '{{.Size}}'
}

compose_runtime_configured_cpus() {
    echo "${DG_RUNTIME_CPUS:-2.0}"
}

compose_runtime_configured_memory() {
    echo "${DG_RUNTIME_MEMORY:-768m}"
}

compose_runtime_configured_pids_limit() {
    echo "${DG_RUNTIME_PIDS_LIMIT:-256}"
}

compose_runtime_configured_max_ram_percentage() {
    echo "${DG_RUNTIME_MAX_RAM_PERCENTAGE:-75.0}"
}

compose_runtime_configured_vus() {
    echo "${LOAD_TEST_VUS:-$(compose_runtime_load_test_value '.loadProfile.vus')}"
}

compose_runtime_configured_duration() {
    echo "${LOAD_TEST_DURATION:-$(compose_runtime_load_test_value '.loadProfile.duration')}"
}

compose_runtime_configured_load_cases() {
    echo "${LOAD_TEST_CASES:-post,get,mixed}"
}

compose_runtime_configured_get_seed_rows() {
    echo "${LOAD_TEST_GET_SEED_ROWS:-100}"
}

compose_runtime_validate_load_case() {
    local load_test_case="$1"

    case "$load_test_case" in
        post|get|mixed)
            ;;
        *)
            echo "Unsupported load-test case: $load_test_case" >&2
            return 1
            ;;
    esac
}
