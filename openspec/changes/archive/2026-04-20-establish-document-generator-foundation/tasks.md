## 1. Maven Scaffolding

- [x] 1.1 Create the root Maven parent project with Java 25 defaults and module declarations
- [x] 1.2 Add empty module skeletons for `document-generator-domain`, `document-generator-application`, `document-generator-adapter-out-renderer-stub`, `document-generator-app-spring`, and `document-generator-app-quarkus`

## 2. Core Contracts

- [x] 2.1 Model the shared domain types for generation requests, history entries, template types, and document formats
- [x] 2.2 Define `GenerateDocumentUseCase`, `ListGenerationHistoryUseCase`, `GenerationRequestRepository`, and `DocumentRenderer` in the application module
- [x] 2.3 Implement template-type parameter validation in pure Java with unit tests

## 3. Shared Stub Rendering

- [x] 3.1 Implement a shared stub `DocumentRenderer` adapter that returns deterministic file content and metadata
- [x] 3.2 Add application-level tests covering successful generation and validation failures against the stub renderer

## 4. Spring Boot First Slice

- [x] 4.1 Create the Spring Boot application entrypoint and wire the shared core
- [x] 4.2 Expose `POST /api/v1/document-generations` in the Spring module
- [x] 4.3 Expose `GET /api/v1/document-generations` in the Spring module with a simple repository adapter

## 5. Persistence Hardening

- [x] 5.1 Add a PostgreSQL-ready persistence model and migration strategy for saved generation requests
- [x] 5.2 Implement the Spring persistence adapter against the shared repository port

## 6. Quarkus Parity

- [x] 6.1 Create the Quarkus application entrypoint and wire the shared core
- [x] 6.2 Expose the same generation and history endpoints in the Quarkus module
- [x] 6.3 Implement the Quarkus persistence adapter against the shared repository port

## 7. Cross-Runtime Verification

- [x] 7.1 Add parity tests or contract tests that assert the same behavior across Spring Boot and Quarkus
- [x] 7.2 Prepare follow-up tasks for JVM versus native-image comparison once both runtimes are functionally aligned
