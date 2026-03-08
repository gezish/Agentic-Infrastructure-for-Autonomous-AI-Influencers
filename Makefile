# Project Chimera - Makefile
# This Makefile standardizes common development commands
# Requires: Maven 3.8+, Java 21+

.PHONY: help setup test lint clean build docker-build docker-test spec-check

help:
	@echo "Project Chimera - Development Commands"
	@echo "========================================"
	@echo "Local Development:"
	@echo "  make setup     - Clean install dependencies (skips tests)"
	@echo "  make test      - Run full Maven test suite"
	@echo "  make lint      - Run Spotless code formatter/linter"
	@echo "  make build     - Build JAR without tests"
	@echo "  make clean     - Remove build artifacts"
	@echo ""
	@echo "Docker Commands:"
	@echo "  make docker-build - Build Docker image (prefetches deps, no tests)"
	@echo "  make docker-test  - Run tests inside Docker container"
	@echo ""
	@echo "Governance & Compliance:"
	@echo "  make spec-check   - Verify spec-driven development alignment"
	@echo ""
	@echo "  make help      - Display this help message

setup:
	@echo "Setting up Project Chimera..."
	mvn clean install -DskipTests

test:
	@echo "Running test suite..."
	mvn test

lint:
	@echo "Running Spotless code formatter and linter..."
	mvn spotless:apply

build:
	@echo "Building Project Chimera..."
	mvn clean package -DskipTests

clean:
	@echo "Cleaning build artifacts..."
	mvn clean
	rm -rf target/

docker-build:
	@echo "Building Docker image: project-chimera:latest"
	docker build -t project-chimera:latest .
	@echo "Docker image built successfully"

docker-test:
	@echo "Running tests inside Docker container..."
	docker run --rm \
		-v $(PWD)/target:/app/target \
		project-chimera:latest

spec-check:
	@echo "Running spec-alignment verification..."
	./scripts/spec-check.sh

# ============================================================================
# NOTE: Spotless Dependency
# ============================================================================
# If you see error: "spotless:apply" goal not found, add this plugin to
# pom.xml <build><plugins> section:
#
# <plugin>
#     <groupId>com.diffplug.spotless</groupId>
#     <artifactId>spotless-maven-plugin</artifactId>
#     <version>2.43.0</version>
#     <configuration>
#         <java>
#             <toggleOffOn/>
#             <removeUnusedImports/>
#             <googleJavaFormat>
#                 <version>1.17.0</version>
#             </googleJavaFormat>
#             <licenseHeader>
#                 <content>
// SPDX-License-Identifier: Apache-2.0
// Copyright (c) 2026 Project Chimera Contributors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//                 </content>
#             </licenseHeader>
#         </java>
#     </configuration>
#     <executions>
#         <execution>
#             <goals>
#                 <goal>check</goal>
#             </goals>
#         </execution>
#     </executions>
# </plugin>
#
# Then run: mvn spotless:apply
# ============================================================================
.PHONY: setup test lint docker-build docker-test spec-check

setup:
	mvn clean install -DskipTests

test:
	mvn test

lint:
	@echo "TODO: Add Spotless/Checkstyle to pom.xml and wire it here."
	@echo "For now, lint is a placeholder."

docker-build:
	docker build -t chimera-test .

docker-test: docker-build
	docker run --rm chimera-test