package com.example.documentgenerator.spring.config;

import com.example.documentgenerator.adapter.renderer.stub.StubDocumentRenderer;
import com.example.documentgenerator.application.port.out.DocumentRenderer;
import com.example.documentgenerator.application.port.out.GenerationRequestRepository;
import com.example.documentgenerator.application.service.DocumentGenerationService;
import com.example.documentgenerator.domain.validation.TemplateCatalog;
import com.example.documentgenerator.domain.validation.TemplateParameterValidator;
import com.example.documentgenerator.spring.repository.InMemoryGenerationRequestRepository;
import com.example.documentgenerator.spring.repository.jdbc.JdbcGenerationRequestRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.flywaydb.core.Flyway;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DriverManagerDataSource;

import javax.sql.DataSource;

@Configuration
public class DocumentGeneratorConfiguration {
    @Bean
    TemplateParameterValidator templateParameterValidator() {
        return new TemplateParameterValidator(TemplateCatalog.defaultCatalog());
    }

    @Bean
    DocumentRenderer documentRenderer() {
        return new StubDocumentRenderer();
    }

    @Bean
    @ConditionalOnProperty(name = "document-generator.persistence-mode", havingValue = "jdbc")
    DataSource dataSource(
            @Value("${spring.datasource.url}") String url,
            @Value("${spring.datasource.username}") String username,
            @Value("${spring.datasource.password}") String password,
            @Value("${spring.datasource.driver-class-name:org.postgresql.Driver}") String driverClassName
    ) {
        var dataSource = new DriverManagerDataSource();
        dataSource.setDriverClassName(driverClassName);
        dataSource.setUrl(url);
        dataSource.setUsername(username);
        dataSource.setPassword(password);
        return dataSource;
    }

    @Bean(initMethod = "migrate")
    @ConditionalOnProperty(name = "document-generator.persistence-mode", havingValue = "jdbc")
    Flyway flyway(DataSource dataSource) {
        return Flyway.configure()
                .dataSource(dataSource)
                .locations("classpath:db/migration")
                .load();
    }

    @Bean
    GenerationRequestRepository generationRequestRepository(
            @Value("${document-generator.persistence-mode:in-memory}") String persistenceMode,
            ObjectProvider<DataSource> dataSourceProvider,
            ObjectMapper objectMapper
    ) {
        return switch (persistenceMode) {
            case "in-memory" -> new InMemoryGenerationRequestRepository();
            case "jdbc" -> new JdbcGenerationRequestRepository(requireDataSource(dataSourceProvider), objectMapper);
            default -> throw new IllegalArgumentException(
                    "Unsupported document-generator.persistence-mode: " + persistenceMode
            );
        };
    }

    @Bean
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

    private static DataSource requireDataSource(ObjectProvider<DataSource> dataSourceProvider) {
        var dataSource = dataSourceProvider.getIfAvailable();
        if (dataSource == null) {
            throw new IllegalStateException(
                    "document-generator.persistence-mode=jdbc requires a configured DataSource"
            );
        }
        return dataSource;
    }
}
