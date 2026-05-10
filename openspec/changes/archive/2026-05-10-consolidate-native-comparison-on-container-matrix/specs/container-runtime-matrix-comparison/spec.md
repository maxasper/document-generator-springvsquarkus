## MODIFIED Requirements

### Requirement: Automated container runtime matrix covers all four scenarios
The repository SHALL provide the supported automated containerized runtime comparison flow that runs Spring Boot and Quarkus in both `jvm` and `native` modes sequentially against the same PostgreSQL-backed baseline.

#### Scenario: Combined matrix run executes the four runtime scenarios
- **WHEN** a developer runs the documented combined container runtime matrix command
- **THEN** the repository executes `spring-jvm`, `quarkus-jvm`, `spring-native`, and `quarkus-native` one after the other instead of at the same time

#### Scenario: Each matrix scenario starts from a recreated PostgreSQL baseline
- **WHEN** the combined matrix flow moves from one runtime scenario to the next
- **THEN** the PostgreSQL-backed container baseline is recreated before the next scenario begins

## ADDED Requirements

### Requirement: Automated matrix native scenarios use real framework-native images
The automated container runtime matrix SHALL build the `spring-native` and `quarkus-native` scenarios as true native executable container images using the documented framework-native build paths for each runtime.

#### Scenario: Spring Boot native matrix scenario uses Spring Boot native buildpacks mode
- **WHEN** the matrix flow builds the `spring-native` scenario image
- **THEN** it enables the Spring Boot native buildpacks path so the produced image runs as a native executable container rather than a JVM container image

#### Scenario: Quarkus native matrix scenario keeps the Quarkus native container-build path
- **WHEN** the matrix flow builds the `quarkus-native` scenario image
- **THEN** it uses the documented Quarkus native container-build path that produces the native runner and packages it as the runtime image
