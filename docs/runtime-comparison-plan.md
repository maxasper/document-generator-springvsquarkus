# Runtime Comparison Plan

These tasks start after Spring Boot and Quarkus are functionally aligned, pass the same runtime contract tests in `in-memory` mode, and pass the same PostgreSQL-backed verification flow against the shared database setup.

## JVM Mode

- measure cold startup time for both applications
- capture steady-state memory footprint
- compare basic request latency for generate and history endpoints
- record packaging size and build time

## Native Image Mode

- build a Quarkus native executable
- build a Spring native executable
- compare native build time, binary size, startup, and RSS
- rerun the same contract tests against both native binaries

## Reporting

- keep one benchmark input dataset and one test command per runtime
- record environment details for every run: CPU, RAM, OS, Java version, Docker version if used
- separate framework effects from database effects by running the same PostgreSQL setup for both
