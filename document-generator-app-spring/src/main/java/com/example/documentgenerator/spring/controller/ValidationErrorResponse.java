package com.example.documentgenerator.spring.controller;

import java.util.List;

public record ValidationErrorResponse(List<String> errors) {
}
