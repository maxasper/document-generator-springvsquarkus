## ADDED Requirements

### Requirement: JVM comparison environment metrics support macOS and Ubuntu
The repository SHALL collect JVM comparison environment metadata and artifact-size metrics on both Ubuntu and macOS while preserving the existing report schema.

#### Scenario: macOS JVM comparison report includes host metadata
- **WHEN** a developer runs the documented JVM comparison flow on macOS
- **THEN** the generated report includes OS name, OS version, architecture, Java version, available processor count, total memory in kilobytes, and Docker version using the same report fields as Ubuntu

#### Scenario: Artifact size measurement works on macOS and Ubuntu
- **WHEN** a JVM comparison run records packaged artifact size on macOS or Ubuntu
- **THEN** the generated report stores the artifact size in bytes without requiring host-specific GNU utility installation
