# JVM Runtime Comparison

## Purpose

Use this workflow when you want to benchmark Spring Boot and Quarkus in JVM mode as host-run Java processes against the same PostgreSQL-backed baseline.

## Prerequisites

- Java `25`
- Docker and Docker Compose
- `curl`
- `jq`
- use `./mvnw` from the repository root
- prefer a warm dependency cache in `.mvn/repository` if you want build time to reflect packaging work instead of first-time downloads

## Workload and Report Contract

- workload definition: `benchmarks/jvm-runtime-comparison-workload.json`
- machine-readable report schema: `benchmarks/jvm-runtime-comparison-report.schema.json`
- generated output root: `target/jvm-runtime-comparison/`

## Commands

Run the Spring Boot JVM benchmark flow:

```bash
./scripts/benchmark-spring-jvm.sh
```

Run the Quarkus JVM benchmark flow:

```bash
./scripts/benchmark-quarkus-jvm.sh
```

Run the combined JVM comparison flow:

```bash
./scripts/benchmark-jvm-comparison.sh
```

The per-runtime wrapper scripts also accept an optional custom output directory:

```bash
./scripts/benchmark-spring-jvm.sh /absolute/path/to/output-dir
./scripts/benchmark-quarkus-jvm.sh /absolute/path/to/output-dir
```

## What the Scripts Do

Each JVM benchmark run:

1. packages the selected runtime and its dependencies
2. recreates the PostgreSQL benchmark baseline from `compose.postgres-verification.yml`
3. starts the runtime on the host in PostgreSQL-backed mode on `http://localhost:18080` or `http://localhost:18081`
4. waits for `GET /api/v1/document-generations` to return `200`
5. performs warmup generate and history requests
6. records build duration, packaged artifact size, cold startup, steady-state RSS, and measured endpoint latency
7. writes the machine-readable report and runtime log

The combined script runs Spring Boot first and Quarkus second, then merges both per-runtime reports into one comparison report.

## Output Layout

Per-runtime runs emit:

- `report.json`
- `runtime.log`

Combined runs emit:

- `spring/report.json`
- `quarkus/report.json`
- `report.json`
- `summary.txt`

`target/jvm-runtime-comparison/latest/` points to the most recent generated run directory.

## Tunable Inputs

- edit `benchmarks/jvm-runtime-comparison-workload.json` if you want to change warmup counts, measurement counts, or request payloads
- use the optional custom output directory argument if you want to store a per-runtime run in a specific location

## Cleanup

- the runtime process is stopped automatically
- the PostgreSQL benchmark Compose environment is torn down automatically

## Interpretation Limits

- this is a local developer benchmark, not a CI gate or production load test
- this is a host-process comparison workflow; it is intentionally separate from the containerized runtime matrix comparison
- compare runs only on the same machine and under similar background load
- the PostgreSQL baseline is recreated between Spring Boot and Quarkus runs
- Spring Boot artifact size is measured from the packaged fat jar
- Quarkus artifact size is measured from the packaged `quarkus-app/` directory
- RSS capture is Linux-first in the current implementation
