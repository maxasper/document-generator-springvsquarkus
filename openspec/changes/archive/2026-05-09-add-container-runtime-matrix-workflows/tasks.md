## 1. Generalize Container Runtime Lifecycle

- [x] 1.1 Introduce a shared runtime-and-mode helper layer for container image naming, service naming, base URLs, ports, and supported scenario validation
- [x] 1.2 Extend the Compose topology to support `spring-jvm`, `quarkus-jvm`, `spring-native`, and `quarkus-native` as one-runtime-at-a-time services plus shared PostgreSQL and `k6`
- [x] 1.3 Generalize the image-build scripts so Spring Boot and Quarkus can be built in both `jvm` and `native` modes through one repository-local entrypoint

## 2. Manual Container Runtime Workflows

- [x] 2.1 Generalize the Compose startup and shutdown scripts so a developer can start any one supported runtime scenario manually
- [x] 2.2 Generalize the load-test scripts so a developer can run the repository-local `k6` workload against any selected running runtime scenario
- [x] 2.3 Add thin operator-friendly wrapper scripts for the four manual runtime scenarios where they improve discoverability

## 3. Automated Matrix Workflow

- [x] 3.1 Implement a reusable scenario runner that builds the selected image, starts the runtime container with the configured limits, waits for readiness, runs the shared load test, captures results, and tears the scenario down
- [x] 3.2 Add a combined matrix script that runs all four scenarios sequentially under one shared condition set
- [x] 3.3 Emit a machine-readable matrix report and a human-readable summary table with per-scenario limits and load-test metrics

## 4. Documentation And Validation

- [x] 4.1 Add or update workflow guides for manual container runtime inspection and automated container runtime matrix comparison
- [x] 4.2 Update `README.md` and related testing docs so host-based JVM comparison and containerized matrix comparison are clearly separated
- [x] 4.3 Validate the new scripts, OpenSpec artifacts, and at least one manual and one automated container-runtime scenario end to end
