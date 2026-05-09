## Context

The repository already has a working `in-memory` runtime verification baseline and both runtime modules already contain PostgreSQL-oriented configuration. Spring Boot has a dedicated `application-postgres.properties` profile, and Quarkus already defines `%postgres` datasource and Flyway settings in its main application config.

What is still missing is a repeatable way to verify both runtimes against the same PostgreSQL setup before any JVM or native-image comparison starts. That next step should preserve the current architecture:

- Spring Boot and Quarkus remain separate runnable modules
- the shared business core stays untouched
- verification still happens through the external HTTP contract tests
- the next step focuses on parity, not benchmarking

## Goals / Non-Goals

**Goals:**

- define one repeatable PostgreSQL-backed verification flow for Spring Boot
- define one repeatable PostgreSQL-backed verification flow for Quarkus
- provision one shared PostgreSQL setup for local verification without requiring a manually installed database
- keep using the shared `document-generator-contract-tests` module through `document.generator.base-url`
- document the PostgreSQL-backed verification flow as the next milestone after the `in-memory` baseline

**Non-Goals:**

- containerizing the Spring Boot and Quarkus applications for benchmarking in this change
- adding CPU or memory comparison harnesses in this change
- changing the HTTP API, the business-core contracts, or the persistence model itself
- introducing CI pipelines beyond what is needed for a repeatable local verification path

## Decisions

### Decision: Provision PostgreSQL through Docker Compose

The change will use one repository-local `docker-compose.yml` or equivalent Compose file to start PostgreSQL for verification.

Why this approach:

- both runtimes will talk to the same external database shape
- local verification will not depend on a developer already running PostgreSQL manually
- the setup stays explicit and easy to inspect when verification fails

Alternatives considered:

- requiring a manually installed PostgreSQL instance: rejected because it makes parity verification less reproducible
- using separate PostgreSQL setups per runtime: rejected because it weakens the comparison signal
- using an embedded database: rejected because it would not verify the intended PostgreSQL-backed path

### Decision: Keep the application runtimes local JVM processes for this change

Spring Boot and Quarkus will still be packaged and started as local JVM processes, just as in the current `in-memory` verification flow. Only PostgreSQL will be containerized in this change.

Why this approach:

- it extends the current thin verification automation instead of replacing it
- it isolates the persistence-mode change from future benchmarking concerns
- it keeps debugging simple when a runtime fails before reaching the HTTP boundary

Alternatives considered:

- containerizing both runtimes now: rejected because it mixes parity verification with the later JVM comparison phase
- adding a full benchmark harness now: rejected because correctness against PostgreSQL should come first

### Decision: Reuse the existing helper-script verification model

The PostgreSQL-backed flow should extend the current script-based approach with PostgreSQL-specific commands rather than introducing heavy Maven lifecycle orchestration.

The intended flow remains:

1. start a clean PostgreSQL instance
2. package and start one runtime with its PostgreSQL profile
3. wait for the HTTP endpoint to become ready
4. execute the shared contract suite against that runtime
5. stop the runtime and tear down the PostgreSQL environment

Alternatives considered:

- embedding the whole lifecycle into Maven integration-test phases: rejected because the two runtimes still have different startup models
- creating framework-specific end-to-end tests inside each runtime module: rejected because it would duplicate assertions and weaken parity guarantees

### Decision: Standardize on one Compose-backed PostgreSQL connection shape with isolated host ports

The first PostgreSQL-backed verification path should use one baseline local database shape shared by both runtimes:

- host: `localhost`
- host port: `55432`
- container port: `5432`
- database: `document_generator`
- username: `document_generator`
- password: `document_generator`

The runtime verification scripts should inject these settings into the application processes so the repository can avoid conflicts with a developer's existing local PostgreSQL instance.

For the same reason, the PostgreSQL-backed runtime flows should use isolated HTTP ports:

- Spring Boot on `http://localhost:18080`
- Quarkus on `http://localhost:18081`

Alternatives considered:

- keeping PostgreSQL on host port `5432`: rejected after confirming that local port collisions are likely on developer machines
- reusing `8080` and `8081` for PostgreSQL-backed verification: rejected because those ports may already be used by local `in-memory` runs or other development processes

## Risks / Trade-offs

- [Default local development ports may already be occupied] → Use dedicated PostgreSQL-backed ports and inject database settings through the verification scripts.
- [PostgreSQL state can leak between runs] → Start from a clean Compose-backed database state for each verification flow.
- [Spring and Quarkus may diverge in Flyway or JDBC startup behavior] → Keep the same SQL migration scripts and verify both flows through the same HTTP contract suite.
- [Docker becomes a local prerequisite] → Limit Docker usage in this change to PostgreSQL only, not the application runtimes.

## Migration Plan

1. Add one shared Compose-based PostgreSQL setup for local verification.
2. Add Spring Boot PostgreSQL-backed verification commands on top of the existing runtime scripts.
3. Add Quarkus PostgreSQL-backed verification commands on top of the existing runtime scripts.
4. Verify both runtimes locally against the shared PostgreSQL setup.
5. Update README and comparison-oriented documentation to place PostgreSQL-backed verification before JVM/native comparison.

Rollback is low risk because the change only adds verification orchestration and documentation around existing PostgreSQL-aware runtime wiring.

## Open Questions

- When the project moves to JVM benchmarking, should the Compose-based PostgreSQL setup stay as the default comparison database, or should the comparison harness promote a separate benchmark-specific Compose file?
