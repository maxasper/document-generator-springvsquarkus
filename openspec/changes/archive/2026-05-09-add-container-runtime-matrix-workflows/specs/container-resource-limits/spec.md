## MODIFIED Requirements

### Requirement: Manual runtime containers support documented CPU and memory limits
The repository SHALL provide documented CPU and memory limit controls for the containerized runtime workflows so Spring Boot and Quarkus can be evaluated under comparable container budgets in both `jvm` and `native` modes.

#### Scenario: Manual Spring Boot runtime can be started with configured limits
- **WHEN** a developer uses the documented Spring Boot container workflow with the supported resource-limit settings in either `jvm` or `native` mode
- **THEN** the selected Spring Boot container starts with the configured CPU and memory constraints applied through the documented container controls

#### Scenario: Manual Quarkus runtime can be started with configured limits
- **WHEN** a developer uses the documented Quarkus container workflow with the supported resource-limit settings in either `jvm` or `native` mode
- **THEN** the selected Quarkus container starts with the configured CPU and memory constraints applied through the documented container controls

#### Scenario: Automated matrix reuses the same configured limits
- **WHEN** a developer runs the automated container runtime matrix flow after setting the supported resource-limit variables
- **THEN** those configured CPU and memory limits are reused for every scenario in the matrix run

### Requirement: Resource-limit documentation explains JVM interpretation
The repository SHALL document how the configured container limits relate to runtime behavior so the developer can interpret the results correctly for both JVM and native scenarios.

#### Scenario: Operator documentation explains runtime-limit effects
- **WHEN** a developer consults the documented container runtime workflow
- **THEN** the documentation explains which limit knobs are supported, how JVM-specific controls such as heap-percentage apply, and which controls are shared by native scenarios
