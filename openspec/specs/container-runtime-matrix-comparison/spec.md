# container-runtime-matrix-comparison Specification

## Purpose
Define the automated Docker-to-Docker comparison flow that runs Spring Boot and Quarkus in both JVM and native modes under one shared resource budget and load profile.

## Requirements

### Requirement: Automated container runtime matrix covers all four scenarios
The repository SHALL provide an automated containerized runtime comparison flow that runs Spring Boot and Quarkus in both `jvm` and `native` modes sequentially against the same PostgreSQL-backed baseline.

#### Scenario: Combined matrix run executes the four runtime scenarios
- **WHEN** a developer runs the documented combined container runtime matrix command
- **THEN** the repository executes `spring-jvm`, `quarkus-jvm`, `spring-native`, and `quarkus-native` one after the other instead of at the same time

#### Scenario: Each matrix scenario starts from a recreated PostgreSQL baseline
- **WHEN** the combined matrix flow moves from one runtime scenario to the next
- **THEN** the PostgreSQL-backed container baseline is recreated before the next scenario begins

#### Scenario: Each workload case starts from an isolated PostgreSQL baseline
- **WHEN** the combined matrix flow executes `post`, `get`, and `mixed` workload cases for a runtime scenario
- **THEN** the PostgreSQL-backed container baseline is recreated before each workload case begins

### Requirement: Automated matrix applies one shared resource budget and load profile
The automated container runtime matrix SHALL apply one shared set of documented container resource controls and load-test overrides across all four scenarios in a run.

#### Scenario: Shared CPU and memory settings are reused across the full matrix
- **WHEN** a developer configures the supported container resource-limit variables before starting the combined matrix flow
- **THEN** the same configured CPU, memory, and PID-limit settings are applied to every runtime scenario in that matrix run

#### Scenario: Shared load-test overrides are reused across the full matrix
- **WHEN** a developer configures the supported load-test override variables before starting the combined matrix flow
- **THEN** the same configured load-test profile is used for each runtime scenario in that matrix run

### Requirement: Automated matrix produces a combined scenario report
The repository SHALL write one machine-readable report and one human-readable summary for the automated container runtime matrix run.

#### Scenario: Combined report includes per-scenario metadata and per-case results
- **WHEN** a container runtime matrix run completes
- **THEN** the generated report includes one entry per scenario with runtime, mode, configured limits, build metadata, startup timing, and one result entry per workload case

#### Scenario: Human-readable summary shows the scenario and workload-case comparison table
- **WHEN** a container runtime matrix run completes
- **THEN** the repository writes a summary table that allows the developer to compare each runtime scenario and workload case without opening the raw JSON report

#### Scenario: Missing successful latency is not reported as zero
- **WHEN** a workload case completes without successful HTTP responses
- **THEN** the generated machine-readable report stores successful-response latency metrics as unavailable values and the human-readable summary renders them as `n/a`

#### Scenario: Container resource observations are scoped to each workload case
- **WHEN** a container runtime matrix run completes
- **THEN** CPU and memory metrics in the generated summary are derived from samples collected for the corresponding workload case

### Requirement: Automated matrix native scenarios use real framework-native images
The automated container runtime matrix SHALL build the `spring-native` and `quarkus-native` scenarios as true native executable container images using the documented framework-native build paths for each runtime.

#### Scenario: Spring Boot native matrix scenario uses Spring Boot native buildpacks mode
- **WHEN** the matrix flow builds the `spring-native` scenario image
- **THEN** it enables the Spring Boot native buildpacks path so the produced image runs as a native executable container rather than a JVM container image

#### Scenario: Quarkus native matrix scenario keeps the Quarkus native container-build path
- **WHEN** the matrix flow builds the `quarkus-native` scenario image
- **THEN** it uses the documented Quarkus native container-build path that produces the native runner and packages it as the runtime image

### Requirement: Automated container runtime matrix supports macOS and Ubuntu shells
The repository SHALL run the documented automated container runtime matrix flow on both Ubuntu and macOS without requiring GNU-specific shell utilities beyond the documented benchmark prerequisites.

#### Scenario: macOS matrix run uses the same runtime scenarios
- **WHEN** a developer runs the documented combined container runtime matrix command on macOS with the supported Docker and benchmark prerequisites installed
- **THEN** the repository executes `spring-jvm`, `quarkus-jvm`, `spring-native`, and `quarkus-native` in the same order and with the same workload cases as the Ubuntu flow

#### Scenario: Matrix report shape is preserved across supported host operating systems
- **WHEN** a container runtime matrix run completes on macOS or Ubuntu
- **THEN** the generated machine-readable report and human-readable summary use the same fields and configured-limit values for the same selected workload profile
