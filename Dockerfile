# Project Chimera - Test Container
# Purpose: Provide a reproducible Java 21 + Maven environment to run tests in Docker.
# Note: Tests may fail by design (TDD "empty slots"), so tests are NOT executed during image build.

FROM maven:3.9.9-eclipse-temurin-21

WORKDIR /workspace

# Cache dependencies first
COPY pom.xml /workspace/pom.xml
RUN mvn -q -DskipTests dependency:go-offline

# Copy the rest of the repository
COPY . /workspace

# Default command: run tests (may fail intentionally)
CMD ["mvn", "-q", "test"]