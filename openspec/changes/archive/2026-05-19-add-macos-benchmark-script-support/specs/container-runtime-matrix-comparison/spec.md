## ADDED Requirements

### Requirement: Automated container runtime matrix supports macOS and Ubuntu shells
The repository SHALL run the documented automated container runtime matrix flow on both Ubuntu and macOS without requiring GNU-specific shell utilities beyond the documented benchmark prerequisites.

#### Scenario: macOS matrix run uses the same runtime scenarios
- **WHEN** a developer runs the documented combined container runtime matrix command on macOS with the supported Docker and benchmark prerequisites installed
- **THEN** the repository executes `spring-jvm`, `quarkus-jvm`, `spring-native`, and `quarkus-native` in the same order and with the same workload cases as the Ubuntu flow

#### Scenario: Matrix report shape is preserved across supported host operating systems
- **WHEN** a container runtime matrix run completes on macOS or Ubuntu
- **THEN** the generated machine-readable report and human-readable summary use the same fields and configured-limit values for the same selected workload profile
