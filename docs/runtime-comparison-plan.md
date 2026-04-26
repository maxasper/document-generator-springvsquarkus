# Runtime Comparison Plan

These tasks start after Spring Boot and Quarkus are functionally aligned, pass the same runtime contract tests in `in-memory` mode, and pass the same PostgreSQL-backed verification flow against the shared database setup.

## JVM Mode

Current repository-local JVM comparison commands:

- `./scripts/benchmark-spring-jvm.sh`
- `./scripts/benchmark-quarkus-jvm.sh`
- `./scripts/benchmark-jvm-comparison.sh`

Current workload and report contract:

- workload definition: `benchmarks/jvm-runtime-comparison-workload.json`
- machine-readable report shape: `benchmarks/jvm-runtime-comparison-report.schema.json`
- generated output root: `target/jvm-runtime-comparison/`

Current JVM metrics:

- cold startup time for both applications
- steady-state RSS
- measured latency for generate and history endpoints
- packaging size
- build time

Interpretation limits for the current JVM harness:

- it is a local developer benchmark, not a CI gate or production load test
- compare runs only on the same machine and under similar background load
- the PostgreSQL baseline is recreated between Spring Boot and Quarkus runs
- Spring Boot size is measured from the packaged fat jar
- Quarkus size is measured from the packaged `quarkus-app/` directory
- RSS capture is Linux-first in the current implementation

## Native Image Mode

- build a Quarkus native executable
- build a Spring native executable
- compare native build time, binary size, startup, and RSS
- rerun the same contract tests against both native binaries

## Reporting

- keep one benchmark input dataset and one test command per runtime
- record environment details for every run: CPU, RAM, OS, Java version, Docker version if used
- separate framework effects from database effects by running the same PostgreSQL setup for both
