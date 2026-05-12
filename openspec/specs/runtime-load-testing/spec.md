# runtime-load-testing Specification

## Purpose
Define the repository-local load-testing workflow and result-artifact output for containerized runtime evaluation.

## Requirements

### Requirement: Repository-local load testing for a selected running runtime
The repository SHALL provide a documented repository-local load-testing flow that targets the selected running container runtime started through the manual Compose workflow.

#### Scenario: Spring Boot container runtime can be load-tested
- **WHEN** a developer runs the documented load-test flow while a supported Spring Boot container runtime is active in either `jvm` or `native` mode
- **THEN** the repository executes the shared load-test workload against the running Spring Boot HTTP endpoint

#### Scenario: Quarkus container runtime can be load-tested
- **WHEN** a developer runs the documented load-test flow while a supported Quarkus container runtime is active in either `jvm` or `native` mode
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
- **THEN** the load-test step is presented as an interactive manual exercise that complements, but does not replace, the automated comparison flows

### Requirement: Automated container runtime matrix reuses the shared load-test controls
The repository SHALL let the automated container runtime matrix consume the same documented load-test override controls used by the manual container runtime workflow.

#### Scenario: Matrix scenarios share the same configured load-test profile
- **WHEN** a developer sets the supported load-test override variables before starting the automated container runtime matrix
- **THEN** every scenario in that matrix run is exercised with the same configured `k6` load profile

### Requirement: Runtime load testing supports distinct workload cases
The repository SHALL support `post`, `get`, and `mixed` load-test cases for supported container runtimes.

#### Scenario: Post case exercises document generation writes
- **WHEN** a developer runs the load-test flow with the `post` workload case selected
- **THEN** the repository executes a workload that sends document-generation create requests without the mixed-workflow read step

#### Scenario: Get case exercises document generation reads
- **WHEN** a developer runs the load-test flow with the `get` workload case selected
- **THEN** the repository executes a workload that reads document-generation history without creating new measured requests during the case

#### Scenario: Mixed case preserves the existing workflow
- **WHEN** a developer runs the load-test flow with the `mixed` workload case selected
- **THEN** the repository executes the existing write-then-read workflow, including its documented think time

### Requirement: Read-only load testing uses deterministic history setup
The repository SHALL seed a deterministic document-generation history before measuring the `get` workload case.

#### Scenario: Get case seeds history before measurement
- **WHEN** the `get` workload case starts in an automated benchmark flow
- **THEN** the repository creates the configured number of document-generation history entries before collecting measured `get` results

#### Scenario: Get seed size is configurable
- **WHEN** a developer configures the supported get-history seed-size override before starting the benchmark flow
- **THEN** the repository uses that configured seed size for every `get` case in the run

### Requirement: Load-test artifacts are separated by workload case
The repository SHALL write load-test artifacts in a way that identifies the workload case that produced them.

#### Scenario: Case-specific artifacts are stored separately
- **WHEN** a benchmark run executes multiple workload cases for one runtime
- **THEN** the generated load-test artifacts are stored under case-specific output locations

#### Scenario: Case-specific metrics remain attributable
- **WHEN** a developer reviews generated load-test artifacts after a benchmark run
- **THEN** each artifact can be attributed to its runtime scenario and workload case
