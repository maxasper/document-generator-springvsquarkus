## ADDED Requirements

### Requirement: Spring runtime contract verification flow
The repository SHALL provide a documented and repeatable way to start the Spring Boot application in `in-memory` mode and execute the shared HTTP contract suite against it.

#### Scenario: Spring runtime is verified through the shared contract suite
- **WHEN** a developer runs the documented Spring runtime verification flow
- **THEN** the Spring Boot application starts on its baseline local port and the shared contract tests execute against that runtime through `document.generator.base-url`

### Requirement: Quarkus runtime contract verification flow
The repository SHALL provide a documented and repeatable way to start the Quarkus application in `in-memory` mode and execute the shared HTTP contract suite against it.

#### Scenario: Quarkus runtime is verified through the shared contract suite
- **WHEN** a developer runs the documented Quarkus runtime verification flow
- **THEN** the Quarkus application starts on its baseline local port and the shared contract tests execute against that runtime through `document.generator.base-url`

### Requirement: Shared HTTP contract suite across runtimes
The repository SHALL use one shared set of HTTP contract tests to verify document generation and history behavior for both runtime applications.

#### Scenario: Contract assertions remain runtime-agnostic
- **WHEN** the runtime verification flow is executed for Spring Boot and Quarkus
- **THEN** both flows use the same contract test module and assert the same generate and history endpoint behavior without duplicating runtime-specific test logic

### Requirement: Baseline verification remains infrastructure-light
The first runtime verification baseline SHALL use the existing `in-memory` persistence mode and SHALL not require PostgreSQL.

#### Scenario: Verification can run before database-backed comparison
- **WHEN** a developer executes the first runtime verification flow on a machine without PostgreSQL running
- **THEN** the Spring Boot and Quarkus verification paths can still be executed against their `in-memory` configurations
