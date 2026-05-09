## 1. Shared PostgreSQL Verification Wiring

- [x] 1.1 Add one repository-local PostgreSQL setup for verification, including clean start and teardown commands
- [x] 1.2 Extend the runtime verification automation so PostgreSQL-backed flows can start the database, wait for readiness, and run `document-generator-contract-tests` against a supplied `document.generator.base-url`

## 2. Spring Boot PostgreSQL Flow

- [x] 2.1 Add a documented Spring Boot PostgreSQL-backed runtime verification flow using the existing Spring `postgres` profile
- [x] 2.2 Verify that the shared contract suite passes against the Spring Boot PostgreSQL-backed flow

## 3. Quarkus PostgreSQL Flow

- [x] 3.1 Add a documented Quarkus PostgreSQL-backed runtime verification flow using the existing Quarkus `postgres` profile
- [x] 3.2 Verify that the shared contract suite passes against the Quarkus PostgreSQL-backed flow

## 4. Documentation And Comparison Sequencing

- [x] 4.1 Update `README.md` with the PostgreSQL-backed verification commands, Docker prerequisite, and baseline database settings
- [x] 4.2 Update comparison-oriented documentation to state that JVM and native-image comparison starts after PostgreSQL-backed parity is green
