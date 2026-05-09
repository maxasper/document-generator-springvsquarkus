## ADDED Requirements

### Requirement: Dedicated manual JVM inspection guide is linked from the repository entrypoint
The repository SHALL surface the documented manual JVM container inspection flow through a dedicated workflow guide linked from `README.md`.

#### Scenario: Developer can discover manual inspection workflow from README
- **WHEN** a developer uses `README.md` to find how to start a runtime manually for JMX inspection and load testing
- **THEN** the repository guide links to the dedicated manual JVM inspection document

#### Scenario: Manual inspection guide explains one-runtime-at-a-time operation
- **WHEN** a developer opens the dedicated manual JVM inspection document
- **THEN** the guide states that the supported workflow starts PostgreSQL and one selected runtime rather than running Spring Boot and Quarkus application containers simultaneously
