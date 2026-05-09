## Context

The repository starts almost empty, but the demo goal is already specific: compare Spring Boot and Quarkus for the same document generation service without rewriting business rules. The first step therefore needs to lock down a small service contract, a module plan, and the architectural boundaries that future implementation slices must preserve.

Key constraints:

- Java 25
- Maven multi-module structure
- hexagonal architecture
- pure Java domain and application layers
- separate runnable Spring Boot and Quarkus applications
- PostgreSQL-ready persistence, with permission to start simpler if that speeds up the first slice

## Goals / Non-Goals

**Goals:**

- establish a shared-core plus dual-runtime structure that both frameworks can use
- make the v1 API contract concrete enough for iterative implementation
- keep document generation simple so architectural comparison stays central
- keep follow-up implementation slices small and easy to verify

**Non-Goals:**

- implement real document templating or a production-grade rendering pipeline
- design for every future document format or template storage option
- optimize for native-image compatibility before the base functionality exists
- extract every conceivable shared adapter before duplication appears

## Decisions

### 1. Use a small Maven multi-module layout from the start

Proposed modules:

- `document-generator-domain`
- `document-generator-application`
- `document-generator-adapter-out-renderer-stub`
- `document-generator-app-spring`
- `document-generator-app-quarkus`

Rationale:

- it keeps the shared core visible in the build
- it prevents runtime applications from absorbing domain logic
- it creates a clean baseline for later JVM versus native-image comparison

Alternatives considered:

- single-module project: rejected because framework and business code would mix too early
- many fine-grained adapter modules from day one: rejected because the repo is still proving its basic seams

### 2. Keep use cases and ports in the application module

The application module will own inbound use cases such as `GenerateDocumentUseCase` and `ListGenerationHistoryUseCase`, plus outbound ports such as `GenerationRequestRepository` and `DocumentRenderer`.

Rationale:

- the core remains testable without HTTP or database frameworks
- both runtimes can wire the same orchestration logic
- persistence and rendering decisions stay replaceable

Alternative considered:

- letting controllers or resources coordinate persistence and rendering directly: rejected because it duplicates flow logic across runtimes

### 3. Model template rules in the shared core

Template-type parameter validation belongs in pure Java policy code, not in Spring or Quarkus adapters.

Rationale:

- validation is business logic, not transport logic
- both runtimes must enforce identical rules
- the core can start with a small code-defined registry and evolve later if templates become externalized

Alternative considered:

- loading validation rules from framework configuration immediately: rejected because it adds integration complexity before rules are stable

### 4. Share only the stub renderer adapter in the first iteration

The initial `DocumentRenderer` implementation should be a framework-neutral stub module reused by both runtimes.

Rationale:

- it keeps the comparison centered on application structure rather than file-generation mechanics
- it avoids duplicating mock rendering code in Spring and Quarkus

Alternative considered:

- runtime-specific renderer stubs: rejected because the behavior should be identical and does not need framework-specific code

### 5. Keep HTTP and persistence adapters inside each runtime module for now

Both runtime modules will own their REST and persistence integration. The repository contract and API contract must stay shared, but the adapters themselves can remain runtime-local initially.

Rationale:

- the framework comparison stays explicit
- integration code can follow each framework's idioms without contaminating the shared core
- a shared persistence adapter can be revisited later if duplication becomes meaningful

Alternative considered:

- a shared JPA adapter module: deferred until actual duplication justifies it

### 6. Start PostgreSQL-ready, but allow an in-memory first slice

The domain model and repository port must assume durable request history, but the first thin slice may use an in-memory adapter before PostgreSQL wiring is added.

Rationale:

- it reduces time to first runnable comparison
- it lets the team validate ports, DTOs, and controller-resource boundaries before adding database complexity

Trade-off:

- one early adapter will be temporary and later replaced or supplemented

### 7. Keep the first request model intentionally simple

Working assumption for v1:

- `parameters` is a flat map
- `documentFormat` and `templateType` come from a small code-defined enum set
- history is newest-first and initially unpaginated

Rationale:

- the demo focus is architecture, not schema richness
- simple request semantics make behavior easier to reproduce in both runtimes

## Risks / Trade-offs

- [Framework leakage into the core] -> keep port ownership in the application module and review dependencies before adding libraries
- [Spring and Quarkus adapters diverge in behavior] -> add shared contract tests around the same endpoint scenarios
- [Temporary in-memory persistence hides DB concerns too long] -> make PostgreSQL adapter a dedicated early milestone, not a vague future task
- [Stub rendering hides file semantics] -> keep response contract explicit around filename and content metadata
- [Template-rule growth becomes hard to manage] -> centralize template rules behind one core policy abstraction

## Migration Plan

There is no runtime system to migrate yet. The implementation plan is incremental:

1. scaffold the Maven parent and shared core modules
2. implement the pure Java core contracts and validation rules
3. deliver one runtime slice with stub generation
4. add the second runtime against the same core
5. add PostgreSQL-backed persistence and parity checks

## Open Questions

- should v1 start with only `TXT` output, or must it emit a minimal valid `PDF` from the first slice?
- should `parameters` be restricted to string values in the public API, or is typed JSON required immediately?
- should history pagination be deferred entirely, or included from the first contract to avoid breaking changes later?
- should database migration scripts eventually live in one shared location, or alongside each runtime module?
