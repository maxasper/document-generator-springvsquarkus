## 1. JVM Container Runtime Setup

- [x] 1.1 Add JVM-oriented container build assets for Spring Boot and Quarkus suitable for local Compose startup
- [x] 1.2 Add a dedicated Compose file and helper commands for starting PostgreSQL plus one selected JVM runtime manually
- [x] 1.3 Verify that Spring Boot and Quarkus can each be started in PostgreSQL-backed mode through the new Compose workflow

## 2. JVM Observability And Resource Controls

- [x] 2.1 Add documented JMX-based observability configuration for each JVM runtime so local tools such as VisualVM or JDK Mission Control can attach
- [x] 2.2 Add documented CPU and memory limit controls for the runtime containers, including sensible defaults and override knobs
- [x] 2.3 Verify that the containerized runtimes remain reachable and diagnostically usable under the documented resource-limit setup

## 3. Load-Testing Flow

- [x] 3.1 Add a shared repository-local load-test workload and runner for a selected running runtime
- [x] 3.2 Add per-runtime helper commands that execute the load test against the active Spring Boot or Quarkus Compose service and write result artifacts under `target/`
- [x] 3.3 Verify that both runtimes can be load-tested through the documented workflow while staying online for manual inspection

## 4. Documentation And Operator Workflow

- [x] 4.1 Update `README.md` and comparison-oriented docs with the step-by-step manual Compose workflow for Spring Boot and Quarkus
- [x] 4.2 Document the scope boundary that JVM-level tooling applies to JVM containers only, while native-image observability is deferred
- [x] 4.3 Run one end-to-end manual evaluation session per runtime and record the validated commands, assumptions, and limitations in the docs
