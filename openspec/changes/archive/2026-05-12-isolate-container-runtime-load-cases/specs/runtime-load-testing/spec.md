## ADDED Requirements

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
