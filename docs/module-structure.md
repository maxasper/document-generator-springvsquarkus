# Proposed Module Structure

## Principles

- keep domain and application code free from Spring, Quarkus, JPA, and servlet annotations
- let both runtime applications depend on the same core modules
- keep runtime-specific HTTP and persistence code local to each application module
- share only adapters that are framework-neutral and clearly reusable
- treat the two runtime modules as this repository's project-specific adaptation of `bootstrap + adapters`, not as generic feature modules

See [project-rules.md](project-rules.md) for the repository-wide rules used in this project.

## Proposed Maven Modules

### `document-generator-domain`

- value objects such as `DocumentFormat`, `TemplateType`, and `DocumentName`
- domain entities or records representing a generation request and history entry
- template parameter rules expressed as pure Java policies

### `document-generator-application`

- inbound use case interfaces:
  - `GenerateDocumentUseCase`
  - `ListGenerationHistoryUseCase`
- outbound ports:
  - `GenerationRequestRepository`
  - `DocumentRenderer`
- application services orchestrating validation, generation, and history persistence
- application-level DTOs independent from HTTP or persistence frameworks

### `document-generator-adapter-out-renderer-stub`

- shared stub implementation of `DocumentRenderer`
- deterministic output for early tests and runtime parity checks
- no Spring or Quarkus dependency

### `document-generator-app-spring`

- Spring Boot main application
- REST controller or controllers for generate and history endpoints
- Spring-specific persistence adapter
- future DB migration setup and runtime configuration

### `document-generator-app-quarkus`

- Quarkus main application
- JAX-RS resource or resources for the same endpoints
- Quarkus-specific persistence adapter
- future DB migration setup and runtime configuration

### `document-generator-contract-tests`

- reusable HTTP contract tests that can run against either runtime
- one shared assertion set for generation, validation, and history behavior
- kept framework-neutral so both applications are checked the same way

## Dependency Rules

- `document-generator-domain` depends on nothing outside the JDK
- `document-generator-application` may depend on `document-generator-domain`, but not on runtime frameworks
- runtime modules depend on the core modules and supply adapter implementations
- no runtime module depends on the other runtime module

## Ports and Adapter Mapping

- inbound port `GenerateDocumentUseCase`
  - Spring adapter: REST controller
  - Quarkus adapter: REST resource
- inbound port `ListGenerationHistoryUseCase`
  - Spring adapter: REST controller
  - Quarkus adapter: REST resource
- outbound port `GenerationRequestRepository`
  - early adapter: in-memory repository for the first thin slice
  - later adapters: Spring PostgreSQL adapter and Quarkus PostgreSQL adapter
- outbound port `DocumentRenderer`
  - initial shared adapter: stub renderer returning deterministic content

## Why Persistence Stays Runtime-Local For Now

The comparison goal is easier to preserve when each application owns its HTTP and persistence integration. A shared JPA adapter could be extracted later, but doing it now would blur the runtime comparison and create abstraction work before duplication is proven.
