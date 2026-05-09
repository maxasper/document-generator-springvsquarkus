# Manual JVM Runtime Inspection

## Purpose

Use this workflow when you want to keep one JVM runtime online for manual inspection, JMX attachment, container-level resource observation, and repository-local `k6` load testing.

## Prerequisites

- Java `25`
- Docker and Docker Compose
- `curl`
- `jq`
- use `./mvnw` from the repository root
- a local JVM inspection tool if you want Java-level live diagnostics:
  - `VisualVM`
  - `JDK Mission Control`

## Supported Topology

- supported workflow: `postgres` plus one selected runtime
- Spring Boot and Quarkus are intentionally started separately, not at the same time
- helper scripts use `compose.runtime-inspection.yml`, which contains both runtime services but starts only the one you selected

This keeps the comparison cleaner and avoids resource cross-talk between the two application runtimes.

## Build the JVM Images

Build the Spring Boot inspection image:

```bash
./scripts/build-compose-runtime-image.sh spring
```

Build the Quarkus inspection image:

```bash
./scripts/build-compose-runtime-image.sh quarkus
```

Build both inspection images:

```bash
./scripts/build-compose-runtime-image.sh all
```

## Start the Compose Environment

Start PostgreSQL plus Spring Boot:

```bash
./scripts/run-compose-spring-jvm.sh
```

Start PostgreSQL plus Quarkus:

```bash
./scripts/run-compose-quarkus-jvm.sh
```

The startup script:

1. resets the previous runtime-inspection environment
2. starts PostgreSQL and one selected JVM runtime
3. waits until `GET /api/v1/document-generations` returns `200`
4. leaves the environment running for manual inspection and follow-up load testing

## Endpoints

- Spring Boot HTTP: `http://localhost:18080`
- Spring Boot JMX: `service:jmx:rmi:///jndi/rmi://127.0.0.1:9010/jmxrmi`
- Quarkus HTTP: `http://localhost:18081`
- Quarkus JMX: `service:jmx:rmi:///jndi/rmi://127.0.0.1:9011/jmxrmi`

Check the running services:

```bash
docker compose -f compose.runtime-inspection.yml ps
```

## Load Testing

After the selected runtime is up, run the load test only for that active runtime.

Spring Boot:

```bash
./scripts/load-test-spring-compose.sh
```

Quarkus:

```bash
./scripts/load-test-quarkus-compose.sh
```

The default load-test profile uses containerized `k6`, so no host installation is required.

Generated load-test output is written under `target/runtime-load-testing/`:

- `latest/` points to the most recent run directory
- each run emits:
  - `summary.json`
  - `summary.txt`
  - `k6.log`

The wrapper scripts also allow an optional custom output directory under `target/runtime-load-testing/`.

## Observe Resources

Container-level view:

```bash
docker stats document-generator-postgres-runtime-inspection document-generator-spring-jvm-inspection
docker stats document-generator-postgres-runtime-inspection document-generator-quarkus-jvm-inspection
```

JVM-level view:

- attach `VisualVM` or `JDK Mission Control`
- use the JMX endpoint for the selected runtime
- inspect heap, threads, classes, GC, and JVM-level CPU behavior

Runtime logs:

```bash
docker compose -f compose.runtime-inspection.yml logs -f spring-jvm
docker compose -f compose.runtime-inspection.yml logs -f quarkus-jvm
```

## Tunable Parameters

Load-test controls:

- `LOAD_TEST_VUS`
- `LOAD_TEST_DURATION`

Example:

```bash
LOAD_TEST_VUS=20 \
LOAD_TEST_DURATION=45s \
./scripts/load-test-spring-compose.sh
```

Container and JVM controls for the selected runtime:

- `DG_RUNTIME_CPUS`
- `DG_RUNTIME_MEMORY`
- `DG_RUNTIME_PIDS_LIMIT`
- `DG_RUNTIME_MAX_RAM_PERCENTAGE`

Example:

```bash
DG_RUNTIME_CPUS=1.5 \
DG_RUNTIME_MEMORY=512m \
DG_RUNTIME_PIDS_LIMIT=256 \
DG_RUNTIME_MAX_RAM_PERCENTAGE=75.0 \
./scripts/run-compose-quarkus-jvm.sh
```

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
- compare Spring Boot and Quarkus only under the same `DG_RUNTIME_*` settings if you want to reason about resource differences
- JMX is configured for local-only use with authentication and SSL disabled
- this workflow is JVM-only; native-image containers use a different observability and comparison path
