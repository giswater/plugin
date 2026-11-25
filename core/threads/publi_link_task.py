"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from .task import GwTask
from ..utils import tools_gw
from ...libs import tools_db


class GwPubliLinkTask(GwTask):
    """Seed one source schema into publi and publish its tables."""

    def __init__(self, description, source_schema, prefix):
        super().__init__(description)
        self.source_schema = source_schema
        self.prefix = prefix
        self.seed_result = None
        self.sync_result = None
        self.error = None

    def run(self):
        super().run()
        try:
            self.seed_result = tools_gw.execute_procedure(
                "gw_fct_publi_seed_config",
                {"data": {"sourceSchema": self.source_schema, "prefix": self.prefix}},
                schema_name="publi",
                commit=True,
                aux_conn=self.aux_conn,
                is_thread=True,
                show_exception=False,
            )
            if not self._accepted(self.seed_result):
                self.error = self._error_text(self.seed_result) or "Seed failed"
                return False
            self.setProgress(8)
            if not self._ensure_sync_identity():
                return False
            targets = self._target_names()
            ok = 0
            failed = 0
            total = len(targets) or 1
            for index, target in enumerate(targets or [None]):
                if self.isCanceled():
                    self.error = "Cancelled"
                    return False
                result = self._sync_one(target, reset=index == 0)
                if not self._accepted(result):
                    self.sync_result = result
                    self.error = self._error_text(result) or "Sync failed"
                    return False
                data = ((result or {}).get("body") or {}).get("data") or {}
                ok += int(data.get("ok") or 0)
                failed += int(data.get("failed") or 0)
                self.setProgress(8 + int(92 * (index + 1) / total))
            self.sync_result = {
                "status": "Accepted",
                "body": {"data": {"ok": ok, "failed": failed}},
            }
            self.setProgress(100)
            return True
        except Exception as exc:
            self.exception = exc
            self.error = str(exc)
            return False

    def _target_names(self):
        rows = tools_db.get_rows(
            "SELECT target_name FROM publi.config_publi_table "
            "WHERE source_schema = %s AND active ORDER BY orderby NULLS LAST, id",
            params=(self.source_schema,),
            log_info=False,
            commit=False,
            aux_conn=self.aux_conn,
            is_thread=True,
        ) or []
        return [str(row[0]) for row in rows if row and row[0]]

    def _sync_one(self, target, reset):
        data = {"sourceSchema": self.source_schema, "resetSelectors": reset}
        if target:
            data["targets"] = [target]
        return tools_gw.execute_procedure(
            "gw_fct_publi_sync",
            {"data": data},
            schema_name="publi",
            commit=True,
            aux_conn=self.aux_conn,
            is_thread=True,
            show_exception=False,
        )

    def _ensure_sync_identity(self) -> bool:
        """ve_* filters on current_user. Sync must run as role_system, not the QGIS login."""
        row = tools_db.get_row(
            "SELECT r.rolname, p.prosecdef FROM pg_proc p "
            "JOIN pg_roles r ON r.oid = p.proowner "
            "WHERE p.oid = 'publi.gw_fct_publi_sync(json)'::regprocedure",
            log_info=False,
            commit=False,
            aux_conn=self.aux_conn,
            is_thread=True,
        )
        if row and row[0] == "role_system" and row[1]:
            return True
        sql = """
            DO $g$
            BEGIN
                ALTER FUNCTION publi.gw_fct_publi_sync(json) OWNER TO role_system;
                ALTER FUNCTION publi.gw_fct_publi_sync(json) SECURITY DEFINER;
                ALTER FUNCTION publi.gw_fct_publi_sync(json) SET search_path = publi, public;
                REVOKE ALL ON FUNCTION publi.gw_fct_publi_sync(json) FROM PUBLIC;
                GRANT EXECUTE ON FUNCTION publi.gw_fct_publi_sync(json) TO role_system;
                IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_admin') THEN
                    GRANT EXECUTE ON FUNCTION publi.gw_fct_publi_sync(json) TO role_admin;
                END IF;
            END
            $g$
        """
        ok = tools_db.execute_sql(
            sql, commit=True, aux_conn=self.aux_conn, is_thread=True, show_exception=False,
        )
        if not ok:
            self.error = "Sync must run as role_system. Connect as a superuser and integrate again."
            return False
        return True

    @staticmethod
    def _accepted(result) -> bool:
        return isinstance(result, dict) and result.get("status") == "Accepted"

    @staticmethod
    def _error_text(result) -> str:
        if not isinstance(result, dict):
            return ""
        return str(result.get("NOSQLERR") or result.get("message") or "")
