# pgTAP Full Function Reference

Source: https://pgtap.org/documentation.html

## Plan Functions

```sql
plan(integer)                          -- declare N expected tests; fails if count wrong
no_plan()                              -- run without declaring count (SETOF text)
finish()                               -- conclude testing, output diagnostics
finish(boolean)                        -- conclude + throw exception if any test failed
```

## Basic Value Assertions

```sql
ok(boolean, text)                      -- pass if boolean is true
ok(boolean)
is(anyelement, anyelement, text)       -- equality (IS NOT DISTINCT FROM; NULL-safe)
is(anyelement, anyelement)
isnt(anyelement, anyelement, text)     -- inequality (IS DISTINCT FROM)
isnt(anyelement, anyelement)
pass(text)                             -- unconditional pass
fail(text)                             -- unconditional fail
```

## Pattern Matching

```sql
matches(text, text, text)              -- regex match
imatches(text, text, text)             -- case-insensitive regex
doesnt_match(text, text, text)         -- regex non-match
doesnt_imatch(text, text, text)        -- case-insensitive regex non-match
alike(text, text, text)                -- SQL LIKE match
ialike(text, text, text)               -- case-insensitive LIKE
unalike(text, text, text)              -- LIKE non-match
unialike(text, text, text)             -- case-insensitive LIKE non-match
```

## Comparisons

```sql
cmp_ok(anyelement, text, anyelement, text)  -- compare with operator: '<', '>', '>=', etc.
isa_ok(anyelement, regtype, text)           -- check value is of given type
```

## Exception Assertions

```sql
throws_ok(text, text, text, text)      -- throws error with (sql, code, msg, desc)
throws_ok(text, text, text)            -- (sql, code_or_msg, desc)
throws_ok(text, text)                  -- (sql, desc) — any exception
throws_ok(text)                        -- sql throws any exception
throws_like(text, text, text)          -- exception msg matches LIKE pattern
throws_ilike(text, text, text)         -- case-insensitive LIKE on exception msg
throws_matching(text, text, text)      -- exception msg matches regex
throws_imatching(text, text, text)     -- case-insensitive regex on exception msg
lives_ok(text, text)                   -- sql executes without exception
lives_ok(text)
performs_ok(text, numeric, text)       -- executes within N milliseconds
performs_within(text, numeric, numeric, integer, text)  -- avg within variance over iterations
```

> **throws_ok error codes** — `'P0001'` = RAISE EXCEPTION, `'42501'` = permission denied,
> `'23505'` = unique violation, `'23503'` = FK violation, `'42703'` = undefined column

## Result Set Assertions

```sql
-- Order-sensitive equality
results_eq(text, text, text)           -- two SQL queries same rows same order
results_eq(text, anyarray, text)       -- SQL vs array
results_eq(refcursor, refcursor, text) -- cursor vs cursor
results_ne(...)                        -- inverse of results_eq variants

-- Order-insensitive, ignores duplicates
set_eq(text, text, text)               -- same rows regardless of order/dupes
set_eq(text, anyarray, text)
set_ne(...)                            -- inverse
set_has(text, text, text)              -- first contains all rows of second
set_hasnt(text, text, text)            -- first does not contain second

-- Order-insensitive, counts duplicates
bag_eq(text, text, text)               -- same rows+counts regardless of order
bag_eq(text, anyarray, text)
bag_ne(...)
bag_has(text, text, text)
bag_hasnt(text, text, text)

-- Emptiness
is_empty(text, text)                   -- query returns no rows
isnt_empty(text, text)                 -- query returns at least one row

-- Single row
row_eq(text, anyelement, text)         -- single-row query matches composite value
```

## Schema Object Inventory (exhaustiveness checks)

```sql
schemas_are(text[], text)              -- DB has exactly these schemas
tables_are(text, text[], text)         -- schema has exactly these tables
views_are(text, text[], text)          -- schema has exactly these views
materialized_views_are(text, text[], text)
sequences_are(text, text[], text)
columns_are(text, text, text[], text)  -- table has exactly these columns (schema, table, cols[])
columns_are(text, text[], text)        -- without schema
indexes_are(text, text, text[], text)  -- table has exactly these indexes
triggers_are(text, text, text[], text) -- table has exactly these triggers
functions_are(text, text[], text)      -- schema has exactly these functions
roles_are(text[], text)
extensions_are(text[], text)
types_are(text, text[], text)
enums_are(text, text[], text)
```

## Schema Object Existence

```sql
-- Tables / Views
has_table(text, text, text)            -- (schema, table, desc)
has_table(text, text)                  -- (table, desc) or (schema, table)
has_table(text)                        -- (table)
hasnt_table(...)                       -- inverse

has_view(text, text, text)
has_view(text, text)
has_view(text)
hasnt_view(...)

has_materialized_view(text, text, text)
hasnt_materialized_view(...)

has_sequence(text, text, text)
hasnt_sequence(...)

has_schema(text, text)
hasnt_schema(...)

-- Columns
has_column(text, text, text, text)     -- (schema, table, col, desc)
has_column(text, text, text)           -- (table, col, desc)
has_column(text, text)                 -- (table, col)
hasnt_column(...)

-- Functions
has_function(text, text[], text, text) -- (schema, fn, args[], desc)
has_function(text, text[], text)
has_function(text, text)
has_function(text)
hasnt_function(...)

-- Indexes
has_index(text, text, text, text)      -- (schema, table, index, desc)
has_index(text, text, text)            -- (table, index, desc) or (table, index, cols[])
has_index(text, text)
hasnt_index(...)

-- Triggers
has_trigger(text, text, text, text)    -- (schema, table, trigger, desc)
has_trigger(text, text, text)          -- (table, trigger, desc)
has_trigger(text, text)
hasnt_trigger(...)

-- Types / Enums / Domains
has_type(text, text, text)
hasnt_type(...)
has_enum(text, text, text)
hasnt_enum(...)
has_domain(text, text, text)
hasnt_domain(...)

-- Roles / Users
has_role(text, text)
hasnt_role(...)
has_user(text, text)
hasnt_user(...)

-- Extensions
has_extension(text, text, text)        -- (schema, ext, desc)
has_extension(text, text)
has_extension(text)
hasnt_extension(...)
```

## Column-Specific Assertions

```sql
col_not_null(text, text, text)         -- (table, col, desc) — has NOT NULL
col_not_null(text, text, text, text)   -- (schema, table, col, desc)
col_is_null(text, text, text)          -- column allows NULL

col_has_default(text, text, text)      -- column has a default value
col_has_default(text, text, text, text)-- with schema
col_hasnt_default(...)                 -- inverse

col_type_is(text, text, text, text)    -- (table, col, type, desc)
col_type_is(text, text, text, text, text) -- with schema
col_default_is(text, text, text, text) -- column default equals value

col_is_pk(text, text[], text, text)    -- composite PK (schema, table, cols[], desc)
col_is_pk(text, text, text, text)      -- (schema, table, col, desc)
col_is_pk(text, text, text)            -- (table, col, desc)
col_isnt_pk(...)

col_is_fk(text, text, text, text)      -- (schema, table, col, desc)
col_is_fk(text, text, text)
col_isnt_fk(...)

col_is_unique(text, text, text, text)  -- (schema, table, col, desc)
col_is_unique(text, text, text)
col_has_check(text, text, text, text)  -- (schema, table, col, desc)
col_has_check(text, text, text)

has_pk(text, text[], text, text)       -- table has PK on cols[]
has_pk(text, text, text)               -- table has any PK (schema, table, desc)
has_pk(text, text)
has_pk(text)
hasnt_pk(...)

has_fk(text, text[], text[], text, text) -- FK from cols[] to ref_table cols[]
has_fk(text, text, text)               -- table has any FK
has_fk(text, text)
hasnt_fk(...)

fk_ok(text, text[], text, text[], text) -- (table, cols[], ref_table, ref_cols[], desc)
fk_ok(text, text[], text, text[])       -- without desc

has_unique(text, text[], text, text)   -- table has unique constraint on cols[]
has_check(text, text[], text, text)    -- table has check constraint on cols[]

-- Index properties
index_is_unique(text, text, text, text)  -- (schema, table, index, desc)
index_is_unique(text, text, text)
index_is_primary(text, text, text)
index_is_partial(text, text, text)
index_is_type(text, text, text, text, text)  -- (schema, table, index, type, desc)
is_indexed(text, text, text, text)       -- (schema, table, col, desc) — column is indexed
is_clustered(text, text, text)           -- table is clustered on index
```

## Function-Specific Assertions

```sql
can(text, text[], text)                -- function is executable (schema, fn, desc)
function_lang_is(text, text[], text, text)  -- (schema, fn, args[], lang, desc)
function_returns(text, text[], text, text)  -- (schema, fn, args[], type, desc)
is_definer(text, text[], text)         -- has SECURITY DEFINER
isnt_definer(...)
is_strict(text, text[], text)          -- has STRICT
isnt_strict(...)
is_aggregate(text, text[], text)       -- is aggregate function
is_window(text, text[], text)          -- is window function
is_procedure(text, text[], text)       -- is procedure
volatility_is(text, text[], text, text) -- (schema, fn, args[], level, desc)
                                        -- level: 'volatile', 'stable', 'immutable'
trigger_is(text, text, text, text[], text)  -- (schema, table, trigger, fns[], desc)
```

## Privilege Assertions

```sql
table_privs_are(text, text, text, text[], text)    -- (schema, table, role, privs[], desc)
column_privs_are(text, text, text, text, text[], text) -- (schema, table, col, role, privs[], desc)
any_column_privs_are(text, text, text, text[], text)
schema_privs_are(text, text, text[], text)          -- (schema, role, privs[], desc)
database_privs_are(text, text[], text)              -- (db, privs[], desc)
function_privs_are(text, text, text, text[], text)
sequence_privs_are(text, text, text, text[], text)

-- Privs values: 'SELECT', 'INSERT', 'UPDATE', 'DELETE', 'TRUNCATE', 'REFERENCES', 'TRIGGER',
--               'USAGE', 'EXECUTE', 'CREATE', 'CONNECT', 'TEMPORARY'

-- RLS policies
policies_are(text, text, text[], text)              -- table has exactly these policies
policy_roles_are(text, text, text, text[], text)    -- policy applies to roles
policy_cmd_is(text, text, text, text, text)         -- policy applies to command
```

## Ownership Assertions

```sql
table_owner_is(text, text, text, text)    -- (schema, table, role, desc)
table_owner_is(text, text, text)
view_owner_is(text, text, text)
schema_owner_is(text, text, text)
function_owner_is(text, text[], text, text) -- (schema, fn, args[], role, desc)
sequence_owner_is(text, text, text)
type_owner_is(text, text, text)
```

## Role Assertions

```sql
is_superuser(text, text)               -- role is superuser
isnt_superuser(text, text)
is_member_of(text, text[], text)       -- role is member of groups[]
isnt_member_of(text, text[], text)
```

## Inheritance

```sql
has_inherited_tables(text, text, text) -- table has child tables
is_ancestor_of(text, text, text)       -- first is ancestor of second
is_descendent_of(text, text, text)
is_partitioned(text, text, text)
is_partition_of(text, text, text)
```

## Diagnostic & Utility

```sql
diag(text)                             -- output # comment in TAP stream (debug info)
skip(text, integer)                    -- skip N tests with reason
todo(text, integer)                    -- mark N tests as TODO (won't fail suite)
todo_start(text)                       -- begin TODO block
todo_end()                             -- end TODO block
pgtap_version()                        -- returns pgTAP version string
runtests()                             -- run all test functions in DB
```

## Notes

- All description args are optional — omit for auto-generated description
- Schema arg is optional — when omitted, uses `search_path`
- `is` uses `IS NOT DISTINCT FROM` — handles NULL correctly (`is(NULL, NULL)` passes)
- `throws_ok` error code: 5-char SQLSTATE, e.g. `'P0001'`, `'42501'`, `'23505'`
- `results_eq` is order-sensitive; `set_eq` is not
- `bag_eq` is like `set_eq` but counts duplicates
