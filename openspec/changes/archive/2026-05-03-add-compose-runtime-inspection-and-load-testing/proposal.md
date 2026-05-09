## Why

The repository already has automated verification and benchmark flows, but it still lacks a developer-oriented way to run Spring Boot and Quarkus manually in containers, inspect their JVM behavior, constrain container resources, and execute repeatable load tests against the same setup. This is the next useful step because it turns the comparison from a batch benchmark into an interactive runtime evaluation workflow.

## What Changes

- add a repository-local Docker Compose workflow for starting Spring Boot and Quarkus one at a time against PostgreSQL in JVM mode
- expose JVM-observability hooks suitable for local tools such as VisualVM or JDK Mission Control
- add documented container CPU and memory limit controls for each runtime so manual evaluation can be done under equivalent resource budgets
- add a repository-local load-testing flow that can target the selected running runtime and write repeatable result artifacts
- document the operator workflow for building images, starting one runtime, connecting observability tools, running load tests, and tearing the environment down

## Capabilities

### New Capabilities
- `compose-runtime-inspection`: manual Compose-based startup and JVM observability workflow for Spring Boot and Quarkus
- `container-resource-limits`: repeatable container CPU and memory limit controls for manual runtime evaluation
- `runtime-load-testing`: repository-local load-testing flow for a selected running runtime with generated result artifacts

### Modified Capabilities
- none

## Impact

- affects Dockerfiles, Compose files, and runtime-oriented scripts
- adds JVM observability configuration and local operator documentation
- likely adds a load-testing workload, output directory, and per-runtime helper commands
- deliberately focuses on JVM-mode container evaluation; native-image container inspection remains a later follow-up
