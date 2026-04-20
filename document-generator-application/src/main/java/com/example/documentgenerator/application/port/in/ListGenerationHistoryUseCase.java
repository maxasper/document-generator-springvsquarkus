package com.example.documentgenerator.application.port.in;

import com.example.documentgenerator.domain.model.GenerationHistoryEntry;

import java.util.List;

public interface ListGenerationHistoryUseCase {
    List<GenerationHistoryEntry> getHistory();
}
