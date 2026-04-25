# Document Generator Service Demo

This repository hosts a spec-first demo for comparing Spring Boot and Quarkus while keeping the same document generation business core. The project is intentionally structured around hexagonal architecture: domain and application code stay pure Java, while HTTP, persistence, and framework wiring live in adapters and runtime modules.

## Goal

- compare Spring Boot and Quarkus against the same service behavior and data model
- keep one shared business core reused by both runtime applications
- prepare for later JVM and native image comparison without changing domain logic

## Bounded V1 Scope

- `POST /api/v1/document-generations` generates a document and returns the file
- `GET /api/v1/document-generations` returns saved request history
- each request contains `documentFormat`, `templateType`, `documentName`, and `parameters`
- template type drives parameter validation rules
- document generation is a stub in v1
- generated file content is not stored in the database in v1
- persistence is designed for PostgreSQL, but the first vertical slice may start with an in-memory adapter to prove boundaries quickly

## Proposed Module Structure

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

For the current Spring slice, the default mode is `in-memory`. A PostgreSQL-backed mode is prepared through the `postgres` Spring profile, which switches the repository adapter to JDBC and runs the SQL migration from `db/migration`.

## Repository Guide

- [docs/module-structure.md](docs/module-structure.md)
- [docs/project-rules.md](docs/project-rules.md)
- [docs/v1-scope.md](docs/v1-scope.md)
- [docs/roadmap.md](docs/roadmap.md)
- [docs/risks-and-open-questions.md](docs/risks-and-open-questions.md)
- [docs/runtime-comparison-plan.md](docs/runtime-comparison-plan.md)
- [openspec/changes/archive/2026-04-20-add-runtime-e2e-verification/proposal.md](openspec/changes/archive/2026-04-20-add-runtime-e2e-verification/proposal.md)
- [openspec/changes/archive/2026-04-20-establish-document-generator-foundation/proposal.md](openspec/changes/archive/2026-04-20-establish-document-generator-foundation/proposal.md)

## Spec-First Workflow

The initial foundation change `establish-document-generator-foundation` is archived and its specs have been synced into `openspec/specs/`.

The most recently completed change is `postgres-backed-runtime-verification`. It extends runtime verification from the initial `in-memory` baseline to a repeatable PostgreSQL-backed flow for Spring Boot and Quarkus before JVM and native-image comparison work.

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

## Runtime Verification

Prerequisites:

- Java `25`
- use `./mvnw` from the repository root
- internet access on the first run if Maven still needs to download dependencies from Maven Central
- no PostgreSQL instance is required for the baseline `in-memory` verification flows
- Docker and Docker Compose are required for the PostgreSQL-backed verification flows

Run the shared HTTP contract suite against any already-running runtime:

```bash
./scripts/run-contract-tests.sh http://localhost:8080
```

Run the full Spring Boot `in-memory` verification flow on `http://localhost:8080`:

```bash
./scripts/verify-spring.sh
```

Run the full Quarkus `in-memory` verification flow on `http://localhost:8081`:

```bash
./scripts/verify-quarkus.sh
```

Run the full Spring Boot PostgreSQL-backed verification flow on `http://localhost:18080`:

```bash
./scripts/verify-spring-postgres.sh
```

Run the full Quarkus PostgreSQL-backed verification flow on `http://localhost:18081`:

```bash
./scripts/verify-quarkus-postgres.sh
```

The runtime verification scripts all follow the same baseline flow:

1. package the selected runtime and the shared modules it depends on
2. start the runtime on its baseline local port
3. wait until `GET /api/v1/document-generations` responds with `200`
4. execute the shared `document-generator-contract-tests` suite against that base URL
5. stop the runtime process

The PostgreSQL-backed verification scripts add one extra step before runtime startup:

1. recreate the Compose-backed PostgreSQL verification environment from `compose.postgres-verification.yml`
2. inject the PostgreSQL connection settings into the selected runtime
3. start Spring Boot on `18080` or Quarkus on `18081`
4. run the shared contract tests
5. tear down the PostgreSQL container and its data volume

Baseline PostgreSQL-backed verification settings:

- host: `localhost`
- port: `55432`
- database: `document_generator`
- username: `document_generator`
- password: `document_generator`

## Next Comparison Steps

After the PostgreSQL-backed parity baseline stays green for both runtimes, the next changes should focus on:

1. JVM-mode comparison using the same verified PostgreSQL-backed contract baseline
2. native-image comparison after the JVM-mode comparison path is stable
3. containerized application-runtime comparison only if the benchmark harness needs tighter CPU or memory normalization
