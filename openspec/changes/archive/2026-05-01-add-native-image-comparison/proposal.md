## Why

The repository now has a repeatable JVM comparison flow for Spring Boot and Quarkus, but the original comparison goal also includes native-image behavior. The next useful step is to benchmark both runtimes in native mode against the same verified PostgreSQL-backed behavioral baseline while preserving the native build and packaging approaches that are idiomatic for each framework.

## What Changes

- add a repeatable native-image comparison flow for Spring Boot and Quarkus on the same PostgreSQL-backed runtime baseline
- define one shared native benchmark contract around framework-native containerized delivery artifacts, not a forced common Dockerfile
- use Spring Boot's native container-image path for Spring and Quarkus' native container-build path for Quarkus
- add repository-local automation that builds, starts, verifies, and benchmarks both native runtimes and writes the results in a machine-readable report
- document native build prerequisites, commands, output locations, and interpretation limits relative to the existing JVM comparison flow

## Capabilities

### New Capabilities
- `native-image-comparison`: compare Spring Boot and Quarkus in native mode using the same PostgreSQL-backed setup, benchmark inputs, and reporting format while preserving the official native build paths recommended by each framework

### Modified Capabilities

## Impact

- affects runtime comparison scripts, benchmark inputs, and comparison-oriented documentation
- likely adds runtime-specific native build commands, container launch paths, and report files alongside the existing JVM benchmark outputs
- builds on the existing PostgreSQL-backed verification flow and JVM comparison discipline without changing the shared API behavior
