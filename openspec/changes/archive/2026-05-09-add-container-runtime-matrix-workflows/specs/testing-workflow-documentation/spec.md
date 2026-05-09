## MODIFIED Requirements

### Requirement: README acts as the testing-workflow entrypoint
The repository SHALL use `README.md` as the entrypoint for testing and benchmarking guidance by linking to dedicated workflow documents under `docs/testing/` instead of embedding every full operator procedure inline.

#### Scenario: Repository guide links to the supported workflow documents
- **WHEN** a developer opens `README.md` to find testing or benchmarking instructions
- **THEN** the repository guide links to dedicated documents for runtime verification, host JVM runtime comparison, native-image comparison, manual container runtime inspection, and automated container runtime matrix comparison

### Requirement: Workflow documents are organized by operator intent
The repository SHALL provide one dedicated workflow document per supported manual testing or benchmarking scenario under `docs/testing/`.

#### Scenario: Each supported workflow has its own runbook
- **WHEN** a developer wants to execute one specific workflow
- **THEN** the repository provides a single dedicated guide for that workflow instead of requiring the developer to extract the steps from mixed comparison notes

### Requirement: Workflow documents follow a consistent structure
Each dedicated workflow document SHALL describe its prerequisites, commands, startup or readiness checks, result artifacts, tunable parameters, cleanup steps, and interpretation limits.

#### Scenario: Workflow guide can be executed without consulting unrelated docs
- **WHEN** a developer opens one of the dedicated workflow guides under `docs/testing/`
- **THEN** the guide contains the operator details needed to execute and interpret that workflow without depending on unrelated runbooks
