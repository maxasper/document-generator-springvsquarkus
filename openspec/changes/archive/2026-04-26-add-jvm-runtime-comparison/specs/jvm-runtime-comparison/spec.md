## ADDED Requirements

### Requirement: Shared JVM runtime comparison flow
The repository SHALL provide a documented JVM-mode comparison flow that benchmarks Spring Boot and Quarkus sequentially against the same PostgreSQL-backed setup.

#### Scenario: Combined JVM comparison run benchmarks both runtimes
- **WHEN** a developer runs the documented combined JVM comparison command
- **THEN** the repository benchmarks Spring Boot and Quarkus one after the other instead of at the same time

#### Scenario: JVM comparison reuses the verified PostgreSQL-backed runtime path
- **WHEN** the JVM comparison flow starts a runtime benchmark session
- **THEN** the selected runtime is started in PostgreSQL-backed mode and exercised through `POST /api/v1/document-generations` and `GET /api/v1/document-generations`

### Requirement: Shared benchmark workload and metric set
The repository SHALL measure the same JVM comparison metrics for Spring Boot and Quarkus using one shared workload definition.

#### Scenario: Cold startup is measured through the live HTTP boundary
- **WHEN** a runtime benchmark session starts
- **THEN** the comparison flow records cold startup time until `GET /api/v1/document-generations` responds with `200`

#### Scenario: Generate and history endpoint latency are measured with the same benchmark inputs
- **WHEN** Spring Boot and Quarkus are benchmarked in JVM mode
- **THEN** both runtimes execute the same measured request sequence for valid `POST /api/v1/document-generations` and `GET /api/v1/document-generations` operations

#### Scenario: Build and packaging metrics are part of the shared comparison
- **WHEN** the JVM comparison flow benchmarks a runtime
- **THEN** it records build time and packaged artifact size for that runtime in addition to startup, latency, and steady-state memory metrics

### Requirement: Equivalent database baseline for each runtime benchmark
The repository SHALL ensure that Spring Boot and Quarkus start their JVM benchmark runs from equivalent PostgreSQL state.

#### Scenario: Database state is reset between runtime benchmark runs
- **WHEN** the combined JVM comparison flow finishes benchmarking one runtime and moves to the other
- **THEN** the PostgreSQL-backed benchmark baseline is reinitialized before measured requests start for the next runtime

### Requirement: JVM comparison produces machine-readable results with environment metadata
The repository SHALL write JVM comparison results in a machine-readable report format that includes the benchmark environment and the metrics captured for both runtimes.

#### Scenario: Comparison report contains per-runtime metrics and environment details
- **WHEN** a JVM comparison run completes
- **THEN** the generated report includes Spring Boot and Quarkus metric values plus the environment details needed to interpret the run, including OS, Java version, CPU or memory information, and Docker version when Docker-backed PostgreSQL is used
