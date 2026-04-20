package com.example.documentgenerator.adapter.renderer.stub;

import com.example.documentgenerator.application.command.GenerateDocumentCommand;
import com.example.documentgenerator.application.port.out.GenerationRequestRepository;
import com.example.documentgenerator.application.service.DocumentGenerationService;
import com.example.documentgenerator.domain.model.DocumentFormat;
import com.example.documentgenerator.domain.model.GenerationHistoryEntry;
import com.example.documentgenerator.domain.model.GenerationRequest;
import com.example.documentgenerator.domain.model.TemplateType;
import com.example.documentgenerator.domain.validation.GenerationRequestValidationException;
import com.example.documentgenerator.domain.validation.TemplateCatalog;
import com.example.documentgenerator.domain.validation.TemplateParameterValidator;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class DocumentGenerationServiceTest {
    @Test
    void generatesDocumentAndStoresHistory() {
        var repository = new FakeGenerationRequestRepository();
        var service = new DocumentGenerationService(
                new TemplateParameterValidator(TemplateCatalog.defaultCatalog()),
                repository,
                new StubDocumentRenderer()
        );

        var generatedDocument = service.generate(new GenerateDocumentCommand(
                DocumentFormat.TXT,
                TemplateType.INVOICE,
                "invoice-42",
                Map.of(
                        "customerName", "Acme",
                        "invoiceNumber", "INV-42",
                        "amount", "4500"
                )
        ));

        assertEquals("invoice-42.txt", generatedDocument.fileName());
        assertEquals(1, service.getHistory().size());
        assertTrue(new String(generatedDocument.content(), StandardCharsets.UTF_8).contains("INV-42"));
    }

    @Test
    void rejectsInvalidRequestBeforeSavingHistory() {
        var repository = new FakeGenerationRequestRepository();
        var service = new DocumentGenerationService(
                new TemplateParameterValidator(TemplateCatalog.defaultCatalog()),
                repository,
                new StubDocumentRenderer()
        );

        assertThrows(GenerationRequestValidationException.class, () -> service.generate(new GenerateDocumentCommand(
                DocumentFormat.PDF,
                TemplateType.EMPLOYMENT_CERTIFICATE,
                "certificate-1",
                Map.of("employeeName", "Jane Doe")
        )));
        assertTrue(repository.findAllOrderByCreatedAtDesc().isEmpty());
    }

    private static final class FakeGenerationRequestRepository implements GenerationRequestRepository {
        private final List<GenerationHistoryEntry> entries = new ArrayList<>();

        @Override
        public GenerationHistoryEntry save(GenerationRequest request) {
            var entry = new GenerationHistoryEntry(
                    UUID.randomUUID(),
                    request.documentFormat(),
                    request.templateType(),
                    request.documentName(),
                    request.parameters(),
                    Instant.parse("2026-04-19T00:00:00Z").plusSeconds(entries.size())
            );
            entries.addFirst(entry);
            return entry;
        }

        @Override
        public List<GenerationHistoryEntry> findAllOrderByCreatedAtDesc() {
            return List.copyOf(entries);
        }
    }
}
