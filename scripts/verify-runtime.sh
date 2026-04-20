#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus>" >&2
}

runtime="${1:-}"
if [[ -z "$runtime" ]]; then
    usage
    exit 1
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

runtime_name=""
module=""
base_url=""
artifact=""

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

trap cleanup EXIT

cd "$repo_root"

echo "Packaging $runtime_name runtime"
./mvnw -q -pl "$module" -am package -DskipTests

if [[ "$runtime" == "spring" ]]; then
    artifact="$(find "$repo_root/$module/target" -maxdepth 1 -type f -name '*.jar' ! -name '*original' | sort | head -n 1)"
fi

if [[ -z "$artifact" || ! -f "$artifact" ]]; then
    echo "Expected runtime artifact is missing: $artifact" >&2
    exit 1
fi

echo "Starting $runtime_name on $base_url"
java -jar "$artifact" >"$log_file" 2>&1 &
app_pid=$!

wait_for_runtime "$base_url/api/v1/document-generations" 60

echo "$runtime_name is ready"
"$repo_root/scripts/run-contract-tests.sh" "$base_url"

echo "$runtime_name verification passed"
