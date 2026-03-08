# Project Chimera: Domain Architecture Strategy

## 1. High-Level Architecture (FastRender Swarm + MCP)

Project Chimera utilizes a **Hierarchical Swarm Pattern** (FastRender) combined with the **Model Context Protocol (MCP)**. Cognitive responsibilities are split into specialized roles—**Planner, Worker, Judge, CFO Judge, HITL Router**—to maximize throughput, guarantee governance, and support safe autonomy at scale.

### 1.1 System Overview

- **Control Plane** (Orchestrator, Auth, Policy, Budget)
- **Execution Plane** (Planner / Semantic Filter / Worker Pool / Judge / CFO Judge / HITL Router)
- **Integration Plane** (MCP gateway and MCP servers for social, media, memory, commerce)
- **Data Plane** (PostgreSQL, Redis, Weaviate, Kafka, Object Storage, Audit Store)
- **Platform Plane** (Secrets, LLM providers, Observability)

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
  %% Platform / Infra
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