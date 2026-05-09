# native-image-comparison Specification

## Purpose
Define the shared native-image benchmarking flow, contract-verification gate, and report metadata used to compare Spring Boot and Quarkus while preserving framework-native build paths.

## Requirements

### Requirement: Shared native-image comparison flow
The repository SHALL provide a documented native-image comparison flow that benchmarks Spring Boot and Quarkus sequentially against the same PostgreSQL-backed setup while preserving the native build path recommended by each framework.

#### Scenario: Combined native comparison run benchmarks both runtimes
- **WHEN** a developer runs the documented combined native comparison command
- **THEN** the repository benchmarks Spring Boot and Quarkus one after the other instead of at the same time

#### Scenario: Native comparison reuses the verified PostgreSQL-backed runtime path
- **WHEN** the native comparison flow starts a runtime benchmark session
- **THEN** the selected native runtime is started in PostgreSQL-backed mode and exercised through `POST /api/v1/document-generations` and `GET /api/v1/document-generations`

#### Scenario: Spring Boot native comparison uses the documented Spring native container path
- **WHEN** the Spring Boot native comparison flow builds its native runtime artifact
- **THEN** it uses the Spring Boot native build path documented for Spring Boot rather than a shared custom Dockerfile invented only for this repository

#### Scenario: Quarkus native comparison uses the documented Quarkus native container-build path
- **WHEN** the Quarkus native comparison flow builds its native runtime artifact
- **THEN** it uses the Quarkus native container-build path documented for Quarkus rather than a shared custom Dockerfile invented only for this repository

### Requirement: Shared contract verification before measured native benchmarking
The repository SHALL execute the same shared HTTP contract suite against each native runtime before recording measured benchmark metrics.

#### Scenario: Native Spring Boot benchmark starts from a verified behavioral baseline
- **WHEN** the Spring Boot native comparison flow starts
- **THEN** the shared contract suite passes against the Spring Boot native runtime before measured native metrics are recorded

#### Scenario: Native Quarkus benchmark starts from a verified behavioral baseline
- **WHEN** the Quarkus native comparison flow starts
- **THEN** the shared contract suite passes against the Quarkus native runtime before measured native metrics are recorded

### Requirement: Shared native benchmark workload and metric set
The repository SHALL measure the same native comparison metrics for Spring Boot and Quarkus using one shared workload definition.

#### Scenario: Cold startup is measured through the live HTTP boundary
- **WHEN** a native runtime benchmark session starts
- **THEN** the comparison flow records cold startup time until `GET /api/v1/document-generations` responds with `200`

#### Scenario: Generate and history endpoint latency are measured with the same benchmark inputs
- **WHEN** Spring Boot and Quarkus are benchmarked in native mode
- **THEN** both runtimes execute the same measured request sequence for valid `POST /api/v1/document-generations` and `GET /api/v1/document-generations` operations

#### Scenario: Native build and artifact metrics are part of the shared comparison
- **WHEN** the native comparison flow benchmarks a runtime
- **THEN** it records native build time and produced deployable artifact size for that runtime in addition to startup, latency, and steady-state memory metrics

#### Scenario: Native report records the runtime-specific build strategy
- **WHEN** a native comparison run completes
- **THEN** the generated report identifies which framework-native build strategy produced each runtime artifact so the result can be interpreted correctly

### Requirement: Equivalent database baseline for each native runtime benchmark
The repository SHALL ensure that Spring Boot and Quarkus start their native benchmark runs from equivalent PostgreSQL state.

#### Scenario: Database state is reset between native runtime benchmark runs
- **WHEN** the combined native comparison flow finishes benchmarking one runtime and moves to the other
- **THEN** the PostgreSQL-backed benchmark baseline is reinitialized before measured requests start for the next runtime

### Requirement: Native comparison produces machine-readable results with build-strategy metadata
The repository SHALL write native comparison results in a machine-readable report format that includes the benchmark environment and the runtime-specific native build strategy metadata captured for both runtimes.

#### Scenario: Comparison report contains per-runtime metrics and native build-strategy details
- **WHEN** a native comparison run completes
- **THEN** the generated report includes Spring Boot and Quarkus metric values plus the environment and native build-strategy details needed to interpret the run

### Requirement: Dedicated native comparison guide is linked from the repository entrypoint
The repository SHALL surface the documented native-image comparison flow through a dedicated workflow guide linked from `README.md`.

#### Scenario: Developer can discover native comparison workflow from README
- **WHEN** a developer uses `README.md` to find how to benchmark Spring Boot and Quarkus in native mode
- **THEN** the repository guide links to the dedicated native-image comparison document

### Requirement: Native comparison guide distinguishes native benchmark assumptions from manual container inspection assumptions
The dedicated native-image comparison guide SHALL explain the native benchmark assumptions that differ from the manual container runtime inspection workflow.

#### Scenario: Native guide explains container-resource interpretation
- **WHEN** a developer opens the dedicated native-image comparison document
- **THEN** the guide states that the native benchmark reports observed container memory usage and does not rely on the manual Compose `DG_RUNTIME_*` runtime-limit controls

#### Scenario: Native guide separates benchmark flow from manual inspection flow
- **WHEN** a developer compares the dedicated native-image guide with the manual container runtime inspection guide
- **THEN** the repository documentation makes it clear that these are different workflows with different operating assumptions and purposes
