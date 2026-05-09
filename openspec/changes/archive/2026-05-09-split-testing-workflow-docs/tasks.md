## 1. Create Dedicated Workflow Guides

- [x] 1.1 Create `docs/testing/runtime-verification.md` with the complete Spring Boot and Quarkus `in-memory` and PostgreSQL-backed verification workflows
- [x] 1.2 Create `docs/testing/jvm-runtime-comparison.md` with the complete JVM comparison workflow, artifact locations, and interpretation limits
- [x] 1.3 Create `docs/testing/native-image-comparison.md` with the complete native comparison workflow and explicit native-specific assumptions
- [x] 1.4 Create `docs/testing/manual-runtime-inspection.md` with the Compose startup, JMX, resource-limit, and repository-local load-testing workflow

## 2. Restructure Existing Entry Docs

- [x] 2.1 Reduce `README.md` to short workflow summaries plus links to the dedicated guides under `docs/testing/`
- [x] 2.2 Trim `docs/runtime-comparison-plan.md` so it keeps comparison framing and reporting notes without duplicating the new runbook steps
- [x] 2.3 Remove `docs/runtime-inspection-ru.md` after its useful operator guidance has been migrated into the canonical workflow guides

## 3. Align Workflow-Specific Guidance

- [x] 3.1 Ensure the runtime verification guide clearly separates `in-memory` and PostgreSQL-backed flows for both runtimes
- [x] 3.2 Ensure the manual JVM inspection guide clearly states that it starts PostgreSQL plus one selected runtime rather than both application runtimes together
- [x] 3.3 Ensure the native comparison guide explicitly distinguishes native benchmark assumptions from the manual JVM inspection `DG_RUNTIME_*` limit controls

## 4. Validate Documentation Consistency

- [x] 4.1 Verify that every documented command, URL, artifact path, and environment variable matches the current scripts and Compose files
- [x] 4.2 Verify that `README.md` links to all dedicated workflow guides and no longer carries stale duplicated operator procedures
