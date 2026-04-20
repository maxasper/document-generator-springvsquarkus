package com.example.documentgenerator.quarkus.config;

import com.example.documentgenerator.adapter.renderer.stub.StubDocumentRenderer;
import com.example.documentgenerator.application.port.out.DocumentRenderer;
import com.example.documentgenerator.application.port.out.GenerationRequestRepository;
import com.example.documentgenerator.application.service.DocumentGenerationService;
import com.example.documentgenerator.domain.validation.TemplateCatalog;
import com.example.documentgenerator.domain.validation.TemplateParameterValidator;
import com.example.documentgenerator.quarkus.repository.InMemoryGenerationRequestRepository;
import com.example.documentgenerator.quarkus.repository.jdbc.JdbcGenerationRequestRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Instance;
import jakarta.enterprise.inject.Produces;
import jakarta.inject.Singleton;
import org.eclipse.microprofile.config.inject.ConfigProperty;

import javax.sql.DataSource;

@ApplicationScoped
public class DocumentGeneratorProducer {
    @Produces
    @Singleton
    TemplateParameterValidator templateParameterValidator() {
        return new TemplateParameterValidator(TemplateCatalog.defaultCatalog());
    }

    @Produces
    @Singleton
    DocumentRenderer documentRenderer() {
        return new StubDocumentRenderer();
    }

    @Produces
    @Singleton
    GenerationRequestRepository generationRequestRepository(
            @ConfigProperty(name = "document-generator.persistence.mode", defaultValue = "in-memory") String persistenceMode,
            Instance<DataSource> dataSourceInstance,
            ObjectMapper objectMapper
    ) {
        return switch (persistenceMode) {
            case "in-memory" -> new InMemoryGenerationRequestRepository();
            case "jdbc" -> new JdbcGenerationRequestRepository(requireDataSource(dataSourceInstance), objectMapper);
            default -> throw new IllegalArgumentException(
                    "Unsupported document-generator.persistence-mode: " + persistenceMode
            );
        };
    }

    @Produces
    @Singleton
    DocumentGenerationService documentGenerationService(
            TemplateParameterValidator templateParameterValidator,
            GenerationRequestRepository generationRequestRepository,
            DocumentRenderer documentRenderer
    ) {
        return new DocumentGenerationService(
                templateParameterValidator,
                generationRequestRepository,
                documentRenderer
        );
    }

    private static DataSource requireDataSource(Instance<DataSource> dataSourceInstance) {
        if (dataSourceInstance.isUnsatisfied()) {
            throw new IllegalStateException("document-generator.persistence-mode=jdbc requires a configured DataSource");
        }
        return dataSourceInstance.get();
    }
}
