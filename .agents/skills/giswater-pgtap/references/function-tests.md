# Function Test Patterns

## Standard JSON-API function test

All giswater functions accept a JSON string and return JSON.
Standard client block:
```json
{"client": {"device": 4, "lang": "es_ES", "infoType": 1, "epsg": 25831}, "form": {}, "feature": {}, "data": {"filterFields": {}, "pageInfo": {}}}
```

### Minimal status check

```sql
SELECT is(
    (gw_fct_myfunction($${"client":{"device":4,"lang":"es_ES","infoType":1,"epsg":25831},
    "form":{}, "feature":{}, "data":{"filterFields":{},"pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'gw_fct_myfunction basic call returns Accepted'
);
```

### Extract nested JSON field

```sql
-- Check body.data.info.values[0].message
SELECT is(
    ((gw_fct_myfunction($$...$$)::JSON)->'body'->'data'->'info'->'values'->0->>'message'),
    'expected message',
    'message matches'
);
```

### Test multiple scenarios (one per feature type)

Pattern from `test_gw_fct_getinfofromid.sql`:
```sql
SELECT plan(5);  -- one per tableName

SELECT is(
    (gw_fct_getinfofromid($${"client":{"device":4,"lang":"es_ES","infoType":1,"epsg":25831},
    "form":{}, "feature":{"tableName":"ve_node","id":"89"},
    "data":{"filterFields":{},"pageInfo":{},"addSchema":""}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getinfofromid tableName --> ve_node returns status "Accepted"'
);

-- repeat for ve_connec, ve_arc, ve_gully, ve_link ...
```

### Test error case (status "Failed")

```sql
SELECT is(
    (gw_fct_myfunction($${"client":{"device":4,"lang":"es_ES","infoType":1,"epsg":25831},
    "form":{}, "feature":{"tableName":"nonexistent"}, "data":{}}$$)::JSON)->>'status',
    'Failed',
    'unknown tableName returns status Failed'
);
```

### Using dollar-quoting for JSON args

Always use `$$...$$` dollar-quoting for JSON args — avoids escaping inner quotes:
```sql
-- Good
SELECT gw_fct_getconfig($${"client":{"device":4}}$$);

-- Bad (escape hell)
SELECT gw_fct_getconfig('{"client":{"device":4}}');
```

## Form-based functions

```sql
SELECT is(
    (gw_fct_getconfig($${"client":{"device":4,"lang":"es_ES","infoType":1,"epsg":25831},
    "form":{"formName":"epaoptions"}, "feature":{},
    "data":{"filterFields":{},"pageInfo":{}}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_getconfig --> "formName":"epaoptions" returns status "Accepted"'
);
```

## Template for new function test file

Replace `<FUNCTION_NAME>`, `<N>`, `<ARGS>`, `<DESCRIPTION>`:

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

-- Plan for <N> test
SELECT plan(<N>);

-- Create roles for testing
CREATE USER plan_user;  GRANT role_plan  TO plan_user;
CREATE USER epa_user;   GRANT role_epa   TO epa_user;
CREATE USER edit_user;  GRANT role_edit  TO edit_user;
CREATE USER om_user;    GRANT role_om    TO om_user;
CREATE USER basic_user; GRANT role_basic TO basic_user;

SELECT is(
    (<FUNCTION_NAME>($$<ARGS>$$)::JSON)->>'status',
    'Accepted',
    'Check if <FUNCTION_NAME> --> <DESCRIPTION> returns status "Accepted"'
);

SELECT finish();
ROLLBACK;
```
