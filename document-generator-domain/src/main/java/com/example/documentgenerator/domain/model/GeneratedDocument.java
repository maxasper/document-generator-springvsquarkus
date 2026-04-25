package com.example.documentgenerator.domain.model;

import java.util.Arrays;

public record GeneratedDocument(
        String fileName,
        String contentType,
        byte[] content
) {
    public GeneratedDocument {
        requireArgument(fileName, "fileName must not be null");
        requireArgument(contentType, "contentType must not be null");
        requireArgument(content, "content must not be null");

        if (fileName.isBlank()) {
            throw new IllegalArgumentException("fileName must not be blank");
        }

        if (contentType.isBlank()) {
            throw new IllegalArgumentException("contentType must not be blank");
        }

        content = Arrays.copyOf(content, content.length);
    }

    @Override
    public byte[] content() {
        return Arrays.copyOf(content, content.length);
    }

    private static void requireArgument(Object value, String message) {
        if (value == null) {
            throw new IllegalArgumentException(message);
        }
    }
}
