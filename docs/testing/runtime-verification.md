# Runtime Verification

## Purpose

Use this workflow when you want to verify Spring Boot or Quarkus behavior through the shared HTTP contract suite rather than measure performance.

## Prerequisites

- Java `25`
- use `./mvnw` from the repository root
- internet access on the first run if Maven still needs to download dependencies from Maven Central
- no PostgreSQL instance is required for the baseline `in-memory` verification flows
- Docker and Docker Compose are required for the PostgreSQL-backed verification flows

## Shared Contract Suite

Run the shared HTTP contract suite against any already-running runtime:

```bash
./scripts/run-contract-tests.sh http://localhost:8080
```

This is useful if you started the runtime manually and only want to rerun the common contract tests.

## `in-memory` Verification

### Spring Boot

```bash
./scripts/verify-spring.sh
```

- starts Spring Boot on `http://localhost:8080`
- waits for `GET /api/v1/document-generations` to return `200`
- runs the shared `document-generator-contract-tests` suite
- stops the runtime

### Quarkus

```bash
./scripts/verify-quarkus.sh
```

- starts Quarkus on `http://localhost:8081`
- waits for `GET /api/v1/document-generations` to return `200`
- runs the shared `document-generator-contract-tests` suite
- stops the runtime

## PostgreSQL-Backed Verification

Shared PostgreSQL baseline:

- host: `localhost`
- port: `55432`
- database: `document_generator`
- username: `document_generator`
- password: `document_generator`

The PostgreSQL-backed scripts recreate the repository-local database environment from `compose.postgres-verification.yml` before starting the selected runtime.

### Spring Boot

```bash
./scripts/verify-spring-postgres.sh
```

- starts PostgreSQL in Docker Compose
- starts Spring Boot on `http://localhost:18080` with the `postgres` profile
- runs the shared contract suite
- tears down the PostgreSQL container and data volume

### Quarkus

```bash
./scripts/verify-quarkus-postgres.sh
```

- starts PostgreSQL in Docker Compose
- starts Quarkus on `http://localhost:18081` with the `postgres` profile
- runs the shared contract suite
- tears down the PostgreSQL container and data volume

## Lower-Level Entry Point

If you want to call the generic script directly:

```bash
./scripts/verify-runtime.sh spring in-memory
./scripts/verify-runtime.sh quarkus in-memory
./scripts/verify-runtime.sh spring postgres
./scripts/verify-runtime.sh quarkus postgres
```

## Output and Logs

- these verification scripts do not write persistent repository-local artifacts under `target/`
- on success, temporary runtime logs are removed automatically
- on failure, the script prints the temporary log path and the tail of the runtime log

## Cleanup

- application processes are stopped automatically
- PostgreSQL-backed verification also tears down the Compose environment automatically

## Interpretation Limits

- this is a behavioral verification workflow, not a benchmark
- use it to confirm parity and contract correctness, not to compare latency or memory numbers
- the PostgreSQL-backed flows depend on local Docker availability
