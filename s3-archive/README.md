# S3 log archive + lifecycle

## What it does
The final, cheap, long-term home for logs synced over from EFS. A lifecycle policy automatically moves objects through progressively cheaper storage classes as they age, without anything having to track object age itself.

## Lifecycle stages

| Age | Storage class | Why |
|---|---|---|
| 0–30 days | Standard | Recent logs are the ones most likely to be queried (incident investigation, debugging) — kept on the fastest, most expensive tier |
| 30–90 days | Standard-IA | Still retrievable in milliseconds, but access is rare by now — Infrequent Access cuts storage cost in exchange for a small per-retrieval fee |
| 90–180 days | Glacier | Kept for audit/compliance, not active use — Glacier trades retrieval latency (minutes–hours) for a large storage cost reduction |
| 180+ days | Glacier Deep Archive | Cheapest tier available — for logs that must be retained but are essentially never read, only restored on a compliance request |
| ~2555 days (7 years) | Expired (deleted) | Matches a typical regulatory/compliance retention window — keeping data indefinitely is cost and liability past the point it's required |

## Behaviour
- **Versioning + noncurrent version expiration**: versioning protects against accidental overwrite/delete of a log archive; `noncurrent_version_expiration` (30 days) stops old versions from accumulating storage cost forever once they're superseded.
- **Default encryption + public access block**: logs often contain sensitive operational detail (hostnames, request data, stack traces) — encrypted at rest by default and completely unreachable from the public internet regardless of any future bucket policy mistake.
- **Lifecycle transitions are automatic**: once applied, AWS manages the transitions — no cron job or Lambda has to remember to "move old logs to cold storage".

## Why it's needed
Log volume only grows, and the value of an individual log line drops sharply with age. Without a lifecycle policy, every log ever written sits on the most expensive storage tier forever; this one rule turns "log cost grows unbounded" into "log cost plateaus automatically" while keeping most of it retrievable for compliance.
