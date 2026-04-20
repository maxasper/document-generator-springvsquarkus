package com.example.documentgenerator.domain.validation;

import com.example.documentgenerator.domain.model.TemplateDefinition;
import com.example.documentgenerator.domain.model.TemplateType;

import java.util.Map;
import java.util.Objects;

public final class TemplateCatalog {
    private final Map<TemplateType, TemplateDefinition> definitions;

    public TemplateCatalog(Map<TemplateType, TemplateDefinition> definitions) {
        this.definitions = Map.copyOf(definitions);
    }

    public static TemplateCatalog defaultCatalog() {
        return new TemplateCatalog(Map.of(
                TemplateType.INVOICE,
                new TemplateDefinition(
                        TemplateType.INVOICE,
                        java.util.Set.of("customerName", "invoiceNumber", "amount"),
                        java.util.Set.of("dueDate")
                ),
                TemplateType.EMPLOYMENT_CERTIFICATE,
                new TemplateDefinition(
                        TemplateType.EMPLOYMENT_CERTIFICATE,
                        java.util.Set.of("employeeName", "startDate"),
                        java.util.Set.of("role", "department")
                )
        ));
    }

    public TemplateDefinition definitionFor(TemplateType templateType) {
        Objects.requireNonNull(templateType, "templateType must not be null");
        var definition = definitions.get(templateType);
        if (definition == null) {
            throw new IllegalArgumentException("Unsupported template type: " + templateType);
        }
        return definition;
    }
}
