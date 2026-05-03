#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus|all>" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/compose-runtime-inspection-common.sh"

compose_runtime_require_binary docker
compose_runtime_require_binary java

runtime="${1:-}"
if [[ -z "$runtime" ]]; then
    usage
    exit 1
fi

build_runtime_image() {
    local selected_runtime="$1"
    local module
    local image_reference

    module="$(compose_runtime_module "$selected_runtime")"
    image_reference="$(compose_runtime_image_reference "$selected_runtime")"

    echo "Packaging $(compose_runtime_runtime_name "$selected_runtime") JVM runtime"
    ./mvnw -q -Dmaven.repo.local=.mvn/repository -pl "$module" -am package -DskipTests

    case "$selected_runtime" in
        spring)
            local app_jar
            app_jar="$(find "$repo_root/$module/target" -maxdepth 1 -type f -name '*.jar' ! -name '*original' | sort | head -n 1)"
            if [[ -z "$app_jar" || ! -f "$app_jar" ]]; then
                echo "Spring Boot runtime jar is missing." >&2
                exit 1
            fi

            docker build \
                -f "$repo_root/$module/src/main/docker/Dockerfile.jvm" \
                --build-arg "APP_JAR=${app_jar#$repo_root/}" \
                -t "$image_reference" \
                "$repo_root"
            ;;
        quarkus)
            local quarkus_app_dir
            quarkus_app_dir="$repo_root/$module/target/quarkus-app"
            if [[ ! -d "$quarkus_app_dir" ]]; then
                echo "Quarkus JVM runtime directory is missing: $quarkus_app_dir" >&2
                exit 1
            fi

            docker build \
                -f "$repo_root/$module/src/main/docker/Dockerfile.jvm" \
                --build-arg "QUARKUS_APP_DIR=${quarkus_app_dir#$repo_root/}" \
                -t "$image_reference" \
                "$repo_root"
            ;;
    esac

    echo "Built image: $image_reference"
}

cd "$repo_root"

case "$runtime" in
    spring|quarkus)
        build_runtime_image "$runtime"
        ;;
    all)
        build_runtime_image spring
        build_runtime_image quarkus
        ;;
    *)
        usage
        exit 1
        ;;
esac
