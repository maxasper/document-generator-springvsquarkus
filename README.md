# Document Generator Service Demo

This repository hosts a spec-first demo for comparing Spring Boot and Quarkus while keeping the same document generation business core. The project is intentionally structured around hexagonal architecture: domain and application code stay pure Java, while HTTP, persistence, and framework wiring live in adapters and runtime modules.

## Goal

- compare Spring Boot and Quarkus against the same service behavior and data model
- keep one shared business core reused by both runtime applications
- support JVM and native image comparison without changing domain logic

## Bounded V1 Scope

- `POST /api/v1/document-generations` generates a document and returns the file
- `GET /api/v1/document-generations` returns saved request history
- each request contains `documentFormat`, `templateType`, `documentName`, and `parameters`
- template type drives parameter validation rules
- document generation is a stub in v1
- generated file content is not stored in the database in v1
- persistence supports an in-memory baseline and a PostgreSQL-backed mode used by verification and comparison flows

## Module Structure

```text
document-generator-parent
├── document-generator-domain
├── document-generator-application
├── document-generator-adapter-out-renderer-stub
├── document-generator-app-spring
├── document-generator-app-quarkus
└── document-generator-contract-tests
```

- `document-generator-domain`: core domain model, value objects, and parameter validation rules
- `document-generator-application`: use cases, ports, and orchestration logic
- `document-generator-adapter-out-renderer-stub`: shared stub document renderer used by both runtimes
- `document-generator-app-spring`: Spring Boot entrypoint plus Spring-specific REST and persistence adapters
- `document-generator-app-quarkus`: Quarkus entrypoint plus Quarkus-specific REST and persistence adapters
- `document-generator-contract-tests`: runtime-agnostic HTTP contract tests that can be executed against either application

The initial decision is to keep HTTP and persistence adapters inside each runtime module. That keeps the framework comparison explicit and avoids premature abstractions in the first iteration.

Both runtime applications keep `in-memory` as the default local mode and expose a PostgreSQL-backed `postgres` profile for verification, benchmarking, and manual container inspection. In PostgreSQL mode each runtime switches its repository adapter to JDBC and applies the runtime-local Flyway migration from `db/migration`.

## Repository Guide

- [docs/module-structure.md](docs/module-structure.md)
- [docs/project-rules.md](docs/project-rules.md)
- [docs/v1-scope.md](docs/v1-scope.md)
- [docs/roadmap.md](docs/roadmap.md)
- [docs/risks-and-open-questions.md](docs/risks-and-open-questions.md)
- [docs/runtime-comparison-plan.md](docs/runtime-comparison-plan.md)
- [docs/testing/benchmark-architecture.md](docs/testing/benchmark-architecture.md)
- [docs/testing/runtime-verification.md](docs/testing/runtime-verification.md)
- [docs/testing/jvm-runtime-comparison.md](docs/testing/jvm-runtime-comparison.md)
- [docs/testing/native-image-comparison.md](docs/testing/native-image-comparison.md)
- [docs/testing/manual-container-runtime-inspection.md](docs/testing/manual-container-runtime-inspection.md)
- [docs/testing/container-runtime-matrix-comparison.md](docs/testing/container-runtime-matrix-comparison.md)
- [openspec/changes/archive/2026-04-20-add-runtime-e2e-verification/proposal.md](openspec/changes/archive/2026-04-20-add-runtime-e2e-verification/proposal.md)
- [openspec/changes/archive/2026-04-20-establish-document-generator-foundation/proposal.md](openspec/changes/archive/2026-04-20-establish-document-generator-foundation/proposal.md)

## Spec-First Workflow

Archived changes live under `openspec/changes/archive/`, and the current synced specification tree lives under `openspec/specs/`.

Recent archived changes cover:

- PostgreSQL-backed runtime verification
- JVM runtime comparison
- native-image comparison
- manual Compose-based container inspection, container resource limits, and repository-local load testing

## Maven Wrapper

Use `./mvnw` instead of the system `mvn`.

- the wrapper is pinned to Maven `3.9.11`
- repo-local Maven settings live under `.mvn/`
- `./mvnw` forces Maven to use `.mvn/global-settings.xml` and `.mvn/settings.xml`, so it does not inherit the machine-wide `toolset.phoenixit.ru` repository configuration
- downloaded dependencies are stored in `.mvn/repository`
- the wrapper prefers `JAVA_HOME` if you set it explicitly
- otherwise it reads the required JDK from `.mvn/java-version` and auto-picks a matching local installation
- if the required JDK is not installed locally, the wrapper fails fast with a clear error instead of silently using an older Java

This repository is pinned to Java `25` in `.mvn/java-version`, and `pom.xml` is compiled with `maven.compiler.release=25`. That is the current project baseline and should be treated as the default JDK for all local builds.

The rationale is simple: as of April 20, 2026, Java 25 is the latest LTS release. Source: Oracle Java SE Support Roadmap.

If you intentionally migrate the repo to a newer LTS later, update both:

1. `.mvn/java-version`
2. `maven.compiler.release` in `pom.xml`

## Quality Gates

Run `./mvnw verify` from the repository root to execute the current shared build baseline:

1. Java and Maven version enforcement
2. unit tests and module packaging
3. repository-wide Checkstyle in `verify`
4. per-module JaCoCo reports plus the aggregate report at `document-generator-quality-report/target/site/jacoco-aggregate`

The quality baseline is intentionally shared across Spring Boot and Quarkus so the framework comparison is constrained by the same core rules.

## Testing And Benchmarking

Use the overview and workflow guides under `docs/testing/` depending on what you want to run:

- [Benchmark Architecture](docs/testing/benchmark-architecture.md)
  - overview of the repository's verification, host-JVM benchmark, native benchmark, manual container inspection, and container-matrix flows
- [Runtime Verification](docs/testing/runtime-verification.md)
  - shared contract verification for Spring Boot and Quarkus in `in-memory` and PostgreSQL-backed modes
- [JVM Runtime Comparison](docs/testing/jvm-runtime-comparison.md)
  - repository-local JVM benchmark flows and generated report layout
- [Native Image Comparison](docs/testing/native-image-comparison.md)
  - repository-local native benchmark flows and native-specific interpretation limits
- [Manual Container Runtime Inspection](docs/testing/manual-container-runtime-inspection.md)
  - Compose-based PostgreSQL plus one selected JVM or native runtime, optional JMX for JVM scenarios, container limits, and repository-local `k6` load testing
- [Container Runtime Matrix Comparison](docs/testing/container-runtime-matrix-comparison.md)
  - unattended Docker-to-Docker comparison across `spring/quarkus x jvm/native` under one shared limit and load profile

For comparison framing, metric interpretation, and reporting conventions across these workflows, see [docs/runtime-comparison-plan.md](docs/runtime-comparison-plan.md).
