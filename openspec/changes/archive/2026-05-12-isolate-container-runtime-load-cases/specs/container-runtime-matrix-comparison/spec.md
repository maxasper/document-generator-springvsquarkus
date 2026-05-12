## MODIFIED Requirements

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
