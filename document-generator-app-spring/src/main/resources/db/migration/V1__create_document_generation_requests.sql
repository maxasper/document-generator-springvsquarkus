CREATE TABLE document_generation_requests (
    id UUID PRIMARY KEY,
    document_format VARCHAR(32) NOT NULL,
    template_type VARCHAR(64) NOT NULL,
    document_name VARCHAR(255) NOT NULL,
    parameters JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX idx_document_generation_requests_created_at
    ON document_generation_requests (created_at DESC);
