package com.example.documentgenerator.spring;

import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.flyway.FlywayAutoConfiguration;
import org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration;
import org.springframework.boot.SpringApplication;

@SpringBootApplication(exclude = {
        DataSourceAutoConfiguration.class,
        FlywayAutoConfiguration.class
})
public class DocumentGeneratorSpringApplication {
    public static void main(String[] args) {
        SpringApplication.run(DocumentGeneratorSpringApplication.class, args);
    }
}
