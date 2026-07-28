"""Internal PyQGIS process used by ``gw project create``.

This module intentionally imports QGIS and plugin modules only after the
headless application and ``qgis.utils.iface`` replacement are prepared.
"""

from __future__ import annotations

import importlib
import json
import os
from pathlib import Path
import sys
import tempfile


class _MessageBar:
    def pushMessage(self, *_args, **_kwargs):
        return None


class _Canvas:
    def setExtent(self, *_args, **_kwargs):
        return None

    def refresh(self):
        return None

    def snappingUtils(self):
        return None


class _Iface:
    def __init__(self):
        self._canvas = _Canvas()
        self._message_bar = _MessageBar()

    def mapCanvas(self):
        return self._canvas

    def messageBar(self):
        return self._message_bar

    def layerTreeView(self):
        return None

    def setActiveLayer(self, *_args, **_kwargs):
        return None

    def __getattr__(self, name):
        def _noop(*_args, **_kwargs):
            return None

        return _noop


def _load_options() -> tuple[dict, dict]:
    try:
        connection = json.loads(os.environ.pop("GW_QGS_CONNECTION"))
        options = json.loads(os.environ.pop("GW_QGS_OPTIONS"))
    except (KeyError, json.JSONDecodeError) as exc:
        raise RuntimeError("Missing or invalid QGIS runner configuration.") from exc
    return connection, options


def _plugin_module(plugin_root: Path, suffix: str):
    parent = str(plugin_root.parent)
    if parent not in sys.path:
        sys.path.insert(0, parent)
    return importlib.import_module(f"{plugin_root.name}.{suffix}")


def _resolve_layer_project_type(tools_db, schema: str, fallback: str) -> str:
    """Match Admin ``_get_layer_project_type``: use config_typevalue.idval."""
    rows = tools_db.get_rows(
        "SELECT id, idval FROM config_typevalue "
        "WHERE typevalue = 'project_type' ORDER BY id"
    )
    if not rows:
        return fallback
    if len(rows) == 1:
        return str(rows[0][1])
    # Prefer an exact idval match with ws/ud when several templates exist.
    for row in rows:
        if str(row[1]).lower() == str(fallback).lower():
            return str(row[1])
    return str(rows[0][1])


def main() -> int:
    connection, options = _load_options()
    plugin_root = Path(options["plugin_root"]).resolve()
    if not (plugin_root / "core" / "admin" / "gis_file_create.py").is_file():
        raise RuntimeError(
            f"Giswater plugin runtime not found at {plugin_root}. "
            "Run this command from a plugin checkout/installation."
        )

    from qgis.core import QgsApplication
    import qgis.utils

    prefix = os.environ.get("QGIS_PREFIX_PATH")
    if prefix:
        QgsApplication.setPrefixPath(prefix, True)

    app = QgsApplication([], False)
    app.initQgis()
    qgis_python = Path(QgsApplication.pkgDataPath()) / "python"
    if qgis_python.is_dir() and str(qgis_python) not in sys.path:
        sys.path.insert(0, str(qgis_python))
    iface = _Iface()
    qgis.utils.iface = iface

    dao = None
    try:
        global_vars = _plugin_module(plugin_root, "global_vars")
        lib_vars = _plugin_module(plugin_root, "libs.lib_vars")
        tools_db = _plugin_module(plugin_root, "libs.tools_db")
        tools_pgdao = _plugin_module(plugin_root, "libs.tools_pgdao")
        gis_module = _plugin_module(plugin_root, "core.admin.gis_file_create")

        user_dir = tempfile.mkdtemp(prefix="giswater-qgs-")
        global_vars.init_global(iface, iface.mapCanvas(), str(plugin_root), "giswater", user_dir)

        dao = tools_pgdao.GwPgDao()
        if connection.get("service"):
            dao.set_service(connection["service"], "prefer")
        else:
            dao.set_params(
                connection.get("host") or "localhost",
                connection.get("port") or "5432",
                connection.get("dbname") or "",
                connection.get("user") or "",
                connection.get("password") or "",
                "prefer",
            )
        if not dao.init_db():
            raise RuntimeError(f"Database connection failed: {dao.last_error}")

        schema = options["schema"]
        tools_db.dao = dao
        tools_db.current_user = connection.get("user") or ""
        tools_db.dao_db_credentials = {
            "host": connection.get("host") or "localhost",
            "port": connection.get("port") or "5432",
            "db": connection.get("dbname") or "",
            "user": connection.get("user") or "",
            "password": connection.get("password") or "",
            "service": connection.get("service") or "",
            "sslmode": "prefer",
            "schema": schema,
        }
        lib_vars.schema_name = schema
        lib_vars.project_vars["main_schema"] = schema
        lib_vars.project_vars["project_type"] = options["project_type"]
        lib_vars.project_vars["store_credentials"] = str(bool(options["export_passwd"]))
        tools_db.set_search_path(schema)

        srid = tools_db.get_srid("ve_node", schema)
        if not srid:
            raise RuntimeError(f"Could not resolve SRID from {schema}.ve_node.")

        # Admin passes config_typevalue.idval (usually "Basic"), not ws/ud.
        # gw_fct_get_project_layers filters sys_table.project_template by that id.
        layer_project_type = _resolve_layer_project_type(tools_db, schema, options["project_type"])

        generator = gis_module.GwGisFileCreate(str(plugin_root))
        ok, qgs_path = generator.gis_project_database(
            folder_path=options["output_dir"],
            filename=options["filename"],
            project_type=options["project_type"],
            schema=schema,
            export_passwd=options["export_passwd"],
            roletype="admin",
            layer_source={
                **tools_db.dao_db_credentials,
                "srid": str(srid),
            },
            layer_project_type=layer_project_type,
            is_cm=False,
            force_overwrite=options["force"],
            headless=True,
        )
        if not ok:
            raise RuntimeError(f"QGIS project could not be written: {qgs_path}")

        print(json.dumps({"ok": True, "schema": schema, "path": qgs_path}))
        return 0
    finally:
        if dao is not None:
            dao.close_db()
        app.exitQgis()


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:  # noqa: BLE001 - subprocess boundary
        print(str(exc), file=sys.stderr)
        raise SystemExit(1)
