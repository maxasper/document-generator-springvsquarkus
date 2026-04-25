# Project Rules

This document is the repository-local ruleset for this project. It adapts the imported portable Java baseline to the actual comparison goal here: one shared business core, two runtime edges, and one shared contract harness.

## 1. Architecture and module boundaries

- Maven multi-module is treated as an architectural boundary, not just as a build convenience.
- The generic portable layout maps to this repository like this:

| Portable rule | This repository |
| --- | --- |
| `domain` | `document-generator-domain` |
| `application` | `document-generator-application` |
| `integrations/adapters/*` | `document-generator-adapter-out-renderer-stub` plus runtime-local REST and persistence adapters inside each app module |
| `integrations/bootstrap` | `document-generator-app-spring` and `document-generator-app-quarkus` |
| `component-test` | `document-generator-contract-tests` |

- `document-generator-domain` contains only domain types and domain validation logic.
- `document-generator-application` contains use-case interfaces, ports, and orchestration code.
- `document-generator-adapter-out-renderer-stub` is the only shared adapter today because it is framework-neutral.
- `document-generator-app-spring` and `document-generator-app-quarkus` own their runtime wiring, HTTP edge, persistence edge, and packaging.
- `document-generator-contract-tests` is the top-level behavioral harness and must stay runtime-agnostic.
- New logic must go to the module that owns the responsibility, not the module that is easiest to import from.
- String-based package scanning remains disallowed. Prefer default root scanning, `@Import`, or class-rooted configuration.

## 2. Dependency rules

- `document-generator-domain` and `document-generator-application` must stay narrow and framework-neutral.
- Core modules must not depend on Spring, Spring Boot, Quarkus, servlet APIs, JAX-RS APIs, Jakarta Persistence APIs, Flyway, or database drivers.
- Spring Boot starters are allowed only in `document-generator-app-spring`.
- Quarkus runtime extensions are allowed only in `document-generator-app-quarkus`.
- Infrastructure dependencies such as JDBC, PostgreSQL, Flyway, and JSON/http runtime libraries live only in runtime modules.
- Only runtime modules are considered publishable application artifacts. Non-runtime modules skip Maven deploy by default.
- Use `./mvnw` for every build, test, and verification flow.

## 3. Hexagonal rules

- Domain and application code must not know about Spring, Quarkus, JPA, servlet APIs, or JAX-RS APIs.
- External technologies plug in through adapters implementing ports from `document-generator-application`.
- Mapping between domain models and runtime-local HTTP or persistence models must stay explicit.
- Runtime-specific DTOs and persistence entities must not leak from one runtime to the other.
- Shared abstractions are allowed only when they are genuinely framework-neutral and improve parity, not when they hide meaningful runtime differences.

## 4. Code writing rules

- Constructor injection is the default for Spring beans, Quarkus beans, controllers, resources, and producers.
- Field injection is not allowed.
- Prefer `final` fields and immutable models where possible.
- If a model already has a builder, builder-first construction is the default.
- Direct `new` is acceptable only for framework-managed objects, exceptions, or very small value objects where a builder would add noise.
- Prefer `record` for small immutable carrier models when it simplifies the code.
- The Lombok conventions from the portable baseline are imported as the default policy if Lombok is introduced later:
  - `@RequiredArgsConstructor` for constructor injection
  - `@Builder` on simple carrier records
  - `@Data`, `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor` for class-based carrier models
- The current repository is still intentionally plain Java. Existing explicit constructors and records remain valid until there is a concrete reason to add Lombok.

## 5. Persistence entity rules

- Persistence entities remain runtime-local technical models.
- Spring and Quarkus must not share entity classes just to remove duplication.
- If class-based persistence entities are introduced, apply the portable conventions:
  - package-private accessors where possible
  - `@Builder`, `@NoArgsConstructor`, `@AllArgsConstructor`
  - `equals/hashCode` limited to stable DB identity
  - `toString` limited to safe, stable fields

## 6. Database and migrations

- Schema changes happen only through Flyway migrations.
- Ad-hoc schema edits outside migrations are forbidden.
- Migrations stay next to the runtime-local persistence adapter resources.
- Because Spring and Quarkus currently own separate persistence edges, duplicated SQL migrations must remain functionally equivalent between the two runtime modules.
- Flyway execution and runtime wiring stay at the runtime edge.

## 7. Test strategy

- `document-generator-domain` and `document-generator-application` require unit tests.
- Runtime-local adapters require integration tests against real technology, not mocks only.
- PostgreSQL, messaging, cache, or other real dependencies should be started with Testcontainers in integration/component tests when those adapters are exercised in-process.
- `document-generator-contract-tests` is the component-test layer for this repository and must continue to run unchanged against both runtimes.
- Runtime verification scripts remain valid as outer-loop smoke flows, but shared behavior must still be asserted in the common contract suite.
- For this repository specifically, every new user-visible behavior should land in the shared contract suite first, then be made green in both runtimes.

## 8. Build, quality, and artifacts

- Platform versions and common plugin versions are centralized in the parent `pom.xml`.
- Java `25` is the baseline until the repository intentionally moves to a newer LTS.
- Checkstyle runs in `verify` with a small enforceable baseline from the repository root `checkstyle.xml`.
- JaCoCo collects per-module coverage and aggregates it in `document-generator-quality-report/target/site/jacoco-aggregate`.
- Container images should be built from runtime modules with Jib-family tooling instead of handwritten Dockerfiles once containerized comparison starts:
  - Spring Boot runtime: `jib-maven-plugin`
  - Quarkus runtime: Jib-based container-image path when that comparison layer is introduced
- The repository keeps two runnable runtime modules on purpose, so there is no single canonical `bootstrap` artifact.

## 9. Minimal style baseline

- Maximum line length: `120`
- wildcard imports are forbidden
- unused imports are forbidden
- `if`, `else`, `for`, and `while` require braces
- empty blocks are forbidden
- basic whitespace rules are enforced
- one statement per line
- standard naming rules for local variables, methods, parameters, and types

## 10. What is enforced today

- Maven Enforcer checks the Java and Maven baseline in every module.
- Maven Enforcer blocks framework/runtime dependencies from entering the core modules.
- Checkstyle runs in `verify` for the whole reactor from one root configuration.
- JaCoCo generates module reports and one aggregate report module.
- Maven deploy is skipped by default outside the runtime application modules.

## 11. What stays as a documented design rule

- Explicit mapping between domain models and runtime-local transport/persistence models.
- Testcontainers for future in-process integration tests that touch PostgreSQL or other external technologies.
- Lombok carrier-model conventions if the repository later decides that plain Java has become too verbose.
- Jib as the default image-build path once containerized Spring vs Quarkus comparison becomes part of the build.
