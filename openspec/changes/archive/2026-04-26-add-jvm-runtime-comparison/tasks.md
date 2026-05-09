## 1. Benchmark Contract And Shared Inputs

- [x] 1.1 Define the shared JVM benchmark workload, metric names, and machine-readable report shape
- [x] 1.2 Add repository-local helpers for timing, RSS capture, artifact-size measurement, and generated output locations

## 2. Shared Comparison Orchestration

- [x] 2.1 Add shared comparison automation that can package one selected runtime, start it in PostgreSQL-backed mode, execute the warmup and measured HTTP sequence, and stop it cleanly
- [x] 2.2 Ensure the shared comparison automation reinitializes the PostgreSQL-backed benchmark baseline between runtime runs and records environment metadata

## 3. Spring Boot JVM Flow

- [x] 3.1 Add a documented Spring Boot JVM comparison command on top of the shared PostgreSQL-backed comparison automation
- [x] 3.2 Verify that the Spring Boot JVM comparison flow records startup, RSS, latency, build time, and artifact-size metrics in the shared report format

## 4. Quarkus JVM Flow

- [x] 4.1 Add a documented Quarkus JVM comparison command on top of the shared PostgreSQL-backed comparison automation
- [x] 4.2 Verify that the Quarkus JVM comparison flow records startup, RSS, latency, build time, and artifact-size metrics in the shared report format

## 5. Combined Comparison And Documentation

- [x] 5.1 Add one combined JVM comparison command that benchmarks Spring Boot and Quarkus sequentially and emits a concise summary from the generated results
- [x] 5.2 Update `README.md` and comparison-oriented documentation with prerequisites, commands, output locations, and interpretation limits for the JVM benchmark flow
- [x] 5.3 Run one full local JVM comparison session and confirm that both runtimes are benchmarked from equivalent PostgreSQL-backed state
