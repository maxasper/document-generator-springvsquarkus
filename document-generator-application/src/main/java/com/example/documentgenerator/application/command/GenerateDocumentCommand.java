package com.example.documentgenerator.application.command;

import com.example.documentgenerator.domain.model.DocumentFormat;
import com.example.documentgenerator.domain.model.GenerationRequest;
import com.example.documentgenerator.domain.model.TemplateType;

import java.util.LinkedHashMap;
import java.util.Map;

public record GenerateDocumentCommand(
        DocumentFormat documentFormat,
        TemplateType templateType,
        String documentName,
        Map<String, String> parameters
) {
    public GenerateDocumentCommand {
        requireArgument(documentFormat, "documentFormat must not be null");
        requireArgument(templateType, "templateType must not be null");
        requireArgument(documentName, "documentName must not be null");
        requireArgument(parameters, "parameters must not be null");
        parameters = Map.copyOf(new LinkedHashMap<>(parameters));
    }

    public GenerationRequest toGenerationRequest() {
        return new GenerationRequest(documentFormat, templateType, documentName, parameters);
    }

    private static void requireArgument(Object value, String message) {
        if (value == null) {
            throw new IllegalArgumentException(message);
        }
    }
}
