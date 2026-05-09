#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "Usage: $0 <spring|quarkus|all> [jvm|native|all]" >&2
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

source "$script_dir/compose-runtime-inspection-common.sh"

compose_runtime_require_binary docker
compose_runtime_require_binary java

runtime="${1:-}"
mode="${2:-$(compose_runtime_default_mode)}"

if [[ -z "$runtime" ]]; then
    usage
    exit 1
fi

case "$runtime" in
    spring|quarkus|all)
        ;;
    *)
        usage
        exit 1
        ;;
esac

case "$mode" in
    jvm|native|all)
        ;;
    *)
        usage
        exit 1
        ;;
esac

spring_native_builder_reference="paketobuildpacks/builder-noble-java-tiny:latest"
quarkus_native_builder_reference="quay.io/quarkus/ubi9-quarkus-mandrel-builder-image:jdk-25"

build_runtime_image() {
    local selected_runtime="$1"
    local selected_mode="$2"
    local module
    local image_reference

    module="$(compose_runtime_module "$selected_runtime")"
    image_reference="$(compose_runtime_image_reference "$selected_runtime" "$selected_mode")"

    echo "Packaging $(compose_runtime_scenario_display_name "$selected_runtime" "$selected_mode") runtime"

    case "$(compose_runtime_scenario_name "$selected_runtime" "$selected_mode")" in
        spring-jvm)
            ./mvnw -q -Dmaven.repo.local=.mvn/repository -pl "$module" -am package -DskipTests

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
        quarkus-jvm)
            ./mvnw -q -Dmaven.repo.local=.mvn/repository -pl "$module" -am package -DskipTests

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
        spring-native)
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
                "-Dspring-boot.build-image.builder=$spring_native_builder_reference" \
                -Dspring-boot.build-image.pullPolicy=IF_NOT_PRESENT
            ;;
        quarkus-native)
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
                "-Dquarkus.native.builder-image=$quarkus_native_builder_reference"
            docker build \
                -f "$repo_root/$module/src/main/docker/Dockerfile.native-micro" \
                -t "$image_reference" \
                "$repo_root/$module"
            ;;
        *)
            echo "Unsupported runtime scenario: $selected_runtime $selected_mode" >&2
            exit 1
            ;;
    esac

    echo "Built image: $image_reference"
}

run_builds() {
    local selected_runtime="$1"
    local selected_mode="$2"

    case "$selected_runtime" in
        all)
            local loop_runtime
            for loop_runtime in spring quarkus; do
                run_builds "$loop_runtime" "$selected_mode"
            done
            ;;
        *)
            case "$selected_mode" in
                all)
                    build_runtime_image "$selected_runtime" jvm
                    build_runtime_image "$selected_runtime" native
                    ;;
                *)
                    build_runtime_image "$selected_runtime" "$selected_mode"
                    ;;
            esac
            ;;
    esac
}

cd "$repo_root"
run_builds "$runtime" "$mode"
