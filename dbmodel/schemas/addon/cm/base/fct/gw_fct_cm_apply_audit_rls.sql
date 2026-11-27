/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: xxxx

CREATE OR REPLACE FUNCTION cm.apply_cm_audit_rls(
  role_org_map jsonb  -- e.g. '[{"role":"role_acciona","org":3},{"role":"role_miya","org":2}]'
) RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = cm, public
AS $$
DECLARE
  r jsonb;
  role_name text;
  org_id integer;
  role_csv text;
  v_error_context text;
  predicate_log text;
  predicate_err text;
  v_prev_search_path text;
BEGIN
  -- Save current search_path and switch to cm (transaction-local)
  v_prev_search_path := current_setting('search_path');
  PERFORM set_config('search_path', 'cm,public', true);
  -- Ensure audit schema exists (idempotent)
  PERFORM 1 FROM pg_namespace WHERE nspname = 'audit';
  IF NOT FOUND THEN
    EXECUTE 'CREATE SCHEMA audit';
  END IF;

  -- Grant usage on audit schema to mapped roles
  SELECT string_agg(quote_ident((e->>'role')), ', ')
    INTO role_csv
    FROM jsonb_array_elements(role_org_map) e;
  IF role_csv IS NOT NULL THEN
    EXECUTE format('GRANT USAGE ON SCHEMA audit TO %s', role_csv);
  END IF;

  -- Base audit tables must exist; enable/force RLS and restrict SELECT
  EXECUTE 'ALTER TABLE audit.cm_log ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE audit.cm_log FORCE  ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE audit.cm_log_error ENABLE ROW LEVEL SECURITY';
  EXECUTE 'ALTER TABLE audit.cm_log_error FORCE  ROW LEVEL SECURITY';

  EXECUTE 'REVOKE ALL ON audit.cm_log FROM PUBLIC';
  EXECUTE 'REVOKE ALL ON audit.cm_log_error FROM PUBLIC';

  -- Admins can read everything from base audit tables
  EXECUTE 'DROP POLICY IF EXISTS audit_admin_sel_log ON audit.cm_log';
  EXECUTE 'DROP POLICY IF EXISTS audit_admin_sel_err ON audit.cm_log_error';
  EXECUTE 'CREATE POLICY audit_admin_sel_log ON audit.cm_log FOR SELECT TO role_addon_cm_admin USING (true)';
  EXECUTE 'CREATE POLICY audit_admin_sel_err ON audit.cm_log_error FOR SELECT TO role_addon_cm_admin USING (true)';

  -- Grant SELECT on base log table to mapped roles; RLS will limit rows by org
  FOR r IN SELECT * FROM jsonb_array_elements(role_org_map) LOOP
    role_name := r->>'role';
    EXECUTE format('GRANT SELECT ON audit.cm_log TO %I', role_name);
  END LOOP;

  -- Allow INSERTs for mapped roles
  FOR r IN SELECT * FROM jsonb_array_elements(role_org_map) LOOP
    role_name := r->>'role';
    EXECUTE format('GRANT INSERT ON audit.cm_log TO %I', role_name);

    EXECUTE format('DROP POLICY IF EXISTS log_ins_%I ON audit.cm_log', role_name);
    EXECUTE format($p$ CREATE POLICY log_ins_%1$I ON audit.cm_log
                     FOR INSERT TO %1$I
                     WITH CHECK (true) $p$, role_name);
  END LOOP;

  -- RLS: restrict SELECT on audit.cm_log to caller's organization (derived from usernames)
  EXECUTE 'DROP POLICY IF EXISTS log_sel_by_org ON audit.cm_log';
  EXECUTE $sql$ CREATE POLICY log_sel_by_org ON audit.cm_log
    FOR SELECT USING (
      cm.user_org_id(current_user) = cm.user_org_id(audit.cm_log.insert_by)
    ) $sql$;

  -- Restore previous search_path before returning
  PERFORM set_config('search_path', v_prev_search_path, true);
  RETURN json_build_object('status','ok');
EXCEPTION WHEN OTHERS THEN
  GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
  -- Ensure restoration on error
  PERFORM set_config('search_path', v_prev_search_path, true);
  RETURN json_build_object('status','error','sqlstate',SQLSTATE,'message',SQLERRM,'context',v_error_context);
END;
$$;
