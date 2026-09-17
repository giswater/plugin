"""``db init`` — install PostgreSQL extensions expected by the dbmodel."""

from __future__ import annotations

import argparse

from ..output import Out
from . import _helpers as h

# Order matters: postgis_raster needs postgis; pgrouting needs PostGIS.
# `public.raster` comes from postgis_raster (PostGIS 3+ splits it from core postgis).
_DEFAULT_EXTENSIONS = (
    "postgis",
    "postgis_topology",
    "postgis_raster",
    "tablefunc",
    "pgrouting",
    "unaccent",
)
_OPTIONAL_EXTENSIONS = ("pgtap",)

# Roles + database grants so a role_system member can create schemas afterwards.
_BOOTSTRAP_ROLES_SQL = """
DO $$
DECLARE
  v_role_exists boolean;
  v_rolename text;
BEGIN
  FOREACH v_rolename IN ARRAY ARRAY[
    'role_basic', 'role_om', 'role_edit', 'role_epa',
    'role_plan', 'role_admin', 'role_system', 'role_crm'
  ]
  LOOP
    SELECT EXISTS(SELECT 1 FROM pg_roles WHERE rolname = v_rolename) INTO v_role_exists;
    IF NOT v_role_exists THEN
      EXECUTE format(
        'CREATE ROLE %I NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION',
        v_rolename
      );
    END IF;
  END LOOP;

  GRANT role_basic TO role_om;
  GRANT role_om TO role_edit;
  GRANT role_edit TO role_epa;
  GRANT role_epa TO role_plan;
  GRANT role_plan TO role_admin;
  GRANT role_admin TO role_system;

  IF NOT pg_has_role(current_user, 'role_system', 'member') THEN
    EXECUTE 'GRANT role_system TO ' || quote_ident(current_user);
  END IF;

  EXECUTE format('GRANT CREATE ON DATABASE %I TO role_system', current_database());
  EXECUTE format('GRANT CONNECT, TEMPORARY ON DATABASE %I TO role_basic', current_database());
END $$;
"""


def run(args: argparse.Namespace, out: Out) -> int:
    exts = list(_DEFAULT_EXTENSIONS)
    if getattr(args, "with_pgtap", False):
        exts.extend(_OPTIONAL_EXTENSIONS)
    if getattr(args, "with_fdw", False):
        exts.append("postgres_fdw")

    statements = [f"CREATE EXTENSION IF NOT EXISTS {ext};" for ext in exts]
    optional = set(_OPTIONAL_EXTENSIONS)

    if args.check:
        out.result(
            {
                "ok": True,
                "mode": "check",
                "extensions": exts,
                "sql": [*statements, _BOOTSTRAP_ROLES_SQL.strip()],
            }
        )
        return 0

    conn = h.open_conn(args, out, require_superuser=True)
    ok = True
    last_err = ""
    executed: list[dict[str, str]] = []
    try:
        for ext, sql in zip(exts, statements):
            if conn.execute(sql):
                executed.append({"extension": ext, "ok": True})
            else:
                last_err = conn.last_error()
                executed.append({"extension": ext, "ok": False, "error": last_err})
                if ext in optional:
                    out.warn(f"optional extension skipped: {ext} ({last_err})")
                    continue
                ok = False
                if not getattr(args, "continue_on_error", False):
                    break
        if ok:
            if conn.execute(_BOOTSTRAP_ROLES_SQL):
                executed.append({"bootstrap": "roles", "ok": True})
            else:
                last_err = conn.last_error()
                executed.append({"bootstrap": "roles", "ok": False, "error": last_err})
                ok = False
        if ok:
            conn.commit()
        else:
            conn.rollback()
    finally:
        conn.close()

    out.result(
        {
            "ok": ok,
            "extensions": executed,
            "error": None if ok else last_err,
        }
    )
    return 0 if ok else 1
