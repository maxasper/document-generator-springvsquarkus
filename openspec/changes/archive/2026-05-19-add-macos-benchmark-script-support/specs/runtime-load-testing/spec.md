## ADDED Requirements

### Requirement: Runtime load-test resource sampling supports macOS and Ubuntu shells
The repository SHALL collect and report per-case container resource observations during runtime load testing on both Ubuntu and macOS using the same Docker stats source.

#### Scenario: Load-test memory samples are parsed on macOS
- **WHEN** a runtime load-test case samples Docker memory usage on macOS
- **THEN** the repository converts the sampled Docker memory unit into bytes and stores it in the case container observation

#### Scenario: Load-test CPU samples remain attributable by case
- **WHEN** a runtime load-test run executes one or more workload cases on macOS or Ubuntu
- **THEN** the generated load-test summary attributes CPU average, CPU maximum, and memory maximum metrics to the workload case that produced the samples
