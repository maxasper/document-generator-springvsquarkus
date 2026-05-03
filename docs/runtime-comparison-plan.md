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

Current repository-local native comparison commands:

- `./scripts/benchmark-spring-native.sh`
- `./scripts/benchmark-quarkus-native.sh`
- `./scripts/benchmark-native-comparison.sh`

Current workload and report contract:

- workload definition: `benchmarks/native-image-comparison-workload.json`
- machine-readable report shape: `benchmarks/native-image-comparison-report.schema.json`
- generated output root: `target/native-image-comparison/`

Current native metrics:

- contract-verification duration after runtime readiness and before measured requests
- native build time
- produced OCI image size
- cold startup time for both applications
- steady-state container memory usage
- measured latency for generate and history endpoints

Interpretation limits for the current native harness:

- it is a local developer benchmark, not a CI gate or production load test
- compare runs only on the same machine and under similar background load
- the PostgreSQL baseline is recreated between Spring Boot and Quarkus runs
- Spring Boot and Quarkus intentionally use different framework-native build strategies in native mode
- Spring Boot size is measured from the produced OCI image built with Spring Boot buildpacks
- Quarkus size is measured from the produced OCI image built from the Quarkus native runner and `Dockerfile.native-micro`
- memory is measured as current Docker container memory usage rather than host-process RSS

## Manual JVM Container Evaluation

Current repository-local manual runtime evaluation commands:

- `./scripts/build-compose-runtime-image.sh spring`
- `./scripts/build-compose-runtime-image.sh quarkus`
- `./scripts/run-compose-spring-jvm.sh`
- `./scripts/run-compose-quarkus-jvm.sh`
- `./scripts/load-test-spring-compose.sh`
- `./scripts/load-test-quarkus-compose.sh`
- `./scripts/compose-runtime-down.sh`

Current runtime-inspection assets:

- Compose definition: `compose.runtime-inspection.yml`
- load-test workload: `benchmarks/runtime-load-testing-workload.json`
- generated load-test output root: `target/runtime-load-testing/`

Current manual JVM evaluation capabilities:

- start PostgreSQL plus one selected JVM runtime container
- attach a local JVM tool through JMX for live inspection
- constrain CPU, memory, and PID count through documented Compose env vars
- run a repository-local `k6` load test while the runtime stays online

Interpretation limits for the current manual JVM evaluation flow:

- it is an interactive operator workflow, not a replacement for the unattended benchmark scripts
- VisualVM, JDK Mission Control, and JMX-based diagnostics apply to JVM containers only
- container resource limits and JVM memory flags must stay equivalent across Spring Boot and Quarkus if the results are compared
- native-image container observability remains deferred to a later change

Validated operator sessions on `2026-05-03`:

- Spring Boot
  - commands: `./scripts/build-compose-runtime-image.sh spring`, `./scripts/run-compose-spring-jvm.sh`, `./scripts/load-test-spring-compose.sh`, `./scripts/compose-runtime-down.sh`
  - startup result: HTTP `http://localhost:18080`, JMX `service:jmx:rmi:///jndi/rmi://127.0.0.1:9010/jmxrmi`
  - verified default limits: `768m`, `2.0 CPU`, `256` PIDs
  - validated load-test artifact: `target/runtime-load-testing/20260503T095933Z-spring/summary.txt`
- Quarkus
  - commands: `./scripts/build-compose-runtime-image.sh quarkus`, `DG_RUNTIME_CPUS=1.5 DG_RUNTIME_MEMORY=512m DG_RUNTIME_PIDS_LIMIT=256 DG_RUNTIME_MAX_RAM_PERCENTAGE=75.0 ./scripts/run-compose-quarkus-jvm.sh`, `./scripts/load-test-quarkus-compose.sh`, `./scripts/compose-runtime-down.sh`
  - startup result: HTTP `http://localhost:18081`, JMX `service:jmx:rmi:///jndi/rmi://127.0.0.1:9011/jmxrmi`
  - verified override limits: `512m`, `1.5 CPU`, `256` PIDs
  - validated load-test artifact: `target/runtime-load-testing/20260503T113216Z-quarkus/summary.txt`

## Reporting

- keep one benchmark input dataset and one test command per runtime
- record environment details for every run: CPU, RAM, OS, Java version, Docker version if used
- separate framework effects from database effects by running the same PostgreSQL setup for both
- record the native build strategy for every native run: build command, builder reference, runtime base image, and produced artifact reference
- keep manual load-test artifacts alongside the rest of the repository-local comparison output under `target/`
