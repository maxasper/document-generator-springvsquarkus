## 1. Shared Verification Wiring

- [x] 1.1 Define one repeatable command path for running `document-generator-contract-tests` against a supplied `document.generator.base-url`
- [x] 1.2 Add lightweight startup-readiness handling so runtime verification waits for the application before executing contract tests

## 2. Spring Boot Runtime Flow

- [x] 2.1 Add a documented Spring Boot `in-memory` runtime verification flow using the baseline local port
- [x] 2.2 Verify that the shared contract suite passes against the Spring Boot flow

## 3. Quarkus Runtime Flow

- [x] 3.1 Add a documented Quarkus `in-memory` runtime verification flow using the baseline local port
- [x] 3.2 Verify that the shared contract suite passes against the Quarkus flow

## 4. Documentation And Follow-Up Boundaries

- [x] 4.1 Update `README.md` with the Spring and Quarkus runtime verification commands, ports, and prerequisites
- [x] 4.2 Document that PostgreSQL-backed verification and JVM/native comparison remain follow-up changes after the `in-memory` parity baseline
