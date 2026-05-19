## 1. Matrix Script Compatibility

- [x] 1.1 Replace Bash 4-only scenario loading in the container runtime matrix with Bash 3.2-compatible logic.
- [x] 1.2 Verify the matrix still reads all configured scenarios in the workload file in order.

## 2. Portable Benchmark Helpers

- [x] 2.1 Replace GNU-specific millisecond epoch calls with a portable implementation used by benchmark timing helpers.
- [x] 2.2 Add macOS-compatible artifact-size measurement while preserving existing Linux behavior.
- [x] 2.3 Add macOS-compatible total-memory metadata collection while preserving existing Linux behavior.

## 3. Portable Resource Parsing

- [x] 3.1 Replace AWK parsing that depends on non-default macOS AWK extensions in shared Docker memory conversion.
- [x] 3.2 Replace AWK parsing that depends on non-default macOS AWK extensions in load-test sampled memory conversion.

## 4. Verification

- [x] 4.1 Run shell syntax checks for the affected scripts under the system Bash.
- [x] 4.2 Verify macOS helper functions produce epoch, memory, processor, artifact-size, and environment JSON values.
- [x] 4.3 Verify the matrix scenario list resolves to `spring jvm`, `quarkus jvm`, `spring native`, and `quarkus native`.
