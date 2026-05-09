## ADDED Requirements

### Requirement: Dedicated JVM comparison guide is linked from the repository entrypoint
The repository SHALL surface the documented JVM runtime comparison flow through a dedicated workflow guide linked from `README.md`.

#### Scenario: Developer can discover JVM comparison workflow from README
- **WHEN** a developer uses `README.md` to find how to benchmark Spring Boot and Quarkus in JVM mode
- **THEN** the repository guide links to the dedicated JVM runtime comparison document

#### Scenario: JVM comparison guide covers per-runtime and combined flows
- **WHEN** a developer opens the dedicated JVM runtime comparison document
- **THEN** the guide presents the documented Spring Boot, Quarkus, and combined JVM comparison commands together with the generated artifact locations and interpretation limits
