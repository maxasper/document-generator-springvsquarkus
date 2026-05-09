## ADDED Requirements

### Requirement: Document generation request endpoint
The system SHALL expose a synchronous REST endpoint at `POST /api/v1/document-generations` that accepts a JSON request containing `documentFormat`, `templateType`, `documentName`, and `parameters`.

#### Scenario: Valid generation request is accepted
- **WHEN** a client submits a well-formed document generation request to `POST /api/v1/document-generations`
- **THEN** the system starts the document generation flow using the submitted format, template type, name, and parameters

### Requirement: Template-specific parameter validation
The system SHALL validate request parameters against rules defined for the selected `templateType` before document generation succeeds.

#### Scenario: Missing required parameter rejects the request
- **WHEN** a client omits a required parameter for the selected `templateType`
- **THEN** the system rejects the request with a client-error response describing the validation failure

### Requirement: Request persistence during generation
The system SHALL persist the generation request metadata and parameter map as part of the generation flow.

#### Scenario: Successful request is written to history
- **WHEN** a generation request passes validation and document generation completes successfully
- **THEN** the request is saved in persistent generation history with its format, template type, document name, and parameters

### Requirement: Generated file response
The system SHALL return the generated document as the response body for a successful generation request.

#### Scenario: Successful generation returns a downloadable file
- **WHEN** document generation succeeds
- **THEN** the response contains file content and metadata that allows the client to download the generated document using the requested document name
