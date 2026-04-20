package com.example.documentgenerator.application.port.in;

import com.example.documentgenerator.application.command.GenerateDocumentCommand;
import com.example.documentgenerator.domain.model.GeneratedDocument;

public interface GenerateDocumentUseCase {
    GeneratedDocument generate(GenerateDocumentCommand command);
}
