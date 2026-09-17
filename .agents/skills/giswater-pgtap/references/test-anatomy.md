# Test File Anatomy

## Minimal boilerplate

```sql
/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

-- Plan: exact count of SELECT assertions below
SELECT plan(N);

-- ... tests here ...

SELECT finish();
ROLLBACK;
```

## plan(N) vs no_plan()

| Use | When |
|-----|------|
| `SELECT plan(N)` | Know exact test count. Preferred — fails if count wrong. |
| `SELECT * FROM no_plan()` | Count varies (loops, conditional tests). Use for security tests with many role combos. |

## Standard role setup block

Paste at top when function respects roles:

```sql
CREATE USER plan_user;  GRANT role_plan  TO plan_user;
CREATE USER epa_user;   GRANT role_epa   TO epa_user;
CREATE USER edit_user;  GRANT role_edit  TO edit_user;
CREATE USER om_user;    GRANT role_om    TO om_user;
CREATE USER basic_user; GRANT role_basic TO basic_user;
```

Roles are created inside `BEGIN`/`ROLLBACK` — auto-cleaned.

## File location

```
dbmodel/test/
  ud/
    function/   test_gw_fct_<name>.sql
    security/   test_<feature>_<scenario>.sql
  ws/
    function/   test_gw_fct_<name>.sql
    security/   test_<feature>_<scenario>.sql
```

## Naming

- Function tests: `test_gw_fct_<function_name>.sql`
- Security tests: `test_<table>_<rule>.sql`
- Test description strings: `'<verb> <function> --> <scenario> returns <expected>'`
