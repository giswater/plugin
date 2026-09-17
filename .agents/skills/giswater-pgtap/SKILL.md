---
name: giswater-pgtap
description: >
  Guide for writing fast pgTAP tests for the Giswater dbmodel. Covers test structure,
  naming conventions, available assertions, function testing patterns (JSON API), security/RLS
  testing, and how to run tests. Trigger when user asks to write, add, fix, or run dbmodel tests,
  or mentions pgTAP in context of giswater.
license: MIT
metadata:
    author: giswater
    version: "0.1.0"
---

# Giswater pgTAP Tests

## References

| Topic | File | Use for |
|-------|------|---------|
| Test anatomy | [references/test-anatomy.md](references/test-anatomy.md) | File structure, boilerplate, plan vs no_plan |
| Assertions cheat-sheet | [references/assertions.md](references/assertions.md) | `is`, `lives_ok`, `throws_ok`, `ok`, `isnt`, etc. |
| Schema test patterns | [references/schema-tests.md](references/schema-tests.md) | Table inventory, columns_are, col_type_is, fk_ok, has_index, has_trigger |
| Function test patterns | [references/function-tests.md](references/function-tests.md) | JSON-API functions, status checks, field extraction |
| Security / RLS tests | [references/security-tests.md](references/security-tests.md) | Role switching, permission checks, lock_level |
| Running tests | [references/running-tests.md](references/running-tests.md) | CLI commands, Docker, execute_sql_files.py |
| pgTAP full reference | [references/pgtap-full-reference.md](references/pgtap-full-reference.md) | Complete function signatures for all pgTAP assertions |

## Quick rules

- All tests live in `dbmodel/test/<project_type>/<category>/test_<function_name>.sql`
- `project_type`: `ud` (urban drainage) or `ws` (water supply)
- `category`: `function` or `security`
- Every test file: `BEGIN` → `SET search_path` → `SELECT plan(N)` or `no_plan()` → tests → `SELECT finish()` → `ROLLBACK`
- Schema placeholder: `"SCHEMA_NAME"` — replaced at runtime by `replace_vars.py`
- Negative test IDs: use IDs like `-999`, `-998` for fixture data to avoid clashes
- Always `ROLLBACK` — tests must be side-effect free
