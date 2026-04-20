# Incremental Roadmap

## 1. Repository Scaffolding

- add the Maven parent project and Java 25 defaults
- create the shared core modules and the two runtime modules

## 2. Shared Core Contracts

- model `GenerationRequest`, `GenerationHistoryEntry`, and related value objects
- define `GenerateDocumentUseCase`, `ListGenerationHistoryUseCase`, `GenerationRequestRepository`, and `DocumentRenderer`
- implement template-type parameter validation in pure Java

## 3. Shared Stub Renderer

- add a deterministic stub `DocumentRenderer`
- cover core validation and use case behavior with unit tests

## 4. Spring Boot First Vertical Slice

- expose `POST /api/v1/document-generations`
- expose `GET /api/v1/document-generations`
- wire the shared core with an in-memory repository first if that accelerates feedback

## 5. PostgreSQL Hardening

- add migration scripts and a concrete persistence model
- replace or complement the in-memory repository with a PostgreSQL-backed Spring adapter

## 6. Quarkus Parity Slice

- expose the same two endpoints from Quarkus using the shared core
- implement the Quarkus persistence adapter against the same repository contract

## 7. Cross-Runtime Verification

- add contract-style tests to keep Spring and Quarkus behavior aligned
- prepare JVM and native-image comparison tasks once both runtimes are functionally equivalent
