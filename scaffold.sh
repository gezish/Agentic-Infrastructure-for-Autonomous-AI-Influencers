#!/bin/bash

# Scaffold Maven directory structure for Project Chimera

# Create main source directories
mkdir -p src/main/java/com/chimera/orchestrator
mkdir -p src/main/java/com/chimera/planner
mkdir -p src/main/java/com/chimera/worker
mkdir -p src/main/java/com/chimera/judge
mkdir -p src/main/java/com/chimera/mcp

# Create test source directories
mkdir -p src/test/java/com/chimera/tests

# Create resources directories
mkdir -p src/main/resources
mkdir -p src/test/resources

echo "Maven directory structure for Project Chimera has been created."