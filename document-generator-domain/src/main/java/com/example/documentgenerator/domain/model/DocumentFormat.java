package com.example.documentgenerator.domain.model;

public enum DocumentFormat {
    TXT("txt", "text/plain"),
    PDF("pdf", "application/pdf");

    private final String extension;
    private final String contentType;

    DocumentFormat(String extension, String contentType) {
        this.extension = extension;
        this.contentType = contentType;
    }

    public String extension() {
        return extension;
    }

    public String contentType() {
        return contentType;
    }
}
