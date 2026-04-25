package com.example.documentgenerator.spring.controller;

import com.example.documentgenerator.domain.validation.GenerationRequestValidationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

    @RestControllerAdvice
public class DocumentGenerationExceptionHandler {
    @ExceptionHandler(GenerationRequestValidationException.class)
    public ResponseEntity<ValidationErrorResponse> handleValidationError(
            GenerationRequestValidationException exception
    ) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ValidationErrorResponse(exception.errors()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<ValidationErrorResponse> handleIllegalArgument(IllegalArgumentException exception) {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(new ValidationErrorResponse(java.util.List.of(exception.getMessage())));
    }
}
