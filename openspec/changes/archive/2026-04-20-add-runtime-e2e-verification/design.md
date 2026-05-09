## Context

The repository already has two runnable application modules and a shared `document-generator-contract-tests` module, but there is no single, repeatable way to start each runtime and execute the same HTTP contract suite against it. The next useful comparison milestone is functional parity in local `in-memory` mode, before adding PostgreSQL-backed verification or native-image benchmarks.

The design must preserve the existing boundaries:

- Spring Boot and Quarkus stay as separate runnable modules
- the shared business core remains untouched by runtime-test orchestration
- verification runs against real HTTP endpoints, not framework-specific controller tests

## Goals / Non-Goals

**Goals:**

- define one repeatable verification flow for Spring Boot in `in-memory` mode
- define one repeatable verification flow for Quarkus in `in-memory` mode
- keep the shared contract test suite runtime-agnostic and driven only by `document.generator.base-url`
- document stable ports, startup commands, and verification commands so future changes can reuse them

**Non-Goals:**

- adding PostgreSQL-backed verification in this change
- adding JVM-versus-native benchmarks in this change
- changing the document generation API or the business-core contracts
- introducing CI pipelines or cross-process orchestration that is more complex than the current project needs

## Decisions

### Decision: Verify through external HTTP contract tests

The verification baseline will continue to use the existing `document-generator-contract-tests` module as an external client that talks to a running application through `document.generator.base-url`.

This keeps the comparison honest:

- both runtimes are exercised through the same transport boundary
- the shared core is verified through real framework wiring
- the contract suite remains reusable later for PostgreSQL and native-image runs

Alternatives considered:

- framework-specific controller or resource tests: rejected because they would not prove parity across runtime wiring
- duplicating Spring and Quarkus end-to-end tests in each runtime module: rejected because it would create drift and duplicate assertions

### Decision: Standardize on explicit local runtime flows

This change will define one explicit local flow per runtime using the existing default ports and `in-memory` persistence mode:

- Spring Boot on `http://localhost:8080`
- Quarkus on `http://localhost:8081`

The contract tests will be executed separately against each runtime, never against both at once.

Alternatives considered:

- forcing both runtimes onto the same port one after another: rejected because the project already uses different defaults and there is no comparison value in changing them now
- running both runtimes concurrently inside one verification command: rejected because it adds process-management complexity without improving the parity signal

### Decision: Prefer thin helper automation over heavy Maven lifecycle coupling

The implementation should introduce thin, explicit automation such as documented commands, small helper scripts, or narrowly scoped Maven profiles rather than a large integration-test harness embedded deep in the Maven lifecycle.

The intent is to keep the verification flow easy to run and easy to debug:

- start one runtime
- wait for it to accept requests
- run the shared contract tests against its base URL
- stop the runtime

Alternatives considered:

- full pre-integration-test and post-integration-test process orchestration for both frameworks in the root build: rejected for now because Quarkus and Spring have different startup models, and premature lifecycle wiring would be harder to maintain than a thin runbook

### Decision: Keep PostgreSQL and native verification as follow-up changes

This change only establishes the first runtime parity baseline. PostgreSQL-backed verification and JVM versus native-image comparison remain separate follow-up changes so they can build on a known-good HTTP contract flow.

## Risks / Trade-offs

- [Process startup differences between Spring Boot and Quarkus] → Keep the first automation thin and runtime-specific rather than forcing one generic launcher too early.
- [False confidence from `in-memory` mode only] → Treat this change as a parity baseline and explicitly defer PostgreSQL-backed verification to the next change.
- [Contract tests may still be skipped accidentally] → Document the exact commands and wire the base URL consistently so verification is easy to invoke.
- [Port collisions on local machines] → Keep the defaults explicit in documentation and allow later overrides if needed, but standardize on one baseline first.

## Migration Plan

1. Add a documented runtime verification flow for Spring Boot in `in-memory` mode.
2. Add a documented runtime verification flow for Quarkus in `in-memory` mode.
3. Make the shared contract test command explicit for both runtimes.
4. Verify both flows locally and capture the commands in project documentation.
5. Use this baseline in the follow-up PostgreSQL and runtime-comparison changes.

Rollback is low risk because the change is limited to verification wiring and documentation. If the automation proves brittle, the repository can keep the shared contract tests and fall back to manual run instructions while preserving the rest of the architecture.

## Open Questions

- Should the first implementation use helper shell scripts, Maven profiles, or a mix of both for the runtime flows?
- Do we want a minimal readiness probe in the applications, or is probing the existing HTTP endpoints sufficient for startup detection?
