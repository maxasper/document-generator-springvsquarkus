## ADDED Requirements

### Requirement: Manual Compose-based JVM runtime startup
The repository SHALL provide a documented Docker Compose workflow that allows a developer to start Spring Boot or Quarkus manually in JVM mode against a repository-local PostgreSQL service and keep the selected runtime online for interactive inspection.

#### Scenario: Spring Boot JVM runtime can be started manually in Compose
- **WHEN** a developer runs the documented Compose startup flow for Spring Boot
- **THEN** the repository starts PostgreSQL and the Spring Boot JVM container in PostgreSQL-backed mode without requiring a host-installed database

#### Scenario: Quarkus JVM runtime can be started manually in Compose
- **WHEN** a developer runs the documented Compose startup flow for Quarkus
- **THEN** the repository starts PostgreSQL and the Quarkus JVM container in PostgreSQL-backed mode without requiring a host-installed database

### Requirement: Manual runtime workflow remains sequential and explicit
The repository SHALL document the manual inspection workflow as a one-runtime-at-a-time process so Spring Boot and Quarkus can be evaluated under comparable conditions.

#### Scenario: Operator workflow starts one runtime at a time
- **WHEN** a developer follows the documented manual runtime inspection flow
- **THEN** the workflow instructs the developer to start Spring Boot or Quarkus individually rather than as simultaneous application containers

### Requirement: JVM observability ports are available for local tools
The repository SHALL expose documented JVM observability connection settings for the selected running JVM container so a local developer tool can inspect Java-level runtime resources.

#### Scenario: Local JVM tool can connect to the selected runtime
- **WHEN** a developer starts a supported JVM runtime through the documented Compose flow
- **THEN** the runtime exposes the documented local observability port and connection settings needed by a host-side JVM inspection tool such as VisualVM or JDK Mission Control
