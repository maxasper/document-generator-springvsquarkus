## MODIFIED Requirements

### Requirement: README acts as the testing-workflow entrypoint
The repository SHALL use `README.md` as the entrypoint for testing and benchmarking guidance by linking to dedicated workflow documents under `docs/testing/` instead of embedding every full operator procedure inline.

#### Scenario: Repository guide links to the supported workflow documents
- **WHEN** a developer opens `README.md` to find testing or benchmarking instructions
- **THEN** the repository guide links to dedicated documents for runtime verification, host JVM runtime comparison, manual container runtime inspection, automated container runtime matrix comparison, and the benchmark architecture overview
