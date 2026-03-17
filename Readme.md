# Project Chimera — Agentic Infrastructure to Builds Autonomous Influencers Agent.  

> **Role:** Forward Deployed Engineer (FDE)  
> **Mission:** Architect a “Factory” that builds Autonomous Influencers  
> **Core Method:** Spec-Driven Development (SDD) + Governance + TDD  
> **Runtime Concepts:** FastRender Swarm (Planner/Worker/Judge), MCP integration, HITL safety, Agentic Commerce

This repository is the **governed engineering foundation** for Project Chimera.  
You are **not** submitting a finished influencer product; you are submitting a **context-engineered, spec-first, test-governed codebase** that a swarm of AI agents (and humans) can extend safely.

---

## Table of Contents
- [Challenge Summary](#challenge-summary)
- [What’s Delivered](#whats-delivered)
- [Architecture Overview](#architecture-overview)
- [How to Run (Local)](#how-to-run-local)
- [TDD Proof (Failing Tests)](#tdd-proof-failing-tests)
- [Governance & Spec Alignment](#governance--spec-alignment)
- [IDE Agent Context Demo](#ide-agent-context-demo)
- [CI/CD](#cicd)
- [Directory Structure](#directory-structure)
- [Notes / Assumptions](#notes--assumptions)

---

## Challenge Summary

The primary risk in agentic systems is **ambiguity**: vague prompts, unstable code patterns, and weak governance.  
This repo addresses that by enforcing:

- **Spec-Driven Development:** Implementation must be derived from `specs/`
- **Traceability:** Every feature maps to a spec and is test-verified
- **MCP Exclusivity:** No direct external API calls from core logic
- **Swarm Architecture:** Planner → Worker → Judge pattern with safety gates
- **Human-in-the-Loop:** Confidence + sensitivity routes tasks to review
- **Enterprise-Grade Additions (“Beyond SRS”):**
  - FinOps budget controls and kill-switch concepts
  - Audit trails for tool calls and decisions
  - OpenTelemetry fields (`correlation_id`, `tenant_id`, `agent_id`)
  - “Supreme Court” multi-model consensus for high-risk commerce

---

## What’s Delivered

### Day 1 Deliverables (Specs + Architecture)
- **Executable specs** in `specs/`:
  - `_meta.md` — vision, constraints, directives
  - `functional.md` — user stories and behaviors
  - `technical.md` — JSON schemas, governance rules, ERD
  - `openclaw_integration.md` — bonus spec for agent social networking
- **Architecture strategy** (domain architecture + diagrams) in `research/architecture_strategy.md`

### Day 2 Deliverables (Context + Tooling + TDD + Governance)
- **Context Engineering rules**: `.cursor/rules` and/or `CLAUDE.md`
- **Tooling/skills strategy**: `research/tooling_strategy.md`
- **Runtime skill contracts**: `skills/*`
- **Failing JUnit 5 tests** (TDD “red” stage): `src/test/...`
- **Automation**: `Makefile`
- **CI/CD**: `.github/workflows/main.yml`
- **AI review policy**: `.coderabbit.yaml`
- **Bonus**:
  - `Dockerfile` + `make docker-test`
  - `scripts/spec-check.sh` + `make spec-check`

---

## Architecture Overview

### High-Level Pattern: FastRender Swarm + MCP

- **Planner:** decomposes high-level goals into tasks
- **Worker:** executes atomic tasks (stateless) using MCP tools
- **Judge:** validates outputs, routes HITL, commits state using OCC
- **HITL:** humans approve medium confidence or sensitive content
- **CFO Judge (Beyond SRS):** financial safety gate for commerce actions

### Detailed Archtecture

> The architecture diagram is defined in Mermaid inside:
- `research/architecture_strategy.md`

```mermaid
graph TB

  %% Actors
  Operator["Network Operator"]
  Reviewer["HITL Moderator"]

  %% -------------------------
  %% Control Plane
  %% -------------------------
  subgraph CONTROL["Control Plane"]
    UI["Dashboard UI (React)"]
    ORCH["Orchestrator API"]
    AUTH["Auth & RBAC (OIDC)"]
    POLICY["Policy Engine (Brand, Safety, Compliance)"]
    BUDGET["Budget Governor (FinOps Limits)"]
  end

  %% -------------------------
  %% Execution Plane (Swarm)
  %% -------------------------
  subgraph EXEC["Execution Plane (FastRender Swarm)"]
    PLANNER["Planner Service<br/>Goal -> Task DAG"]
    FILTER["Semantic Filter<br/>Relevance + Sensitivity Classifier"]
    WORKERS["Worker Pool<br/>Java 21 Virtual Threads"]
    JUDGE["Judge Service<br/>Quality Gate + OCC Commit"]
    CFO["CFO Judge<br/>Transaction Guardrails"]
    HITLROUTER["HITL Router<br/>Confidence-tier Routing"]
  end

  %% -------------------------
  %% Integration Plane (MCP)
  %% -------------------------
  subgraph INTEG["Integration Plane (MCP)"]
    MCPGW["MCP Client Gateway"]
    MCPSOC["MCP Server: Social Platforms"]
    MCPMEDIA["MCP Server: Media Generation"]
    MCPMEM["MCP Server: Memory (Weaviate)"]
    MCPCOMM["MCP Server: Coinbase AgentKit Bridge"]
  end

  %% -------------------------
  %% Data Plane
  %% -------------------------
  subgraph DATA["Data Plane"]
    PG["PostgreSQL<br/>GlobalState + Tenancy + Campaign Logs"]
    WEAV["Weaviate<br/>Long-term Semantic Memory"]
    REDIS["Redis<br/>Episodic Cache + Queues + Spend Counters"]
    KAFKA["Event Backbone (Kafka)"]
    OBJ["Object Storage<br/>Media Artifacts"]
    AUDIT["Append-only Audit Log<br/>Tool Calls + Decisions + Txns"]
    PERSONA["Persona Repo (SOUL.md GitOps)"]
  end

  %% -------------------------
  %% Platform / Infra (Enterprise add-ons)
  %% -------------------------
  subgraph PLATFORM["Platform / Infra"]
    VAULT["Secrets Manager (Vault / AWS Secrets)"]
    LLM["LLM Providers<br/>Gemini / Claude"]
    OTEL["OpenTelemetry<br/>Logs/Metrics/Traces"]
  end

  %% Control plane flows
  Operator --> UI
  Reviewer --> UI
  UI --> ORCH
  ORCH --> AUTH
  ORCH --> POLICY
  ORCH --> BUDGET
  ORCH --> PLANNER

  %% Swarm + eventing
  PLANNER --> FILTER
  FILTER -->|"Create tasks"| KAFKA
  KAFKA -->|"Dispatch tasks"| WORKERS
  WORKERS -->|"Publish results"| KAFKA
  KAFKA -->|"Results for review"| JUDGE

  %% RAG context + persona
  WORKERS --> REDIS
  WORKERS --> WEAV
  WORKERS --> PERSONA

  %% LLM usage
  PLANNER --> LLM
  FILTER --> LLM
  WORKERS --> LLM
  JUDGE --> LLM

  %% MCP boundary (all external actions via MCP)
  WORKERS <--> MCPGW
  CFO <--> MCPGW
  MCPGW <--> MCPSOC
  MCPGW <--> MCPMEDIA
  MCPGW <--> MCPMEM
  MCPGW <--> MCPCOMM

  %% OCC + state commit
  JUDGE -->|"OCC commit (state_version check)"| PG

  %% HITL routing
  JUDGE --> HITLROUTER
  HITLROUTER -->|"High confidence"| ORCH
  HITLROUTER -->|"Medium confidence (async approve)"| UI
  HITLROUTER -->|"Low confidence or sensitive"| UI

  %% Agentic commerce guardrails
  JUDGE -->|"If txn task"| CFO
  CFO --> BUDGET
  CFO --> REDIS
  CFO --> VAULT
  CFO -->|"Approved (call AgentKit via MCP)"| MCPGW

  %% Artifacts + audit
  WORKERS --> OBJ
  PLANNER --> AUDIT
  WORKERS --> AUDIT
  JUDGE --> AUDIT
  CFO --> AUDIT
  ORCH --> AUDIT

  %% Observability
  ORCH --> OTEL
  PLANNER --> OTEL
  FILTER --> OTEL
  WORKERS --> OTEL
  JUDGE --> OTEL
  CFO --> OTEL
  MCPGW --> OTEL
```

---
## Detailed Archtecture
## How to Run (Local)

### Prerequisites
- Java **21+**
- Maven **3.9+**
- Docker

### Verify Java & Maven
```bash
java -version
mvn -v
```

### Setup dependencies
```bash
make setup
# or
mvn clean install -DskipTests
```

---

## TDD Proof (Failing Tests)

This repository intentionally includes **failing tests** to prove true TDD:
- tests define the “empty slot”
- implementation is expected to be filled in later by agents/humans
- CI executes these tests on push (governance gate)

Run:
```bash
make test
# or
mvn test
```

Expected: **tests fail** deterministically (red stage).

---

## Governance & Spec Alignment

### Spec-check (bonus governance)
This script verifies:
- required specs exist
- rules file contains required directives
- technical schema anchors exist
- no direct HTTP clients in core code (MCP exclusivity guard)

Run:
```bash
make spec-check
# or
bash scripts/spec-check.sh
```

### AI Review Policy
- `.coderabbit.yaml` instructs AI reviewer to verify:
  - spec alignment (`specs/`)
  - Java thread safety (records, immutability)
  - security (no secrets, no direct HTTP)
  - reliability and observability

---

## IDE Agent Context Demo

For Loom video, demonstrate that your IDE agent follows the repo rules.

1) Open `CLAUDE.md` or `.cursor/rules` and highlight:
- `NEVER generate code without checking specs/ first.`
- `Explain your plan before writing code.`

2) In IDE chat, ask:

> “I want to implement AgentTask and WorkerResult. Before writing any code, check specs/technical.md and summarize the required fields and constraints. Then provide a plan. Do not write implementation code yet.”

A correct response should:
- cite `specs/technical.md`
- provide a plan before code
- mention Java 21 Records, OCC (`state_version`), MCP-only boundary, and observability fields

---

## CI/CD

GitHub Actions workflow:
- runs on `push` and `pull_request`
- uses Java 21
- runs `make setup` then `make test`

Path:
- `.github/workflows/main.yml`

---

## Directory Structure

```txt
.cursor/
  rules
.github/
  workflows/
    main.yml
research/
  architecture_strategy.md
  tooling_strategy.md
scripts/
  spec-check.sh
skills/
  skill_trend_fetcher/
  skill_publish_social_post/
specs/
  _meta.md
  functional.md
  technical.md
  openclaw_integration.md
src/
  main/
  test/
Dockerfile
Makefile
pom.xml
.coderabbit.yaml
CLAUDE.md
```

---

## Notes / Assumptions

- External APIs are accessed only through MCP servers (social, memory, commerce, media).
- Redis is used for high-speed queues and episodic cache in the architecture.
- PostgreSQL is the authority for committed global state (OCC) and audit/ledger metadata.
- This repo is a **governed scaffold** rather than a production deployment.

---

## License
See `LICENSE`.
```
