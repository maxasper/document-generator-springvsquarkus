package com.example.documentgenerator.spring.repository;

import com.example.documentgenerator.application.port.out.GenerationRequestRepository;
import com.example.documentgenerator.domain.model.GenerationHistoryEntry;
import com.example.documentgenerator.domain.model.GenerationRequest;

import java.time.Instant;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.ConcurrentLinkedDeque;

public final class InMemoryGenerationRequestRepository implements GenerationRequestRepository {
    private final ConcurrentLinkedDeque<GenerationHistoryEntry> entries = new ConcurrentLinkedDeque<>();

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
        entries.addFirst(entry);
        return entry;
    }

    @Override
    public List<GenerationHistoryEntry> findAllOrderByCreatedAtDesc() {
        return List.copyOf(entries);
    }
}
