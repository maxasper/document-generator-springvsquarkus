## ADDED Requirements

### Requirement: Manual runtime containers support documented CPU and memory limits
The repository SHALL provide documented CPU and memory limit controls for the manual Compose-based JVM runtime workflow so Spring Boot and Quarkus can be evaluated under comparable container budgets.

#### Scenario: Spring Boot manual runtime can be started with configured limits
- **WHEN** a developer uses the documented Spring Boot Compose workflow with the supported resource-limit settings
- **THEN** the Spring Boot container starts with the configured CPU and memory constraints applied through the documented container controls

#### Scenario: Quarkus manual runtime can be started with configured limits
- **WHEN** a developer uses the documented Quarkus Compose workflow with the supported resource-limit settings
- **THEN** the Quarkus container starts with the configured CPU and memory constraints applied through the documented container controls

### Requirement: Resource-limit documentation explains JVM interpretation
The repository SHALL document how the configured container limits relate to JVM runtime behavior so the developer can interpret the results correctly.

#### Scenario: Operator documentation explains resource-limit effects
- **WHEN** a developer consults the documented manual runtime workflow
- **THEN** the documentation explains which limit knobs are supported and how those limits affect JVM execution and observability
