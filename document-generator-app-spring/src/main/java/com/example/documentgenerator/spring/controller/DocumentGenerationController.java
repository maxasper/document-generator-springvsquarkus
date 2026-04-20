package com.example.documentgenerator.spring.controller;

import com.example.documentgenerator.application.port.in.GenerateDocumentUseCase;
import com.example.documentgenerator.application.port.in.ListGenerationHistoryUseCase;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/document-generations")
public class DocumentGenerationController {
    private final GenerateDocumentUseCase generateDocumentUseCase;
    private final ListGenerationHistoryUseCase listGenerationHistoryUseCase;

    public DocumentGenerationController(
            GenerateDocumentUseCase generateDocumentUseCase,
            ListGenerationHistoryUseCase listGenerationHistoryUseCase
    ) {
        this.generateDocumentUseCase = generateDocumentUseCase;
        this.listGenerationHistoryUseCase = listGenerationHistoryUseCase;
    }

    @PostMapping
    public ResponseEntity<byte[]> generate(@RequestBody DocumentGenerationRequestBody requestBody) {
        var generatedDocument = generateDocumentUseCase.generate(requestBody.toCommand());

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(generatedDocument.contentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(generatedDocument.fileName())
                        .build()
                        .toString())
                .body(generatedDocument.content());
    }

    @GetMapping
    public List<GenerationHistoryResponseBody> getHistory() {
        return listGenerationHistoryUseCase.getHistory().stream()
                .map(GenerationHistoryResponseBody::from)
                .toList();
    }
}
