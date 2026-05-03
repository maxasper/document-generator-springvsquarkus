# Repository Milestones

## 1. Foundation Completed

- add the Maven parent project and Java 25 defaults
- create the shared core modules and the two runtime modules

## 2. Shared Core Completed

- model `GenerationRequest`, `GenerationHistoryEntry`, and related value objects
- define `GenerateDocumentUseCase`, `ListGenerationHistoryUseCase`, `GenerationRequestRepository`, and `DocumentRenderer`
- implement template-type parameter validation in pure Java

## 3. Shared Stub Renderer Completed

- add a deterministic stub `DocumentRenderer`
- cover core validation and use case behavior with unit tests

## 4. Dual Runtime Slice Completed

- expose `POST /api/v1/document-generations`
- expose `GET /api/v1/document-generations`
- wire the shared core into both Spring Boot and Quarkus runtime applications

## 5. PostgreSQL Runtime Support Completed

- add migration scripts and a concrete persistence model
- provide PostgreSQL-backed runtime modes for both Spring Boot and Quarkus while keeping the in-memory local baseline

## 6. Cross-Runtime Verification Completed

- add shared contract-style tests to keep Spring Boot and Quarkus behavior aligned
- provide repeatable PostgreSQL-backed verification flows for both runtimes

## 7. Comparison Tooling Completed

- add repository-local JVM comparison flows
- add repository-local native-image comparison flows
- add manual Compose-based JVM inspection with JMX, resource limits, and repository-local load testing

## 8. Current State

- the repository now supports contract verification, JVM comparison, native-image comparison, and manual JVM container inspection against the same PostgreSQL-backed baseline
- future work should be described as new changes in `openspec/` rather than inferred from this completed milestone list
