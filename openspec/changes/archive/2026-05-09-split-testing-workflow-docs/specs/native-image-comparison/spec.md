## ADDED Requirements

### Requirement: Dedicated native comparison guide is linked from the repository entrypoint
The repository SHALL surface the documented native-image comparison flow through a dedicated workflow guide linked from `README.md`.

#### Scenario: Developer can discover native comparison workflow from README
- **WHEN** a developer uses `README.md` to find how to benchmark Spring Boot and Quarkus in native mode
- **THEN** the repository guide links to the dedicated native-image comparison document

### Requirement: Native comparison guide distinguishes native benchmark assumptions from manual JVM inspection assumptions
The dedicated native-image comparison guide SHALL explain the native benchmark assumptions that differ from the manual JVM inspection workflow.

#### Scenario: Native guide explains container-resource interpretation
- **WHEN** a developer opens the dedicated native-image comparison document
- **THEN** the guide states that the native benchmark reports observed container memory usage and does not rely on the manual Compose `DG_RUNTIME_*` runtime-limit controls

#### Scenario: Native guide separates benchmark flow from manual inspection flow
- **WHEN** a developer compares the dedicated native-image guide with the manual JVM inspection guide
- **THEN** the repository documentation makes it clear that these are different workflows with different operating assumptions and purposes
