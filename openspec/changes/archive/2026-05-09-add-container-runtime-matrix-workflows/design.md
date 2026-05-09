## Context

The repository already has three partially overlapping runtime evaluation paths:

- host-run runtime verification and JVM comparison scripts that launch Spring Boot and Quarkus directly with `java`
- an automated native benchmark path that builds native images and starts native containers transiently
- a manual Compose inspection path for long-running JVM containers with JMX and repository-local `k6`

The missing piece is one coherent container-centric comparison layer that treats all four runtime scenarios the same way:

- `spring-jvm`
- `quarkus-jvm`
- `spring-native`
- `quarkus-native`

The user goal is to:

- start any scenario manually and inspect it under Docker resource limits
- run the same scenario automatically and collect reproducible results
- set CPU, memory, and load-profile conditions once and reuse them across all four scenarios
- get one summary table for the full four-scenario matrix

## Goals / Non-Goals

**Goals:**

- Introduce a shared runtime-and-mode selector model in repository scripts.
- Support manual Compose startup for JVM and native container runtimes, one application runtime at a time plus PostgreSQL.
- Reuse one repository-local `k6` workload and one set of Docker resource controls across manual and automated flows.
- Add an automated matrix report for the four container scenarios with consistent metadata: runtime, mode, limits, build/startup timings, load-test output, and observed container resource usage.
- Keep JMX support for JVM scenarios and provide container-level observation guidance for native scenarios.

**Non-Goals:**

- Replacing the existing host-based JVM benchmark flow.
- Replacing the existing framework-native artifact build paths.
- Running multiple application runtimes simultaneously in one comparison session.
- Introducing production-grade observability, orchestration, or remote profiling infrastructure.

## Decisions

### Decision: Use one shared `<runtime> <mode>` control surface

All new manual and automated scripts will accept or derive both a framework runtime (`spring|quarkus`) and an execution mode (`jvm|native`). This avoids maintaining separate script families with duplicated lifecycle logic.

Alternatives considered:

- Keep separate JVM and native script trees. Rejected because lifecycle, readiness, load-test, and cleanup behavior would diverge again.
- Hide mode inside script names only. Rejected because the automated matrix needs mode-aware orchestration and reporting anyway.

### Decision: Extend the existing Compose topology to include native services

The manual runtime Compose file will remain the local control plane for PostgreSQL, application runtime services, and `k6`. It will be extended with `spring-native` and `quarkus-native` services while preserving one-runtime-at-a-time startup through helper scripts.

Primary ports and assumptions:

- Spring Boot JVM HTTP: `18080 -> 8080`
- Quarkus JVM HTTP: `18081 -> 8081`
- Spring Boot native HTTP: `28080 -> 8080`
- Quarkus native HTTP: `28081 -> 8081`
- Spring Boot JVM JMX: `9010`
- Quarkus JVM JMX: `9011`
- native services expose no JMX port and rely on `docker stats`, logs, and load-test artifacts

Alternatives considered:

- Separate Compose files for JVM and native. Rejected because the user wants the same operator shape and shared container controls across all scenarios.
- Running native services outside Compose with ad-hoc `docker run`. Rejected because it would split manual and automated flows again.

### Decision: Keep framework-native image build paths, but wrap them in one shared build script layer

Image production will stay aligned with current framework idioms:

- Spring Boot JVM: existing JVM Dockerfile path
- Quarkus JVM: existing JVM Dockerfile path
- Spring Boot native: Spring Boot native profile plus `spring-boot:build-image`
- Quarkus native: Quarkus native container-build plus `Dockerfile.native-micro`

The repository will add a shared build helper that dispatches to the correct path based on `<runtime> <mode>`, so both manual and automated flows reuse the same build implementation.

Alternatives considered:

- Replace everything with one generic Dockerfile strategy. Rejected because it weakens framework-specific native comparison fidelity.
- Use only existing benchmark scripts as wrappers. Rejected because they include measurement logic and cleanup behavior that is too coupled to the old report formats.

### Decision: Reuse one shared container resource control surface

Manual and automated container-runtime flows will consume the same environment variables for resource controls. The existing `DG_RUNTIME_*` family is the most natural starting point and will be extended or documented for native scenarios as well:

- `DG_RUNTIME_CPUS`
- `DG_RUNTIME_MEMORY`
- `DG_RUNTIME_PIDS_LIMIT`
- `DG_RUNTIME_MAX_RAM_PERCENTAGE` for JVM scenarios only

The automated matrix scripts will read these values once and apply them uniformly across all four scenarios, then write them into the combined report for traceability.

Alternatives considered:

- Separate `MANUAL_*` and `MATRIX_*` variables. Rejected because the user explicitly wants one shared condition set that can be reused.

### Decision: Reuse the repository-local `k6` workload for automated matrix runs

The automated matrix will reuse the same load-test workload and overrides as the manual container flow:

- `LOAD_TEST_VUS`
- `LOAD_TEST_DURATION`
- workload request shape from `benchmarks/runtime-load-testing-workload.json`

The matrix orchestrator will call the same load-test helper used by manual runs, then aggregate the produced `summary.json` outputs into one matrix report and text table.

Alternatives considered:

- Maintain a separate benchmark-only HTTP loop. Rejected because it would create another load profile instead of one comparable pressure source.

### Decision: Introduce a dedicated container-runtime matrix report

The combined four-scenario flow will write a report under a new output root such as `target/container-runtime-matrix/`. Each scenario entry will include:

- runtime and mode
- image reference and build strategy metadata
- configured CPU, memory, PID, and JVM heap-percentage limits
- build duration
- container startup duration
- container-level observed memory or CPU snapshots
- load-test summary metrics such as request count, failure rate, average latency, and `p95`

This report is intentionally separate from the existing host-JVM and native benchmark report schemas because the measurement method and operator intent differ.

## Risks / Trade-offs

- [Different image build paths remain asymmetric] → Preserve that asymmetry explicitly in the report metadata and docs so the comparison remains honest rather than artificially normalized.
- [Compose file complexity increases] → Centralize runtime-mode mapping logic in shell helpers and keep service names predictable.
- [Native scenarios lack JVM-level tooling] → Document that native manual inspection is container-level only and keep JMX support JVM-only.
- [Longer automated matrix execution time] → Run scenarios sequentially, reuse helper scripts, and keep the load-test profile configurable through environment variables.
- [Observed `docker stats` metrics are noisier than in-process metrics] → Record the configured limits and use consistent collection points after readiness and load-test completion.

## Migration Plan

1. Add the mode-aware helper layer and native manual container services without removing existing JVM helpers.
2. Switch manual runbooks to the generalized container-runtime entrypoints.
3. Add the automated matrix report path and keep the existing host-JVM and native benchmark flows available side by side.
4. Validate all four scenarios individually, then validate the combined matrix run.
5. Archive the change only after documentation and scripts describe the containerized comparison path unambiguously.

## Open Questions

- Whether the final operator-facing commands should prefer `./scripts/run-compose-runtime.sh spring native` style selectors or thin named wrappers in addition to the generic entrypoint.
- Whether to sample container stats only before and after the `k6` run or also capture a short rolling window during load.
