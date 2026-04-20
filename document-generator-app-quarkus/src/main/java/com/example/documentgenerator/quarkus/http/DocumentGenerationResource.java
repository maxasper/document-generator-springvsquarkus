package com.example.documentgenerator.quarkus.http;

import com.example.documentgenerator.application.port.in.GenerateDocumentUseCase;
import com.example.documentgenerator.application.port.in.ListGenerationHistoryUseCase;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/api/v1/document-generations")
@Consumes(MediaType.APPLICATION_JSON)
public class DocumentGenerationResource {
    private final GenerateDocumentUseCase generateDocumentUseCase;
    private final ListGenerationHistoryUseCase listGenerationHistoryUseCase;

    @Inject
    public DocumentGenerationResource(
            GenerateDocumentUseCase generateDocumentUseCase,
            ListGenerationHistoryUseCase listGenerationHistoryUseCase
    ) {
        this.generateDocumentUseCase = generateDocumentUseCase;
        this.listGenerationHistoryUseCase = listGenerationHistoryUseCase;
    }

    @POST
    public Response generate(DocumentGenerationRequestBody requestBody) {
        var generatedDocument = generateDocumentUseCase.generate(requestBody.toCommand());
        return Response.ok(generatedDocument.content())
                .type(generatedDocument.contentType())
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + generatedDocument.fileName() + "\"")
                .build();
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<GenerationHistoryResponseBody> getHistory() {
        return listGenerationHistoryUseCase.getHistory().stream()
                .map(GenerationHistoryResponseBody::from)
                .toList();
    }
}
