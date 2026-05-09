## Context

The repository already has:

- repeatable `in-memory` and PostgreSQL-backed runtime verification for Spring Boot and Quarkus
- a repository-local JVM comparison harness with shared workload, shared report format, and sequential Spring-versus-Quarkus execution

What is still missing is the native-image comparison layer that the project roadmap has always reserved as the next step after JVM-mode parity and benchmarking.

The design must preserve the same constraints as the JVM harness:

- `document-generator-domain` and `document-generator-application` remain framework-neutral
- Spring Boot and Quarkus remain separate runnable modules with separate build integrations
- native comparison must exercise the same PostgreSQL-backed HTTP behavior as the existing runtime verification and JVM comparison flows
- native comparison must remain repository-local and debuggable from shell scripts rather than a deeply coupled Maven lifecycle
- native comparison should reflect the native build and packaging workflows that the two frameworks actually recommend, instead of forcing a synthetic shared Dockerfile or a shared raw GraalVM invocation

## Goals / Non-Goals

**Goals:**

- define one repeatable native-image comparison flow for Spring Boot and Quarkus
- reuse the existing PostgreSQL-backed behavioral baseline and shared HTTP workload discipline
- measure the same comparison categories for both native runtimes:
  - native build time
  - produced deployable native artifact size
  - cold startup time
  - steady-state runtime memory footprint
  - measured latency for `POST /api/v1/document-generations`
  - measured latency for `GET /api/v1/document-generations`
- rerun the same shared contract checks against both native runtimes before measured benchmarking
- write machine-readable results plus a concise human summary under a native-specific output directory
- document native build prerequisites, commands, and interpretation limits
- keep the runtime-specific native build strategy visible in the resulting report

**Non-Goals:**

- changing the document generation API or shared contract semantics
- forcing Spring Boot and Quarkus to share one common multi-stage Dockerfile or one common raw GraalVM build command
- turning native comparison into a CI gate
- pursuing statistically rigorous performance testing beyond a local comparison baseline
- extracting a new shared runtime module only for native benchmarking

## Decisions

### Decision: Reuse the PostgreSQL-backed HTTP baseline and the shared contract suite

Native comparison will run the same real HTTP boundary as the JVM harness:

- the selected native runtime starts against the shared PostgreSQL-backed setup
- the shared contract tests are executed against the native runtime before measured benchmarking starts
- measured requests still target `POST /api/v1/document-generations` and `GET /api/v1/document-generations`

This keeps the native benchmark tied to verified behavior instead of allowing a benchmark-only fast path.

Alternatives considered:

- benchmark native binaries without rerunning contract checks: rejected because a faster native build is not useful if behavior silently diverges
- use a benchmark-only request path: rejected because it would weaken parity with the rest of the repository comparison model

### Decision: Use framework-native containerized build flows instead of forcing a common raw native-image baseline

The first native comparison slice will preserve the native build and packaging approach that is idiomatic for each framework:

- Spring Boot should use the Spring Boot native container-image flow based on buildpacks
- Quarkus should use the Quarkus native container-build flow and its native container-image packaging path

This intentionally compares the frameworks as developers would normally build and package them in native mode, instead of flattening the differences into one artificial shared Dockerfile.

This keeps the comparison honest to the repository goal:

- Spring Boot native ergonomics are evaluated through Spring Boot's own path
- Quarkus native ergonomics are evaluated through Quarkus' own path
- the behavioral and database baseline stays shared even though the build path differs

Alternatives considered:

- force both runtimes through one common multi-stage Dockerfile: rejected because it would hide meaningful framework-level native build differences
- force both runtimes through one common local GraalVM installation: rejected because it optimizes for toolchain uniformity over framework-native developer experience

### Decision: Treat the produced native delivery artifact as the primary artifact under comparison

Because the selected framework-native flows produce containerized native delivery artifacts, the comparison should record the produced deployable artifact and its size rather than insisting on one shared on-disk binary convention.

This means the native report should include:

- runtime identifier
- build strategy identifier
- produced image or artifact reference
- produced artifact size
- startup time
- steady-state runtime memory footprint
- generate and history latency summaries
- host environment details
- build-tool and container-strategy details needed to interpret the run

Alternatives considered:

- insist on comparing only naked native binaries on disk: rejected because Spring Boot's official native path naturally centers on container-image production
- record only build duration and ignore produced artifact shape: rejected because deployable artifact size is a meaningful part of the comparison

### Decision: Keep the existing HTTP workload discipline but separate native output and report contracts

The native harness should reuse the same HTTP workload shape as the JVM harness where possible, but write into a native-specific output tree and report contract:

- workload definition under `benchmarks/native-image-comparison-workload.json`
- machine-readable report contract under `benchmarks/native-image-comparison-report.schema.json`
- generated output under `target/native-image-comparison/`

The native report must include:

- runtime identifier
- build strategy metadata
- native build time
- native delivery artifact reference and size
- startup time
- steady-state runtime memory footprint
- generate and history latency summaries
- host environment details

Alternatives considered:

- reuse the JVM report schema verbatim: rejected because native comparison must carry extra build-strategy metadata and should remain clearly separate from JVM results
- reuse the JVM output directory: rejected because mixing JVM and native results would make interpretation and cleanup harder

### Decision: Keep Spring and Quarkus native execution sequential and reset the database baseline between runs

The combined native comparison command will benchmark Spring Boot and Quarkus one after the other, just like the JVM harness, and recreate the PostgreSQL-backed baseline between runtime runs.

This keeps the comparison consistent with the current repository discipline and reduces hidden contention.

Alternatives considered:

- run both native binaries at once: rejected because host contention would weaken the signal
- keep one database state for both native runs: rejected because history accumulation would leak into the second runtime's measured requests

### Decision: Use thin runtime-specific wrappers on top of shared native orchestration

The native implementation should follow the same shape as the JVM benchmark layer:

- one shared native benchmark runner
- one Spring Boot wrapper
- one Quarkus wrapper
- one combined native comparison command

The runtime-specific wrappers remain responsible only for:

- native build invocation according to the framework's own recommended path
- produced container or artifact resolution
- runtime-specific launch flags, image names, and ports

Alternatives considered:

- embed all native logic in one monolithic script: rejected because it would be harder to debug when one runtime build path changes
- push native orchestration deep into Maven profiles only: rejected because startup timing, process control, and report generation are easier to understand in thin scripts

## Risks / Trade-offs

- [Spring Boot and Quarkus use different native build chains] → Accept this as part of the comparison goal and record the selected strategy explicitly in the report.
- [Produced artifact types differ from the local-binary JVM harness] → Compare deployable artifact size and runtime behavior instead of forcing a fake shared binary layout.
- [Native builds are much slower than JVM packaging] → Keep the benchmark output machine-readable and reusable so developers do not need to rerun builds unnecessarily.
- [Runtime memory measurement becomes container-oriented] → Record the chosen measurement strategy in the report and keep interpretation limits explicit.
- [Buildpacks and Quarkus native builders normalize environments differently] → Treat that as a real framework-level difference, not as noise to be erased in this change.

## Migration Plan

1. Redefine the native benchmark workload and report contract around framework-native containerized native delivery.
2. Add shared native comparison automation for build, startup, contract verification, measured requests, memory capture, and report generation.
3. Wire the Spring Boot native flow through the documented Spring Boot build-image path.
4. Wire the Quarkus native flow through the documented Quarkus native container-build path.
5. Add one combined native comparison command and document how to interpret the results relative to the JVM benchmark.

Rollback is low risk because the change adds comparison automation and documentation only. If the native harness proves too brittle, the repository can remove the scripts and benchmark assets without affecting the existing JVM comparison or runtime verification baselines.

## Open Questions

- Should the first report record only delivered image size, or both image size and extracted native executable size when the framework path makes that practical?
- Should the first runtime-memory metric be container memory only, or container memory plus in-container process RSS when the image layout allows simple introspection?
