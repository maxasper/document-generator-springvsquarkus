package com.example.documentgenerator.spring.repository.jdbc;

import com.example.documentgenerator.application.port.out.GenerationRequestRepository;
import com.example.documentgenerator.domain.model.DocumentFormat;
import com.example.documentgenerator.domain.model.GenerationHistoryEntry;
import com.example.documentgenerator.domain.model.GenerationRequest;
import com.example.documentgenerator.domain.model.TemplateType;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;

import javax.sql.DataSource;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public final class JdbcGenerationRequestRepository implements GenerationRequestRepository {
    private static final TypeReference<LinkedHashMap<String, String>> PARAMETERS_TYPE = new TypeReference<>() {
    };

    private final JdbcTemplate jdbcTemplate;
    private final ObjectMapper objectMapper;

    public JdbcGenerationRequestRepository(DataSource dataSource, ObjectMapper objectMapper) {
        this.jdbcTemplate = new JdbcTemplate(dataSource);
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

        jdbcTemplate.update("""
                        INSERT INTO document_generation_requests (
                            id,
                            document_format,
                            template_type,
                            document_name,
                            parameters,
                            created_at
                        ) VALUES (?, ?, ?, ?, CAST(? AS JSONB), ?)
                        """,
                entry.id(),
                entry.documentFormat().name(),
                entry.templateType().name(),
                entry.documentName(),
                writeParameters(entry.parameters()),
                OffsetDateTime.ofInstant(entry.createdAt(), java.time.ZoneOffset.UTC)
        );

        return entry;
    }

    @Override
    public List<GenerationHistoryEntry> findAllOrderByCreatedAtDesc() {
        return jdbcTemplate.query("""
                        SELECT
                            id,
                            document_format,
                            template_type,
                            document_name,
                            parameters::text AS parameters,
                            created_at
                        FROM document_generation_requests
                        ORDER BY created_at DESC
                        """,
                (resultSet, rowNumber) -> mapRow(resultSet)
        );
    }

    private GenerationHistoryEntry mapRow(ResultSet resultSet) throws SQLException {
        return new GenerationHistoryEntry(
                resultSet.getObject("id", UUID.class),
                DocumentFormat.valueOf(resultSet.getString("document_format")),
                TemplateType.valueOf(resultSet.getString("template_type")),
                resultSet.getString("document_name"),
                readParameters(resultSet.getString("parameters")),
                resultSet.getObject("created_at", OffsetDateTime.class).toInstant()
        );
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
