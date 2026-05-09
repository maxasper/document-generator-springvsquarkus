# generation-history Specification

## Purpose
Define the shared HTTP history contract, response contents, and ordering rules for persisted document generation requests.
## Requirements
### Requirement: Generation history endpoint
The system SHALL expose a REST endpoint at `GET /api/v1/document-generations` that returns saved generation request history.

#### Scenario: History endpoint returns saved requests
- **WHEN** a client calls `GET /api/v1/document-generations`
- **THEN** the system returns the saved generation requests as a JSON collection

### Requirement: History entry contents
The system SHALL return each history entry with the persisted request metadata, including `documentFormat`, `templateType`, `documentName`, `parameters`, and creation timestamp.

#### Scenario: History shows request details without file content
- **WHEN** the system returns generation history
- **THEN** each entry includes the saved request metadata and excludes generated file bytes

### Requirement: History ordering
The system SHALL return generation history ordered from newest request to oldest request.

#### Scenario: Newest request appears first
- **WHEN** multiple generation requests have been saved
- **THEN** the most recently saved request appears before older requests in the history response
