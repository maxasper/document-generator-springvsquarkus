## Why

The current container runtime matrix can produce misleading results because the new `post`, `get`, and `mixed` load cases run against one shared database state. A high-throughput `post` phase can create enough history rows to make later `get` and `mixed` phases fail, which then surfaces as `p95=0`, `cpu=0`, or otherwise unusable metrics.

## What Changes

- Run the container runtime load cases as isolated phases instead of sequentially sharing one database state.
- Keep the existing mixed workflow, but run it after `post` and `get` on its own reset environment.
- Add a deterministic history seed step for `get` so read performance is measured against a known history size.
- Preserve per-case report output for `post`, `get`, and `mixed`, including request count, failure rate, successful-response latency, and per-case container CPU/memory samples.
- Render unavailable latency values as `n/a` when a case has no successful responses, rather than showing misleading zero values.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `runtime-load-testing`: split the runtime load workflow into isolated `post`, `get`, and `mixed` cases with deterministic setup per case.
- `container-runtime-matrix-comparison`: report per-case metrics in the matrix summary and avoid misleading values for failed cases.

## Impact

- Affected scripts: `scripts/runtime-load-test.js`, `scripts/load-test-compose-runtime.sh`, `scripts/benchmark-container-runtime-scenario.sh`, and `scripts/benchmark-container-runtime-matrix.sh`.
- Affected benchmark schema: `benchmarks/container-runtime-matrix-report.schema.json`.
- Affected generated outputs under `target/container-runtime-matrix/...`: per-case summaries, logs, and container stats.
- Benchmark runtime will increase because each case needs an isolated environment and `get` requires a seed phase.
