package com.example.documentgenerator.quarkus.repository.jdbc;

import com.example.documentgenerator.application.port.out.GenerationRequestRepository;
import com.example.documentgenerator.domain.model.DocumentFormat;
import com.example.documentgenerator.domain.model.GenerationHistoryEntry;
import com.example.documentgenerator.domain.model.GenerationRequest;
import com.example.documentgenerator.domain.model.TemplateType;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

import javax.sql.DataSource;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public final class JdbcGenerationRequestRepository implements GenerationRequestRepository {
    private static final TypeReference<LinkedHashMap<String, String>> PARAMETERS_TYPE = new TypeReference<>() {
    };

    private final DataSource dataSource;
    private final ObjectMapper objectMapper;

    public JdbcGenerationRequestRepository(DataSource dataSource, ObjectMapper objectMapper) {
        this.dataSource = dataSource;
        this.objectMapper = objectMapper;
    }

    @Override
    public GenerationHistoryEntry save(GenerationRequest request) {
        var entry = new GenerationHistoryEntry(
                UUID.randomUUID(),
                request.documentFormat(),
                request.templateType(),
                request.documentName(),
                request.parameters(),
                Instant.now()
        );

        try (var connection = dataSource.getConnection();
             var statement = connection.prepareStatement("""
                     INSERT INTO document_generation_requests (
                         id,
                         document_format,
                         template_type,
                         document_name,
                         parameters,
                         created_at
                     ) VALUES (?, ?, ?, ?, CAST(? AS JSONB), ?)
                     """)) {
            statement.setObject(1, entry.id());
            statement.setString(2, entry.documentFormat().name());
            statement.setString(3, entry.templateType().name());
            statement.setString(4, entry.documentName());
            statement.setString(5, writeParameters(entry.parameters()));
            statement.setObject(6, OffsetDateTime.ofInstant(entry.createdAt(), ZoneOffset.UTC));
            statement.executeUpdate();
            return entry;
        } catch (SQLException exception) {
            throw new IllegalStateException("Failed to save generation request", exception);
        }
    }

    @Override
    public List<GenerationHistoryEntry> findAllOrderByCreatedAtDesc() {
        try (var connection = dataSource.getConnection();
             var statement = connection.prepareStatement("""
                     SELECT
                         id,
                         document_format,
                         template_type,
                         document_name,
                         parameters::text AS parameters,
                         created_at
                     FROM document_generation_requests
                     ORDER BY created_at DESC
                     """);
             var resultSet = statement.executeQuery()) {
            var entries = new java.util.ArrayList<GenerationHistoryEntry>();
            while (resultSet.next()) {
                entries.add(new GenerationHistoryEntry(
                        resultSet.getObject("id", UUID.class),
                        DocumentFormat.valueOf(resultSet.getString("document_format")),
                        TemplateType.valueOf(resultSet.getString("template_type")),
                        resultSet.getString("document_name"),
                        readParameters(resultSet.getString("parameters")),
                        resultSet.getObject("created_at", OffsetDateTime.class).toInstant()
                ));
            }
            return List.copyOf(entries);
        } catch (SQLException exception) {
            throw new IllegalStateException("Failed to fetch generation history", exception);
        }
    }

    private String writeParameters(Map<String, String> parameters) {
        try {
            return objectMapper.writeValueAsString(parameters);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Failed to serialize generation parameters", exception);
        }
    }

    private Map<String, String> readParameters(String parametersJson) {
        try {
            return objectMapper.readValue(parametersJson, PARAMETERS_TYPE);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Failed to deserialize generation parameters", exception);
        }
    }
}
