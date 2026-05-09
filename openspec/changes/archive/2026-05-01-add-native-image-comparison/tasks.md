## 1. Native Benchmark Contract And Build-Strategy Baseline

- [x] 1.1 Redefine the shared native benchmark workload, metric names, and machine-readable report shape around framework-native containerized delivery artifacts and build-strategy metadata
- [x] 1.2 Document Docker-based native build prerequisites and add repository-local helpers for native output directories, produced image or artifact size measurement, and runtime-memory capture

## 2. Shared Native Comparison Orchestration

- [x] 2.1 Add shared native comparison automation that can build one selected runtime using its framework-native build path, start the produced native runtime in PostgreSQL-backed mode, run the shared contract tests, execute the warmup and measured HTTP sequence, and stop it cleanly
- [x] 2.2 Ensure the shared native comparison automation reinitializes the PostgreSQL-backed benchmark baseline between runtime runs and records host plus native build-strategy metadata in the report

## 3. Spring Boot Native Flow

- [x] 3.1 Add a documented Spring Boot native comparison command based on the Spring Boot native container-image path
- [x] 3.2 Verify that the Spring Boot native comparison flow records native build time, produced artifact size, startup, runtime memory, latency, and contract-verification results in the shared report format

## 4. Quarkus Native Flow

- [x] 4.1 Add a documented Quarkus native comparison command based on the Quarkus native container-build path
- [x] 4.2 Verify that the Quarkus native comparison flow records native build time, produced artifact size, startup, runtime memory, latency, and contract-verification results in the shared report format

## 5. Combined Native Comparison And Documentation

- [x] 5.1 Add one combined native comparison command that benchmarks Spring Boot and Quarkus sequentially and emits a concise summary from the generated results
- [x] 5.2 Update `README.md` and comparison-oriented documentation with framework-native Docker-based prerequisites, commands, output locations, and interpretation limits relative to the JVM benchmark flow
- [x] 5.3 Run one full local native comparison session and confirm that both runtimes are benchmarked from equivalent PostgreSQL-backed state after passing the shared contract checks
