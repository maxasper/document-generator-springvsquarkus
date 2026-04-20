package com.example.documentgenerator.domain.model;

import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

public record GenerationHistoryEntry(
        UUID id,
        DocumentFormat documentFormat,
        TemplateType templateType,
        String documentName,
        Map<String, String> parameters,
        Instant createdAt
) {
    public GenerationHistoryEntry {
        requireArgument(id, "id must not be null");
        requireArgument(documentFormat, "documentFormat must not be null");
        requireArgument(templateType, "templateType must not be null");
        requireArgument(documentName, "documentName must not be null");
        requireArgument(parameters, "parameters must not be null");
        requireArgument(createdAt, "createdAt must not be null");

        if (documentName.isBlank()) {
            throw new IllegalArgumentException("documentName must not be blank");
        }

        parameters = Map.copyOf(new LinkedHashMap<>(parameters));
    }

    private static void requireArgument(Object value, String message) {
        if (value == null) {
            throw new IllegalArgumentException(message);
        }
    }
}
