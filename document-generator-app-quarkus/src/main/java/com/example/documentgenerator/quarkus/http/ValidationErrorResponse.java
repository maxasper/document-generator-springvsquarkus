package com.example.documentgenerator.quarkus.http;

import java.util.List;

public record ValidationErrorResponse(List<String> errors) {
}
