package com.example.documentgenerator.spring.config;

import org.flywaydb.core.api.ResourceProvider;
import org.flywaydb.core.api.resource.LoadableResource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

import java.io.IOException;
import java.io.InputStreamReader;
import java.io.Reader;
import java.io.UncheckedIOException;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

final class FlywayMigrationResourceProvider implements ResourceProvider {
    private static final String MIGRATION_PATTERN = "classpath*:db/migration/*.sql";
    private static final String RELATIVE_PREFIX = "db/migration/";

    private final List<LoadableResource> resources;

    FlywayMigrationResourceProvider(ClassLoader classLoader) {
        var resolver = new PathMatchingResourcePatternResolver(classLoader);
        try {
            resources = Arrays.stream(resolver.getResources(MIGRATION_PATTERN))
                    .map(SpringLoadableResource::new)
                    .sorted()
                    .map(LoadableResource.class::cast)
                    .toList();
        } catch (IOException exception) {
            throw new IllegalStateException("Failed to resolve Flyway SQL migration resources", exception);
        }
    }

    @Override
    public LoadableResource getResource(String name) {
        for (var resource : resources) {
            if (resource.getRelativePath().equalsIgnoreCase(name)
                    || resource.getFilename().equalsIgnoreCase(name)
                    || resource.getAbsolutePath().equalsIgnoreCase(name)) {
                return resource;
            }
        }
        return null;
    }

    @Override
    public Collection<LoadableResource> getResources(String prefix, String[] suffixes) {
        return resources.stream()
                .filter(resource -> resourceNameMatches(resource.getFilename(), prefix, suffixes))
                .toList();
    }

    private static boolean resourceNameMatches(String fileName, String prefix, String[] suffixes) {
        if (!fileName.startsWith(prefix)) {
            return false;
        }

        for (var suffix : suffixes) {
            if (fileName.endsWith(suffix)) {
                return true;
            }
        }
        return false;
    }

    private static final class SpringLoadableResource extends LoadableResource {
        private final org.springframework.core.io.Resource resource;
        private final String absolutePath;
        private final String relativePath;

        private SpringLoadableResource(org.springframework.core.io.Resource resource) {
            this.resource = resource;
            this.absolutePath = resourcePath(resource);
            this.relativePath = RELATIVE_PREFIX + resource.getFilename();
        }

        @Override
        public Reader read() {
            try {
                return new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8);
            } catch (IOException exception) {
                throw new UncheckedIOException("Failed to read Flyway migration resource " + absolutePath, exception);
            }
        }

        @Override
        public String getAbsolutePath() {
            return absolutePath;
        }

        @Override
        public String getAbsolutePathOnDisk() {
            return absolutePath;
        }

        @Override
        public String getFilename() {
            return resource.getFilename();
        }

        @Override
        public String getRelativePath() {
            return relativePath;
        }

        private static String resourcePath(org.springframework.core.io.Resource resource) {
            try {
                return resource.getURL().toExternalForm();
            } catch (IOException exception) {
                return resource.getDescription();
            }
        }
    }
}
