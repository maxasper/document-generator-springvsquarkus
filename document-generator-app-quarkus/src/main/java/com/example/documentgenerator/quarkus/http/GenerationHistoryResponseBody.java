package com.example.documentgenerator.quarkus.http;

import com.example.documentgenerator.domain.model.DocumentFormat;
import com.example.documentgenerator.domain.model.GenerationHistoryEntry;
import com.example.documentgenerator.domain.model.TemplateType;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;

public record GenerationHistoryResponseBody(
        UUID id,
        DocumentFormat documentFormat,
        TemplateType templateType,
        String documentName,
        Map<String, String> parameters,
        Instant createdAt
) {
    public static GenerationHistoryResponseBody from(GenerationHistoryEntry entry) {
        return new GenerationHistoryResponseBody(
                entry.id(),
                entry.documentFormat(),
                entry.templateType(),
                entry.documentName(),
                entry.parameters(),
                entry.createdAt()
        );
    }
}
