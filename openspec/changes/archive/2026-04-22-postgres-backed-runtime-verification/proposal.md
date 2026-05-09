## Why

The repository now has a repeatable `in-memory` verification baseline, but that is not yet enough for a credible framework comparison. Before measuring JVM or native-image behavior, both runtimes need to prove that they behave the same way against the same PostgreSQL-backed persistence path.

## What Changes

- add a repeatable PostgreSQL-backed runtime verification flow for Spring Boot
- add a repeatable PostgreSQL-backed runtime verification flow for Quarkus
- define one shared PostgreSQL setup, suitable for local verification, that both runtimes use without changing the contract test suite
- reuse the existing shared HTTP contract tests so PostgreSQL-backed verification still runs through `document.generator.base-url`
- document the PostgreSQL verification commands, profiles, ports, and prerequisites as the next comparison baseline after `in-memory`

## Capabilities

### New Capabilities

### Modified Capabilities
- `runtime-contract-verification`: extend runtime verification from the initial `in-memory` baseline to include repeatable PostgreSQL-backed verification for both runtimes

## Impact

- affects `document-generator-app-spring`, `document-generator-app-quarkus`, and the runtime verification scripts
- likely adds a shared PostgreSQL orchestration file and runtime-specific PostgreSQL verification commands
- updates `README.md` and comparison-oriented documentation so the PostgreSQL-backed path becomes the next required verification milestone before JVM/native comparison
