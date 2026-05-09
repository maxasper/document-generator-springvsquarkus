## MODIFIED Requirements

### Requirement: Manual Compose-based JVM runtime startup
The repository SHALL provide a documented Docker Compose workflow that allows a developer to start Spring Boot or Quarkus manually in either `jvm` or `native` mode against a repository-local PostgreSQL service and keep the selected runtime online for interactive inspection.

#### Scenario: Spring Boot JVM runtime can be started manually in Compose
- **WHEN** a developer runs the documented Compose startup flow for Spring Boot in `jvm` mode
- **THEN** the repository starts PostgreSQL and the Spring Boot JVM container in PostgreSQL-backed mode without requiring a host-installed database

#### Scenario: Quarkus JVM runtime can be started manually in Compose
- **WHEN** a developer runs the documented Compose startup flow for Quarkus in `jvm` mode
- **THEN** the repository starts PostgreSQL and the Quarkus JVM container in PostgreSQL-backed mode without requiring a host-installed database

#### Scenario: Spring Boot native runtime can be started manually in Compose
- **WHEN** a developer runs the documented Compose startup flow for Spring Boot in `native` mode
- **THEN** the repository starts PostgreSQL and the Spring Boot native container in PostgreSQL-backed mode without requiring a host-installed database

#### Scenario: Quarkus native runtime can be started manually in Compose
- **WHEN** a developer runs the documented Compose startup flow for Quarkus in `native` mode
- **THEN** the repository starts PostgreSQL and the Quarkus native container in PostgreSQL-backed mode without requiring a host-installed database

### Requirement: Manual runtime workflow remains sequential and explicit
The repository SHALL document the manual inspection workflow as a one-runtime-at-a-time process so Spring Boot and Quarkus can be evaluated under comparable conditions across both `jvm` and `native` modes.

#### Scenario: Operator workflow starts one runtime scenario at a time
- **WHEN** a developer follows the documented manual runtime inspection flow
- **THEN** the workflow instructs the developer to start exactly one of `spring-jvm`, `quarkus-jvm`, `spring-native`, or `quarkus-native` rather than running multiple application runtime containers simultaneously

### Requirement: JVM observability ports are available for local tools
The repository SHALL expose documented JVM observability connection settings for the selected running JVM container so a local developer tool can inspect Java-level runtime resources.

#### Scenario: Local JVM tool can connect to the selected JVM runtime
- **WHEN** a developer starts a supported Spring Boot or Quarkus runtime through the documented Compose flow in `jvm` mode
- **THEN** the runtime exposes the documented local observability port and connection settings needed by a host-side JVM inspection tool such as VisualVM or JDK Mission Control

## ADDED Requirements

### Requirement: Manual container runtime flow includes repository-local image builds
The repository SHALL provide documented repository-local image build commands for each supported manual container runtime scenario.

#### Scenario: Developer can build all four manual container runtime images from the repository
- **WHEN** a developer follows the documented manual container runtime workflow
- **THEN** the repository provides build commands for Spring Boot and Quarkus in both `jvm` and `native` modes before startup

### Requirement: Manual native runtime inspection is documented as container-level observation
The repository SHALL document native manual runtime inspection through container-level tools rather than JVM-only tools.

#### Scenario: Native manual runtime uses container metrics instead of JMX
- **WHEN** a developer starts a supported runtime through the documented Compose flow in `native` mode
- **THEN** the workflow directs the developer to observe logs and container metrics for that native process rather than expecting JVM JMX attachment
