## Why

The repository already contains shared HTTP contract tests, but they are not yet wired into a repeatable workflow for either runtime. Until Spring Boot and Quarkus can be started and verified the same way, the project cannot make credible framework comparisons beyond code structure.

## What Changes

- add a repeatable runtime verification workflow for Spring Boot in `in-memory` mode
- add a repeatable runtime verification workflow for Quarkus in `in-memory` mode
- wire the shared `document-generator-contract-tests` module so the same HTTP contract suite can be executed against either runtime through one documented command path
- document the runtime verification flow and the expected ports, profiles, and prerequisites for local execution

## Capabilities

### New Capabilities
- `runtime-contract-verification`: define how the same HTTP contract suite is executed against the Spring Boot and Quarkus runtime modules before PostgreSQL and native-image comparisons

### Modified Capabilities

## Impact

- affects `document-generator-app-spring`, `document-generator-app-quarkus`, and `document-generator-contract-tests`
- likely adds Maven profiles, test wiring, or helper scripts for repeatable local runs
- updates `README.md` and comparison-oriented documentation so future work can build on one verification workflow
