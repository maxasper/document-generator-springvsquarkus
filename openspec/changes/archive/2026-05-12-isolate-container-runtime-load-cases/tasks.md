## 1. Workload Cases

- [x] 1.1 Update `scripts/runtime-load-test.js` to support an explicit `post`, `get`, or `mixed` workload case selection.
- [x] 1.2 Preserve the current write-then-read workflow and think time as the `mixed` case.
- [x] 1.3 Make the `post` case measure only document-generation create requests.
- [x] 1.4 Make the `get` case measure only document-generation history reads.
- [x] 1.5 Add validation and clear error output for unsupported workload case values.

## 2. Case Setup And Isolation

- [x] 2.1 Add a configurable ordered workload-case list for automated matrix runs, defaulting to `post,get,mixed`.
- [x] 2.2 Reset the Compose runtime and PostgreSQL baseline before every workload case inside each runtime scenario.
- [x] 2.3 Add deterministic history seeding for the `get` case before measured requests start.
- [x] 2.4 Add a documented seed-size override, defaulting to a practical local value.
- [x] 2.5 Ensure runtime image packaging/build work is reused where practical and not repeated unnecessarily for every case.

## 3. Metrics And Reports

- [x] 3.1 Write load-test outputs to case-specific artifact directories.
- [x] 3.2 Aggregate matrix report JSON by runtime scenario and workload case.
- [x] 3.3 Update `benchmarks/container-runtime-matrix-report.schema.json` for per-case results and unavailable latency values.
- [x] 3.4 Render unavailable successful-response latency metrics as `n/a` in `summary.txt`.
- [x] 3.5 Round `failed`, `p95(ms)`, and `p95_ok(ms)` consistently in the human-readable summary.
- [x] 3.6 Scope Docker CPU and memory samples to the measured workload case and prevent missing samples from becoming misleading zeroes.

## 4. Documentation

- [x] 4.1 Document the `post`, `get`, and `mixed` workload cases.
- [x] 4.2 Document the workload-case list override and get-history seed-size override.
- [x] 4.3 Explain that Docker CPU/memory values are per-case container observations, not JVM profiler measurements.
- [x] 4.4 Update report examples or descriptions to show per-case summary output.

## 5. Verification

- [x] 5.1 Run script syntax checks for the changed shell scripts.
- [x] 5.2 Run JavaScript syntax validation for the changed k6 workload script.
- [x] 5.3 Run a short local matrix with reduced VUs and duration to verify all three workload cases produce artifacts.
- [x] 5.4 Inspect `target/container-runtime-matrix/latest/summary.txt` and `report.json` to confirm per-case rows, no misleading latency zeroes, and non-empty per-case resource samples.
- [x] 5.5 Run the relevant existing Maven tests to confirm application behavior was not changed.
