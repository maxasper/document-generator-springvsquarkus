## Why

The benchmark and load-test scripts currently rely on GNU/Linux-specific shell features and utilities, so macOS developers cannot run the same container runtime matrix from the repository. This blocks local comparison work on macOS even though the Docker scenarios themselves are intended to be identical across developer machines.

## What Changes

- Make the container runtime matrix script compatible with the system Bash version shipped on macOS.
- Replace GNU-specific time, file-size, memory, and AWK parsing usage in shared benchmark helpers with portable behavior.
- Preserve the existing Ubuntu behavior, scenario order, resource controls, load-test cases, and report formats.
- Keep Docker, Compose, `jq`, `curl`, Java, Maven, and k6-container workflow expectations unchanged.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `container-runtime-matrix-comparison`: The automated matrix must run the same four scenarios and produce the same artifacts on macOS and Ubuntu.
- `runtime-load-testing`: Load-test case metric collection must parse container resource samples on macOS and Ubuntu.
- `jvm-runtime-comparison`: JVM benchmark environment and artifact metrics must be collected on macOS and Ubuntu.

## Impact

- Affected scripts: `scripts/benchmark-container-runtime-matrix.sh`, `scripts/container-runtime-matrix-common.sh`, `scripts/compose-runtime-inspection-common.sh`, `scripts/load-test-compose-runtime.sh`, and `scripts/jvm-benchmark-common.sh`.
- No API, database, document-generation, Docker Compose service, or benchmark workload changes.
- No new runtime dependencies beyond tools already available on standard macOS or Ubuntu developer environments.
