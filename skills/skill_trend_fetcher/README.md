# Skill Contract: skill_trend_fetcher

## Purpose
The `skill_trend_fetcher` skill queries external news and trend sources via MCP to discover trending topics, hashtags, and engagement patterns. It supports multi-region queries and time-scoped searches to identify relevant content opportunities for agents.

**Spec Reference**: specs/technical.md Section 3.1 (skill_trend_fetcher), specs/functional.md Section 2.2 (Content Generation)

---

## Inputs

### Skill Invocation Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "TrendFetcherInput",
  "properties": {
    "task_id": {
      "type": "string",
      "description": "Parent task identifier"
    },
    "campaign_id": {
      "type": "string",
      "description": "Campaign context"
    },
    "correlation_id": {
      "type": "string",
      "description": "Trace correlation ID (REQUIRED for observability)"
    },
    "skill_params": {
      "type": "object",
      "properties": {
        "keywords": {
          "type": "array",
          "items": {
            "type": "string"
          },
          "minItems": 1,
          "maxItems": 10,
          "description": "Topic keywords to search"
        },
        "time_range": {
          "type": "object",
          "properties": {
            "start_time": {
              "type": "string",
              "format": "date-time",
              "description": "Start of search window"
            },
            "end_time": {
              "type": "string",
              "format": "date-time",
              "description": "End of search window"
            }
          },
          "required": ["start_time", "end_time"]
        },
        "regions": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["US", "EU", "APAC", "LATAM", "GLOBAL"]
          },
          "minItems": 1,
          "description": "Geographic regions to search"
        },
        "platforms": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["twitter", "news", "reddit", "tiktok"]
          },
          "minItems": 1,
          "description": "Platforms to query"
        },
        "limit": {
          "type": "integer",
          "minimum": 1,
          "maximum": 100,
          "default": 20,
          "description": "Maximum results to return"
        }
      },
      "required": ["keywords", "time_range", "regions", "platforms"]
    }
  },
  "required": ["task_id", "campaign_id", "correlation_id", "skill_params"]
}
```

### Input Constraints
- `keywords`: 1-10 keywords, max 50 chars each
- `time_range`: Cannot exceed 30 days
- `regions`: At least one region required
- `platforms`: At least one platform required
- `limit`: 1-100 results (default 20)

---

## Outputs

### Success Response Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "TrendFetcherOutput",
  "properties": {
    "execution_id": {
      "type": "string",
      "description": "Unique execution identifier"
    },
    "task_id": {
      "type": "string",
      "description": "Reference to parent task"
    },
    "correlation_id": {
      "type": "string",
      "description": "Propagated correlation ID"
    },
    "status": {
      "type": "string",
      "enum": ["success"],
      "description": "Execution status"
    },
    "result": {
      "type": "object",
      "properties": {
        "trends": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "trend_id": {
                "type": "string",
                "description": "Unique trend identifier"
              },
              "keyword": {
                "type": "string",
                "description": "Trending keyword/hashtag"
              },
              "platform": {
                "type": "string",
                "enum": ["twitter", "news", "reddit", "tiktok"]
              },
              "region": {
                "type": "string"
              },
              "momentum": {
                "type": "number",
                "minimum": 0,
                "maximum": 100,
                "description": "Trend momentum score (0-100)"
              },
              "sentiment": {
                "type": "string",
                "enum": ["positive", "neutral", "negative"],
                "description": "Overall sentiment"
              },
              "engagement_count": {
                "type": "integer",
                "minimum": 0,
                "description": "Total engagement (likes, retweets, etc.)"
              },
              "mention_count": {
                "type": "integer",
                "minimum": 0,
                "description": "Number of mentions"
              },
              "discovered_at": {
                "type": "string",
                "format": "date-time",
                "description": "When trend was discovered"
              }
            },
            "required": ["trend_id", "keyword", "platform", "region", "momentum", "sentiment"]
          },
          "description": "Array of discovered trends"
        },
        "query_metadata": {
          "type": "object",
          "properties": {
            "keywords_queried": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "regions_queried": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "platforms_queried": {
              "type": "array",
              "items": {
                "type": "string"
              }
            },
            "results_returned": {
              "type": "integer",
              "minimum": 0
            },
            "query_duration_ms": {
              "type": "integer",
              "minimum": 0
            }
          }
        }
      },
      "required": ["trends", "query_metadata"]
    },
    "actual_cost": {
      "type": "number",
      "minimum": 0,
      "description": "Actual API cost incurred"
    },
    "audit_log": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "timestamp": {
            "type": "string",
            "format": "date-time"
          },
          "action": {
            "type": "string"
          },
          "details": {
            "type": "object"
          }
        }
      },
      "description": "Audit trail of operations"
    }
  },
  "required": ["execution_id", "task_id", "status", "result", "actual_cost", "correlation_id"]
}
```

---

## Errors & Exceptions

### Exception 1: RateLimitedException
**Status Code**: 429  
**Description**: MCP news server rate limit exceeded

**Response**:
```json
{
  "execution_id": "exec_xyz",
  "task_id": "task_abc",
  "status": "failure",
  "error": {
    "type": "RateLimitedException",
    "message": "News API rate limit exceeded",
    "retry_after_seconds": 300
  },
  "correlation_id": "corr_123"
}
```

**Recovery**: 
- Exponential backoff: retry after `retry_after_seconds`
- Judge routes to HITL if multiple consecutive failures
- Task requeued to Redis task queue

---

### Exception 2: APIUnavailableException
**Status Code**: 503  
**Description**: External news source is temporarily unavailable

**Response**:
```json
{
  "execution_id": "exec_xyz",
  "task_id": "task_abc",
  "status": "failure",
  "error": {
    "type": "APIUnavailableException",
    "message": "News API temporarily unavailable",
    "affected_platforms": ["twitter", "news"],
    "estimated_recovery_time_minutes": 5
  },
  "correlation_id": "corr_123"
}
```

**Recovery**:
- Retry with exponential backoff (max 3 retries)
- Route to HITL for manual trend override

---

### Exception 3: InvalidParametersException
**Status Code**: 400  
**Description**: Input parameters do not match schema

**Response**:
```json
{
  "execution_id": "exec_xyz",
  "task_id": "task_abc",
  "status": "failure",
  "error": {
    "type": "InvalidParametersException",
    "message": "Invalid input parameters",
    "violations": [
      {
        "field": "keywords",
        "message": "must contain 1-10 items"
      }
    ]
  },
  "correlation_id": "corr_123"
}
```

**Recovery**:
- Planner revalidates and resubmits corrected task
- Logged as planning error in audit

---

## Governance & Policy

### HITL Integration
- **Automatic Routing**: Trends with momentum < 10 flagged for human review
- **Dashboard Display**: All discovered trends shown in HITL dashboard
- **Approval Path**: Human can approve/reject before content generation
- **Override**: HITL operator can manually inject trends

### Budget Implications
- **Cost Model**: Per-API-call charge (typically $0.01 - $0.10 per query)
- **Budget Deduction**: Charged to campaign budget immediately
- **Budget Check**: Planner verifies budgets BEFORE invoking skill
- **Kill-Switch**: If query cost exceeds remaining budget, skill rejected

### Policy Checks
- **Platform Allowlist**: Only approved platforms allowed (configured in specs)
- **Keyword Filtering**: Offensive/blocked keywords rejected at planning stage
- **Time Window Validation**: Time ranges validated (max 30 days)
- **Rate Limits**: Built-in Rate Limit Handler (3 retries, exponential backoff)

### Observability
- **Correlation ID**: Propagated in every API call to news server
- **Metrics**: Query duration, results count, API cost tracked
- **Traces**: OpenTelemetry spans for each platform query
- **Alerts**: Alert if > 5 consecutive failures or cost spike detected

### Logging
- **Audit Trail**: All queries logged with timestamp, keywords, platforms, results
- **Secrets**: Never log API keys or authentication tokens
- **Result Logging**: Sanitized trend data logged (no sensitive user info)
- **Error Logging**: Full error context logged for debugging

---

## Implementation Notes

### Java 21+ Constraints
- Use virtual threads for concurrent platform queries
- Records for immutable TrendData, QueryMetadata
- Use sealed interfaces for error types

### MCP Integration
- Invokes via MCP News server exclusively
- No direct API calls to external sources
- Secrets (API keys) fetched from secrets manager

### Reference Architecture
```
Planner
  ↓ (creates task)
Worker
  ↓ (invokes)
skill_trend_fetcher
  ↓ (calls via MCP)
MCP News Gateway
  → Twitter, News, Reddit, TikTok APIs
  ↓ (returns trends)
Worker Result
  ↓ (sends result)
Judge
  ↓ (validates, applies OCC)
PostgreSQL (audit log)
```
