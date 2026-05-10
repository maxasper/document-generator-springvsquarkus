## Context

The repository has grown two different Docker-native comparison stories:

- the older `native-image comparison` harness, which builds Spring Boot and Quarkus native artifacts and benchmarks them with its own orchestration, request loop, and report format
- the newer `container runtime matrix comparison` harness, which is already the unified Docker-to-Docker workflow for `spring/quarkus x jvm/native` under one shared resource budget and one shared load profile

That overlap is already confusing in documentation, and the situation is worse because the shared Spring Boot `spring-native` container build path used by the matrix and manual Compose inspection is not actually producing a native executable image. The runtime logs show a JVM-based Spring Boot process with `BOOT-INF/classes`, which means the current matrix results for `spring-native` are not trustworthy.

## Goals / Non-Goals

**Goals:**

- make the container runtime matrix the single supported automated Docker comparison workflow
- remove the legacy standalone native benchmark entrypoints and their documentation
- keep the existing host JVM comparison workflow intact
- fix the shared Spring Boot `spring-native` build path so both matrix and manual Compose workflows use a real native executable image
- keep Spring Boot and Quarkus on their framework-native native build paths rather than inventing a shared custom Dockerfile just for symmetry

**Non-Goals:**

- redesign the host JVM benchmark harness
- add new benchmark metrics beyond the existing matrix report
- change the Quarkus native build path
- add JVM-only observability to native scenarios

## Decisions

### Decision: Remove the legacy native benchmark workflow from supported workflows

The repository will keep `benchmark-container-runtime-matrix.sh` as the canonical automated Docker comparison flow and will stop documenting the older `benchmark-native-comparison.sh` path.

Why:

- the matrix already covers both native scenarios plus the JVM scenarios under one shared resource budget and one shared `k6` workload
- one Docker comparison entrypoint is easier to explain, validate, and maintain than two partially overlapping ones
- the separate legacy harness no longer justifies its cost once native comparison is interpreted as part of the broader container runtime matrix

Alternative considered:

- keep both workflows and only improve the docs
  - rejected because it preserves duplicate orchestration and does not solve the operator confusion

### Decision: Fix Spring Boot native through the existing Spring Boot buildpacks path

The shared `spring-native` image build will continue to use `spring-boot:build-image`, but it must explicitly enable the native-image buildpack environment instead of relying on `-Pnative` alone.

Why:

- the current logs prove that `-Pnative` plus `spring-boot:build-image` is not sufficient in this repository's current setup
- Spring Boot documentation and the Paketo native-image flow require the buildpack native toggle so the produced OCI image contains a native executable rather than a JVM application image
- reusing the framework-native buildpacks path keeps the comparison honest and avoids a repository-specific Dockerfile workaround

Alternative considered:

- generate a host native binary first and wrap it in a custom Dockerfile
  - rejected because it diverges from the intended Spring Boot native container path and creates a bespoke packaging flow just for this repository

### Decision: Keep manual Compose inspection on the same shared build entrypoint

The fix for Spring Boot native will be applied in `scripts/build-compose-runtime-image.sh`, which is already shared by manual Compose inspection and the container runtime matrix.

Why:

- one shared build entrypoint prevents the matrix and manual inspection flows from drifting apart again
- the manual `spring-native` scenario should benefit from the same correctness fix automatically

## Risks / Trade-offs

- [Loss of legacy native-specific report fields] → The old standalone native benchmark included contract-verification timing and a dedicated report shape. Mitigation: keep runtime verification as the correctness gate and use the container runtime matrix as the canonical Docker comparison report.
- [Spring native build may become slower] → Enabling actual native image compilation for Spring Boot will likely increase build time. Mitigation: document that this is the expected cost of a real native build and validate with the matrix output.
- [Stale documentation or scripts may remain] → The repository has several overview documents. Mitigation: update README, benchmark architecture, runtime comparison notes, and workflow runbooks in the same change.
