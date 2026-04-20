package com.example.documentgenerator.contract;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

class DocumentGenerationRuntimeContractTest {
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(10);

    private final HttpClient httpClient = HttpClient.newHttpClient();
    private String baseUrl;

    @BeforeEach
    void setUp() {
        baseUrl = System.getProperty("document.generator.base-url");
        assumeTrue(baseUrl != null && !baseUrl.isBlank(),
                "Set -Ddocument.generator.base-url to run runtime contract tests");
    }

    @Test
    void generateEndpointReturnsDownloadableFile() throws IOException, InterruptedException {
        var documentName = "contract-" + UUID.randomUUID();
        var response = postGeneration(documentName, "INV-" + UUID.randomUUID(), "customerName", "Acme");

        assertEquals(200, response.statusCode());
        assertEquals("text/plain", response.headers().firstValue("content-type").orElseThrow());
        assertTrue(response.headers().firstValue("content-disposition").orElseThrow().contains(documentName + ".txt"));
        assertTrue(response.body().contains("stub-document"));
    }

    @Test
    void generateEndpointRejectsInvalidTemplateParameters() throws IOException, InterruptedException {
        var requestBody = """
                {
                  "documentFormat": "TXT",
                  "templateType": "INVOICE",
                  "documentName": "invalid-request",
                  "parameters": {
                    "customerName": "Acme",
                    "amount": "10"
                  }
                }
                """;

        var response = httpClient.send(buildPostRequest(requestBody), HttpResponse.BodyHandlers.ofString());

        assertEquals(400, response.statusCode());
        assertTrue(response.body().contains("Missing required parameters"));
        assertTrue(response.body().contains("invoiceNumber"));
    }

    @Test
    void historyEndpointReturnsNewestRequestFirst() throws IOException, InterruptedException {
        var firstName = "history-first-" + UUID.randomUUID();
        var secondName = "history-second-" + UUID.randomUUID();

        postGeneration(firstName, "INV-001-" + UUID.randomUUID(), "customerName", "First");
        postGeneration(secondName, "INV-002-" + UUID.randomUUID(), "customerName", "Second");

        var historyResponse = httpClient.send(
                HttpRequest.newBuilder(URI.create(baseUrl + "/api/v1/document-generations"))
                        .timeout(REQUEST_TIMEOUT)
                        .GET()
                        .build(),
                HttpResponse.BodyHandlers.ofString()
        );

        assertEquals(200, historyResponse.statusCode());

        var body = historyResponse.body();
        assertTrue(body.contains(firstName));
        assertTrue(body.contains(secondName));
        assertTrue(body.indexOf(secondName) < body.indexOf(firstName),
                "Expected the newest history item to appear before the older one");
    }

    private HttpResponse<String> postGeneration(
            String documentName,
            String invoiceNumber,
            String customerNameKey,
            String customerNameValue
    ) throws IOException, InterruptedException {
        var requestBody = """
                {
                  "documentFormat": "TXT",
                  "templateType": "INVOICE",
                  "documentName": "%s",
                  "parameters": {
                    "%s": "%s",
                    "invoiceNumber": "%s",
                    "amount": "10"
                  }
                }
                """.formatted(documentName, customerNameKey, customerNameValue, invoiceNumber);

        return httpClient.send(buildPostRequest(requestBody), HttpResponse.BodyHandlers.ofString());
    }

    private HttpRequest buildPostRequest(String requestBody) {
        return HttpRequest.newBuilder(URI.create(baseUrl + "/api/v1/document-generations"))
                .timeout(REQUEST_TIMEOUT)
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(requestBody))
                .build();
    }
}
