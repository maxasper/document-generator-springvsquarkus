# Runtime Comparison Plan

These tasks start after Spring Boot and Quarkus are functionally aligned and pass the same runtime contract tests.

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
