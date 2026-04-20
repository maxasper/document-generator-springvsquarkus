package com.example.documentgenerator.domain.validation;

import com.example.documentgenerator.domain.model.GenerationRequest;

import java.util.ArrayList;
import java.util.TreeSet;

public final class TemplateParameterValidator {
    private final TemplateCatalog templateCatalog;

    public TemplateParameterValidator(TemplateCatalog templateCatalog) {
        this.templateCatalog = templateCatalog;
    }

    public void validate(GenerationRequest request) {
        var definition = templateCatalog.definitionFor(request.templateType());
        var providedParameters = new TreeSet<>(request.parameters().keySet());
        var missingParameters = new TreeSet<>(definition.requiredParameters());
        missingParameters.removeAll(providedParameters);

        var unexpectedParameters = new TreeSet<>(providedParameters);
        unexpectedParameters.removeAll(definition.allowedParameters());

        var errors = new ArrayList<String>();
        if (!missingParameters.isEmpty()) {
            errors.add("Missing required parameters: " + String.join(", ", missingParameters));
        }
        if (!unexpectedParameters.isEmpty()) {
            errors.add("Unexpected parameters: " + String.join(", ", unexpectedParameters));
        }

        if (!errors.isEmpty()) {
            throw new GenerationRequestValidationException(errors);
        }
    }
}
