package com.example.documentgenerator.application.port.out;

import com.example.documentgenerator.domain.model.GenerationHistoryEntry;
import com.example.documentgenerator.domain.model.GenerationRequest;

import java.util.List;

public interface GenerationRequestRepository {
    GenerationHistoryEntry save(GenerationRequest request);

    List<GenerationHistoryEntry> findAllOrderByCreatedAtDesc();
}
