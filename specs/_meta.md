# Project Meta: Vision, Core Philosophies & Constraints

## High-Level Vision
Project Chimera is an enterprise-grade Autonomous Influencer Network. We are building a factory that provisions and manages persistent, goal-directed digital entities (“Chimera Agents”). These agents perceive trends, reason about campaign goals, generate multimodal content, and may operate with economic autonomy.

Our core directive is **Safety and Scalability through Strict Governance**, achieved via a role-based swarm architecture and strong contracts.

## Core Philosophies
1. **Spec-Driven Development (SDD):** `specs/` is the sole source of truth. No implementation code is written or modified by human or AI agents without verifying these specs first.
2. **MCP Exclusivity:** Core agent logic MUST NOT call third-party APIs directly. All external interaction (social, news, memory, media generation, commerce) SHALL occur via MCP Resources/Tools/Prompts.
3. **Governance by Construction:** Every action MUST be validated by a Judge layer and be auditable.
4. **Determinism at Boundaries:** All inter-service payloads MUST be strongly typed and schema validated.

## Architectural Constraints
- **Language Runtime:** Java 21+.
- **Concurrency Intent:** Worker execution SHOULD be implemented with Java 21 Virtual Threads (`Executors.newVirtualThreadPerTaskExecutor()`), enabling high fan-out I/O without thread pool exhaustion.
- **Immutability:** DTOs crossing Planner/Worker/Judge boundaries MUST be Java `record` types (immutable).
- **State Consistency:** Commits to GlobalState MUST use Optimistic Concurrency Control (OCC) with a `state_version` check.
- **Observability:** All task and tool events MUST carry `tenant_id`, `agent_id`, and `correlation_id`.

## Advancments Beyond-SRS Enterprise Constraints
- **FinOps/Budget Governance:** The system MUST enforce budgets per tenant/campaign/agent. It MUST support a kill-switch to disable costly tools or commerce actions for specific agents.
- **Supreme Court Consensus (High-Risk Commerce):** Transactions above a configurable threshold (default: 10 USD equivalent) MUST require multi-model validation (e.g., Gemini + Claude) before execution.
- **Security & Secrets:** Private keys and API keys MUST be stored in an enterprise secrets manager and MUST NOT be logged or embedded in artifacts. Commerce signing MUST occur only within trusted components (e.g., MCP commerce server).