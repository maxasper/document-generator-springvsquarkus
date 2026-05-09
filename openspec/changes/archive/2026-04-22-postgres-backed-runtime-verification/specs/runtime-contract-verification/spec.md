## MODIFIED Requirements

### Requirement: Spring runtime contract verification flow
The repository SHALL provide documented and repeatable ways to start the Spring Boot application and execute the shared HTTP contract suite against it in both the baseline `in-memory` mode and the PostgreSQL-backed verification mode.

#### Scenario: Spring runtime is verified through the shared contract suite in `in-memory` mode
- **WHEN** a developer runs the documented Spring runtime verification flow for the baseline `in-memory` mode
- **THEN** the Spring Boot application starts on its baseline local port and the shared contract tests execute against that runtime through `document.generator.base-url`

#### Scenario: Spring runtime is verified through the shared contract suite in PostgreSQL-backed mode
- **WHEN** a developer runs the documented Spring runtime verification flow for the PostgreSQL-backed mode
- **THEN** the Spring Boot application starts with its PostgreSQL profile and the shared contract tests execute against that runtime through `document.generator.base-url`

### Requirement: Quarkus runtime contract verification flow
The repository SHALL provide documented and repeatable ways to start the Quarkus application and execute the shared HTTP contract suite against it in both the baseline `in-memory` mode and the PostgreSQL-backed verification mode.

#### Scenario: Quarkus runtime is verified through the shared contract suite in `in-memory` mode
- **WHEN** a developer runs the documented Quarkus runtime verification flow for the baseline `in-memory` mode
- **THEN** the Quarkus application starts on its baseline local port and the shared contract tests execute against that runtime through `document.generator.base-url`

#### Scenario: Quarkus runtime is verified through the shared contract suite in PostgreSQL-backed mode
- **WHEN** a developer runs the documented Quarkus runtime verification flow for the PostgreSQL-backed mode
- **THEN** the Quarkus application starts with its PostgreSQL profile and the shared contract tests execute against that runtime through `document.generator.base-url`

### Requirement: Shared HTTP contract suite across runtimes
The repository SHALL use one shared set of HTTP contract tests to verify document generation and history behavior for both runtime applications across both the baseline `in-memory` mode and the PostgreSQL-backed verification mode.

#### Scenario: Contract assertions remain runtime-agnostic in `in-memory` mode
- **WHEN** the runtime verification flow is executed for Spring Boot and Quarkus in the baseline `in-memory` mode
- **THEN** both flows use the same contract test module and assert the same generate and history endpoint behavior without duplicating runtime-specific test logic

#### Scenario: Contract assertions remain runtime-agnostic in PostgreSQL-backed mode
- **WHEN** the runtime verification flow is executed for Spring Boot and Quarkus in the PostgreSQL-backed mode
- **THEN** both flows use the same contract test module and assert the same generate and history endpoint behavior without duplicating runtime-specific test logic

## ADDED Requirements

### Requirement: Shared PostgreSQL verification setup
The repository SHALL provide one documented and repeatable PostgreSQL setup for local runtime verification that can be used by both Spring Boot and Quarkus without requiring a manually installed database.

#### Scenario: PostgreSQL-backed verification can start from repository-local automation
- **WHEN** a developer runs the documented PostgreSQL-backed runtime verification flow on a machine with Docker available
- **THEN** the repository provisions the PostgreSQL instance needed by the selected runtime verification path

### Requirement: PostgreSQL-backed verification starts from clean database state
The repository SHALL ensure that the PostgreSQL-backed verification flow starts from a clean database state so results do not depend on leftover data from earlier runs.

#### Scenario: PostgreSQL-backed verification is isolated from previous runs
- **WHEN** a developer executes the PostgreSQL-backed verification flow after a previous verification run
- **THEN** the selected runtime verifies against a freshly initialized PostgreSQL state before the shared contract tests are executed
