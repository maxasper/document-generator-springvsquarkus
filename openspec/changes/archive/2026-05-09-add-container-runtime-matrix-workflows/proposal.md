## Why

The repository currently splits containerized evaluation into unrelated flows: manual Docker Compose inspection exists only for JVM runtimes, JVM benchmarking runs the applications on the host instead of in containers, and native comparison is automated but not reusable as a manual long-running container workflow. That makes it hard to compare Spring Boot and Quarkus fairly across `jvm` and `native` modes under identical Docker limits and the same load profile.

## What Changes

- Add a shared container-runtime workflow that can build, start, inspect, and load-test `spring` and `quarkus` in both `jvm` and `native` modes through one runtime-and-mode selector model.
- Extend the manual Compose workflow so developers can start any one of the four container scenarios (`spring-jvm`, `quarkus-jvm`, `spring-native`, `quarkus-native`), keep it online, and run the repository-local load test against it.
- Add an automated container-runtime matrix flow that runs all four scenarios sequentially under one shared set of CPU, memory, and load-test settings and emits a combined machine-readable report plus a human-readable summary table.
- Keep the existing host JVM comparison and native-image benchmark flows intact, but document the new containerized matrix as the Docker-to-Docker comparison path.

## Capabilities

### New Capabilities
- `container-runtime-matrix-comparison`: Automated Docker-based comparison across `spring/quarkus x jvm/native` with one shared resource-budget and load profile.

### Modified Capabilities
- `compose-runtime-inspection`: Expand the manual Compose flow from JVM-only inspection to one-runtime-at-a-time container inspection for both JVM and native runtimes.
- `container-resource-limits`: Apply the documented CPU and memory controls consistently to manual and automated container-runtime flows across all four runtime scenarios.
- `runtime-load-testing`: Allow the repository-local load-test workflow to target a selected running JVM or native container runtime and reuse the same load controls in automated matrix runs.
- `testing-workflow-documentation`: Reorganize the workflow runbooks so the manual container-runtime and automated container-matrix flows are documented as first-class entrypoints.

## Impact

- Affected scripts under `scripts/` for image build, Compose startup, load testing, and automated reporting.
- Affected Compose topology in `compose.runtime-inspection.yml` or its successor to include native runtime services alongside JVM services.
- New benchmark/report artifacts under `benchmarks/` and `target/` for the combined four-scenario container matrix.
- Updated workflow guides under `docs/testing/` and `README.md` to distinguish host-based benchmarks from containerized runtime comparison.
