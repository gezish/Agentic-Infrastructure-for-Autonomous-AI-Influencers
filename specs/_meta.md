# Project Chimera: Master Specification _meta

**Document Version:** 1.0.0  
**Date:** March 8, 2026  
**Status:** FROZEN — Spec-Driven Development (No Implementation Code)  
**Classification:** Enterprise Governance & Architecture  
**Audience:** Architecture Board, Engineering Leadership, Security, Compliance, FinOps

---

## Executive Summary

Project Chimera is an **enterprise-grade autonomous AI agent orchestration platform** implementing the **FastRender Hierarchical Swarm pattern** with **human-in-the-loop (HITL) governance**, **financial operations (FinOps) controls**, **multi-model consensus validation** ("Supreme Court"), and **observability-first audit framework**. This specification pack defines all functional and technical requirements for Project Chimera under strict spec-driven development discipline.

### Core Tenets

| Aspect | Requirement |
| **Architecture Pattern** | Hierarchical Swarm (Planner → Queue → Worker Swarm → Review Queue → Judge) |
| **Language / Runtime** | Java 21+ (with virtual thread constraints for Worker tier) |
| **External Integration** | MCP (Model Context Protocol) exclusivity |
| **State Management** | Redis (task/review queues, spend counters); PostgreSQL (global state, ledger) |
| **Concurrency Model** | Optimistic Concurrency Control (OCC) for distributed state mutations |
| **Governance Layer** | FinOps budgets (per tenant/campaign/agent), Supreme Court consensus (two-model), observability/audit (correlation IDs), security/secrets |
| **HITL Thresholds** | Configurable confidence thresholds (default 0.75 auto, 0.50–0.74 review); sensitive ops always escalated |
| **Beyond-SRS Governance** | FinOps kill-switches, Supreme Court veto, correlation ID propagation, audit ledger, secrets manager enforcement |

---

## Specification Philosophy

This Master Specification pack adheres to **Spec-Driven Development (SDD)**: specifications are canonical; implementation is derived, never invented. No implementation code is generated in this phase. This trilogy of Markdown documents (plus JSON schemas) completely and unambiguously define Project Chimera's behavior, architecture, and governance model.

---

## Document Structure

This Master Specification pack comprises three frozen specifications:

### 1. **specs/_meta.md** (This Document)
- Overview and governance scope
- Component inventory
- Constraint inventory
- Specification cross-references

### 2. **specs/functional.md**
- Functional requirements (MUST/SHALL/SHOULD)
- Use cases and workflows
- HITL decision points
- Role-based access/permissions
- FinOps budget policies
- Supreme Court consensus rules

### 3. **specs/technical.md**
- Technical architecture (MCP, tier layers, data models)
- API/protocol specifications (JSON schemas)
- Database schema (ER diagram)
- Concurrency / OCC strategy
- Observability / correlation ID propagation
- Security / secrets management / MCP allowlist
- Deployment constraints

---

## Component Inventory

### Primary Components

| Component | Role | Constraint | Status |
|-----------|------|-----------|--------|
| **Planner** | Orchestrates campaigns, creates tasks | Java 21+, MCP-driven | Core |
| **Worker Swarm** | Stateless, parallel execution | Virtual threads (Java 21+ feature), no shared state | Core |
| **Judge** | Consensus validation, HITL escalation | Two-model approval (Supreme Court) for high-risk | Core |
| **Redis Task Queue** | Async task distribution | Must support TTL, no persistence of sensitive data | Infrastructure |
| **Redis Review Queue** | Judge input buffer, spend counter ledger | Atomic operations for OCC | Infrastructure |
| **PostgreSQL Global State** | Audit ledger, campaign metadata, user/tenant config | ACID compliance required | Infrastructure |
| **HITL Dashboard** | Human review interface for escalations | Read-only to sensitive data, MFA required | UI/Governance |
| **MCP Servers** | External tool integration (Twitter, News, Weaviate, Coinbase, Media) | Allowlist enforcement, request/response logging | External |

---

## Constraint Inventory

### Language / Runtime Constraints

- **MUST** use Java 21 or later at minimum
- **MUST** constrain Worker tier to leverage virtual threads (Project Loom)
- **MUST NOT** use continuations; virtual threads only for IO-bound workloads
- **MUST** maintain compatibility with JDK Flight Recorder (JFR) for observability

### Concurrency / State

- **MUST** implement Optimistic Concurrency Control (OCC) for PostgreSQL state mutations
- **MUST** use Compare-And-Swap (CAS) semantics for Redis distributed counters
- **MUST** support idempotent task re-execution (ensure Workers can safely replay failed tasks)

### MCP Exclusivity

- **MUST** route all external interactions (data sources, actions, decisions) through MCP servers
- **MUST NOT** embed direct HTTP calls, SDK integrations, or inline API clients
- **MUST** enforce MCP allowlist at Planner and Worker tiers
- **MUST** validate all MCP server responses against strict schemas

### Enterprise Governance (Beyond SRS)

#### FinOps Controls
- **MUST** implement per-tenant, per-campaign, per-agent spend budgets with hierarchical inheritance
- **MUST** maintain real-time spend counters in Redis using atomic Compare-And-Swap (CAS) operations
- **MUST** persist all spend transactions to PostgreSQL ledger (immutable, append-only)
- **MUST** support hard kill-switch on budget exhaustion: transaction MUST fail immediately with status code 429
- **MUST** log all spend events with campaign_id, agent_id, tenant_id, and correlation_id
- **MUST** support budget override (with audit logging of override reason, timestamp, and authorizer)
- **MUST** emit spend change events to Kafka for real-time monitoring and alerting

#### Supreme Court Consensus (Two-Model Approval)
- **MUST** require two independent model approvals for "high-risk" transactions (high-value commerce, account creation, policy changes)
- **MUST** log complete decision rationale from both models (including confidence scores and supporting evidence)
- **MUST** enforce veto power: either model rejection MUST veto consensus, even if both approve initially
- **MUST** store dissenting opinions in audit ledger for compliance review
- **MUST** support async consensus with timeout (default: 5 minutes); timeout escalates to HITL

#### Observability / Correlation ID Propagation
- **MUST** propagate `correlation_id` (UUID v4) through all tiers: request → Planner → Task Queue → Worker → Judge → Response
- **MUST** include correlation_id in all structured log entries (JSON format)
- **MUST** log tool calls (MCP invocations) with: correlation_id, client_id, endpoint, method, request_size, response_size, latency_ms, http_status, model_name, confidence_score
- **MUST** log all state mutations with: correlation_id, timestamp, identity (user/service), operation (INSERT/UPDATE/DELETE), table_name, row_id, change_delta
- **MUST NOT** log secrets, API keys, credit card data, PII, or auth tokens in any log output
- **MUST** sample high-frequency logs (e.g., poll operations): log 1% at INFO level, store 100% at DEBUG level (disabled in production)

#### Security / Secrets Management
- **MUST** store all API keys, commerce credentials, MCP server tokens, and database passwords in an external secrets manager (HashiCorp Vault or equivalent)
- **MUST NOT** embed secrets in code, configuration files, environment variables (except transient CI/CD runner context), or data stores
- **MUST** enforce mandatory rotation of all commerce keys and MCP credentials on a 90-day cycle (default; configurable per secret)
- **MUST** enforce Mutual TLS (mTLS) authentication for inter-service MCP calls
- **MUST** enforce MFA (multi-factor authentication) for all access to HITL Dashboard, FinOps dashboards, and audit logs
- **MUST** maintain allowlist of approved MCP servers at application startup; deny-by-default for unlisted servers
- **MUST** encrypt all secrets in transit (TLS 1.3+) and at rest (AES-256-GCM)

### HITL Thresholds

- **SHALL** define per-campaign confidence thresholds (default: 0.75 for auto-execution, 0.50–0.74 for human review)
- **SHALL** define per-operation risk categories: `LOW` (auto), `MEDIUM` (review queue), `HIGH` (Supreme Court + review queue)
- **SHALL** support manual escalation from Workers to Review Queue
- **MUST** provide SLA targets for human review (e.g., \≤15 minutes for financial transactions)

---

## Specification Freeze & Change Control

This Master Specification pack is **FROZEN** under Spec-Driven Development discipline:

- ✅ **Canonical Deliverables:** specs/_meta.md, specs/functional.md, specs/technical.md, and embedded JSON schemas. NO implementation code is generated.
- ✅ **Strict Conformance:** All future implementation MUST conform to these specifications exactly. No deviations, shortcuts, or architectural modifications without formal Change Control.
- ✅ **Change Control Process:** Every specification change MUST:
  1. Be documented in a Change Request (CR) with business justification
  2. Receive approval from Architecture Board, Engineering Lead, and Security Officer
  3. Result in a new version tag (e.g., 1.0.0 → 1.1.0 for backward-compatible, → 2.0.0 for breaking)
  4. Include migration guide for in-flight deployments
- ⚠️ **Technical Debt:** Any implementation-identified issues MUST NOT result in runtime patch-and-hope. File CR or escalate to Architecture Board.

---

## Cross-References

- **Architecture Strategy:** See [research/architecture_strategy.md](../research/architecture_strategy.md) for strategic context and design rationale.
- **Functional Spec:** See [specs/functional.md](functional.md) for use cases, workflows, and business rules.
- **Technical Spec:** See [specs/technical.md](technical.md) for architecture, APIs, databases, and implementation constraints.

---

## Approval & Sign-Off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| **Lead Architect / Governor** | [Assigned] | [TBD] | __________________ |
| **Engineering Lead** | [Assigned] | [TBD] | __________________ |
| **Security Officer** | [Assigned] | [TBD] | __________________ |
| **FinOps / Compliance Officer** | [Assigned] | [TBD] | __________________ |

---

## Version History

| Version | Date | Status | Key Changes |
|---------|------|--------|-------------|
| 1.0.0 | Mar 8, 2026 | FROZEN | Initial Master Specification pack release; FastRender Swarm, FinOps, Supreme Court, observability, security |

