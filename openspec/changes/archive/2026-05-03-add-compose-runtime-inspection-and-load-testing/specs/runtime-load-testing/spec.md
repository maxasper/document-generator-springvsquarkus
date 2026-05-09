## ADDED Requirements

### Requirement: Repository-local load testing for a selected running runtime
The repository SHALL provide a documented repository-local load-testing flow that targets the selected running runtime started through the manual Compose workflow.

#### Scenario: Spring Boot manual runtime can be load-tested
- **WHEN** a developer runs the documented load-test flow while the Spring Boot Compose runtime is active
- **THEN** the repository executes the shared load-test workload against the running Spring Boot HTTP endpoint

#### Scenario: Quarkus manual runtime can be load-tested
- **WHEN** a developer runs the documented load-test flow while the Quarkus Compose runtime is active
- **THEN** the repository executes the shared load-test workload against the running Quarkus HTTP endpoint

### Requirement: Load-test runs produce reusable result artifacts
The repository SHALL write load-test result artifacts to a repository-local output directory so the operator can review the outcome after the run.

#### Scenario: Load-test output is stored for later review
- **WHEN** a documented load-test run completes
- **THEN** the repository writes the generated load-test results to a predictable local output location

### Requirement: Load testing is documented as an interactive evaluation step
The repository SHALL treat load testing as part of the manual runtime evaluation workflow rather than as a replacement for the existing automated comparison scripts.

#### Scenario: Documentation separates manual load testing from comparison benchmarks
- **WHEN** a developer reads the documented runtime evaluation workflow
- **THEN** the load-test step is presented as an interactive manual exercise that complements, but does not replace, the existing benchmark flows
