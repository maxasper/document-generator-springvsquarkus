## 1. Workflow Consolidation

- [x] 1.1 Remove the legacy native-image comparison scripts, benchmark metadata, and runbook from the supported repository workflow set
- [x] 1.2 Update README, benchmark architecture notes, and testing workflow docs so containerized comparison points only to the container runtime matrix and manual inspection flows

## 2. Spring Native Build Fix

- [x] 2.1 Correct the shared Spring Boot `spring-native` build path so it enables the actual native buildpacks mode
- [x] 2.2 Verify that the produced `spring-native` container no longer starts as a JVM image and that the matrix/manual native path still comes up successfully

## 3. Validation

- [x] 3.1 Run focused validation for the updated Spring native container path and the remaining documentation entrypoints
- [x] 3.2 Mark the OpenSpec tasks complete and capture the new supported workflow shape
