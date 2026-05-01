package com.example.documentgenerator.quarkus.http;

import io.quarkus.runtime.annotations.RegisterForReflection;

import java.util.List;

@RegisterForReflection
public record ValidationErrorResponse(List<String> errors) {
}
