## Why

The repository needs a concrete foundation before implementation starts, otherwise Spring Boot and Quarkus work will drift into separate designs and the comparison will stop being meaningful. Defining the service contract, module boundaries, and incremental roadmap now keeps the shared core explicit and makes later implementation slices smaller and safer.

## What Changes

- define the initial v1 service scope for document generation and request history
- define the architectural obligations for a shared pure-Java core with separate Spring Boot and Quarkus runtime modules
- capture practical assumptions, risks, and deferred decisions needed to start implementation incrementally
- prepare repository documentation for a spec-first workflow

## Capabilities

### New Capabilities
- `document-generation`: generate a document from a validated request and return the generated file
- `generation-history`: store generation requests and expose saved request history
- `shared-service-architecture`: require one reusable business core and two separate runtime applications around it

### Modified Capabilities
- None.

## Impact

- adds project-level documentation in `README.md` and `docs/`
- introduces the first OpenSpec change with proposal, specs, design, and tasks
- sets the contract for future Maven modules, REST endpoints, persistence adapters, and shared-core boundaries
