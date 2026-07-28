"""
Coordinator that ensures language packages after a Giswater database connection.

Shows a non-dismissible progress dialog while downloads run; failures warn
without blocking project load.
"""

from __future__ import annotations

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import Qt
from qgis.PyQt.QtWidgets import QProgressDialog

from ...libs import tools_log, tools_qgis, tools_qt
from ..threads.i18n_provision_task import GwI18nProvisionTask
from .i18n_language_service import LocaleRequirement, ProvisionResult

_PROVISION_MESSAGE = (
    "We are downloading the necessary language files. Please do not close QGIS."
)

# Keep a module-level reference so GC does not cancel the task mid-flight.
_active_task: GwI18nProvisionTask | None = None
_active_dialog: QProgressDialog | None = None
_provision_started_for: set[str] = set()


def _connection_key() -> str:
    from ...libs import tools_db, lib_vars
    from qgis.PyQt.QtCore import QSettings

    creds = getattr(tools_db, "dao_db_credentials", None) or {}
    host = str(creds.get("host") or "")
    port = str(creds.get("port") or "")
    db = str(creds.get("db") or "")
    schema = str(getattr(lib_vars, "schema_name", "") or "")
    try:
        selected = str(QSettings().value("PostgreSQL/connections/selected") or "")
    except Exception:
        selected = ""
    return f"{selected}|{host}:{port}/{db}:{schema}"


def _close_progress_dialog() -> None:
    global _active_dialog
    dlg = _active_dialog
    _active_dialog = None
    if dlg is None:
        return
    try:
        dlg.close()
        dlg.deleteLater()
    except Exception:
        pass


def _show_progress_dialog() -> QProgressDialog:
    global _active_dialog
    _close_progress_dialog()
    message = tools_qt.tr(_PROVISION_MESSAGE)
    dlg = QProgressDialog(message, None, 0, 0)
    dlg.setWindowTitle(tools_qt.tr("Language files"))
    dlg.setCancelButton(None)
    dlg.setMinimumDuration(0)
    dlg.setWindowModality(Qt.WindowModality.ApplicationModal)
    dlg.setWindowFlags(
        dlg.windowFlags()
        | Qt.WindowType.WindowStaysOnTopHint
        | Qt.WindowType.CustomizeWindowHint
    )
    # Hide the close button where the platform allows it.
    dlg.setWindowFlag(Qt.WindowType.WindowCloseButtonHint, False)
    dlg.show()
    _active_dialog = dlg
    return dlg


def _on_provision_finished(result: ProvisionResult) -> None:
    global _active_task
    _close_progress_dialog()
    _active_task = None

    if not result.failed:
        return

    details = "; ".join(f"{locale}: {error}" for locale, error in result.failed)
    msg = "Automatic language provisioning failed: {0}"
    msg_params = (details or "unknown error",)
    tools_log.log_warning(msg, msg_params=msg_params)

    msg = "Could not download some language files. The project will continue to load. {0}"
    msg_params = (details or "unknown error",)
    tools_qgis.show_warning(msg, msg_params=msg_params, duration=20)


def ensure_language_packages_after_connection(
    *,
    force: bool = False,
    show_progress: bool = True,
) -> GwI18nProvisionTask | None:
    """
    Start a background task that downloads missing language packages.

    Safe to call after a successful DB connection. Returns the task when work
    may be needed, or None when skipped (already running / already done).
    """
    global _active_task

    if _active_task is not None:
        return _active_task

    key = _connection_key()
    if not force and key in _provision_started_for:
        return None

    requirements: list[LocaleRequirement] = []
    pending: list[LocaleRequirement] = []
    try:
        from . import _admin_catalog as admin_catalog
        from .i18n_language_service import (
            collect_locale_requirements,
            locale_likely_needs_download,
        )

        schema_rows = admin_catalog.fetch_schema_translation_info()
        multilang_langs = admin_catalog.fetch_multilang_operative_languages()
        requirements = collect_locale_requirements(schema_rows, multilang_langs)
        pending = [
            req
            for req in requirements
            if locale_likely_needs_download(req.locale, req.version)
        ]
    except Exception as exc:
        msg = "Language provision pre-check failed: {0}"
        msg_params = (exc,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return None

    if not pending:
        _provision_started_for.add(key)
        return None

    _provision_started_for.add(key)

    if show_progress:
        _show_progress_dialog()

    task = GwI18nProvisionTask(requirements=requirements, pending=pending)
    task.task_finished.connect(_on_provision_finished)
    _active_task = task
    QgsApplication.taskManager().addTask(task)
    return task
