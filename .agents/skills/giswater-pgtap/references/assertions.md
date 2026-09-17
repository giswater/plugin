# pgTAP Assertions Cheat-Sheet

## Most-used in giswater

### `is(got, expected, description)`
Equality check. Most common assertion.
```sql
SELECT is(
    (my_fn('{}')::JSON)->>'status',
    'Accepted',
    'fn returns status Accepted'
);
```

### `isnt(got, expected, description)`
Not-equal check.
```sql
SELECT isnt(result, NULL, 'result not null');
```

### `ok(condition, description)`
Pass if condition is true.
```sql
SELECT ok(
    (my_fn('{}')::JSON)->>'body' IS NOT NULL,
    'body exists in response'
);
```

### `lives_ok(sql_string, description)`
Pass if SQL executes without error.
```sql
SELECT lives_ok(
    'UPDATE arc SET label=''x'' WHERE arc_id=1;',
    'edit_user can update arc label'
);
```

### `throws_ok(sql_string, error_code, error_msg, description)`
Pass if SQL raises specific error.
```sql
SELECT throws_ok(
    'UPDATE arc SET arc_id=99 WHERE arc_id=1;',
    'P0001',
    'Function: [gw_trg_edit_controls] - CANNOT DO THIS OPERATION BECAUSE THE LOCK LEVEL IS SET TO 1. HINT: PLEASE REVIEW THE LOCK LEVEL',
    'cannot update locked arc'
);
```
Common error codes:
- `P0001` — `RAISE EXCEPTION` from PL/pgSQL
- `42501` — permission denied
- `23505` — unique violation
- `23503` — foreign key violation

### `throws_matching(sql_string, pattern, description)`
Pass if error message matches regex. Looser than `throws_ok`.
```sql
SELECT throws_matching(
    'DELETE FROM arc WHERE arc_id=1;',
    'LOCK LEVEL',
    'locked arc cannot be deleted'
);
```

### `set_eq(sql_query, array, description)`
Result set equals expected array.
```sql
SELECT set_eq(
    'SELECT state FROM arc WHERE arc_id=1',
    ARRAY['OPERATIVE'],
    'arc state is OPERATIVE'
);
```

### `results_eq(sql_query, expected_query, description)`
Two queries return same rows (order-sensitive).

### `is_empty(sql_query, description)`
Query returns no rows.
```sql
SELECT is_empty(
    'SELECT * FROM arc WHERE arc_id=-999',
    'test arc not present before insert'
);
```

## Uncommon but useful

| Assertion | Purpose |
|-----------|---------|
| `has_table(schema, table, desc)` | Table exists |
| `has_column(schema, table, col, desc)` | Column exists |
| `has_function(schema, fn, args, desc)` | Function exists |
| `has_trigger(schema, table, trigger, desc)` | Trigger exists |
| `col_type_is(schema, table, col, type, desc)` | Column type check |
| `col_not_null(schema, table, col, desc)` | NOT NULL constraint |
| `fk_ok(schema, table, col, ref_schema, ref_table, ref_col, desc)` | FK exists |
