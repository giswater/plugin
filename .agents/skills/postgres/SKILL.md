---
name: postgres
description: PostgreSQL best practices, query optimization, and performance improvement. Load when working with Postgres databases.
license: MIT
metadata:
    author: giswater
    version: "0.0.1"
---

# Giswater Postgres

## Generic Postgres

| Topic                  | Reference                                                                    | Use for                                                   |
| ---------------------- | -----------------------------------------------------------------------------| --------------------------------------------------------- |
| Schema Design          | [references/schema-design.md](references/schema-design.md)                   | Tables, primary keys, data types, foreign keys            |
| Indexing               | [references/indexing.md](references/indexing.md)                             | Index types, composite indexes, performance               |
| Index Optimization     | [references/index-optimization.md](references/index-optimization.md)         | Unused/duplicate index queries, index audit               |
| Query Patterns         | [references/query-patterns.md](references/query-patterns.md)                 | SQL anti-patterns, JOINs, pagination, batch queries       |
| Optimization Checklist | [references/optimization-checklist.md](references/optimization-checklist.md) | Pre-optimization audit, cleanup, readiness checks         |
