package com.example.documentgenerator.domain.validation;

import com.example.documentgenerator.domain.model.DocumentFormat;
import com.example.documentgenerator.domain.model.GenerationRequest;
import com.example.documentgenerator.domain.model.TemplateType;
import org.junit.jupiter.api.Test;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class TemplateParameterValidatorTest {
    private final TemplateParameterValidator validator =
            new TemplateParameterValidator(TemplateCatalog.defaultCatalog());

    @Test
    void acceptsRequestThatMatchesTemplateRules() {
        var request = new GenerationRequest(
                DocumentFormat.TXT,
                TemplateType.INVOICE,
                "invoice-001",
                Map.of(
                        "customerName", "Acme",
                        "invoiceNumber", "INV-001",
                        "amount", "1200"
                )
        );

        assertDoesNotThrow(() -> validator.validate(request));
    }

    @Test
    void rejectsRequestWhenRequiredParameterIsMissing() {
        var request = new GenerationRequest(
                DocumentFormat.TXT,
                TemplateType.INVOICE,
                "invoice-001",
                Map.of(
                        "customerName", "Acme",
                        "amount", "1200"
                )
        );

        var exception = assertThrows(GenerationRequestValidationException.class, () -> validator.validate(request));
        assertEquals(1, exception.errors().size());
        assertEquals("Missing required parameters: invoiceNumber", exception.errors().getFirst());
    }

    @Test
    void rejectsRequestWhenUnexpectedParameterIsProvided() {
        var request = new GenerationRequest(
                DocumentFormat.TXT,
                TemplateType.EMPLOYMENT_CERTIFICATE,
                "certificate-001",
                Map.of(
                        "employeeName", "Jane Doe",
                        "startDate", "2025-01-10",
                        "unsupported", "value"
                )
        );

        var exception = assertThrows(GenerationRequestValidationException.class, () -> validator.validate(request));
        assertEquals(1, exception.errors().size());
        assertEquals("Unexpected parameters: unsupported", exception.errors().getFirst());
    }
}
