## REMOVED Requirements

### Requirement: Shared native-image comparison flow
**Reason**: The repository now keeps `container-runtime-matrix-comparison` as the single supported automated Docker-to-Docker comparison workflow instead of maintaining a second standalone native benchmark harness.
**Migration**: Run `./scripts/benchmark-container-runtime-matrix.sh` when you want automated Docker-native comparison results.

### Requirement: Shared contract verification before measured native benchmarking
**Reason**: Correctness remains covered by the shared runtime verification workflow rather than a dedicated legacy native benchmark stage.
**Migration**: Run the documented runtime verification workflow before interpreting container runtime matrix results.

### Requirement: Shared native benchmark workload and metric set
**Reason**: The repository no longer maintains a separate native-only request harness and report contract alongside the container runtime matrix.
**Migration**: Use the shared matrix `k6` workload and matrix report under `target/container-runtime-matrix/`.

### Requirement: Equivalent database baseline for each native runtime benchmark
**Reason**: This guarantee now belongs to the container runtime matrix comparison workflow.
**Migration**: Use the automated matrix flow, which recreates the PostgreSQL-backed baseline between scenarios.

### Requirement: Native comparison produces machine-readable results with build-strategy metadata
**Reason**: The native-only report contract is retired with the legacy workflow.
**Migration**: Use the container runtime matrix report for machine-readable Docker comparison output.

### Requirement: Dedicated native comparison guide is linked from the repository entrypoint
**Reason**: The repository entrypoint now points containerized comparison users to the container runtime matrix guide instead of a removed native-only runbook.
**Migration**: Follow the container runtime matrix guide from `README.md`.

### Requirement: Native comparison guide distinguishes native benchmark assumptions from manual container inspection assumptions
**Reason**: The dedicated native benchmark guide is removed along with the legacy workflow.
**Migration**: Use the benchmark architecture overview and the container runtime matrix guide for current benchmark assumptions.
