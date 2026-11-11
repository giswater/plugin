/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = audit, public, pg_catalog;

CREATE TABLE IF NOT EXISTS audit.activity (
    id          bigserial PRIMARY KEY,
    tstamp      timestamptz NOT NULL DEFAULT now(),
    schema_name text        NOT NULL,
    insert_by   text        NOT NULL DEFAULT session_user,
    kind        text        NOT NULL,
    name        text        NOT NULL,
    status      text        NOT NULL DEFAULT '',
    body        jsonb       NOT NULL DEFAULT '{}'::jsonb
);
CREATE INDEX IF NOT EXISTS activity_schema_tstamp_idx
    ON audit.activity (schema_name, tstamp DESC);
CREATE INDEX IF NOT EXISTS activity_tstamp_idx
    ON audit.activity (tstamp);

CREATE TABLE IF NOT EXISTS audit.error (
    id            bigserial PRIMARY KEY,
    tstamp        timestamptz NOT NULL DEFAULT now(),
    schema_name   text        NOT NULL,
    insert_by     text        NOT NULL DEFAULT session_user,
    function_name text        NOT NULL,
    status        text        NOT NULL DEFAULT '',
    message       text        NOT NULL DEFAULT '',
    sqlstate      text        NOT NULL DEFAULT '',
    origin        text        NOT NULL DEFAULT 'call'
);
CREATE INDEX IF NOT EXISTS error_tstamp_idx ON audit.error (tstamp);

CREATE TABLE IF NOT EXISTS audit.activity_user (
    id              bigserial PRIMARY KEY,
    day             date        NOT NULL,
    schema_name     text        NOT NULL,
    insert_by       text        NOT NULL DEFAULT session_user,
    n_place         integer     NOT NULL DEFAULT 0,
    n_call          integer     NOT NULL DEFAULT 0,
    n_error         integer     NOT NULL DEFAULT 0,
    places          text[]      NOT NULL DEFAULT '{}',
    functions       jsonb       NOT NULL DEFAULT '{}'::jsonb,
    error_functions jsonb       NOT NULL DEFAULT '{}'::jsonb,
    first_tstamp    timestamptz NOT NULL DEFAULT now(),
    last_tstamp     timestamptz NOT NULL DEFAULT now(),
    UNIQUE (insert_by, schema_name, day)
);
CREATE INDEX IF NOT EXISTS activity_user_day_idx
    ON audit.activity_user (day DESC);
CREATE INDEX IF NOT EXISTS activity_user_insert_by_day_idx
    ON audit.activity_user (insert_by, day DESC);

-- Column INSERT only. insert_by and tstamp stay on DEFAULT (session_user, now()).
-- The schema is owned by role_system. Updates run as the installer, so a
-- non-superuser cannot REVOKE. The purge's search_path is the real guard.
DO $revoke_create$
BEGIN
    REVOKE CREATE ON SCHEMA audit FROM role_basic;
EXCEPTION
    WHEN insufficient_privilege THEN
        NULL;
END
$revoke_create$;
GRANT SELECT ON audit.activity, audit.error, audit.activity_user TO role_basic;
GRANT INSERT (schema_name, kind, name, status, body) ON audit.activity TO role_basic;
GRANT INSERT (schema_name, function_name, status, message, sqlstate, origin)
    ON audit.error TO role_basic;
GRANT USAGE, SELECT ON SEQUENCE audit.activity_id_seq, audit.error_id_seq TO role_basic;
GRANT DELETE ON audit.activity, audit.error TO role_system;

CREATE OR REPLACE FUNCTION audit.gw_fct_activity_purge()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
BEGIN
    DELETE FROM audit.activity WHERE tstamp < now() - interval '48 hours';
    DELETE FROM audit.error WHERE tstamp < now() - interval '7 days';
END;
$$;

ALTER FUNCTION audit.gw_fct_activity_purge() OWNER TO role_system;
REVOKE ALL ON FUNCTION audit.gw_fct_activity_purge() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION audit.gw_fct_activity_purge() TO role_basic;

CREATE OR REPLACE FUNCTION audit.gw_fct_activity_user_bump(
    p_schema_name text, p_kind text, p_name text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $$
DECLARE
    v_day date := (now() AT TIME ZONE 'UTC')::date;
BEGIN
    INSERT INTO audit.activity_user (
        day, schema_name, n_place, n_call, n_error, places, functions, error_functions
    ) VALUES (
        v_day,
        COALESCE(p_schema_name, ''),
        CASE WHEN p_kind = 'place' THEN 1 ELSE 0 END,
        CASE WHEN p_kind = 'call'  THEN 1 ELSE 0 END,
        CASE WHEN p_kind = 'error' THEN 1 ELSE 0 END,
        CASE WHEN p_kind = 'place' THEN ARRAY[p_name] ELSE ARRAY[]::text[] END,
        CASE WHEN p_kind = 'call'  THEN jsonb_build_object(p_name, 1) ELSE '{}'::jsonb END,
        CASE WHEN p_kind = 'error' THEN jsonb_build_object(p_name, 1) ELSE '{}'::jsonb END
    )
    ON CONFLICT (insert_by, schema_name, day) DO UPDATE SET
        n_place = audit.activity_user.n_place + EXCLUDED.n_place,
        n_call  = audit.activity_user.n_call  + EXCLUDED.n_call,
        n_error = audit.activity_user.n_error + EXCLUDED.n_error,
        places  = CASE WHEN p_kind = 'place' AND NOT (p_name = ANY (audit.activity_user.places))
                       THEN audit.activity_user.places || p_name
                       ELSE audit.activity_user.places END,
        functions = CASE WHEN p_kind = 'call' THEN
            COALESCE(audit.activity_user.functions, '{}'::jsonb) || jsonb_build_object(
                p_name, COALESCE((audit.activity_user.functions->>p_name)::int, 0) + 1)
            ELSE audit.activity_user.functions END,
        error_functions = CASE WHEN p_kind = 'error' THEN
            COALESCE(audit.activity_user.error_functions, '{}'::jsonb) || jsonb_build_object(
                p_name, COALESCE((audit.activity_user.error_functions->>p_name)::int, 0) + 1)
            ELSE audit.activity_user.error_functions END,
        last_tstamp = now();
END;
$$;

ALTER FUNCTION audit.gw_fct_activity_user_bump(text, text, text) OWNER TO role_system;
REVOKE ALL ON FUNCTION audit.gw_fct_activity_user_bump(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION audit.gw_fct_activity_user_bump(text, text, text) TO role_basic;
