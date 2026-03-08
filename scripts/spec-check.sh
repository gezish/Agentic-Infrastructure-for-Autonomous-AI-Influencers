#!/bin/bash
# Project Chimera - Spec-Alignment Verification Script
# This script enforces spec-driven development practices and ensures:
#  1. All required specification documents exist
#  2. Development guidelines are documented
#  3. API schemas are properly defined
#  4. Code respects MCP exclusivity (no direct HTTP clients)
# Exit 1 if any check fails

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track failures
FAILED=0

# Helper function: print error
error() {
    echo -e "${RED}❌ FAIL${NC}: $1" >&2
    FAILED=$((FAILED + 1))
}

# Helper function: print success
success() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

# Helper function: print warning
warning() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
}

echo "=========================================="
echo "Project Chimera - Spec Alignment Check"
echo "=========================================="
echo ""

# ============================================================================
# CHECK 1: Required Specification Documents Exist
# ============================================================================
echo "CHECK 1: Required specification documents..."

specs=(
    "specs/_meta.md"
    "specs/functional.md"
    "specs/technical.md"
)

for spec in "${specs[@]}"; do
    if [ -f "$PROJECT_ROOT/$spec" ]; then
        success "Found $spec"
    else
        error "Missing required specification: $spec"
    fi
done

echo ""

# ============================================================================
# CHECK 2: Development Guidelines (.cursor/rules/agent.mdc or CLAUDE.md)
# ============================================================================
echo "CHECK 2: Development guidelines..."

CURSOR_RULES="$PROJECT_ROOT/.cursor/rules/agent.mdc"
CLAUDE_MD="$PROJECT_ROOT/CLAUDE.md"
GUIDELINES_FOUND=false

if [ -f "$CURSOR_RULES" ]; then
    GUIDELINES_FILE="$CURSOR_RULES"
    GUIDELINES_FOUND=true
    success "Found .cursor/rules/agent.mdc"
elif [ -f "$CLAUDE_MD" ]; then
    GUIDELINES_FILE="$CLAUDE_MD"
    GUIDELINES_FOUND=true
    success "Found CLAUDE.md"
else
    error "Missing .cursor/rules/agent.mdc or CLAUDE.md"
fi

# Check for required guideline content
if [ "$GUIDELINES_FOUND" = true ]; then
    # Check for spec-first guideline
    if grep -q "NEVER generate code without checking specs" "$GUIDELINES_FILE" 2>/dev/null; then
        success "Found spec-first guideline in guidelines file"
    else
        error "Missing guideline: 'NEVER generate code without checking specs' in $GUIDELINES_FILE"
    fi
    
    # Check for documentation guideline
    if grep -q "Explain your plan before writing code" "$GUIDELINES_FILE" 2>/dev/null; then
        success "Found plan-first guideline in guidelines file"
    else
        error "Missing guideline: 'Explain your plan before writing code' in $GUIDELINES_FILE"
    fi
fi

echo ""

# ============================================================================
# CHECK 3: Required JSON Schema Definitions
# ============================================================================
echo "CHECK 3: API schema definitions in technical.md..."

TECH_SPEC="$PROJECT_ROOT/specs/technical.md"

if [ -f "$TECH_SPEC" ]; then
    # Check for AgentTask schema
    if grep -q "AgentTask\|\"AgentTask\"\|\"title\": \"AgentTask\"" "$TECH_SPEC" 2>/dev/null; then
        success "Found AgentTask schema definition"
    else
        error "Missing schema definition: 'AgentTask' in specs/technical.md"
    fi
    
    # Check for WorkerResult schema
    if grep -q "WorkerResult\|\"WorkerResult\"\|\"title\": \"WorkerResult\"" "$TECH_SPEC" 2>/dev/null; then
        success "Found WorkerResult schema definition"
    else
        error "Missing schema definition: 'WorkerResult' in specs/technical.md"
    fi
fi

echo ""

# ============================================================================
# CHECK 4: Code Constraints - No Direct HTTP Clients (MCP Exclusivity)
# ============================================================================
echo "CHECK 4: MCP exclusivity (no direct HTTP clients)..."

SRC_DIR="$PROJECT_ROOT/src/main/java"

if [ -d "$SRC_DIR" ]; then
    # Search for java.net.http.HttpClient usage
    if grep -r "java\.net\.http\.HttpClient" "$SRC_DIR" 2>/dev/null; then
        error "Found forbidden java.net.http.HttpClient usage in src/main/java. All external HTTP interactions MUST use MCP servers."
    else
        success "No direct java.net.http.HttpClient usage found (MCP exclusivity maintained)"
    fi
    
    # Also check for HttpURLConnection
    if grep -r "java\.net\.HttpURLConnection" "$SRC_DIR" 2>/dev/null; then
        error "Found forbidden java.net.HttpURLConnection usage. All external HTTP interactions MUST use MCP servers."
    else
        success "No java.net.HttpURLConnection usage found"
    fi
else
    warning "Source directory $SRC_DIR not found (skipping code analysis)"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "=========================================="
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED${NC}"
    echo "=========================================="
    exit 0
else
    echo -e "${RED}❌ $FAILED CHECK(S) FAILED${NC}"
    echo "=========================================="
    echo ""
    echo "Remediation steps:"
    echo "1. Ensure all specs/ files are present and complete"
    echo "2. Create .cursor/rules or update CLAUDE.md with required guidelines"
    echo "3. Add API schemas to specs/technical.md (AgentTask, WorkerResult)"
    echo "4. Remove direct HTTP clients (java.net.http.HttpClient, etc.) from code"
    echo "5. Use MCP servers exclusively for external interactions"
    echo ""
    exit 1
fi
