## Why

The repository now has repeatable `in-memory` and PostgreSQL-backed verification flows for Spring Boot and Quarkus, but it still lacks a reproducible way to compare their JVM-mode runtime characteristics. Before native-image work starts, the project needs one shared benchmarking layer that measures both runtimes against the same PostgreSQL-backed baseline and records the results in a comparable format.

## What Changes

- add a repeatable JVM-mode comparison flow for Spring Boot and Quarkus on the same PostgreSQL-backed baseline
- define one shared benchmark input and measurement sequence for startup time, steady-state memory footprint, request latency, build time, and packaged artifact size
- add repository-local automation that runs the Spring and Quarkus JVM comparison flows and writes the results to a machine-readable report
- document the benchmark prerequisites, commands, measured metrics, and result interpretation rules

## Capabilities

### New Capabilities
- `jvm-runtime-comparison`: compare Spring Boot and Quarkus in JVM mode using the same PostgreSQL-backed setup, benchmark inputs, and reporting format

### Modified Capabilities

## Impact

- affects runtime comparison scripts, shared benchmarking inputs, and comparison-oriented documentation
- likely adds a repository-local results directory or report file format for benchmark output
- builds on the existing Spring Boot and Quarkus PostgreSQL-backed verification flows without changing the shared contract suite behavior
