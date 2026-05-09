## Context

The repository already supports:

- shared Spring Boot and Quarkus contract verification
- PostgreSQL-backed verification through `compose.postgres-verification.yml`
- JVM and native comparison scripts that run unattended and write reports

What it does not support yet is an operator workflow where a developer can:

- build container images for the JVM runtimes
- start one runtime manually in Compose and keep it running
- attach a local JVM tool such as VisualVM or JDK Mission Control
- constrain CPU and memory at the container level
- run an explicit load test against the chosen runtime while it stays online

This change should stay aligned with the repository comparison goal. The workflow must make Spring Boot and Quarkus comparable under the same PostgreSQL-backed conditions, but it should remain transparent and debuggable rather than becoming another opaque benchmark harness.

## Goals / Non-Goals

**Goals:**

- provide a manual Compose-based JVM runtime workflow for Spring Boot and Quarkus
- allow a developer to start the selected runtime in PostgreSQL-backed mode and keep it running for inspection
- expose JVM-observability ports and startup options that work with local tools such as VisualVM or JDK Mission Control
- allow CPU and memory constraints to be applied through Docker Compose with documented defaults and overrides
- provide one repository-local load-testing command and workload definition that can target the selected running runtime
- write repeatable load-test result artifacts under a repository-local output directory

**Non-Goals:**

- replacing the existing automated JVM or native benchmark flows
- building a production-grade monitoring stack with Prometheus, Grafana, and long-lived dashboards
- adding Java-level observability for native-image containers, where JMX-based tooling is not applicable
- running Spring Boot and Quarkus simultaneously as part of the primary manual evaluation workflow

## Decisions

### Decision: Scope the first slice to JVM containers only

The new manual inspection workflow should target Spring Boot and Quarkus in JVM mode. This is the only mode where VisualVM, JMX, and JFR-style tooling directly answer the user goal of inspecting Java resources such as heap, threads, classes, GC, and CPU usage.

Alternatives considered:

- include native-image containers in the same first slice: rejected because the observability model becomes different and weakens the clarity of the first workflow
- make the workflow runtime-mode agnostic from day one: rejected because it would force the design toward the lowest common denominator of container metrics instead of JVM-level diagnostics

### Decision: Use a dedicated Compose file for manual runtime evaluation

The repository should add a dedicated Compose definition for manual runtime evaluation instead of overloading the existing PostgreSQL verification Compose file. This new Compose file should include:

- a shared PostgreSQL service
- one Spring Boot JVM service
- one Quarkus JVM service
- an optional load-test runner service

Only one application service is expected to be started at a time by the documented workflow.

Alternatives considered:

- extend `compose.postgres-verification.yml` with runtime services: rejected because it mixes automated verification infrastructure with interactive operator flows
- use host-process startup plus only Compose-backed PostgreSQL: rejected because it does not satisfy the container resource-limit requirement

### Decision: Use per-runtime JVM Dockerfiles with remote JMX enabled for local-only diagnostics

Each runtime should have its own JVM container Dockerfile because the application packaging differs:

- Spring Boot uses the packaged fat jar
- Quarkus uses the packaged `quarkus-app/` layout

For observability, the workflow should expose a documented JMX port for the selected runtime and configure the JVM so VisualVM or JDK Mission Control can connect from the host machine. The documented defaults should keep authentication and SSL disabled for local use only, and the same port should be used for both JMX registry and RMI to reduce container-network surprises.

Alternatives considered:

- embed VisualVM or a monitoring agent inside the application container: rejected because it adds unnecessary weight and complexity
- require only JFR file capture without live inspection: rejected because the user explicitly wants live inspection tooling

### Decision: Express resource controls with Compose-level limits plus JVM-aware defaults

The manual workflow should allow developers to constrain CPU and memory through Docker Compose settings that are effective with the local Compose CLI, such as:

- `cpus`
- `mem_limit`
- optional `pids_limit`

The runtime environment should also include documented JVM memory options so container-aware heap sizing stays understandable under those limits.

Alternatives considered:

- use only `deploy.resources`: rejected because standalone Docker Compose does not consistently enforce it outside Swarm
- rely on JVM defaults without documenting heap implications: rejected because the resulting behavior becomes hard to interpret

### Decision: Use k6 as the first repository-local load-testing tool

The first load-testing slice should use `k6`, executed through a containerized workflow so developers do not need a host installation. This fits the repository style because:

- it is easy to parameterize per runtime
- it can run against the Compose network directly
- it produces structured summary data that can be archived under `target/`

The load-test flow should remain separate from the comparison benchmark scripts. Its purpose is manual stress and behavior observation while a chosen runtime is live, not unattended apples-to-apples benchmarking.

Alternatives considered:

- JMeter: rejected because it is heavier for a small repository-local workflow
- `wrk` or `hey`: rejected because they are simpler but produce a weaker structured scenario model for reusable test profiles
- embed load generation into the benchmark scripts: rejected because the manual evaluation use case is distinct from the comparison harness

### Decision: Keep the operator flow sequential and explicit

The documented workflow should intentionally lead the operator through one runtime at a time:

1. build images
2. start Spring Boot or Quarkus with PostgreSQL
3. attach VisualVM or another JVM tool
4. run the load test
5. stop the environment
6. repeat for the other runtime

This matches the repository comparison discipline and keeps resource interpretation cleaner.

Alternatives considered:

- run both runtimes side by side in one Compose session: rejected because it introduces avoidable cross-talk in resource usage

## Risks / Trade-offs

- [JMX over Docker can be brittle] → Keep the configuration local-only, use a single exposed JMX port per runtime, and document exact connection settings.
- [Container memory limits can distort JVM behavior if heap settings are opaque] → Document the relationship between container limits and JVM memory flags, and choose explicit defaults.
- [Load-test numbers from a developer workstation are noisy] → Position this workflow as exploratory and comparative on the same machine, not as a production-grade performance gate.
- [A Compose workflow adds another execution path beside the benchmark scripts] → Reuse the same PostgreSQL-backed runtime assumptions and keep the load-test workload narrow and documented.
- [Native-image users may expect the same observability path] → State clearly that this change is JVM-only for Java-level inspection, with native follow-up deferred.

## Migration Plan

1. Add JVM container build assets for Spring Boot and Quarkus.
2. Add a dedicated Compose file plus helper scripts for build, startup, teardown, and runtime selection.
3. Add JMX-oriented runtime configuration and document local tool attachment.
4. Add shared load-test assets, output handling, and runtime wrappers.
5. Document the manual operator workflow and verify it end-to-end for both runtimes.

Rollback is low risk because this change adds a new optional developer workflow without changing the shared business API or the existing automated verification and comparison flows.

## Open Questions

- Should the first slice expose only JMX, or also preconfigure JFR startup flags and output directories?
- Should the load-test result format be JSON only, or JSON plus a short human-readable summary similar to the benchmark scripts?
- Do we want one shared port convention for Spring Boot and Quarkus JMX, or runtime-specific defaults to reduce accidental collisions across sessions?
