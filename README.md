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

## JVM Runtime Comparison

Prerequisites:

- Java `25`
- Docker and Docker Compose
- `curl`
- `jq`
- use `./mvnw` from the repository root
- prefer a warm dependency cache in `.mvn/repository` if you want the build-time metric to reflect packaging work instead of first-time downloads

The shared benchmark contract is defined in:

- `benchmarks/jvm-runtime-comparison-workload.json`
- `benchmarks/jvm-runtime-comparison-report.schema.json`

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

The JVM benchmark flows all reuse the PostgreSQL-backed runtime path and measure:

1. build duration
2. packaged runtime artifact size
3. cold startup time until `GET /api/v1/document-generations` returns `200`
4. steady-state RSS after warmup and measured requests
5. measured latency for `POST /api/v1/document-generations`
6. measured latency for `GET /api/v1/document-generations`

Generated benchmark output is written under `target/jvm-runtime-comparison/`.

- `latest/` points to the most recent run directory
- per-runtime flows emit one `report.json` plus `runtime.log`
- the combined flow emits:
  - `spring/report.json`
  - `quarkus/report.json`
  - `report.json`
  - `summary.txt`

Interpretation limits:

- this is a local comparison harness, not a statistically rigorous load test
- compare results only across runs made on the same machine with similar background load
- Spring Boot artifact size is measured from the packaged fat jar
- Quarkus artifact size is measured from the packaged `quarkus-app/` directory
- the first implementation is Linux-first for RSS and memory environment capture

## Native Image Comparison

Prerequisites:

- Java `25`
- Docker and Docker Compose
- `curl`
- `jq`
- use `./mvnw` from the repository root
- internet access on the first run so Docker and Maven can pull builder images, base images, and plugins
- prefer a warm dependency cache in `.mvn/repository` and warm Docker image cache if you want the build-time metric to reflect native build work instead of first-time downloads

The native benchmark scripts preserve the build path recommended by each framework instead of forcing a shared Dockerfile or a shared raw `native-image` invocation:

- Spring Boot uses the Spring Boot native buildpacks path via `spring-boot:build-image`
- Quarkus uses the Quarkus native container-build path to produce the native runner and then packages it with the Quarkus-style `Dockerfile.native-micro`

The shared native benchmark contract is defined in:

- `benchmarks/native-image-comparison-workload.json`
- `benchmarks/native-image-comparison-report.schema.json`

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

The native benchmark flows all reuse the PostgreSQL-backed runtime path and add one extra safety step before measured benchmarking starts:

1. build the selected native delivery artifact with the framework-native container build path
2. start the produced native runtime container against the PostgreSQL benchmark baseline
3. wait until `GET /api/v1/document-generations` returns `200`
4. rerun the shared `document-generator-contract-tests` suite against that native runtime
5. run warmup requests followed by measured generate and history requests
6. capture steady-state container memory usage and write the machine-readable report

Generated native benchmark output is written under `target/native-image-comparison/`.

- `latest/` points to the most recent run directory
- per-runtime flows emit one `report.json` plus `runtime.log`
- the combined flow emits:
  - `spring/report.json`
  - `quarkus/report.json`
  - `report.json`
  - `summary.txt`

Interpretation limits:

- this is a local comparison harness, not a CI gate or production load test
- compare results only across runs made on the same machine with similar background load
- the native layer intentionally preserves framework-level build differences instead of flattening them into one shared Dockerfile
- Spring Boot artifact size is measured from the produced OCI image built through buildpacks
- Quarkus artifact size is measured from the produced OCI image built from the native runner and `Dockerfile.native-micro`
- steady-state memory is measured as current Docker container memory usage, not as host-process RSS
- build-time results depend heavily on Docker image cache state, dependency-cache warmth, and background host load

## Manual JVM Container Inspection

Prerequisites:

- Java `25`
- Docker and Docker Compose
- `curl`
- `jq`
- use `./mvnw` from the repository root
- a local JVM inspection tool if you want Java-level live diagnostics:
  - `VisualVM`, or
  - `JDK Mission Control`

This workflow is intentionally JVM-only. It is meant for live Java inspection through JMX while the runtime stays online. Native-image containers remain outside this first manual-inspection slice because Java heap, thread, class, and GC tooling does not apply to them in the same way.

Build the JVM container image for one runtime:

```bash
./scripts/build-compose-runtime-image.sh spring
./scripts/build-compose-runtime-image.sh quarkus
```

Start Spring Boot manually in Compose:

```bash
./scripts/run-compose-spring-jvm.sh
```

Start Quarkus manually in Compose:

```bash
./scripts/run-compose-quarkus-jvm.sh
```

The manual Compose runtime workflow:

1. recreates the PostgreSQL-backed local environment from `compose.runtime-inspection.yml`
2. starts one JVM runtime container in PostgreSQL-backed mode
3. waits until `GET /api/v1/document-generations` returns `200`
4. keeps the runtime online for manual inspection and follow-up load testing

Default host endpoints:

- Spring Boot HTTP: `http://localhost:18080`
- Spring Boot JMX: `service:jmx:rmi:///jndi/rmi://127.0.0.1:9010/jmxrmi`
- Quarkus HTTP: `http://localhost:18081`
- Quarkus JMX: `service:jmx:rmi:///jndi/rmi://127.0.0.1:9011/jmxrmi`

Useful local inspection views:

- Java-level live diagnostics: connect `VisualVM` or `JDK Mission Control` to the runtime JMX endpoint
- Container-level resource view: `docker stats`

Resource-limit controls are applied through Docker Compose env vars before startup:

```bash
DG_RUNTIME_CPUS=1.5 \
DG_RUNTIME_MEMORY=512m \
DG_RUNTIME_PIDS_LIMIT=256 \
DG_RUNTIME_MAX_RAM_PERCENTAGE=75.0 \
./scripts/run-compose-spring-jvm.sh
```

Supported limit knobs:

- `DG_RUNTIME_CPUS`: Docker CPU quota for the selected runtime container
- `DG_RUNTIME_MEMORY`: Docker memory limit for the selected runtime container
- `DG_RUNTIME_PIDS_LIMIT`: process-count limit for the selected runtime container
- `DG_RUNTIME_MAX_RAM_PERCENTAGE`: JVM heap sizing cap relative to the container memory limit

Run the repository-local load test against the active runtime:

```bash
./scripts/load-test-spring-compose.sh
./scripts/load-test-quarkus-compose.sh
```

The shared load-test workload is defined in:

- `benchmarks/runtime-load-testing-workload.json`

Generated load-test output is written under `target/runtime-load-testing/`.

- `latest/` points to the most recent run directory
- each runtime run emits:
  - `summary.json`
  - `summary.txt`
  - `k6.log`

The default load-test profile uses containerized `k6`, so no host installation is required. You can override the default VUs and duration per run:

```bash
LOAD_TEST_VUS=20 \
LOAD_TEST_DURATION=45s \
./scripts/load-test-spring-compose.sh
```

Validated local sessions on `2026-05-03`:

- Spring Boot:
  - build: `./scripts/build-compose-runtime-image.sh spring`
  - startup: `./scripts/run-compose-spring-jvm.sh`
  - applied default limits: `768m`, `2.0 CPU`, `256` PIDs
  - load test: `./scripts/load-test-spring-compose.sh`
  - validated artifact dir: `target/runtime-load-testing/20260503T095933Z-spring/`
  - observed summary: `532` requests, `0` failures, `73.34ms` average latency, `178.21ms` p95 latency
- Quarkus:
  - build: `./scripts/build-compose-runtime-image.sh quarkus`
  - startup: `DG_RUNTIME_CPUS=1.5 DG_RUNTIME_MEMORY=512m DG_RUNTIME_PIDS_LIMIT=256 DG_RUNTIME_MAX_RAM_PERCENTAGE=75.0 ./scripts/run-compose-quarkus-jvm.sh`
  - applied override limits: `512m`, `1.5 CPU`, `256` PIDs, `MaxRAMPercentage=75.0`
  - load test: `./scripts/load-test-quarkus-compose.sh`
  - validated artifact dir: `target/runtime-load-testing/20260503T113216Z-quarkus/`
  - observed summary: `580` requests, `0` failures, `31.14ms` average latency, `60.09ms` p95 latency

Stop and clean the manual runtime environment:

```bash
./scripts/compose-runtime-down.sh
```

Interpretation limits:

- this is an interactive local operator workflow, not a production-grade monitoring stack
- compare results only across runs made on the same machine and under similar background load
- JMX is configured for local-only use with authentication and SSL disabled; do not reuse these settings in shared or remote environments
- container limits affect JVM behavior, so compare Spring Boot and Quarkus only under the same `DG_RUNTIME_*` settings
- this workflow complements the existing JVM and native benchmark scripts; it does not replace them

## Next Comparison Steps

After the native-image baseline stays green and stable, the next changes should focus on:

1. containerized application-runtime comparison only if the benchmark harness needs tighter CPU or memory normalization
