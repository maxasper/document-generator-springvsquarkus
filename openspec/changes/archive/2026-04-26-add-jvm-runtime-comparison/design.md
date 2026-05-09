## Context

The repository already has two verified runtime flows:

- Spring Boot can be started and verified against the shared HTTP contract suite in both `in-memory` and PostgreSQL-backed modes
- Quarkus can be started and verified against the same shared HTTP contract suite in both `in-memory` and PostgreSQL-backed modes

What is still missing is a repeatable JVM-only comparison layer that measures both runtimes against the same PostgreSQL-backed baseline and records the output in one comparable format.

The design must preserve the current architecture:

- `document-generator-domain` and `document-generator-application` remain framework-neutral
- `document-generator-app-spring` and `document-generator-app-quarkus` remain separate runnable modules
- the benchmark must exercise the real HTTP boundary and the real PostgreSQL-backed persistence path
- benchmark automation must stay repository-local and easy to run during development

## Goals / Non-Goals

**Goals:**

- define one repeatable JVM comparison flow for Spring Boot and Quarkus
- reuse the existing PostgreSQL-backed runtime setup and endpoint contract as the benchmark baseline
- measure the same metric set for both runtimes:
  - cold startup time
  - steady-state RSS
  - request latency for `POST /api/v1/document-generations`
  - request latency for `GET /api/v1/document-generations`
  - build time
  - packaged artifact size
- write results in one machine-readable report format and one human-readable summary
- document the benchmark assumptions, commands, and interpretation boundaries

**Non-Goals:**

- native-image comparison
- containerized application-runtime comparison with CPU or memory limits
- changing the business API or the shared contract test assertions
- statistically rigorous load testing, CI performance gates, or production-grade benchmarking infrastructure
- introducing a new shared runtime module just for benchmarking

## Decisions

### Decision: Benchmark both runtimes on the existing PostgreSQL-backed baseline

The JVM comparison flow will build on the already verified PostgreSQL-backed runtime setup instead of introducing a separate benchmark-only data path.

That means:

- the existing Compose-backed PostgreSQL environment remains the database baseline
- Spring Boot continues to use its PostgreSQL profile and benchmark port
- Quarkus continues to use its PostgreSQL profile and benchmark port
- both runtimes are still exercised through `POST /api/v1/document-generations` and `GET /api/v1/document-generations`

This keeps the comparison aligned with the current repository roadmap: behavior first, then JVM comparison on the verified persistence baseline.

Alternatives considered:

- benchmarking the `in-memory` mode only: rejected because it would hide database-integration costs and produce a weaker comparison signal
- introducing a benchmark-only database path: rejected because it would create one more execution mode to maintain without adding comparison value

### Decision: Run Spring and Quarkus benchmarks sequentially, never concurrently

The comparison harness will benchmark one runtime at a time and reset the PostgreSQL state between runtime runs.

This keeps the resource model simple:

- no cross-runtime contention for CPU, memory, or the database
- no need for process orchestration that keeps both runtimes alive at once
- cleaner attribution of startup, memory, and latency metrics to the selected runtime

Alternatives considered:

- running both runtimes concurrently: rejected because shared host contention would distort the comparison
- forcing both runtimes onto one common port: rejected because the existing runtime-specific ports are already documented and do not affect the comparison outcome

### Decision: Use one shared benchmark workload and one shared measurement sequence

The benchmark flow will use one repository-local workload definition for both runtimes.

The shared sequence will include:

1. package the selected runtime and measure build time
2. determine packaged artifact size from the runtime output
3. start the runtime in PostgreSQL-backed mode and measure cold startup until `GET /api/v1/document-generations` returns `200`
4. run a small warmup sequence against the existing generate and history endpoints
5. execute a measured sequence for the same generate and history operations
6. capture steady-state RSS while the runtime is still alive
7. stop the runtime and persist the results

The workload itself should stay simple and deterministic, reusing the same request shape that is already covered by the shared contract tests.

Alternatives considered:

- introducing JMH or a separate load-testing framework: rejected because the repository needs a reproducible comparison baseline, not a full benchmarking platform
- measuring only one endpoint: rejected because this repository exposes both document generation and generation history as first-class behavior

### Decision: Emit machine-readable results plus a concise human summary

The benchmark automation will write one machine-readable report, likely JSON, and one human-readable summary under a repository-local generated output directory such as `target/jvm-runtime-comparison/`.

The report must include:

- runtime identifier
- measured metrics
- benchmark timestamps
- Java version
- OS information
- CPU and memory environment details
- Docker version when the PostgreSQL setup depends on Docker

This makes the comparison useful both for local reading and for later scripted diffing or trend tracking.

Alternatives considered:

- printing metrics only to stdout: rejected because results become hard to compare across runs
- committing benchmark outputs into the repository: rejected because generated benchmark data should remain ephemeral unless a later reporting change says otherwise

### Decision: Prefer thin repository-local scripts over deeper Maven lifecycle coupling

The implementation should use small repository-local automation scripts that orchestrate packaging, runtime startup, benchmarking, and report generation. They may reuse existing verification scripts or factor their shared pieces, but they should remain debuggable from the command line.

No new Maven module is required for the comparison harness itself.

Alternatives considered:

- embedding the full benchmark flow in Maven integration-test phases: rejected because startup timing, RSS capture, and per-runtime process control are easier to reason about in thin scripts
- adding a dedicated Java benchmark runner module: rejected for now because it would increase structure before the benchmark contract is proven

## Risks / Trade-offs

- [Host-machine noise affects timings] → Record environment metadata and keep the sequence small, deterministic, and explicitly local-developer oriented.
- [Build timing becomes dominated by dependency download or cold caches] → Document that comparison runs should happen with dependencies already resolved and capture the exact command used.
- [RSS measurement differs by operating system] → Treat the first implementation as Linux-first unless a portable technique proves simple enough; document this assumption explicitly.
- [History endpoint latency depends on prior generated rows] → Reset PostgreSQL state between runtime runs and use the same warmup and measured request counts for both runtimes.
- [Comparison scripts drift away from verification scripts] → Reuse existing PostgreSQL-backed startup assumptions and ports instead of inventing a separate launcher model.

## Migration Plan

1. Define the benchmark inputs, metric names, and report shape.
2. Add shared comparison automation that can package, start, benchmark, and stop one selected runtime.
3. Wire the Spring Boot JVM comparison flow on top of the shared automation.
4. Wire the Quarkus JVM comparison flow on top of the shared automation.
5. Add one combined comparison command and document how to read the results.

Rollback is low risk because the change only adds comparison automation and documentation. If the benchmark harness proves misleading or too brittle, the repository can remove the scripts and report files without affecting the existing runtime verification baseline.

## Open Questions

- Should the first report format include percentile latency metrics, or is average plus min/max enough for the initial comparison slice?
- Do we want the first implementation to keep only `latest` results, or also timestamped historical result files under the generated output directory?
