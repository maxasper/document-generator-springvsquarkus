## Context

The container runtime matrix now exercises multiple workload shapes (`post`, `get`, and `mixed`) in one benchmark run. The current flow can let these cases share runtime and database state. That makes later cases depend on the volume of data produced by earlier cases instead of measuring the intended workload.

The most visible failure mode is `post` creating a large number of history rows, followed by `get` reading the full unbounded history endpoint. Once the runtime times out or exits, later metrics can degrade into misleading values such as `p95=0`, `p95_ok=0`, `cpu=0`, or empty container stats. Those values describe failed measurement collection more than application performance.

No new Maven modules are needed. The change is limited to benchmark scripts, k6 workload selection, report aggregation, schema, and documentation.

## Goals

- Run `post`, `get`, and `mixed` as isolated load-test cases inside the same matrix command.
- Keep the existing mixed workflow and execute it last, but on a clean runtime/database baseline.
- Seed the `get` case with a deterministic number of history rows before measuring it.
- Capture report metrics and container stats per runtime scenario and per load-test case.
- Represent unavailable latency values as unavailable data, not as zero latency.
- Preserve the current resource-limit and load-profile override controls.

## Non-Goals

- Do not change the application API contract or add pagination to `GET /api/v1/document-generations`.
- Do not change application database schema or business logic.
- Do not replace Docker-level CPU/memory observations with JVM profiling data.
- Do not make manual interactive load testing replace the automated matrix flow.

## Decisions

1. Case isolation belongs in the scenario runner.

   The matrix should still build each runtime image once per scenario, but each workload case should reset the Compose environment before starting measurement. This keeps one command for the operator while preventing `post` from poisoning `get` and `mixed`.

2. Workload selection is explicit.

   The k6 workload will support a single selected case, such as `LOAD_TEST_CASE=post`, `LOAD_TEST_CASE=get`, or `LOAD_TEST_CASE=mixed`. The matrix runner will iterate a configured ordered list, defaulting to `post,get,mixed`.

3. `mixed` preserves the previous behavior.

   The current user-level workflow, including its think time, remains the `mixed` case. The new `post` and `get` cases should avoid adding that sleep because they are meant to isolate endpoint throughput and latency.

4. `get` uses deterministic setup.

   Before measuring the `get` case, the runner seeds a configured number of document-generation history rows. The default seed size should be modest enough to keep local runs practical, and it should be configurable with an environment variable such as `LOAD_TEST_GET_SEED_ROWS`.

5. Reports model missing measurements explicitly.

   If a case has no successful HTTP responses, successful-response latency fields should be `null` in JSON and `n/a` in the human summary. A zero latency value should only mean a measured zero, not "the app never answered".

6. Container stats are scoped to the measured case.

   CPU and memory sampling should start after the case runtime is ready and stop after that case completes. The summary should use per-case samples, not stale values from previous cases or missing values from a stopped container.

## Risks / Trade-offs

- Full matrix runtime will increase because every workload case starts from an isolated environment. The default case list and existing duration overrides keep this controllable.
- HTTP-based seeding is slower than direct database seeding, but it exercises the same public API and avoids coupling the benchmark helper to storage details. If it becomes too slow, a later change can introduce an explicit database seed path.
- The unbounded history endpoint remains inherently sensitive to row count. This change makes that sensitivity measurable instead of accidental.
- Docker-level CPU is still a coarse container observation. It is useful for scenario comparison, but not a replacement for JVM/JFR profiling.
