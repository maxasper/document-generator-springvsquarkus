package com.example.documentgenerator.quarkus.http;

import com.example.documentgenerator.domain.validation.GenerationRequestValidationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;

@Provider
public class GenerationRequestValidationExceptionMapper implements ExceptionMapper<GenerationRequestValidationException> {
    @Override
    public Response toResponse(GenerationRequestValidationException exception) {
        return Response.status(Response.Status.BAD_REQUEST)
                .type(MediaType.APPLICATION_JSON)
                .entity(new ValidationErrorResponse(exception.errors()))
                .build();
    }
}
