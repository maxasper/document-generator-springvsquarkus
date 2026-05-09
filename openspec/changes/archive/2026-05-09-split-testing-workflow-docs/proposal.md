## Why

`README.md` and the current comparison notes now mix several distinct operator workflows: runtime verification, JVM benchmarking, native-image benchmarking, and manual JVM inspection with load testing. This makes the repository harder to navigate and increases the chance of confusing one testing path with another, especially where resource limits and runtime modes differ.

## What Changes

- Split the current testing and benchmarking instructions into separate workflow documents grouped by user intent rather than by script list.
- Reduce `README.md` to a concise entrypoint that links to the dedicated workflow guides instead of carrying full operator procedures inline.
- Add one dedicated document per supported manual workflow:
  - runtime verification
  - JVM runtime comparison
  - native-image comparison
  - manual JVM container inspection and load testing
- Standardize the structure of those workflow documents so each one explains prerequisites, startup commands, readiness checks, result artifacts, tunable parameters, cleanup, and interpretation limits.
- Remove `docs/runtime-inspection-ru.md` after its useful content has been migrated into the new canonical workflow documentation set.

## Capabilities

### New Capabilities
- `testing-workflow-documentation`: Scenario-oriented documentation structure for repository-local verification, benchmarking, and manual inspection workflows.

### Modified Capabilities
- `compose-runtime-inspection`: Clarify that the documented manual inspection flow is surfaced through a dedicated workflow guide linked from the repository entrypoint.
- `jvm-runtime-comparison`: Clarify that the documented JVM benchmark flow is surfaced through its own dedicated workflow guide linked from the repository entrypoint.
- `native-image-comparison`: Clarify that the documented native benchmark flow is surfaced through its own dedicated workflow guide linked from the repository entrypoint.
- `runtime-contract-verification`: Clarify that the documented verification flows are surfaced through a dedicated workflow guide linked from the repository entrypoint.

## Impact

- Affected docs: `README.md`, `docs/runtime-comparison-plan.md`, and the new workflow-guide files under `docs/`.
- Removed docs: `docs/runtime-inspection-ru.md`.
- No runtime code, API contracts, or benchmark scripts should change as part of this documentation-only restructure.
