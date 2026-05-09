# Native Image Comparison

## Purpose

Use this workflow when you want to benchmark Spring Boot and Quarkus in native mode against the same PostgreSQL-backed baseline while preserving each framework's native build path.

## Prerequisites

- Java `25`
- Docker and Docker Compose
- `curl`
- `jq`
- use `./mvnw` from the repository root
- internet access on the first run so Docker and Maven can pull builder images, base images, and plugins
- prefer a warm dependency cache in `.mvn/repository` and warm Docker image cache if you want build time to reflect native build work instead of first-time downloads

## Workload and Report Contract

- workload definition: `benchmarks/native-image-comparison-workload.json`
- machine-readable report schema: `benchmarks/native-image-comparison-report.schema.json`
- generated output root: `target/native-image-comparison/`

## Commands

Run the Spring Boot native benchmark flow:

```bash
./scripts/benchmark-spring-native.sh
```

Run the Quarkus native benchmark flow:

```bash
./scripts/benchmark-quarkus-native.sh
```

Run the combined native comparison flow:

```bash
./scripts/benchmark-native-comparison.sh
```

The per-runtime wrapper scripts also accept an optional custom output directory:

```bash
./scripts/benchmark-spring-native.sh /absolute/path/to/output-dir
./scripts/benchmark-quarkus-native.sh /absolute/path/to/output-dir
```

## What the Scripts Do

Each native benchmark run:

1. builds the selected native delivery artifact with the runtime-specific native build path
2. recreates the PostgreSQL benchmark baseline from `compose.postgres-verification.yml`
3. starts the produced native runtime container on `http://localhost:18080` or `http://localhost:18081`
4. waits for `GET /api/v1/document-generations` to return `200`
5. reruns the shared `document-generator-contract-tests` suite before measured benchmarking starts
6. performs warmup generate and history requests followed by measured requests
7. records build duration, produced image size, cold startup, observed container memory usage, and measured endpoint latency
8. writes the machine-readable report and runtime log

The combined script runs Spring Boot first and Quarkus second, then merges both per-runtime reports into one comparison report.

## Native Build Paths

- Spring Boot uses the Spring Boot native buildpacks path via `spring-boot:build-image`
- Quarkus uses the Quarkus native container-build path to produce the native runner and then packages it with `Dockerfile.native-micro`

## Output Layout

Per-runtime runs emit:

- `report.json`
- `runtime.log`

Combined runs emit:

- `spring/report.json`
- `quarkus/report.json`
- `report.json`
- `summary.txt`

`target/native-image-comparison/latest/` points to the most recent generated run directory.

## Tunable Inputs

- edit `benchmarks/native-image-comparison-workload.json` if you want to change warmup counts, measurement counts, or request payloads
- use the optional custom output directory argument if you want to store a per-runtime run in a specific location

## Cleanup

- the native runtime container is removed automatically
- the PostgreSQL benchmark Compose environment is torn down automatically

## Interpretation Limits

- this is a local developer benchmark, not a CI gate or production load test
- compare runs only on the same machine and under similar background load
- the PostgreSQL baseline is recreated between Spring Boot and Quarkus runs
- Spring Boot and Quarkus intentionally use different framework-native build strategies in native mode
- Spring Boot artifact size is measured from the produced OCI image built through buildpacks
- Quarkus artifact size is measured from the produced OCI image built from the native runner and `Dockerfile.native-micro`
- steady-state memory is measured as current Docker container memory usage rather than host-process RSS
- build-time results depend heavily on Docker image cache state, dependency-cache warmth, and background host load

## Important Difference From Manual JVM Inspection

- this workflow does not use `compose.runtime-inspection.yml`
- this workflow does not consume the manual inspection `DG_RUNTIME_CPUS`, `DG_RUNTIME_MEMORY`, `DG_RUNTIME_PIDS_LIMIT`, or `DG_RUNTIME_MAX_RAM_PERCENTAGE` controls
- the reported native memory value is observed container memory usage from `docker stats`, not a fixed manual container limit

If you want manual container limits, JMX inspection, or repository-local `k6` load testing, use [manual-runtime-inspection.md](manual-runtime-inspection.md) instead.
