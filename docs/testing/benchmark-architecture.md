# Benchmark Architecture

Use this document when you want to understand how the repository's verification, benchmarking, and container-evaluation workflows fit together before choosing a specific runbook.

Detailed operator steps still live in the workflow guides:

- [runtime-verification.md](runtime-verification.md)
- [jvm-runtime-comparison.md](jvm-runtime-comparison.md)
- [native-image-comparison.md](native-image-comparison.md)
- [manual-container-runtime-inspection.md](manual-container-runtime-inspection.md)
- [container-runtime-matrix-comparison.md](container-runtime-matrix-comparison.md)

## What Exists Today

The repository currently has four runtime-evaluation paths plus one non-benchmark verification path:

- `Runtime Verification`
  - purpose: confirm behavior, not performance
  - Spring Boot and Quarkus are checked in `in-memory` and PostgreSQL-backed modes
  - output is pass or fail
- `JVM Runtime Comparison`
  - purpose: compare Spring Boot and Quarkus as host-run JVM applications
  - PostgreSQL runs in Docker, but the runtime applications do not
  - output root: `target/jvm-runtime-comparison/`
- `Native Image Comparison`
  - purpose: compare Spring Boot and Quarkus in native mode while preserving each framework's native build path
  - native runtimes run in containers
  - output root: `target/native-image-comparison/`
- `Manual Container Runtime Inspection`
  - purpose: keep one selected JVM or native container online, inspect it manually, constrain resources, and run `k6`
  - this is an interactive operator workflow, not a consolidated comparison harness
  - output root: `target/runtime-load-testing/`
- `Container Runtime Matrix Comparison`
  - purpose: run all four Docker scenarios under one shared limit and load profile
  - scenarios: `spring-jvm`, `quarkus-jvm`, `spring-native`, `quarkus-native`
  - output root: `target/container-runtime-matrix/`

## How Each Harness Works

### Runtime Verification

This path validates correctness only.

- shared contract tests live in `document-generator-contract-tests`
- Spring Boot and Quarkus are exercised against the same HTTP behavior
- the workflow is intentionally separate from performance reporting so functional regressions fail fast before any benchmark interpretation starts

### JVM Runtime Comparison

Main scripts:

- `scripts/benchmark-jvm-runtime.sh`
- `scripts/benchmark-jvm-comparison.sh`

Execution model:

1. package the selected runtime with Maven
2. recreate the PostgreSQL baseline from `compose.postgres-verification.yml`
3. start the runtime as a host Java process
4. wait for readiness on `GET /api/v1/document-generations`
5. run warmup requests and measured requests from `benchmarks/jvm-runtime-comparison-workload.json`
6. capture artifact size, startup duration, latency summaries, and host-process RSS
7. write per-runtime `report.json`, then merge Spring Boot and Quarkus into a combined comparison report

This harness measures JVM applications without Docker container limits on the application process.

### Native Image Comparison

Main scripts:

- `scripts/benchmark-native-runtime.sh`
- `scripts/benchmark-native-comparison.sh`

Execution model:

1. build Spring Boot and Quarkus with their framework-native native-image paths
2. recreate the PostgreSQL baseline from `compose.postgres-verification.yml`
3. start the produced native runtime container
4. wait for readiness on `GET /api/v1/document-generations`
5. rerun the shared contract tests before measured benchmarking starts
6. run warmup requests and measured requests from `benchmarks/native-image-comparison-workload.json`
7. capture OCI image size, startup duration, latency summaries, and current container memory usage from `docker stats`
8. write per-runtime `report.json`, then merge Spring Boot and Quarkus into a combined comparison report

This harness compares native runtime behavior, but it does not reuse the manual `DG_RUNTIME_*` limit controls.

### Manual Container Runtime Inspection

Main scripts:

- `scripts/build-compose-runtime-image.sh`
- `scripts/compose-runtime-up.sh`
- `scripts/load-test-compose-runtime.sh`

Execution model:

1. build one selected runtime image
2. start `postgres` plus one selected JVM or native runtime from `compose.runtime-inspection.yml`
3. optionally attach a JVM tool through JMX when the selected mode is `jvm`
4. inspect the live container with `docker stats` or a local profiling tool
5. run repository-local `k6` load testing against the running service
6. stop the environment manually when finished

This flow is meant for operator-driven inspection. It keeps the service online instead of tearing it down immediately after one unattended benchmark run.

### Container Runtime Matrix Comparison

Main scripts:

- `scripts/benchmark-container-runtime-scenario.sh`
- `scripts/benchmark-container-runtime-matrix.sh`

Execution model:

1. read the four-scenario list from `benchmarks/container-runtime-matrix-workload.json`
2. for each scenario, build the image, start `postgres` plus that runtime, and run the shared `k6` workload
3. capture image size, startup duration, container memory, container CPU snapshot, and load-test summary metrics
4. write a scenario-level `report.json`
5. merge all four scenario reports into one matrix `report.json` and one summary table

This is the most complete Docker-to-Docker comparison path in the repository today.

## How Load Is Generated

The repository uses two different load styles on purpose.

For `JVM Runtime Comparison` and `Native Image Comparison`:

- requests are driven directly by the benchmark shell scripts
- latency is measured from `curl` response timing
- the measured workload is defined in:
  - `benchmarks/jvm-runtime-comparison-workload.json`
  - `benchmarks/native-image-comparison-workload.json`

For `Manual Container Runtime Inspection` and `Container Runtime Matrix Comparison`:

- load is generated by `k6`
- the scenario is implemented in `scripts/runtime-load-test.js`
- the shared workload file is `benchmarks/runtime-load-testing-workload.json`
- default profile is `10` virtual users for `30s`
- runtime overrides come from `LOAD_TEST_VUS` and `LOAD_TEST_DURATION`

Each `k6` iteration currently does:

1. `POST /api/v1/document-generations`
2. `GET /api/v1/document-generations`
3. `sleep(1)`

## What The Metrics Mean

Not every harness measures the same thing in the same way.

`JVM Runtime Comparison` reports:

- `buildDurationMs`
- `artifactSizeBytes`
- `startupDurationMs`
- `steadyStateRssKb`
- `generateLatencyMs`
- `historyLatencyMs`

`Native Image Comparison` reports:

- `contractVerification.durationMs`
- `buildDurationMs`
- `artifactSizeBytes`
- `startupDurationMs`
- `steadyStateMemoryBytes`
- `generateLatencyMs`
- `historyLatencyMs`

`Container Runtime Matrix Comparison` reports:

- `buildDurationMs`
- `startupDurationMs`
- `image.sizeBytes`
- `containerObservation.memoryBytes`
- `containerObservation.cpuPercent`
- `loadTest.httpReqs`
- `loadTest.httpReqFailedRate`
- `loadTest.avgDurationMs`
- `loadTest.p95DurationMs`

The most important interpretation difference is memory:

- host JVM comparison uses host-process RSS
- native comparison uses current container memory usage from `docker stats`
- container matrix comparison also uses current container memory usage from `docker stats`

Those numbers are all useful, but they are not the same measurement and should not be merged into one table without that caveat.

## Shared Fairness Rules

The benchmark scripts try to keep comparisons fair in these ways:

- Spring Boot and Quarkus always use the same PostgreSQL-backed baseline for a given harness
- paired runs execute sequentially, not in parallel
- PostgreSQL is recreated between runtimes or scenarios
- request shape stays the same within each harness
- the container matrix reuses the same `DG_RUNTIME_*` and `LOAD_TEST_*` settings across all four scenarios

## Limits And Caveats

These workflows are useful local developer benchmarks, not production-grade performance labs.

Keep these limits in mind:

- compare only runs produced on the same machine and under similar background load
- native build time is sensitive to Docker cache state and builder image reuse
- `cpuPercent` in the container matrix is a snapshot, not a full time-series CPU profile
- JVM JMX-based tooling applies only to JVM scenarios
- manual container inspection and unattended matrix comparison answer different questions even when they use the same Compose assets

## Which Workflow To Choose

Use:

- `runtime-verification.md` when you want to validate correctness
- `jvm-runtime-comparison.md` when you want host JVM metrics without Docker application containers
- `native-image-comparison.md` when you want framework-native native comparison
- `manual-container-runtime-inspection.md` when you want to keep one container online and inspect it interactively
- `container-runtime-matrix-comparison.md` when you want one automated Docker report across all four scenarios
