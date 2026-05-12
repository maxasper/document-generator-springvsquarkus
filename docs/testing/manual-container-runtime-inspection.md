# Manual Container Runtime Inspection

## Purpose

Use this workflow when you want to keep one selected container runtime online for manual inspection, container-level resource observation, and repository-local `k6` load testing.

JMX tooling is available for the JVM scenarios only:

- `spring-jvm`
- `quarkus-jvm`

Native scenarios rely on container-level observation:

- `spring-native`
- `quarkus-native`

## Prerequisites

- Java `25`
- Docker and Docker Compose
- `curl`
- `jq`
- use `./mvnw` from the repository root
- optional local JVM inspection tool for JVM scenarios:
  - `VisualVM`
  - `JDK Mission Control`

## Supported Topology

- supported workflow: `postgres` plus one selected runtime scenario
- Spring Boot and Quarkus are intentionally started separately, not at the same time
- JVM and native scenarios are intentionally started separately, not at the same time
- helper scripts use `compose.runtime-inspection.yml`, which contains all runtime services but starts only the one you selected

This keeps the comparison cleaner and avoids resource cross-talk between application runtimes or execution modes.

## Build the Images

Build the Spring Boot JVM image:

```bash
./scripts/build-compose-runtime-image.sh spring jvm
```

Build the Quarkus JVM image:

```bash
./scripts/build-compose-runtime-image.sh quarkus jvm
```

Build the Spring Boot native image:

```bash
./scripts/build-compose-runtime-image.sh spring native
```

Build the Quarkus native image:

```bash
./scripts/build-compose-runtime-image.sh quarkus native
```

Build both JVM images:

```bash
./scripts/build-compose-runtime-image.sh all
```

Build both native images:

```bash
./scripts/build-compose-runtime-image.sh all native
```

Build all four runtime images:

```bash
./scripts/build-compose-runtime-image.sh all all
```

## Start the Compose Environment

Start PostgreSQL plus Spring Boot JVM:

```bash
./scripts/run-compose-spring-jvm.sh
```

Start PostgreSQL plus Quarkus JVM:

```bash
./scripts/run-compose-quarkus-jvm.sh
```

Start PostgreSQL plus Spring Boot native:

```bash
./scripts/run-compose-spring-native.sh
```

Start PostgreSQL plus Quarkus native:

```bash
./scripts/run-compose-quarkus-native.sh
```

Or use the generic entrypoint:

```bash
./scripts/compose-runtime-up.sh spring jvm
./scripts/compose-runtime-up.sh quarkus native
```

The startup script:

1. resets the previous runtime-inspection environment
2. starts PostgreSQL and one selected runtime scenario
3. waits until `GET /api/v1/document-generations` returns `200`
4. leaves the environment running for manual inspection and follow-up load testing

## Endpoints

- Spring Boot HTTP, both modes: `http://localhost:18080`
- Quarkus HTTP, both modes: `http://localhost:18081`
- Spring Boot JVM JMX: `service:jmx:rmi:///jndi/rmi://127.0.0.1:9010/jmxrmi`
- Quarkus JVM JMX: `service:jmx:rmi:///jndi/rmi://127.0.0.1:9011/jmxrmi`
- native scenarios expose no JMX port

Check the running services:

```bash
docker compose -f compose.runtime-inspection.yml ps
```

## Load Testing

After the selected runtime is up, run the load test only for that active runtime scenario.

Spring Boot JVM:

```bash
./scripts/load-test-spring-jvm-compose.sh
```

Quarkus JVM:

```bash
./scripts/load-test-quarkus-jvm-compose.sh
```

Spring Boot native:

```bash
./scripts/load-test-spring-native-compose.sh
```

Quarkus native:

```bash
./scripts/load-test-quarkus-native-compose.sh
```

Or use the generic entrypoint:

```bash
./scripts/load-test-compose-runtime.sh spring native
./scripts/load-test-compose-runtime.sh quarkus jvm
```

The default load-test profile uses containerized `k6`, so no host installation is required.

Generated load-test output is written under `target/runtime-load-testing/`:

- `latest/` points to the most recent run directory
- each run emits:
  - `summary.json`
  - `summary.txt`
  - case-specific directories such as `post/`, `get/`, and `mixed/`
  - each case directory contains `k6.log`, `k6-summary.json`, `container-stats.log`, and `container-observation.json`

The generic load-test helper also allows a custom output directory anywhere under `target/`.

## Observe Resources

Container-level view:

```bash
docker stats document-generator-postgres-runtime-inspection document-generator-spring-jvm-inspection
docker stats document-generator-postgres-runtime-inspection document-generator-quarkus-jvm-inspection
docker stats document-generator-postgres-runtime-inspection document-generator-spring-native-inspection
docker stats document-generator-postgres-runtime-inspection document-generator-quarkus-native-inspection
```

JVM-level view for JVM scenarios only:

- attach `VisualVM` or `JDK Mission Control`
- use the JMX endpoint for the selected JVM runtime
- inspect heap, threads, classes, GC, and JVM-level CPU behavior

Native observation:

- use `docker stats` for current memory and CPU consumption
- inspect service logs with `docker compose ... logs`
- use the same repository-local `k6` load-test artifacts to compare response behavior under pressure

Runtime logs:

```bash
docker compose -f compose.runtime-inspection.yml logs -f spring-jvm
docker compose -f compose.runtime-inspection.yml logs -f quarkus-jvm
docker compose -f compose.runtime-inspection.yml logs -f spring-native
docker compose -f compose.runtime-inspection.yml logs -f quarkus-native
```

## Tunable Parameters

Shared container resource controls:

- `DG_RUNTIME_CPUS`
- `DG_RUNTIME_MEMORY`
- `DG_RUNTIME_PIDS_LIMIT`
- `DG_RUNTIME_MAX_RAM_PERCENTAGE` for JVM scenarios only

Example:

```bash
DG_RUNTIME_CPUS=1.5 \
DG_RUNTIME_MEMORY=512m \
DG_RUNTIME_PIDS_LIMIT=256 \
DG_RUNTIME_MAX_RAM_PERCENTAGE=75.0 \
./scripts/run-compose-quarkus-jvm.sh
```

Shared load-test controls:

- `LOAD_TEST_VUS`
- `LOAD_TEST_DURATION`
- `LOAD_TEST_CASES` as a comma-separated list of `post`, `get`, and `mixed`; default is `post,get,mixed`
- `LOAD_TEST_CASE` for a single selected case; useful when a runtime is already running and you want one focused measurement

Example:

```bash
LOAD_TEST_VUS=20 \
LOAD_TEST_DURATION=45s \
./scripts/load-test-spring-native-compose.sh
```

The workload cases are:

- `post`: sends document-generation create requests only
- `get`: reads document-generation history only
- `mixed`: preserves the original write-then-read workflow, including the one-second think time

If you want to change the request shape, thresholds, or default `k6` profile, edit:

```text
benchmarks/runtime-load-testing-workload.json
```

## Cleanup

Stop and remove the manual runtime environment:

```bash
./scripts/compose-runtime-down.sh
```

## Interpretation Limits

- this is an interactive operator workflow, not a replacement for the unattended benchmark scripts
- compare runtime scenarios only under the same `DG_RUNTIME_*` and `LOAD_TEST_*` settings if you want to reason about resource differences
- JMX is configured for local-only use with authentication and SSL disabled
- native scenarios do not expose JVM-level diagnostics and should be interpreted from container-level metrics and load-test output
