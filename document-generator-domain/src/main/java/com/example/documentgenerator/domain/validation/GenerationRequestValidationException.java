package com.example.documentgenerator.domain.validation;

import java.util.List;

public final class GenerationRequestValidationException extends RuntimeException {
    private final List<String> errors;

    public GenerationRequestValidationException(List<String> errors) {
        super(String.join("; ", errors));
        this.errors = List.copyOf(errors);
    }

    public List<String> errors() {
        return errors;
    }
}
