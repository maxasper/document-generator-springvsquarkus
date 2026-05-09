# Container Runtime Matrix Comparison

## Purpose

Use this workflow when you want the Docker-to-Docker comparison path for all four runtime scenarios under one shared condition set:

- `spring-jvm`
- `quarkus-jvm`
- `spring-native`
- `quarkus-native`

This is the automated counterpart to the manual container runtime inspection guide.

## Prerequisites

- Java `25`
- Docker and Docker Compose
- `jq`
- use `./mvnw` from the repository root
- internet access on the first run so Docker and Maven can pull builder images, base images, and plugins for the native scenarios

## Workload and Report Contract

- matrix workload definition: `benchmarks/container-runtime-matrix-workload.json`
- shared load-test workload: `benchmarks/runtime-load-testing-workload.json`
- machine-readable report schema: `benchmarks/container-runtime-matrix-report.schema.json`
- generated output root: `target/container-runtime-matrix/`

## Commands

Run one automated container scenario:

```bash
./scripts/benchmark-container-runtime-scenario.sh spring jvm
./scripts/benchmark-container-runtime-scenario.sh quarkus native
```

The per-scenario runner also accepts an optional custom output directory under `target/`:

```bash
./scripts/benchmark-container-runtime-scenario.sh spring native \
  /absolute/path/to/repo/target/container-runtime-matrix/manual-spring-native
```

Run the combined four-scenario matrix:

```bash
./scripts/benchmark-container-runtime-matrix.sh
```

## What the Scripts Do

Each automated container scenario:

1. builds the selected runtime image through the repository-local build entrypoint
2. resets the Compose environment
3. starts PostgreSQL plus one selected runtime scenario
4. waits until `GET /api/v1/document-generations` returns `200`
5. runs the shared repository-local `k6` workload against that running container
6. captures container memory and CPU snapshots after the load test
7. writes scenario-level startup logs, runtime logs, load-test artifacts, and a machine-readable scenario report
8. tears the Compose environment down automatically

The combined matrix script runs the four scenarios sequentially, reusing the same configured limits and load profile for every scenario in the run.

## Output Layout

Per-scenario runs emit:

- `startup.log`
- `runtime.log`
- `load-test/summary.json`
- `load-test/summary.txt`
- `load-test/k6.log`
- `report.json`

Combined matrix runs emit:

- `spring-jvm/`
- `quarkus-jvm/`
- `spring-native/`
- `quarkus-native/`
- `report.json`
- `summary.txt`

`target/container-runtime-matrix/latest/` points to the most recent combined run directory.

## Tunable Inputs

Shared container resource controls for every scenario in the matrix:

- `DG_RUNTIME_CPUS`
- `DG_RUNTIME_MEMORY`
- `DG_RUNTIME_PIDS_LIMIT`
- `DG_RUNTIME_MAX_RAM_PERCENTAGE` for JVM scenarios only

Shared load-test controls for every scenario in the matrix:

- `LOAD_TEST_VUS`
- `LOAD_TEST_DURATION`

Example:

```bash
DG_RUNTIME_CPUS=1.5 \
DG_RUNTIME_MEMORY=512m \
DG_RUNTIME_PIDS_LIMIT=256 \
DG_RUNTIME_MAX_RAM_PERCENTAGE=75.0 \
LOAD_TEST_VUS=20 \
LOAD_TEST_DURATION=45s \
./scripts/benchmark-container-runtime-matrix.sh
```

If you want to change the load-test request shape or thresholds, edit:

```text
benchmarks/runtime-load-testing-workload.json
```

If you want to change the scenario order or matrix output root, edit:

```text
benchmarks/container-runtime-matrix-workload.json
```

## Cleanup

- every automated scenario tears the Compose environment down automatically
- the combined matrix leaves only report artifacts under `target/container-runtime-matrix/`

## Interpretation Limits

- this is the containerized comparison path; the host JVM benchmark scripts remain a separate workflow
- compare runs only on the same machine and under similar background load
- the same `DG_RUNTIME_*` and `LOAD_TEST_*` settings should be reused if you want the four-scenario report to be comparable
- Spring Boot and Quarkus intentionally keep different framework-native build strategies in native mode
- native scenarios expose container-level metrics only; JVM scenarios can also be inspected manually through JMX in the manual workflow
