package com.example.documentgenerator.application.port.out;

import com.example.documentgenerator.domain.model.GeneratedDocument;
import com.example.documentgenerator.domain.model.GenerationRequest;

public interface DocumentRenderer {
    GeneratedDocument render(GenerationRequest request);
}
