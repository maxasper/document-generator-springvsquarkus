# Runtime Comparison Plan

These tasks start after Spring Boot and Quarkus are functionally aligned, pass the same runtime contract tests in `in-memory` mode, and pass the same PostgreSQL-backed verification flow against the shared database setup.

## Workflow Guides

Detailed operator procedures now live in dedicated workflow guides:

- [docs/testing/runtime-verification.md](testing/runtime-verification.md)
- [docs/testing/jvm-runtime-comparison.md](testing/jvm-runtime-comparison.md)
- [docs/testing/native-image-comparison.md](testing/native-image-comparison.md)
- [docs/testing/manual-container-runtime-inspection.md](testing/manual-container-runtime-inspection.md)
- [docs/testing/container-runtime-matrix-comparison.md](testing/container-runtime-matrix-comparison.md)

This document keeps comparison context, metric interpretation, and reporting notes rather than duplicating the runbook steps from those guides.

## JVM Mode

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
- native benchmark runs do not use the manual inspection `DG_RUNTIME_*` container-limit controls

## Manual Container Runtime Evaluation

Current runtime-inspection assets:

- Compose definition: `compose.runtime-inspection.yml`
- load-test workload: `benchmarks/runtime-load-testing-workload.json`
- generated load-test output root: `target/runtime-load-testing/`

Current manual container evaluation capabilities:

- start PostgreSQL plus one selected JVM or native runtime container
- attach a local JVM tool through JMX for the JVM scenarios
- constrain CPU, memory, and PID count through documented Compose env vars
- run a repository-local `k6` load test while the runtime stays online

Interpretation limits for the current manual container evaluation flow:

- it is an interactive operator workflow, not a replacement for the unattended benchmark scripts
- VisualVM, JDK Mission Control, and JMX-based diagnostics apply to JVM scenarios only
- container resource limits and JVM memory flags must stay equivalent across Spring Boot and Quarkus if the results are compared

## Container Runtime Matrix Comparison

Current automated container-matrix assets:

- matrix workload: `benchmarks/container-runtime-matrix-workload.json`
- shared load-test workload: `benchmarks/runtime-load-testing-workload.json`
- machine-readable report shape: `benchmarks/container-runtime-matrix-report.schema.json`
- generated output root: `target/container-runtime-matrix/`

Current automated container-matrix capabilities:

- build and start `spring-jvm`, `quarkus-jvm`, `spring-native`, and `quarkus-native` sequentially
- reuse the same `DG_RUNTIME_*` resource controls across the full four-scenario run
- reuse the same `LOAD_TEST_*` profile across the full four-scenario run
- write scenario-level startup and runtime logs plus a combined summary table

Interpretation limits for the current container-matrix flow:

- it is a local developer workflow, not a CI gate or production load test
- the PostgreSQL baseline is recreated between scenarios
- native scenarios are compared through container-level metrics and load-test output rather than JVM-level diagnostics
- Spring Boot and Quarkus intentionally keep different native image build strategies

## Reporting

- keep one benchmark input dataset and one test command per runtime
- record environment details for every run: CPU, RAM, OS, Java version, Docker version if used
- separate framework effects from database effects by running the same PostgreSQL setup for both
- record the native build strategy for every native run: build command, builder reference, runtime base image, and produced artifact reference
- keep manual load-test artifacts alongside the rest of the repository-local comparison output under `target/`
