# Security / RLS Test Patterns

## Role switching pattern

```sql
-- Switch role mid-transaction
SET ROLE edit_user;

SELECT lives_ok(
    'UPDATE arc SET label=''test'' WHERE arc_id=1;',
    'edit_user can update arc label'
);

-- Switch to another role
SET ROLE admin_user;

SELECT lives_ok(
    'UPDATE arc SET arc_id=2 WHERE arc_id=1;',
    'admin_user can update pk'
);
```

## Permission denied test

```sql
SELECT throws_ok(
    'UPDATE table SET col=val WHERE id=1;',
    '42501',
    'permission denied for table table',
    'role_edit cannot update restricted column'
);
```

## Lock-level trigger test

```sql
SELECT throws_ok(
    'UPDATE drainzone set name=''zone'' WHERE drainzone_id=-997;',
    'P0001',
    'Function: [gw_trg_edit_controls] - CANNOT DO THIS OPERATION BECAUSE THE LOCK LEVEL IS SET TO 1. HINT: PLEASE REVIEW THE LOCK LEVEL',
    'Normal user can not update when lock_level is 1'
);
```

## Full security test template

Pattern from `test_drainzone_lock_level.sql`:

```sql
BEGIN;
SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT * FROM no_plan();  -- count varies per role combo

-- ===========================
-- PREPARE DATA
-- ===========================
INSERT INTO mytable (id, name, lock_level) VALUES (-999, 'test_null', NULL);
INSERT INTO mytable (id, name, lock_level) VALUES (-998, 'test_0', 0);
INSERT INTO mytable (id, name, lock_level) VALUES (-997, 'test_1', 1);

-- Grant/revoke column-level permissions as needed
REVOKE UPDATE ON TABLE mytable FROM role_edit;
GRANT UPDATE (id, name) ON mytable TO role_edit;
GRANT UPDATE (lock_level) ON mytable TO role_admin;

CREATE USER admin_user;  GRANT role_admin TO admin_user;
CREATE USER edit_user;   GRANT role_edit  TO edit_user;

-- per-user config if needed
INSERT INTO config_param_user ("parameter", value, cur_user)
    VALUES ('edit_disable_locklevel', '{"update":"false","delete":"false"}', 'edit_user');

-- ===========================
-- TESTS AS edit_user
-- ===========================
SET ROLE edit_user;

SELECT lives_ok(
    'UPDATE mytable SET name=''x'' WHERE id=-999;',
    'edit_user can update when lock_level is NULL'
);

SELECT throws_ok(
    'UPDATE mytable SET name=''x'' WHERE id=-997;',
    'P0001',
    'Function: [gw_trg_edit_controls] - CANNOT DO THIS OPERATION BECAUSE THE LOCK LEVEL IS SET TO 1. HINT: PLEASE REVIEW THE LOCK LEVEL',
    'edit_user cannot update when lock_level=1'
);

-- ===========================
-- TESTS AS admin_user
-- ===========================
SET ROLE admin_user;

SELECT lives_ok(
    'UPDATE mytable SET lock_level=0 WHERE id=-997;',
    'admin_user can change lock_level'
);

SELECT * FROM finish();
ROLLBACK;
```

## Key rules for security tests

1. Use negative IDs (`-999`, `-998`, ...) for fixture rows — never clash with real data
2. `no_plan()` preferred — role-switching loops make count hard to predict
3. Always recreate rows deleted by earlier roles in same test (see security test example)
4. `ROLLBACK` cleans up users/grants — no manual cleanup needed
5. Order: setup → role_edit tests → role_admin tests → finish
