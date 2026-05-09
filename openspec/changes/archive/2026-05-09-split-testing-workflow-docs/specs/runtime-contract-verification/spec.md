## ADDED Requirements

### Requirement: Dedicated runtime verification guide is linked from the repository entrypoint
The repository SHALL surface the documented runtime verification flows through a dedicated workflow guide linked from `README.md`, covering Spring Boot and Quarkus in both `in-memory` and PostgreSQL-backed modes.

#### Scenario: Developer can discover verification workflow from README
- **WHEN** a developer uses `README.md` to find how to verify runtime behavior
- **THEN** the repository guide links to the dedicated runtime verification document instead of requiring the developer to extract the commands from a mixed workflow section

#### Scenario: Verification guide covers both runtime modes and both runtimes
- **WHEN** a developer opens the dedicated runtime verification document
- **THEN** the guide presents the documented Spring Boot and Quarkus verification flows for both the baseline `in-memory` mode and the PostgreSQL-backed mode
