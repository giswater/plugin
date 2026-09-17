# Schema Test Patterns

## Two-level structure

```
test/<pt>/schema/
  test_tables.sql          — inventory: has_table() for every table in schema
  tables/
    test_schema_<table>.sql — deep test per table: columns, types, PKs, FKs, indexes, triggers
```

## test_tables.sql — table inventory

Uses `plan(N)` with exact count. One `has_table()` per table.

```sql
BEGIN;
SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(319);  -- must match exact number of has_table calls

SELECT has_table('arc')       AS "Table 'arc' exists";
SELECT has_table('node')      AS "Table 'node' exists";
SELECT has_table('connec')    AS "Table 'connec' exists";
-- ... one per table ...

SELECT * FROM finish();
ROLLBACK;
```

> **When to update plan(N):** Add/remove a table → update count. CI fails if count wrong.

## test_schema_<table>.sql — deep table test

Uses `no_plan()` — count varies by table size. Sections in order:

### 1. Table exists
```sql
SELECT has_table('arc'::name, 'Table arc should exist');
```

### 2. Columns (exhaustive list)
```sql
SELECT columns_are(
    'arc',
    ARRAY[
        'arc_id', 'code', 'node_1', 'node_2', 'arc_type', 'state',
        'the_geom', 'created_at', 'created_by', 'updated_at', 'updated_by'
        -- all columns, alphabetically or schema order
    ],
    'Table arc should have the correct columns'
);
```
Fails if any extra or missing column — catches accidental schema drift.

### 3. Primary key
```sql
SELECT col_is_pk('arc', 'arc_id', 'Column arc_id should be primary key');
```

### 4. Check constraints
```sql
SELECT col_has_check('arc', 'epa_type', 'Table should have check on epa_type');
```

### 5. Column types
```sql
SELECT col_type_is('arc', 'arc_id',   'integer',                   'Column arc_id should be integer');
SELECT col_type_is('arc', 'code',     'text',                      'Column code should be text');
SELECT col_type_is('arc', 'state',    'int2',                      'Column state should be int2');
SELECT col_type_is('arc', 'the_geom', 'geometry(linestring, 25831)', 'Column the_geom should be geometry(linestring, SRID_VALUE)');
-- geometry uses SRID_VALUE placeholder — replaced by replace_vars.py → 25831
```

Common giswater types:
| Pattern | SQL type |
|---------|----------|
| IDs | `integer` |
| Short codes | `varchar(16)`, `varchar(30)`, `varchar(50)` |
| Long text | `text` |
| Elevations/lengths | `numeric(12,3)` |
| Coords/slopes | `numeric(12,4)` |
| Flags | `boolean` |
| Timestamps | `timestamptz` |
| Arrays | `integer[]`, `smallint[]` |
| Geometry | `geometry(linestring, 25831)`, `geometry(point, 25831)`, `geometry(polygon, 25831)` |
| Small int | `int2` |

### 6. Default values
```sql
SELECT col_has_default('arc', 'arc_id',       'Column arc_id should have default value');
SELECT col_has_default('arc', 'feature_type',  'Column feature_type should have default value');
SELECT col_has_default('arc', 'created_at',    'Column created_at should have default value');
```

### 7. Foreign keys
```sql
-- Single column FK
SELECT fk_ok('arc', 'arc_type',    'cat_feature_arc', 'id',    'FK arc_type → cat_feature_arc.id');
SELECT fk_ok('arc', 'state',       'value_state',     'id',    'FK state → value_state.id');
SELECT fk_ok('arc', 'expl_id',     'exploitation',    'expl_id', 'FK expl_id → exploitation.expl_id');

-- Composite FK
SELECT fk_ok(
    'arc', ARRAY['muni_id', 'streetaxis_id'],
    'ext_streetaxis', ARRAY['muni_id', 'id'],
    'FK (muni_id, streetaxis_id) → ext_streetaxis(muni_id, id)'
);

-- Check table has any FK at all
SELECT has_fk('arc', 'Table arc should have foreign keys');
```

### 8. Indexes
```sql
SELECT has_index('arc', 'arc_pkey',           ARRAY['arc_id'],     'Index on arc_id');
SELECT has_index('arc', 'arc_index',           ARRAY['the_geom'],   'Spatial index on the_geom');
SELECT has_index('arc', 'arc_exploitation',    ARRAY['expl_id'],    'Index on expl_id');
SELECT has_index('arc', 'arc_expl_visibility_gin', ARRAY['expl_visibility'], 'GIN index on expl_visibility');
```

### 9. Triggers
```sql
SELECT has_trigger('arc', 'gw_trg_edit_controls',       'Trigger gw_trg_edit_controls exists');
SELECT has_trigger('arc', 'gw_trg_topocontrol_arc',     'Trigger gw_trg_topocontrol_arc exists');
SELECT has_trigger('arc', 'gw_trg_arc_node_values',     'Trigger gw_trg_arc_node_values exists');
SELECT has_trigger('arc', 'gw_trg_typevalue_fk_insert', 'Trigger gw_trg_typevalue_fk_insert exists');
```

## Full template for new table test

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

SELECT * FROM no_plan();

-- Check table
SELECT has_table('<table>'::name, 'Table <table> should exist');

-- Check columns
SELECT columns_are(
    '<table>',
    ARRAY['<col1>', '<col2>', ...],
    'Table <table> should have the correct columns'
);

-- Check primary key
SELECT col_is_pk('<table>', '<pk_col>', 'Column <pk_col> should be primary key');

-- Check column types
SELECT col_type_is('<table>', '<col>', '<type>', 'Column <col> should be <type>');
-- ...

-- Check default values
SELECT col_has_default('<table>', '<col>', 'Column <col> should have default value');
-- ...

-- Check foreign keys
SELECT has_fk('<table>', 'Table <table> should have foreign keys');
SELECT fk_ok('<table>', '<col>', '<ref_table>', '<ref_col>', 'FK <col> → <ref_table>.<ref_col>');
-- ...

-- Check indexes
SELECT has_index('<table>', '<index_name>', ARRAY['<col>'], 'Index on <col>');
-- ...

-- Check triggers
SELECT has_trigger('<table>', '<trigger_name>', 'Trigger <trigger_name> exists');
-- ...

SELECT * FROM finish();
ROLLBACK;
```

## Tips

- `columns_are` fails on ANY mismatch (extra, missing, or renamed column) — best migration regression guard
- Use `no_plan()` for per-table tests — column count varies widely
- Geometry type string must match exactly: `'geometry(linestring, 25831)'` not `'geometry(LineString, 25831)'` (lowercase)
- `SRID_VALUE` placeholder in geometry types gets replaced by `replace_vars.py` — use it for portability
- Add `has_trigger` for all triggers defined in `07_trg_schema_model.sql` for that table
