# Container Runtime Matrix Comparison

## Purpose

Use this workflow when you want the Docker-to-Docker comparison path for all four runtime scenarios under one shared condition set:

- `spring-jvm`
- `quarkus-jvm`
- `spring-native`
- `quarkus-native`

This is the automated counterpart to the manual container runtime inspection guide.
It is also the supported automated container-native comparison path in this repository.

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
2. runs the configured workload cases, defaulting to `post`, then `get`, then `mixed`
3. resets the Compose environment before every workload case
4. waits until `GET /api/v1/document-generations` returns `200`
5. seeds a deterministic document-generation history before the measured `get` case
6. runs the selected repository-local `k6` workload case against that running container
7. captures container memory and CPU samples for that workload case
8. writes scenario-level startup logs, runtime logs, load-test artifacts, and a machine-readable scenario report
9. tears the Compose environment down automatically

The combined matrix script runs the four scenarios sequentially, reusing the same configured limits and load profile for every scenario in the run.
For native scenarios, Spring Boot and Quarkus keep their framework-native image build paths rather than sharing one repository-specific native Docker packaging shortcut.

## Output Layout

Per-scenario runs emit:

- `load-test/summary.json`
- `load-test/summary.txt`
- `load-test/post/`
- `load-test/get/`
- `load-test/mixed/`
- `report.json`

Each case directory contains the case startup log, runtime log, k6 log, k6 summary, container stats samples, and container observation JSON.

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
- `LOAD_TEST_CASES` as a comma-separated ordered list of `post`, `get`, and `mixed`; default is `post,get,mixed`
- `LOAD_TEST_GET_SEED_ROWS` for the deterministic history size used before each measured `get` case; default is `100`

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

The workload cases are reported as separate rows in `summary.txt`:

- `post`: create requests only
- `get`: history reads against the configured seed size
- `mixed`: the original write-then-read workflow, including think time, run last by default

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
- this repository no longer keeps a second standalone native-only benchmark harness alongside the container matrix
- compare runs only on the same machine and under similar background load
- the same `DG_RUNTIME_*` and `LOAD_TEST_*` settings should be reused if you want the four-scenario report to be comparable
- CPU and memory values in the matrix are Docker container observations scoped to the workload case, not JVM profiler measurements
- `n/a` latency or resource values mean the measurement was unavailable, for example because no successful HTTP response was recorded
- Spring Boot and Quarkus intentionally keep different framework-native build strategies in native mode
- native scenarios expose container-level metrics only; JVM scenarios can also be inspected manually through JMX in the manual workflow
