#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus> [in-memory|postgres]" >&2
}

runtime="${1:-}"
if [[ -z "$runtime" ]]; then
    usage
    exit 1
fi

mode="${2:-in-memory}"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
compose_file="$repo_root/compose.postgres-verification.yml"

runtime_name=""
module=""
base_url=""
artifact=""
java_opts=()
app_args=()
runtime_env=()
requires_postgres=false

case "$runtime" in
    spring)
        runtime_name="Spring Boot"
        module="document-generator-app-spring"
        base_url="http://localhost:8080"
        artifact=""
        ;;
    quarkus)
        runtime_name="Quarkus"
        module="document-generator-app-quarkus"
        base_url="http://localhost:8081"
        artifact="$repo_root/$module/target/quarkus-app/quarkus-run.jar"
        ;;
    *)
        usage
        exit 1
        ;;
esac

case "$mode" in
    in-memory)
        ;;
    postgres)
        requires_postgres=true
        runtime_env+=(
            DOCUMENT_GENERATOR_POSTGRES_HOST=localhost
            DOCUMENT_GENERATOR_POSTGRES_PORT=55432
            DOCUMENT_GENERATOR_POSTGRES_DATABASE=document_generator
            DOCUMENT_GENERATOR_POSTGRES_USER=document_generator
            DOCUMENT_GENERATOR_POSTGRES_PASSWORD=document_generator
        )
        if [[ "$runtime" == "spring" ]]; then
            base_url="http://localhost:18080"
            app_args+=(--spring.profiles.active=postgres)
            app_args+=(--server.port=18080)
        else
            base_url="http://localhost:18081"
            java_opts+=(-Dquarkus.profile=postgres)
            java_opts+=(-Dquarkus.http.port=18081)
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac

log_file="$(mktemp "/tmp/${runtime}-runtime-verification.XXXX.log")"
app_pid=""

cleanup() {
    local exit_code=$?
    if [[ -n "$app_pid" ]] && kill -0 "$app_pid" 2>/dev/null; then
        kill "$app_pid" 2>/dev/null || true
        wait "$app_pid" 2>/dev/null || true
    fi
    if [[ $exit_code -ne 0 ]]; then
        echo "$runtime_name verification failed. Log: $log_file" >&2
        echo "--- $runtime_name log ---" >&2
        tail -n 200 "$log_file" >&2 || true
    else
        rm -f "$log_file"
    fi

    if [[ "$requires_postgres" == "true" ]]; then
        docker compose -f "$compose_file" down -v --remove-orphans >/dev/null 2>&1 || true
    fi
}

wait_for_runtime() {
    local health_url="$1"
    local timeout_seconds="$2"
    local start_time=$SECONDS

    # Poll the public HTTP endpoint so both runtimes use the same readiness signal.
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

    echo "Timed out waiting for PostgreSQL verification container to become healthy." >&2
    return 1
}

trap cleanup EXIT

cd "$repo_root"

if [[ "$requires_postgres" == "true" ]]; then
    echo "Starting PostgreSQL verification environment"
    docker compose -f "$compose_file" down -v --remove-orphans >/dev/null 2>&1 || true
    docker compose -f "$compose_file" up -d
    wait_for_postgres 60
    echo "PostgreSQL verification environment is ready"
fi

echo "Packaging $runtime_name runtime"
./mvnw -q -pl "$module" -am package -DskipTests

if [[ "$runtime" == "spring" ]]; then
    artifact="$(find "$repo_root/$module/target" -maxdepth 1 -type f -name '*.jar' ! -name '*original' | sort | head -n 1)"
fi

if [[ -z "$artifact" || ! -f "$artifact" ]]; then
    echo "Expected runtime artifact is missing: $artifact" >&2
    exit 1
fi

echo "Starting $runtime_name on $base_url in $mode mode"
env "${runtime_env[@]}" java "${java_opts[@]}" -jar "$artifact" "${app_args[@]}" >"$log_file" 2>&1 &
app_pid=$!

wait_for_runtime "$base_url/api/v1/document-generations" 60

echo "$runtime_name is ready"
"$repo_root/scripts/run-contract-tests.sh" "$base_url"

echo "$runtime_name verification passed"
