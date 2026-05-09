## ADDED Requirements

### Requirement: Shared pure-Java business core
The system SHALL implement document generation business rules in shared domain and application modules that remain free from Spring Boot and Quarkus dependencies.

#### Scenario: Both runtimes reuse the same core modules
- **WHEN** the Spring Boot and Quarkus applications are assembled
- **THEN** both applications depend on the same shared business-core modules for generation and history use cases

### Requirement: Separate runnable runtime applications
The system SHALL provide separate runnable modules for the Spring Boot application and the Quarkus application.

#### Scenario: Runtime modules remain independent
- **WHEN** the project is built
- **THEN** Spring Boot and Quarkus are packaged from different application modules with independent runtime entrypoints

### Requirement: Hexagonal boundaries
The system SHALL express document generation and history through application ports so that HTTP and persistence concerns are implemented as adapters outside the core.

#### Scenario: Core depends on abstractions rather than framework adapters
- **WHEN** a generation or history use case is implemented
- **THEN** the core uses port interfaces for document rendering and request persistence instead of depending on HTTP or ORM frameworks

### Requirement: V1 history storage excludes generated content
The system SHALL keep generated document content outside persistent request history in v1.

#### Scenario: Stored history remains metadata-only
- **WHEN** a generation request is persisted
- **THEN** the stored history record contains request metadata and parameters without storing generated file bytes
