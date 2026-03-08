# Project Chimera - Context Engineering Rules

## Project Context
Project Chimera is an Agentic Infrastructure for Autonomous AI Influencers. The system uses a **FastRender Swarm** architecture with specialized roles:
- **Planner**: Decomposes goals into task DAGs
- **Worker Swarm**: Executes tasks using Java 21+ virtual threads
- **Judge**: Validates quality and applies OCC (Optimistic Concurrency Control)

### Technology Stack
- **MCP (Model Context Protocol)**: Exclusive gateway for all external integrations (Twitter, News, Weaviate, Coinbase AgentKit, Media)
- **Redis Queues**: Task queuing, review queuing, episodic caching, spend counters
- **PostgreSQL GlobalState**: Persistent tenant data, campaign logs, audit ledger, budget tracking
- **HITL (Human-in-the-Loop)**: Dashboard for low-confidence or sensitive task approvals
- **OpenTelemetry**: Observability with correlation ID propagation
- **Kafka**: Event backbone for async communication

### Enterprise Governance Features
- **FinOps**: Per-tenant, per-campaign, per-agent budgets with kill-switch
- **Supreme Court Validation**: Two-model consensus for high-risk transactions
- **Observability**: Correlation IDs propagated across all operations
- **Security**: Secrets manager, MCP allowlist, no secrets in logs

## Prime Directive
**NEVER generate code without checking specs/ first.**

All implementation MUST align with the Master Specification Pack:
- `specs/_meta.md` - Overview and metadata
- `specs/functional.md` - Functional requirements
- `specs/technical.md` - Technical specifications with JSON schemas and ER diagram
- `specs/openclaw_integration.md` - OpenClaw agent social network integration

## Java-Specific Directives
- **Java Version**: SHALL use Java 21 or higher
- **Immutable DTOs**: Use Java Records for all immutable data transfer objects
  - Example: `record TaskPayload(String taskId, String campaignId, String type) {}`
- **Testing Framework**: JUnit 5 (Jupiter) for all unit and integration tests
- **Concurrency Model**: Virtual threads preferred for high-concurrency tasks
  - Use `Executors.newVirtualThreadPerTaskExecutor()` for worker pools
- **State Management**: Immutable data structures required for core payloads
  - NO mutable Maps, Sets, or Collections in critical path code
  - Use unmodifiable collections or Records
- **Naming**: Use camelCase for variables/methods, PascalCase for classes, UPPER_SNAKE_CASE for constants

## Traceability
**Explain your plan before writing code.**

Before implementing any feature or component:
1. Reference the relevant specification section
2. Describe the task decomposition strategy
3. List the data structures/schemas being used
4. Identify integration points (MCP, Redis, PostgreSQL, Kafka)
5. Name the expected test coverage
6. Only THEN write code

## Skills vs Tools: Clear Distinction

### Dev MCP Tools (Development-Time)
These are MCP servers/tools used during development and project scaffolding:
- `git-mcp`: Version control operations
- `filesystem-mcp`: File system operations
- `github-mcp`: GitHub API integration

### Runtime Agent Skills (Execution-Time)
These are capabilities deployed as part of the agent infrastructure:
- `skill_trend_fetcher`: Queries news/trend sources via MCP
- `skill_publish_post`: Posts to social platforms via MCP
- `skill_generate_content`: Creates content using LLM
- `skill_analyze_engagement`: Analyzes campaign metrics
- `skill_execute_commerce_txn`: Executes trades via Coinbase AgentKit MCP
- `skill_check_budget`: Validates spend against budget limits
- `skill_route_to_hitl`: Routes to human dashboard for approval

## Spec Alignment and Governance

### All Code Must Map to specs/technical.md
Every implementation SHALL reference the corresponding JSON schema or ER entity:

**Task Execution**:
- Uses `Task Schema` from technical.md Section 4.1
- Maps to TASK entity in ER diagram (Section 3.1)

**Execution Results**:
- Uses `Execution Result Schema` from technical.md Section 4.2
- Maps to EXECUTION and DECISION entities

**Budget Enforcement**:
- Uses `Budget Schema` from technical.md Section 4.3
- Maps to CAMPAIGN entity budgets

### Spec Updates Required Before Implementation
If a new feature or requirement is discovered:
1. Update the relevant spec file FIRST
2. Add/modify JSON schema if needed
3. Update ER diagram if new entities/relationships
4. THEN implement code to match the updated spec
5. Include spec file references in commit messages

### Code Review Checklist
- [ ] Spec referenced and followed
- [ ] JSON schemas validated
- [ ] ER diagram entities used correctly
- [ ] Java 21+ standards applied
- [ ] Records used for immutable data
- [ ] JUnit 5 tests included
- [ ] Virtual threads for concurrency (where applicable)
- [ ] Correlation IDs propagated
- [ ] No secrets in logs
- [ ] MCP calls properly audited

## Architecture Layers

### Control Plane (Orchestrator, Policy, Budget)
- Manages campaigns, policies, budgets
- Routes to execution plane
- No direct data mutation (reads through queries)

### Execution Plane (Planner/Worker/Judge)
- Planner: Decomposes goals
- Worker: Stateless execution
- Judge: Quality gate and OCC commit

### Integration Plane (MCP)
- All external calls via MCP exclusively
- No direct API calls
- Allowlist enforcement

### Data Plane (PostgreSQL, Redis, Weaviate, Kafka)
- PostgreSQL: Global state, tenancy, audit
- Redis: Queues, caches, spend counters
- Weaviate: Semantic memory
- Kafka: Events

## Observability Requirements
- Correlation ID: Generated at request ingress, propagated to all downstream calls
- Audit Logging: Capture all tool calls, decisions, financial transactions
- OpenTelemetry: Logs, metrics, traces for performance monitoring
- Never Log Secrets: No API keys, tokens, or financial data in plain text

## File Structure Reference
```
src/main/java/com/chimera/
├── orchestrator/       # Control plane
├── planner/            # Execution plane
├── worker/             # Execution plane
├── judge/              # Execution plane
└── mcp/                # MCP client gateway

specs/
├── _meta.md            # Overview
├── functional.md       # Requirements
├── technical.md        # Architecture & schemas
└── openclaw_integration.md  # Agent social network
```

## Decision Log
Document major architectural decisions in comments with references to specifications.
Format: `// DECISION: [context] → [choice] (ref: specs/technical.md#section)`
