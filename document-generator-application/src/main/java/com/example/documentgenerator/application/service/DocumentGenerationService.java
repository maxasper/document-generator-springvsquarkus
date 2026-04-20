package com.example.documentgenerator.application.service;

import com.example.documentgenerator.application.command.GenerateDocumentCommand;
import com.example.documentgenerator.application.port.in.GenerateDocumentUseCase;
import com.example.documentgenerator.application.port.in.ListGenerationHistoryUseCase;
import com.example.documentgenerator.application.port.out.DocumentRenderer;
import com.example.documentgenerator.application.port.out.GenerationRequestRepository;
import com.example.documentgenerator.domain.model.GeneratedDocument;
import com.example.documentgenerator.domain.model.GenerationHistoryEntry;
import com.example.documentgenerator.domain.validation.TemplateParameterValidator;

import java.util.List;
import java.util.Objects;

public final class DocumentGenerationService implements GenerateDocumentUseCase, ListGenerationHistoryUseCase {
    private final TemplateParameterValidator templateParameterValidator;
    private final GenerationRequestRepository generationRequestRepository;
    private final DocumentRenderer documentRenderer;

    public DocumentGenerationService(
            TemplateParameterValidator templateParameterValidator,
            GenerationRequestRepository generationRequestRepository,
            DocumentRenderer documentRenderer
    ) {
        this.templateParameterValidator = Objects.requireNonNull(templateParameterValidator, "templateParameterValidator must not be null");
        this.generationRequestRepository = Objects.requireNonNull(generationRequestRepository, "generationRequestRepository must not be null");
        this.documentRenderer = Objects.requireNonNull(documentRenderer, "documentRenderer must not be null");
    }

    @Override
    public GeneratedDocument generate(GenerateDocumentCommand command) {
        var request = command.toGenerationRequest();
        templateParameterValidator.validate(request);

        var generatedDocument = documentRenderer.render(request);
        generationRequestRepository.save(request);
        return generatedDocument;
    }

    @Override
    public List<GenerationHistoryEntry> getHistory() {
        return List.copyOf(generationRequestRepository.findAllOrderByCreatedAtDesc());
    }
}
