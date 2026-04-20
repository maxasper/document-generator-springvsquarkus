package com.example.documentgenerator.spring.controller;

import com.example.documentgenerator.application.command.GenerateDocumentCommand;
import com.example.documentgenerator.domain.model.DocumentFormat;
import com.example.documentgenerator.domain.model.TemplateType;

import java.util.LinkedHashMap;
import java.util.Map;

public record DocumentGenerationRequestBody(
        DocumentFormat documentFormat,
        TemplateType templateType,
        String documentName,
        Map<String, String> parameters
) {
    public GenerateDocumentCommand toCommand() {
        return new GenerateDocumentCommand(
                documentFormat,
                templateType,
                documentName,
                parameters == null ? Map.of() : Map.copyOf(new LinkedHashMap<>(parameters))
        );
    }
}
