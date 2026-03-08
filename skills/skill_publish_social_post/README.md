# Skill Contract: skill_publish_social_post

## Purpose
The `skill_publish_social_post` skill publishes content to social media platforms via MCP. It handles text posts, media attachments, scheduling, multi-platform distribution, and engagement optimization. All publications are subject to brand policy validation, HITL approval workflows, and budget enforcement.

**Spec Reference**: specs/technical.md Section 3.1 (skill_publish_post), specs/functional.md Section 2.2 (Content Generation), specs/openclaw_integration.md (Agent status broadcasting)

---

## Inputs

### Skill Invocation Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "PublishSocialPostInput",
  "properties": {
    "task_id": {
      "type": "string",
      "description": "Parent task identifier"
    },
    "campaign_id": {
      "type": "string",
      "description": "Campaign context"
    },
    "agent_id": {
      "type": "string",
      "description": "Agent publishing the post"
    },
    "correlation_id": {
      "type": "string",
      "description": "Trace correlation ID (REQUIRED for observability)"
    },
    "skill_params": {
      "type": "object",
      "properties": {
        "content": {
          "type": "object",
          "properties": {
            "text": {
              "type": "string",
              "minLength": 1,
              "maxLength": 500,
              "description": "Post text content"
            },
            "media": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "url": {
                    "type": "string",
                    "format": "uri",
                    "description": "Media URL (image/video)"
                  },
                  "type": {
                    "type": "string",
                    "enum": ["image", "video", "gif"],
                    "description": "Media type"
                  },
                  "alt_text": {
                    "type": "string",
                    "description": "Accessibility alt text"
                  }
                },
                "required": ["url", "type"]
              },
              "maxItems": 4,
              "description": "Attached media (platform-dependent limits)"
            },
            "hashtags": {
              "type": "array",
              "items": {
                "type": "string",
                "pattern": "^#[a-zA-Z0-9_]{1,30}$"
              },
              "maxItems": 10,
              "description": "Hashtags to include"
            },
            "mentions": {
              "type": "array",
              "items": {
                "type": "string",
                "pattern": "^@[a-zA-Z0-9_]{1,30}$"
              },
              "maxItems": 5,
              "description": "User mentions to include"
            }
          },
          "required": ["text"]
        },
        "platforms": {
          "type": "array",
          "items": {
            "type": "string",
            "enum": ["twitter", "linkedin", "facebook", "instagram", "tiktok"]
          },
          "minItems": 1,
          "description": "Platforms to publish to"
        },
        "scheduling": {
          "type": "object",
          "properties": {
            "publish_immediately": {
              "type": "boolean",
              "default": true,
              "description": "Publish now or schedule for later"
            },
            "scheduled_time": {
              "type": "string",
              "format": "date-time",
              "description": "Publication timestamp (if not immediate)"
            }
          }
        },
        "engagement_settings": {
          "type": "object",
          "properties": {
            "enable_replies": {
              "type": "boolean",
              "default": true,
              "description": "Allow public replies"
            },
            "reply_filter": {
              "type": "string",
              "enum": ["everyone", "followers_only", "none"],
              "default": "everyone"
            }
          }
        },
        "sensitivity_level": {
          "type": "string",
          "enum": ["low", "medium", "high"],
          "default": "low",
          "description": "Content sensitivity (affects HITL routing)"
        }
      },
      "required": ["content", "platforms"]
    }
  },
  "required": ["task_id", "campaign_id", "agent_id", "correlation_id", "skill_params"]
}
```

### Input Constraints
- `text`: 1-500 characters
- `media`: Max 4 items (platform-dependent)
- `hashtags`: Max 10, format `#word`
- `mentions`: Max 5, format `@username`
- `platforms`: At least 1 required
- `scheduled_time`: Must be future timestamp (if not immediate)
- `sensitivity_level`: Affects HITL approval routing

---

## Outputs

### Success Response Schema
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "title": "PublishSocialPostOutput",
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
      "enum": ["success", "pending_approval"],
      "description": "Status (success if auto-published, pending if HITL approval needed)"
    },
    "result": {
      "type": "object",
      "properties": {
        "publications": {
          "type": "array",
          "items": {
            "type": "object",
            "properties": {
              "platform": {
                "type": "string",
                "enum": ["twitter", "linkedin", "facebook", "instagram", "tiktok"]
              },
              "post_id": {
                "type": "string",
                "description": "Platform-specific post identifier"
              },
              "url": {
                "type": "string",
                "format": "uri",
                "description": "Direct link to published post"
              },
              "published_at": {
                "type": "string",
                "format": "date-time",
                "description": "Actual publication timestamp"
              },
              "status": {
                "type": "string",
                "enum": ["published", "scheduled", "failed"],
                "description": "Publication status for this platform"
              }
            },
            "required": ["platform", "post_id", "published_at", "status"]
          },
          "description": "Publication details per platform"
        },
        "hitl_ticket": {
          "type": "object",
          "properties": {
            "ticket_id": {
              "type": "string",
              "description": "HITL approval ticket ID (if pending approval)"
            },
            "reason": {
              "type": "string",
              "enum": ["high_sensitivity", "high_reach_estimate", "policy_conflict", "manual_override"],
              "description": "Reason for HITL routing"
            },
            "estimated_reach": {
              "type": "integer",
              "minimum": 0,
              "description": "Estimated audience reach"
            }
          }
        },
        "engagement_snapshot": {
          "type": "object",
          "properties": {
            "initial_impressions": {
              "type": "integer",
              "minimum": 0
            },
            "engagement_rate_estimate": {
              "type": "number",
              "minimum": 0,
              "maximum": 1,
              "description": "Predicted engagement rate based on historical data"
            }
          }
        },
        "monetization": {
          "type": "object",
          "properties": {
            "platform_earnings_enabled": {
              "type": "boolean",
              "description": "Eligible for platform monetization"
            },
            "estimated_earnings": {
              "type": "number",
              "minimum": 0
            }
          }
        }
      },
      "required": ["publications"]
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
            "type": "string",
            "enum": ["content_validated", "policy_check_passed", "hitl_routed", "published", "error"]
          },
          "details": {
            "type": "object"
          }
        }
      },
      "description": "Audit trail of publication process"
    }
  },
  "required": ["execution_id", "task_id", "status", "result", "actual_cost", "correlation_id"]
}
```

---

## Errors & Exceptions

### Exception 1: BudgetExceededException
**Status Code**: 402  
**Description**: Task would exceed campaign budget

**Response**:
```json
{
  "execution_id": "exec_xyz",
  "task_id": "task_abc",
  "status": "failure",
  "error": {
    "type": "BudgetExceededException",
    "message": "Campaign budget exceeded",
    "budget": {
      "allocated": 1000.00,
      "spent": 950.00,
      "requested": 75.00,
      "remaining": 50.00
    },
    "action": "KILL_SWITCH_ACTIVATED"
  },
  "correlation_id": "corr_123"
}
```

**Recovery**:
- Automatic kill-switch blocks publication
- Task routed to CFO Judge for budget override decision
- HITL notification sent

---

### Exception 2: ContentPolicyViolationException
**Status Code**: 403  
**Description**: Content violates brand or platform policy

**Response**:
```json
{
  "execution_id": "exec_xyz",
  "task_id": "task_abc",
  "status": "failure",
  "error": {
    "type": "ContentPolicyViolationException",
    "message": "Content violates policy",
    "violations": [
      {
        "rule": "brand_tone",
        "severity": "high",
        "message": "Content tone aggressive (brand policy: friendly)"
      },
      {
        "rule": "platform_guidelines",
        "severity": "medium",
        "platform": "twitter",
        "message": "URL may violate link policy"
      }
    ]
  },
  "correlation_id": "corr_123"
}
```

**Recovery**:
- Route to HITL for manual review
- Operator can override or request reformulation
- Logged as policy violation

---

### Exception 3: PlatformAuthenticationException
**Status Code**: 401  
**Description**: Authentication failed for one or more platforms

**Response**:
```json
{
  "execution_id": "exec_xyz",
  "task_id": "task_abc",
  "status": "failure",
  "error": {
    "type": "PlatformAuthenticationException",
    "message": "Authentication failed",
    "failed_platforms": ["twitter", "linkedin"],
    "reason": "Token expired or invalid credentials"
  },
  "correlation_id": "corr_123"
}
```

**Recovery**:
- Secrets manager consulted for credential refresh
- Automatic retry with refreshed tokens
- If 3+ retries fail, escalate to HITL

---

### Exception 4: RateLimitedException
**Status Code**: 429  
**Description**: Platform rate limit exceeded

**Response**:
```json
{
  "execution_id": "exec_xyz",
  "task_id": "task_abc",
  "status": "failure",
  "error": {
    "type": "RateLimitedException",
    "message": "Rate limit exceeded",
    "platform": "twitter",
    "retry_after_seconds": 900
  },
  "correlation_id": "corr_123"
}
```

**Recovery**:
- Exponential backoff: retry after `retry_after_seconds`
- Task requeued to Redis task queue
- Judge routes to HITL if recurring

---

## Governance & Policy

### HITL Approval Workflow
**Automatic Routing Triggers**:
- Sensitivity level = "high"
- Estimated reach > 100,000 impressions
- Policy violations detected
- Content uses flagged keywords
- Manual operator override

**HITL Dashboard Flow**:
1. HITL ticket created with context (content, reason, estimated reach)
2. Operator reviews and approves/rejects
3. If approved: publication proceeds immediately
4. If rejected: task logged as cancelled, no publication
5. If modified: reformulated content resubmitted to skill

**Approval SLA**: 5 minutes for high-sensitivity content

---

### Budget Integration
- **Cost Model**: Per-platform publication fee + media upload fee
- **Budget Deduction**: Charged immediately upon successful publication
- **Budget Verification**: Planner checks available budget BEFORE invoking
- **Kill-Switch**: If cost > remaining budget, execution blocked immediately
- **Escalation**: HITL can request budget override from CFO Judge

---

### Platform Policy Checks
- **Brand Tone**: Content must match brand guidelines (verified against tone classifier)
- **Prohibited Content**: Offensive language, spam, hate speech blocked
- **URL Validation**: Links checked for malware/phishing
- **Media Compliance**: Image/video checked for inappropriate content
- **Platform-Specific**: Twitter character limits, Instagram hashtag limits, etc.

---

### Observability & Monitoring
- **Correlation ID**: Propagated to all platform API calls
- **Metrics**: Publication latency, platform success rate, engagement snapshot
- **Traces**: OpenTelemetry spans for content validation, platform calls, HITL routing
- **Alerts**:
  - Budget overrun detected
  - Policy violation detected
  - High failure rate (> 20%)
  - Engagement anomaly (sudden drop)

---

### Audit Logging
- **Audit Events**:
  - Content validated
  - Policy checks passed/failed (reason)
  - HITL routed (reason)
  - Published (per platform, post ID, timestamp)
  - Engagement snapshot recorded
  - Cost deduction recorded
- **Sensitive Data**: Content text logged (sanitized), user mentions logged, API keys never logged
- **Immutability**: Audit entries append-only in PostgreSQL

---

## Governance Integration

### Supreme Court Validation
For high-reach posts (> 500K estimated impressions):
- Requires two-model consensus approval
- Models independently validate content safety, brand alignment
- Both must approve before publication

### Correlation ID Flow
```
Planner
  → creates correlation_id (UUID)
  → includes in Task payload
Worker
  → receives correlation_id
  → invokes skill_publish_social_post
    → includes in API call headers
MCP Social Gateway
  → propagates to Twitter/LinkedIn/etc. APIs
  → returns correlation_id in response
Audit Log
  → stores correlation_id with all events
OpenTelemetry
  → correlates all traces end-to-end
```

---

## Implementation Notes

### Java 21+ Constraints
- Use virtual threads for concurrent platform publishing
- Records for immutable PublicationPayload, PolicyCheckResult
- Sealed interfaces for error types
- Immutable input/output classes

### MCP Integration
- Invokes via MCP Twitter/Social gateway exclusively
- No direct API calls to platforms
- Secrets (OAuth tokens) fetched from secrets manager at runtime
- Automatic token refresh via secrets manager

### Reference Architecture
```
Planner
  ↓ (validates budget, creates task)
Worker
  ↓ (invokes)
skill_publish_social_post
  ↓ (validates content, applies policies)
Policy Engine
  ↓ (checks brand/platform rules)
HITL Router
  ↓ (if approval needed)
HITL Dashboard (operator review)
  ↓ (if approved)
MCP Social Gateway
  → Twitter, LinkedIn, Facebook, Instagram, TikTok
  ↓ (returns post IDs)
Worker Result
  ↓ (sends result with post URLs)
Judge
  ↓ (validates, deducts cost, applies OCC)
PostgreSQL (audit log)
```
