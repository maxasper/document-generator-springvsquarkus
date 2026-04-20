package com.example.documentgenerator.domain.model;

import java.util.LinkedHashSet;
import java.util.Set;

public record TemplateDefinition(
        TemplateType templateType,
        Set<String> requiredParameters,
        Set<String> optionalParameters
) {
    public TemplateDefinition {
        requiredParameters = Set.copyOf(new LinkedHashSet<>(requiredParameters));
        optionalParameters = Set.copyOf(new LinkedHashSet<>(optionalParameters));
    }

    public Set<String> allowedParameters() {
        var allowedParameters = new LinkedHashSet<String>();
        allowedParameters.addAll(requiredParameters);
        allowedParameters.addAll(optionalParameters);
        return Set.copyOf(allowedParameters);
    }
}
