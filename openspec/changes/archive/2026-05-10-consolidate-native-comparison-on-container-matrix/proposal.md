## Why

The repository currently exposes two overlapping native-container comparison paths, which makes the operator story harder to follow and splits maintenance across duplicate benchmark code. At the same time, the shared Spring Boot `spring-native` container path is mislabeled today because it produces a JVM image rather than a true native executable image.

## What Changes

- **BREAKING** remove the standalone `native-image comparison` workflow from the supported repository benchmarking surface and keep `container runtime matrix comparison` as the sole automated Docker-to-Docker comparison path
- remove the legacy native benchmark scripts, workload metadata, and dedicated native comparison runbook that described the old flow
- update repository documentation so Docker-native comparison guidance points to the container runtime matrix and manual container inspection flows only
- fix the shared Spring Boot `spring-native` image build path so matrix and manual container scenarios run a real native executable image built through the documented Spring Boot buildpacks path
- document the migration path from the removed native-image comparison workflow to the remaining container runtime matrix workflow

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `native-image-comparison`: remove the standalone native-image benchmark workflow and migrate users to the container runtime matrix workflow
- `container-runtime-matrix-comparison`: treat the matrix flow as the supported automated Docker-to-Docker comparison path and require real native images for native scenarios
- `compose-runtime-inspection`: require the shared Spring Boot `native` image build used by manual inspection to produce a true native executable container
- `testing-workflow-documentation`: update repository entrypoints and workflow guides to remove the dedicated native-image comparison runbook and point container comparisons at the remaining supported workflows

## Impact

- affected scripts: `scripts/benchmark-native-*.sh`, `scripts/build-compose-runtime-image.sh`, container-runtime helpers, and documentation entrypoints
- affected docs: `README.md`, `docs/runtime-comparison-plan.md`, `docs/testing/*`
- affected benchmark metadata: legacy native workload and report schema files may be removed if they are no longer used
- affected operator behavior: users migrate from `benchmark-native-comparison.sh` to `benchmark-container-runtime-matrix.sh`
