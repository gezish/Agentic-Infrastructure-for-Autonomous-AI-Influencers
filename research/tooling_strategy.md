# Project Chimera: Tooling & MCP Strategy

## 1. Developer Tools (MCP)
To enable efficient development of the Chimera swarm, the following MCP servers are selected and configured for the IDE:

- **git-mcp**: For managing version control, creating branches, and committing code through agentic workflows.
- **filesystem-mcp**: For direct file manipulation and directory structure management.
- **sqlite-mcp**: For local data prototyping and task queue simulation during development.
- **weaviate-mcp**: For direct interaction and debugging of the agent's semantic memory during the persona design phase.

## 2. Agent Skills (Runtime)
The Chimera Agent operates through a specialized set of Skills (Runtime Tools). These are distinct from Dev MCPs and are part of the agent's "Action" system.

### **Core Skills**
- `skill_generate_image`: Image generation via Midjourney/Ideogram MCP.
- `skill_render_video`: Video rendering via Luma/Runway MCP.
- `skill_coinbase_transfer`: On-chain financial transactions via Coinbase AgentKit.
- `skill_trend_fetcher`: Ingestion of social/news resources via Twitter/News MCP.

## 3. Tooling Integration Plan
1. **Host Configuration**: The Chimera Orchestrator acts as the MCP Host, aggregating these tools into a unified context.
2. **Dynamic Discovery**: Skills are discovered dynamically at runtime through the MCP `list_tools` primitive.
3. **Execution Logic**:
    - **Planner**: Identifies the necessary tool for a task.
    - **Worker**: Executes the tool call with the required parameters.
    - **Judge**: Validates the tool's output before committing it to the global state.
