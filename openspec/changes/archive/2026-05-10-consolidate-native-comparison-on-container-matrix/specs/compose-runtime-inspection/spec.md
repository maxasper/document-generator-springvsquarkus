## ADDED Requirements

### Requirement: Manual Spring Boot native inspection image is a real native container
The repository SHALL build the shared `spring-native` inspection image as a true Spring Boot native executable container so manual Compose inspection does not observe a mislabeled JVM scenario.

#### Scenario: Manual Spring Boot native image uses the native buildpacks toggle
- **WHEN** a developer builds the Spring Boot `native` inspection image through the documented repository-local build command
- **THEN** the build enables the Spring Boot native buildpacks mode required to produce a native executable image
