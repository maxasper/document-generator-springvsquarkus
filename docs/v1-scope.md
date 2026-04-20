# V1 Scope

## Objective

Deliver a small but complete service slice that proves the shared-core plus dual-runtime architecture:

- accept a document generation request
- validate request parameters based on template rules
- persist request history
- return a generated file
- expose history through a REST endpoint

## In Scope

- synchronous generation flow
- one generation endpoint and one history endpoint
- persistence of request metadata and parameter map
- a small code-defined catalog of template types and document formats
- stubbed document generation output
- design ready for PostgreSQL-backed history storage

## Out of Scope

- real document templating engines
- storing generated file bytes in the database
- authentication and authorization
- asynchronous jobs or queue-based generation
- update or delete history operations
- advanced filtering, pagination, or search
- native image tuning and performance benchmarking

## Main Domain Concepts

- `GenerationRequest`: the incoming command containing format, template type, name, and parameters
- `TemplateType`: a code-defined document template identifier with parameter rules
- `DocumentFormat`: the requested output format
- `GeneratedDocument`: the returned file payload plus metadata such as filename and content type
- `GenerationHistoryEntry`: the stored record of a generation request

## Main Use Cases

- `GenerateDocument`: validate the request, persist the request metadata, invoke document rendering, and return the generated file
- `ListGenerationHistory`: return saved requests ordered from newest to oldest

## Working Assumptions

- `parameters` is a flat map for v1; nested structures are deferred
- initial parameter validation checks required and unexpected keys by template type
- the first implementation may support only a minimal initial format set if that keeps the rendering stub simple
- history can start without pagination while the data volume is small
