"""
Background load of admin-dialog metadata (schemas, versions, aux flags).
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Optional

import psycopg2
from qgis.core import QgsTask

from ..admin._admin_catalog import (
    fetch_aux_schema_flags,
    fetch_sys_version_schemas,
    make_psycopg2_fetcher,
)
from ...libs import tools_db, tools_log


_READ_EXTENSIONS = (
    "postgis",
    "pgrouting",
    "postgis_raster",
    "tablefunc",
    "unaccent",
    "fuzzystrmatch",
    "intarray",
)

# Public alias for admin_btn sync loader
READ_EXTENSIONS = _READ_EXTENSIONS


@dataclass
class AdminLoadResult:
    ok: bool = False
    error: str = ""
    connection_name: str = ""
    sys_version_schemas: list[tuple[str, str]] = field(default_factory=list)
    aux_flags: dict[str, bool] = field(default_factory=lambda: {"am": False, "cm": False, "audit": False})
    pg_version: Optional[str] = None
    postgis_version: Optional[str] = None
    pgrouting_version: Optional[str] = None
    extensions_present: dict[str, bool] = field(default_factory=dict)


class GwAdminLoadTask(QgsTask):
    """Fetch admin catalog metadata without blocking the QGIS UI thread."""

    def __init__(self, description: str, credentials: dict, connection_name: str):
        super().__init__(description, QgsTask.Flag.CanCancel)
        self.credentials = dict(credentials)
        self.connection_name = connection_name
        self.result = AdminLoadResult(connection_name=connection_name)
        self._admin_ref: Any = None

    def bind_admin(self, admin_ref: Any) -> None:
        self._admin_ref = admin_ref

    def run(self) -> bool:
        if self.isCanceled():
            return False

        timeout = tools_db.get_db_connect_timeout()
        conn_string = tools_db._credentials_conn_string(self.credentials, connect_timeout=timeout)
        conn = None
        try:
            conn = psycopg2.connect(conn_string)
            if self.isCanceled():
                return False

            fetcher = make_psycopg2_fetcher(conn)

            self.result.sys_version_schemas = fetch_sys_version_schemas(fetcher=fetcher)
            if self.isCanceled():
                return False

            self.result.aux_flags = fetch_aux_schema_flags(fetcher=fetcher)
            if self.isCanceled():
                return False

            row = fetcher("SELECT current_setting('server_version_num')", None)
            if row:
                self.result.pg_version = str(row[0][0])

            ext_rows = fetcher(
                "SELECT extname FROM pg_extension WHERE extname = ANY(%s)",
                [list(_READ_EXTENSIONS)],
            )
            installed = {str(r[0]) for r in ext_rows} if ext_rows else set()
            self.result.extensions_present = {name: name in installed for name in _READ_EXTENSIONS}

            if self.isCanceled():
                return False

            if self.result.extensions_present.get("postgis"):
                row = fetcher("SELECT postgis_lib_version()", None)
                if row:
                    self.result.postgis_version = str(row[0][0])

            if self.result.extensions_present.get("pgrouting"):
                row = fetcher("SELECT pgr_version()", None)
                if row:
                    self.result.pgrouting_version = str(row[0][0])

            if self.isCanceled():
                return False

            self.result.ok = True
            return True
        except Exception as e:
            self.result.error = str(e)
            tools_log.log_warning(f"GwAdminLoadTask: {e}")
            return False
        finally:
            if conn is not None:
                try:
                    conn.close()
                except Exception:
                    pass

    def finished(self, task_result: bool) -> None:
        if self._admin_ref is None:
            return
        try:
            self._admin_ref._on_admin_load_finished(self.result, task_result)
        except Exception as e:
            tools_log.log_warning(f"GwAdminLoadTask finished handler: {e}")
            self._admin_ref._admin_loading = False
