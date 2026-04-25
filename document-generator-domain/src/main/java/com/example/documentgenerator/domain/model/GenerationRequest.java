package com.example.documentgenerator.domain.model;

import java.util.LinkedHashMap;
import java.util.Map;

public record GenerationRequest(
        DocumentFormat documentFormat,
        TemplateType templateType,
        String documentName,
        Map<String, String> parameters
) {
    public GenerationRequest {
        requireArgument(documentFormat, "documentFormat must not be null");
        requireArgument(templateType, "templateType must not be null");
        requireArgument(documentName, "documentName must not be null");
        requireArgument(parameters, "parameters must not be null");

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
