## Context

The repository currently documents several distinct operator workflows in overlapping places:

- `README.md` contains full step-by-step instructions for runtime verification, JVM benchmarking, native benchmarking, and manual JVM inspection.
- `docs/runtime-comparison-plan.md` mixes comparison guidance, benchmark interpretation, and validated operator sessions.
- `docs/runtime-inspection-ru.md` adds a second, partially overlapping workflow description for the manual JVM inspection path.

This makes it too easy to confuse workflows that have different purposes and operating assumptions. The main confusion already observed is between:

- manual JVM inspection with optional container limits and `k6` load testing
- native-image comparison, which currently does not enforce explicit container CPU or memory limits

The repository modules, ports, and runtime code do not need to change. This is a documentation-structure change only:

- Maven modules remain unchanged
- primary HTTP ports remain unchanged
- runtime adapters and benchmark scripts remain unchanged
- only the operator-facing documentation surface is being reorganized

## Goals / Non-Goals

**Goals:**

- provide one dedicated workflow document per supported manual testing or benchmarking scenario
- make `README.md` the entrypoint and link hub rather than the place that contains every operator procedure inline
- ensure each workflow guide is complete on its own: prerequisites, commands, readiness checks, artifacts, tunable parameters, cleanup, and interpretation limits
- remove overlapping ad-hoc workflow copies once the canonical guides exist
- preserve the current comparison goal and keep the distinction between verification, benchmarking, and manual inspection explicit

**Non-Goals:**

- changing any benchmark script, Compose file, Dockerfile, or runtime code
- redefining benchmark metrics or comparison methodology
- introducing new runtime modes or new operator tooling
- maintaining parallel canonical guides in multiple languages for the same workflow in this change

## Decisions

### Decision: Organize operator documentation by workflow intent

The new documentation set should be grouped by what the developer is trying to do, not by which script happens to exist.

Target structure:

- `docs/testing/runtime-verification.md`
- `docs/testing/jvm-runtime-comparison.md`
- `docs/testing/native-image-comparison.md`
- `docs/testing/manual-runtime-inspection.md`

Alternatives considered:

- keep all procedures in `README.md`: rejected because the file has already become too broad and causes workflow confusion
- keep one large `runtime-comparison-plan.md` as the primary operator manual: rejected because it mixes operator steps with interpretation notes and historical context

### Decision: Keep `README.md` as the entrypoint, not the procedure store

`README.md` should keep short high-level descriptions and link to the dedicated workflow guides. It should not duplicate the full command-by-command procedures for every testing path.

Alternatives considered:

- remove testing instructions from `README.md` entirely: rejected because the repository still needs an obvious entrypoint for new users
- keep both short summaries and full duplicated procedures in `README.md`: rejected because duplication is the current maintenance problem

### Decision: Keep one canonical language for the workflow guide set

The repository documentation is predominantly English. The new workflow-guide set should therefore be canonical in English, and the temporary Russian-only `docs/runtime-inspection-ru.md` should be removed after its useful content is migrated.

Alternatives considered:

- keep both English workflow guides and the Russian helper document: rejected because the two sources would drift
- rewrite the full repository documentation into Russian in this change: rejected because it is unrelated to the workflow split itself

### Decision: Preserve `runtime-comparison-plan.md` as a comparison-context document

`docs/runtime-comparison-plan.md` should remain focused on comparison context, metric interpretation, and reporting conventions. Detailed operator runbooks should move to the dedicated workflow guides.

Alternatives considered:

- delete `runtime-comparison-plan.md`: rejected because it still provides useful comparison-specific framing that is not the same as an operator runbook
- leave it untouched: rejected because it would continue to overlap with the new guides

### Decision: Standardize one guide template for all testing workflows

Each workflow guide should use the same structural template:

- purpose
- prerequisites
- commands
- what gets started or built
- readiness or success checks
- artifacts
- tunable parameters
- cleanup
- interpretation limits

Alternatives considered:

- tailor each document freely: rejected because uneven guide structure makes the set harder to scan and maintain

## Risks / Trade-offs

- [Documentation split can hide context if overdone] → Keep a short summary in `README.md` and preserve comparison-level framing in `docs/runtime-comparison-plan.md`.
- [Deleting the Russian helper doc could remove user-friendly detail] → Migrate its concrete operator guidance into the canonical manual inspection guide before removing it.
- [Multiple workflow docs can still drift if they repeat the same baseline facts] → Keep shared facts minimal and only where they are necessary for executing that workflow.
- [Workflow boundaries may still be misunderstood] → Make each guide explicit about its purpose, what it does not cover, and how it differs from adjacent workflows.

## Migration Plan

1. Create the new workflow-guide files under `docs/testing/`.
2. Move the detailed operator procedures out of `README.md` into the appropriate guide.
3. Reduce `README.md` to short summaries and links.
4. Trim `docs/runtime-comparison-plan.md` so it keeps comparison context without duplicating runbook steps.
5. Delete `docs/runtime-inspection-ru.md` after its operator details have been migrated.
6. Validate that every documented command, path, and artifact location still matches the current scripts.

## Open Questions

- Should the workflow guides explicitly include example expected outputs, or should they stay command-focused and concise?
- Should `docs/testing/` contain only the four primary guides, or also a small index page if more workflows appear later?
