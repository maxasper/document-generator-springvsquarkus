package com.example.documentgenerator.spring;

import com.example.documentgenerator.spring.config.DocumentGeneratorRuntimeHints;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.context.annotation.ImportRuntimeHints;

@SpringBootApplication(exclude = {
        DataSourceAutoConfiguration.class,
        FlywayAutoConfiguration.class
})
@ImportRuntimeHints(DocumentGeneratorRuntimeHints.class)
public class DocumentGeneratorSpringApplication {
    public static void main(String[] args) {
        SpringApplication.run(DocumentGeneratorSpringApplication.class, args);
    }
}
