# Project Chimera: Functional Specifications

**Document Version:** 1.0.0  
**Date:** March 8, 2026  
**Status:** FROZEN — Spec-Driven Development  
**Audience:** Product Managers, Engineering Teams, Business Stakeholders

---

## Document Purpose

This specification defines all functional requirements for Project Chimera using strict MUST/SHALL/SHOULD language. These requirements are guaranteed to be implemented; any deviation requires formal Change Control approval.

---

## Domain 1: Perception & Memory (Ingestion)
### Requirements
- The system SHALL ingest external signals strictly via MCP Resources.
- The system SHALL semantically filter ingested signals before generating tasks.
- The system SHALL retrieve hierarchical memory (episodic + semantic) prior to generation.

### User Stories
- As a Planner Agent, I need to poll MCP resources (e.g., `twitter://mentions`, `news://latest`) so that I can react to real-time events.
- As a Semantic Filter, I need to score content relevance against active goals so that only relevant items become tasks.
- As a Worker Agent, I need to retrieve relevant memories from Weaviate and recent context from Redis so that outputs remain persona-consistent.

## Domain 2: Swarm Orchestration (FastRender: Planner/Worker/Judge)
### Requirements
- The system SHALL implement a Hierarchical Swarm pattern (“FastRender”).
- Planner SHALL decompose high-level goals into executable tasks and enqueue them.
- Workers SHALL execute tasks statelessly and submit results for review.
- Judge SHALL validate results, enforce policies, and commit to state using OCC.

### User Stories
- As a Network Operator, I want to define a campaign goal so that the Planner can generate a task graph.
- As a Planner Agent, I want to push atomic tasks to a queue so that Workers can execute them concurrently.
- As a Worker Agent, I want to execute a single task using MCP Tools and submit the artifact for judgment.
- As a Judge Agent, I want to approve/reject/escalate results so that the system remains safe and consistent.

## Domain 3: Governance & Safety (Judge + HITL)
### Requirements
- Every Worker output SHALL include a confidence score and sensitivity flags.
- Judge SHALL route outputs to:
  - Auto-approve (high confidence, not sensitive)
  - Async HITL approval (medium confidence)
  - Reject/retry (low confidence) OR mandatory HITL (sensitive topics)
- Sensitive topics (Politics, Health Advice, Financial Advice, Legal Claims) SHALL require HITL regardless of confidence.

### HITL User Stories
- As a HITL Moderator, I want to approve or reject flagged items so that the system remains brand-safe.
- As a HITL Moderator, I want to see confidence score, sensitivity flags, and a reasoning trace summary so that I can decide quickly.

## Domain 4: Agentic Commerce & FinOps (Beyond SRS)
### Requirements
- Commerce actions SHALL be executed via MCP commerce tools only.
- A CFO Judge SHALL review all transaction requests.
- Transactions above threshold MUST require “Supreme Court” multi-model validation.
- The system SHALL enforce budgets per tenant/campaign/agent and support an emergency kill-switch.

### User Stories
- As a CFO Judge, I want to block transactions that exceed budget so that spend is controlled.
- As a Network Operator, I want a kill-switch to disable commerce tools for an agent during anomalies.
- As the system, I want to log every transaction request, decision, and execution so that audits are possible.

## Domain 5: FinOps & Budget Controls (Beyond SRS)

### Requirements
- The system **MUST** enforce hierarchical budget constraints: tenant budget ≥ campaign allocations ≥ agent ceilings
- Budget enforcement **MUST** occur pre-execution: Worker SHALL not accept task if remaining budget < estimated cost
- Spend counters in Redis **MUST** use atomic Compare-And-Swap (CAS) operations to prevent race conditions
- All spend transactions **MUST** be appended to PostgreSQL audit ledger (immutable, append-only)
- Budget exhaustion **MUST** trigger immediate hard kill-switch: reject all subsequent commerce/spend tasks with HTTP 429
- Budget override **MUST** require audit logging: override_reason, timestamp, authorizer_id, and spend_delta
- Spend events **MUST** be published to Kafka topic `chimera.spend.events` for real-time monitoring and alerting

### FinOps User Stories
- As a Tenant Administrator, I want to allocate quarterly budgets to campaigns so that spend remains controlled and predictable.
- As a Campaign Manager, I want to distribute my campaign budget across agents so that resource allocation is optimized.
- As a Finance Controller, I want real-time spend dashboards and daily reconciliation reports so that anomalies are detected immediately.
- As an On-Call Engineer, I want to activate a kill-switch instantly so that runaway agents stop immediately.

## Domain 6: Supreme Court Consensus (Multi-Model Approval)

### Requirements
- High-risk transactions **MUST** be defined by configuration: transaction amount threshold, account creation, policy changes
- High-risk transactions **MUST** require approval from two independent models (e.g., GPT-4 and Claude-3)
- Each model **MUST** provide: approval/rejection, confidence_score (0.0–1.0), reasoning (text), and supporting evidence
- Consensus **MUST** follow unanimous rule: if either model rejects, transaction MUST be rejected (veto power)
- Decision rationale from both models **MUST** be logged to PostgreSQL with correlation_id for compliance audit
- Dissenting opinions **MUST** be preserved in audit ledger with full reasoning trace
- Consensus timeout **MUST** default to 5 minutes; timeout escalates to HITL review (pending manual decision)
- Async consensus **MUST** not block Planner; tasks enter "pending_consensus" state until verdict
- Consensus decisions **MUST** be immutable: no post-approval modification allowed

### Supreme Court User Stories
- As a Risk Officer, I want automatic two-model validation for high-value transactions so that fraud and policy violations are caught.
- As a Compliance Auditor, I want complete dissent logs with reasoning so that regulatory reviews are possible.
- As a Judge Agent, I want to override consensus timeout escalations so that stuck transactions progress.

## Domain 7: Observability & Correlation ID Propagation

### Requirements
- Every request **MUST** receive a unique `correlation_id` (UUID v4) at entry point (Planner)
- Correlation_id **MUST** be propagated through all system components: Planner → Task Queue → Worker → Judge → Response
- Correlation_id **MUST** be included in all structured log entries (JSON format with key `correlation_id`)
- Every MCP tool call **MUST** be logged with:
  - correlation_id, timestamp, client_id, endpoint, method, request_size_bytes, response_size_bytes
  - latency_ms, http_status_code, model_name, confidence_score, execution_id
- Every state mutation (INSERT/UPDATE/DELETE) **MUST** be logged with:
  - correlation_id, timestamp, identity (user_id or service_id), operation, table_name, row_id, change_delta (old→new values)
- Secrets **MUST NEVER** appear in logs: API keys, auth tokens, credit card data, PII, or commerce credentials
- High-frequency polls (Redis checks, memory queries) **MUST** be sampled: 1% logged at INFO, 100% stored at DEBUG (disabled in prod)
- All audit logs **MUST** be persisted to PostgreSQL for long-term compliance (retention: 7 years minimum)

### Observability User Stories
- As an SRE, I want to trace any failure by correlation_id so that root cause analysis is rapid.
- As a Security Auditor, I want request/response logs with exact timestamps so that compliance investigations are conclusive.
- As a Performance Engineer, I want MCP latency breakdown by endpoint so that bottlenecks are identified.

## Domain 8: HITL (Human-in-the-Loop) Governance

### Requirements
- Every Worker output **MUST** include confidence_score (0.0–1.0) and sensitivity_flags (list of strings)
- Judge **MUST** route outputs based on confidence threshold and sensitivity:
  - **Auto-Approve:** confidence_score ≥ 0.75 AND not sensitive → immediate commit
  - **Review Queue:** 0.50 ≤ confidence_score < 0.75 → async HITL review
  - **Mandatory HITL:** sensitivity_flags contain ["political", "health_advice", "financial_advice", "legal_claim"] → always escalate, regardless of confidence
  - **Reject & Retry:** confidence_score < 0.50 → automatic retry (up to 3 times) or escalate if retries fail
- HITL reviewers **MUST** see: confidence_score, sensitivity_flags, result artifact, reasoning trace, and estimated cost impact
- HITL decisions **MUST** be logged with: reviewer_id, timestamp, verdict (approve/reject), comments (optional)
- HITL decisions **MUST** feed back to Worker for retraining signals
- SLA for HITL review **MUST** be configurable per task type (default: 15 minutes for financial, 1 hour for general)

### HITL User Stories
- As a Brand Safety Officer, I want to review and approve risky content before it posts so that brand reputation is protected.
- As a Compliance Officer, I want HITL history and audit trails so that regulatory investigations are supported.
- As a Planner Agent, I want feedback from HITL decisions so that I improve future task decomposition.

## Domain 9: Security & Secrets Management

### Requirements
- All API keys, commerce credentials, MCP tokens, and database passwords **MUST** be stored in an external secrets manager (HashiCorp Vault, AWS Secrets Manager, or equivalent)
- Secrets **MUST NOT** be embedded in code, config files, environment variables (except transient CI/CD runner context), or data stores
- Secrets **MUST** be rotated on a mandatory schedule: default 90 days for commerce keys, 180 days for MCP tokens (configurable per secret)
- Rotation **MUST NOT** cause service interruption: old and new secrets valid during grace period (default: 30 minutes)
- MCP server allowlist **MUST** be loaded at application startup; unlisted servers MUST be rejected with HTTP 403
- All inter-service MCP calls **MUST** use Mutual TLS (mTLS) authentication with client certificates issued by internal PKI
- HITL Dashboard, FinOps Dashboard, and Audit Log access **MUST** require MFA (multi-factor authentication)
- All secrets in transit **MUST** be encrypted with TLS 1.3+ (no downgrade to TLS 1.2)
- All secrets at rest **MUST** be encrypted with AES-256-GCM

### Security User Stories
- As a Security Officer, I want secrets rotation to happen automatically so that compromised keys don't cause breach.
- As a DevOps Engineer, I want to manage SCP servers via allowlist so that rogue MCP servers cannot be used.
- As a System Administrator, I want MFA enforcement so that unauthorized dashboard access is prevented.

## Domain 10: Cross-Functional Requirements

### Idempotency
- All task executions **MUST** be idempotent: running the same task twice with identical inputs SHALL produce identical outputs
- Idempotent operations **MUST** be marked in task catalog; non-idempotent operations **MUST** fail with explicit error

### Error Handling
- All errors **MUST** be logged with: correlation_id, timestamp, error_code, error_message, and stack trace (if applicable)
- Transient errors (network timeouts, temporary unavailability) **MUST** trigger automatic retry with exponential backoff (default: 1s, 2s, 4s, 8s)
- Permanent errors (validation errors, budget exhaustion, missing resource) **MUST** fail immediately and escalate to HITL

### Event Propagation
- All domain events (task_created, execution_completed, judgment_rendered, budget_exceeded) **MUST** be published to Kafka
- Event consumers **MUST** be idempotent; duplicate events SHALL not cause state inconsistency

---

## Domain Summary Table

| Domain | Key MUST Requirements | Status |
|--------|----------------------|--------|
| Ingestion | MCP-only sources, semantic filtering, memory retrieval | Core |
| Swarm | Hierarchical pattern, task queuing, stateless workers | Core |
| HITL | Confidence routing, sensitivity escalation, audit log | Core |
| Commerce | MCP-only, CFO review, Supreme Court for high-risk, budget enforcement | Enterprise Governance |
| FinOps | Per-tenant/campaign/agent budgets, real-time counters, kill-switch, audit ledger | Enterprise Governance |
| Supreme Court | Two-model validation, veto power, decision logging, timeout escalation | Enterprise Governance |
| Observability | Correlation ID propagation, no-secrets logging, audit storage | Enterprise Governance |
| HITL Escalation | Confidence thresholds, sensitivity flags, SLAs, feedback loops | Enterprise Governance |
| Security | Secrets manager, rotation, MCP allowlist, MFA, mTLS, TLS 1.3+ | Enterprise Governance |
| Idempotency | Replay-safe execution, idempotent markers, error handling | Cross-Functional |

---

## Document Sign-Off

| Role | Name | Date |
|------|------|------|
| **Product Lead** | [Assigned] | [TBD] |
| **Engineering Lead** | [Assigned] | [TBD] |
| **Security & Compliance** | [Assigned] | [TBD] |