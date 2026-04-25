package com.example.documentgenerator.adapter.renderer.stub;

import com.example.documentgenerator.application.port.out.DocumentRenderer;
import com.example.documentgenerator.domain.model.GeneratedDocument;
import com.example.documentgenerator.domain.model.GenerationRequest;

import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.TreeMap;

public final class StubDocumentRenderer implements DocumentRenderer {
    @Override
    public GeneratedDocument render(GenerationRequest request) {
        return new GeneratedDocument(
                fileNameFor(request),
                request.documentFormat().contentType(),
                contentFor(request)
        );
    }

    private static String fileNameFor(GenerationRequest request) {
        var expectedSuffix = "." + request.documentFormat().extension();
        if (request.documentName().endsWith(expectedSuffix)) {
            return request.documentName();
        }
        return request.documentName() + expectedSuffix;
    }

    private static byte[] contentFor(GenerationRequest request) {
        return switch (request.documentFormat()) {
            case TXT -> textPayload(request).getBytes(StandardCharsets.UTF_8);
            case PDF -> pdfPayload(request).getBytes(StandardCharsets.UTF_8);
        };
    }

    private static String textPayload(GenerationRequest request) {
        return "stub-document%nformat=%s%ntemplate=%s%nname=%s%nparameters=%s%n".formatted(
                request.documentFormat(),
                request.templateType(),
                request.documentName(),
                sortedParameters(request.parameters())
        );
    }

    private static String pdfPayload(GenerationRequest request) {
        return """
                %%PDF-1.4
                %% Stub PDF document
                1 0 obj
                << /Type /Catalog >>
                endobj
                %% content=%s
                """.formatted(sortedParameters(request.parameters()));
    }

    private static Map<String, String> sortedParameters(Map<String, String> parameters) {
        return new TreeMap<>(parameters);
    }
}
