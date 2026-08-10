"""
Asynchronous task: create multilang schema and seed baseline rows,
or seed/delete translation rows for a single language without
recreating the schema.
"""

from __future__ import annotations

import json
from typing import Any, Callable, Literal

from qgis.PyQt.QtCore import pyqtSignal

from ...giswater_admin.adapters.psycopg2_adapter import Psycopg2Adapter
from ...giswater_admin.engine import (
    BuildParams,
    BuildResult,
    CancelToken,
    Manifest,
    SchemaBuilder,
)
from ...giswater_admin.log_format import (
    LogStyle,
    format_build_header,
    format_done,
    format_failure,
    format_file,
    format_progress_status,
)
from ...libs import lib_vars, tools_log, tools_qt
from ..admin._admin_catalog import make_psycopg2_fetcher
from ..admin.i18n.multilang_seed_sql import (
    SEED_LANGUAGE_FOLDER,
    SEED_LANGUAGE_ID,
    TRANSLATABLE_PROJECT_TYPES,
    compute_baseline_fingerprint,
    delete_language_seed_sql,
    delete_project_type_seed_sql,
    ensure_cat_language_sql,
    fetch_seeded_project_types_from_multilang,
    invalidate_baseline_fingerprint_cache,
    language_baselines_exist,
    multilang_user_param_provision_sql,
    multilang_views_provision_sql,
    multilang_json_error_message,
    run_multilang_function_sql,
    normalize_language_folder,
    normalize_language_id,
    seed_sql_for_project_types,
    translatable_project_types_with_baseline,
)
from .schema_builder_task import load_kind_manifest
from .task import GwTask

LanguageAction = Literal["seed", "delete"]


class GwMultilangSchemaTask(GwTask):
    """Build multilang schema, then populate translation tables from baselines.

    When ``language_action`` is set, skips SchemaBuilder and only seeds
    or deletes rows for the given ``locale``.
    """

    task_finished = pyqtSignal(bool, str, str)  # ok, locale, error

    def __init__(
        self,
        admin: Any,
        params: BuildParams,
        *,
        description: str = "Create multilang schema",
        timer: Any = None,
        on_done: Callable[[BuildResult], None] | None = None,
        manage_schemas_dlg: Any = None,
        language_action: LanguageAction | None = None,
        locale: str | None = None,
    ) -> None:
        self.language_action = language_action
        self._language_only = language_action is not None

        if self._language_only:
            lang_folder = normalize_language_folder(locale)
            if description == "Create multilang schema":
                if language_action == "delete":
                    description = f"Delete multilang translations for {lang_folder}"
                else:
                    description = f"Seed multilang translations for {lang_folder}"
        super().__init__(description)
        self.admin = admin
        self.params = params
        self.timer = timer
        self.on_done = on_done
        self.manage_schemas_dlg = manage_schemas_dlg
        self.locale = locale or ""
        self.lang_id = normalize_language_id(locale) if self._language_only else SEED_LANGUAGE_ID
        self.lang_folder = (
            normalize_language_folder(locale) if self._language_only else SEED_LANGUAGE_FOLDER
        )
        self.error: str | None = None

        if params.cancel_token is None:
            params.cancel_token = CancelToken()

        self.manifest: Manifest | None = None
        if not self._language_only:
            self.manifest = load_kind_manifest(admin.plugin_dir, "multilang")
        self.result: BuildResult | None = None
        self.seeded_project_types: list[str] = []
        self._last_progress_label = ""
        self._log_style = LogStyle(
            sql_root=params.sql_root or "",
            show_timing_ms=False,
        )
        self._adapter: Psycopg2Adapter | None = None

    def _set_task_error(self, message: str) -> None:
        text = str(message or "").strip() or "Multilang schema task failed."
        self.error = text
        lib_vars.session_vars["last_error"] = text
        lib_vars.session_vars["last_error_msg"] = text
        tools_log.log_warning("Multilang schema task", parameter=text)

    def _execute_sql(self, sql: str) -> bool:
        if self._adapter is None:
            msg = "Database connection is not available."
            self._set_task_error(msg)
            return False
        if not self._adapter.execute(sql):
            msg = "SQL execution failed."
            self._set_task_error(self._adapter.last_error() or msg)
            return False
        return True

    def run(self) -> bool:
        super().run()
        lib_vars.session_vars["last_error"] = None
        lib_vars.session_vars["last_error_msg"] = None
        self.error = None

        if self.aux_conn is None or isinstance(self.aux_conn, dict):
            msg = "Could not open database connection for multilang task."
            self._set_task_error(msg)
            return False

        self._adapter = Psycopg2Adapter(self.aux_conn)

        try:
            if self.language_action == "delete":
                return self._run_delete_language()
            if self._language_only:
                return self._run_seed_language_only()
            return self._run_create_schema()
        except Exception as exc:  # noqa: BLE001
            self.exception = exc
            self._set_task_error(str(exc))
            if self._adapter is not None:
                self._adapter.rollback()
            return False

    def _clear_language_rows(self, *, drop_catalog: bool) -> bool:
        for sql in delete_language_seed_sql(self.locale or self.lang_id, drop_catalog=drop_catalog):
            if self.isCanceled():
                return False
            if not self._execute_sql(sql):
                return False
        return True

    def _run_delete_language(self) -> bool:
        """Delete all multilang rows (and cat_language) for one locale."""
        self.setProgress(10)
        if not self._clear_language_rows(drop_catalog=True):
            if self._adapter is not None:
                self._adapter.rollback()
            return False
        if self._adapter is not None:
            self._adapter.commit()
        self.setProgress(100)
        msg = "Multilang language delete completed for {0}."
        msg_params = (self.lang_id,)
        tools_log.log_info(msg, msg_params=msg_params)
        return True

    def _run_seed_language_only(self) -> bool:
        """Insert/update baseline rows for one locale; do not create/upgrade schema."""
        if not self._provision_network_user_param(enable=True):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        sql_root = self.params.sql_root or ""
        if not language_baselines_exist(sql_root, self.locale or self.lang_folder):
            msg = "No local i18n baseline SQL found for ({0}). Download plugin language files first."
            msg_params = (self.lang_folder,)
            self._set_task_error(tools_qt.tr(msg, list_params=msg_params))
            return False

        if not self._execute_sql(ensure_cat_language_sql(self.locale or self.lang_id)):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        target_types = self._translatable_project_types(sql_root)
        if not target_types:
            msg = (
                "Multilang seed: no project types with bundled baselines detected; "
                "only cat_language ensured for {0}."
            )
            msg_params = (self.lang_id,)
            tools_log.log_info(msg, msg_params=msg_params)
            if self._adapter is not None:
                self._adapter.commit()
            return True

        if not self._seed_project_types(target_types, lang=self.lang_id, progress_base=0):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        if self._adapter is not None:
            self._adapter.commit()
        return True

    def _run_create_schema(self) -> bool:
        sql_root = self.params.sql_root or ""
        tools_log.log_info(
            format_build_header(
                self.manifest.kind,
                self.params.schema_name,
                self.params.profile,
                self.params.plugin_version,
                style=self._log_style,
            )
        )

        builder = SchemaBuilder(
            self._adapter,
            self.manifest,
            self.params,
            progress_cb=self._progress_cb_build,
            commit_each_file=bool(getattr(self.admin, "dev_commit", False)),
        )
        try:
            self.result = builder.run()
        except Exception as exc:  # noqa: BLE001
            self.exception = exc
            self._set_task_error(str(exc))
            msg = "Multilang SchemaBuilder exception: {0}"
            msg_params = (str(exc),)
            tools_log.log_info(msg, msg_params=msg_params)
            return False

        if self.result.cancelled or not self.result.ok:
            self._record_failure()
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        target_types = self._translatable_project_types(sql_root)
        if not target_types:
            msg = "Multilang seed: no project types with bundled baselines detected; skipping import."
            tools_log.log_info(msg)
            self._finalize_addparam([])
            if not self._provision_network_user_param(enable=True):
                if self._adapter is not None:
                    self._adapter.rollback()
                return False
            if not self._provision_network_views(enable=True):
                if self._adapter is not None:
                    self._adapter.rollback()
                return False
            if self._adapter is not None:
                self._adapter.commit()
            return True

        if not self._ensure_cat_language():
            return False

        fetcher = make_psycopg2_fetcher(self.aux_conn)
        if not self._remove_orphaned_project_type_rows(fetcher, set(target_types)):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        if not self._seed_project_types(target_types, lang=SEED_LANGUAGE_ID, progress_base=80):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        if not self._finalize_addparam(target_types):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        if not self._provision_network_user_param(enable=True):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        if not self._provision_network_views(enable=True):
            if self._adapter is not None:
                self._adapter.rollback()
            return False

        if self._adapter is not None:
            self._adapter.commit()
        return True

    def _execute_multilang_function(self, sql: str, *, label: str) -> bool:
        json_result, ok = run_multilang_function_sql(
            sql,
            adapter=self._adapter,
            is_thread=True,
            show_exception=False,
        )
        if ok:
            return True

        msg = "{0} failed."
        msg = msg.format(label)
        err = (
            lib_vars.session_vars.get("last_error_msg")
            or lib_vars.session_vars.get("last_error")
            or multilang_json_error_message(json_result, sql=sql)
            or msg
        )
        self._set_task_error(err)
        if json_result:
            from ..utils import tools_gw

            tools_gw.manage_json_exception(json_result, sql=sql, is_thread=True)
        return False

    def _provision_network_user_param(self, *, enable: bool) -> bool:
        msg = "Multilang user parameter provisioning"
        return self._execute_multilang_function(
            multilang_user_param_provision_sql(enable=enable),
            label=msg,
        )

    def _provision_network_views(self, *, enable: bool) -> bool:
        msg = "Multilang views provisioning"
        return self._execute_multilang_function(
            multilang_views_provision_sql(enable=enable),
            label=msg,
        )

    def _seed_project_types(
        self,
        target_types: list[str],
        *,
        lang: str,
        progress_base: int = 80,
    ) -> bool:
        """Insert baseline SQL once per project type."""
        seeded: list[str] = []
        total = len(target_types)
        per_type = seed_sql_for_project_types(
            self.params.sql_root or "",
            target_types,
            lang=lang,
        )
        for idx, (project_type, statements) in enumerate(per_type, start=1):
            if self.isCanceled():
                self.params.cancel_token.cancel()
                return False
            self._progress_cb_seed(idx, total, project_type, progress_base=progress_base)
            if not statements:
                msg = "Multilang seed: no baseline SQL for project_type={0} (lang={1}); skipping."
                msg_params = (project_type, lang)
                tools_log.log_info(msg, msg_params=msg_params)
            else:
                for sql in statements:
                    if self.isCanceled():
                        return False
                    if not self._execute_sql(sql):
                        if self._adapter is not None:
                            err = self._adapter.last_error() or "seed SQL failed"
                            msg = "Multilang seed failed for project_type {0}: {1}"
                            msg_params = (project_type, err)
                            self._set_task_error(tools_qt.tr(msg, list_params=msg_params))
                        return False
            seeded.append(project_type)
        self.seeded_project_types = seeded
        return True

    def _translatable_project_types(self, sql_root: str) -> list[str]:
        """All supported project types with local baselines (ignore inventory)."""
        types = translatable_project_types_with_baseline(sql_root)
        if types:
            return types
        # Fall back to declared kinds even when folders are missing (logged as skip).
        return sorted(TRANSLATABLE_PROJECT_TYPES)

    def _remove_orphaned_project_type_rows(
        self,
        fetcher,
        current_project_types: set[str],
    ) -> bool:
        stored = fetch_seeded_project_types_from_multilang(fetcher)
        removed = sorted(stored - {str(x).lower() for x in current_project_types})
        if not removed:
            return True
        tools_log.log_info(
            "Multilang seed: removing baseline rows for unsupported project types",
            parameter=", ".join(removed),
        )
        for sql in delete_project_type_seed_sql(removed):
            if self.isCanceled():
                return False
            if not self._execute_sql(sql):
                msg = "Failed to delete multilang rows for removed project types."
                self._set_task_error(
                    self._adapter.last_error() if self._adapter else tools_qt.tr(msg)
                )
                return False
        return True

    def _ensure_cat_language(self) -> bool:
        return self._execute_sql(ensure_cat_language_sql(SEED_LANGUAGE_ID))

    def _finalize_addparam(self, seeded_project_types: list[str]) -> bool:
        sql_root = self.params.sql_root or ""
        invalidate_baseline_fingerprint_cache(sql_root)
        payload = json.dumps({
            "seeded_project_types": seeded_project_types,
            "seed_language": SEED_LANGUAGE_FOLDER,
            "seed_baseline_fingerprint": compute_baseline_fingerprint(sql_root),
        }).replace("'", "''")
        sql = (
            "UPDATE multilang.sys_version "
            f"SET addparam = COALESCE(addparam, '{{}}'::jsonb) || '{payload}'::jsonb "
            "WHERE id = (SELECT id FROM multilang.sys_version ORDER BY id DESC LIMIT 1);"
        )
        return self._execute_sql(sql)

    def _record_failure(self) -> None:
        if self.result is None:
            if self._adapter is not None and self._adapter.last_error():
                self._set_task_error(self._adapter.last_error())
            return
        failure = self.result.first_failure()
        if failure is None:
            if self._adapter is not None and self._adapter.last_error():
                self._set_task_error(self._adapter.last_error())
            return
        err = (
            (self._adapter.last_error() if self._adapter is not None else "")
            or lib_vars.session_vars.get("last_error")
            or failure.error
            or ""
        )
        lib_vars.session_vars["last_error"] = err
        msg = format_failure(
            failure.path,
            str(failure.error or err),
            sql_root=self._log_style.sql_root,
            sql=getattr(failure, "sql", "") or "",
            statement_position=getattr(failure, "statement_position", 0) or 0,
        )
        if err and not lib_vars.session_vars.get("last_error_msg"):
            lib_vars.session_vars["last_error_msg"] = msg
        self.error = str(err or msg)
        detail = self.error
        msg = "Multilang schema build failed: {0}"
        msg_params = (detail,)
        tools_log.log_warning(msg, msg_params=msg_params)

    def _progress_cb_build(
        self,
        seen: int,
        total: int,
        label: str,
        fx: Any = None,
    ) -> None:
        self._last_progress_label = label
        if label == "done":
            tools_log.log_info(format_done(seen, total, style=self._log_style))
        elif not label.startswith("phase:"):
            tools_log.log_info(format_file(seen, total, label, style=self._log_style))

        if hasattr(self.admin, "schema_build_progress_hint"):
            self.admin.schema_build_progress_hint = format_progress_status(
                seen,
                total,
                label,
                sql_root=self._log_style.sql_root,
            )

        if total > 0:
            pct = int(round((seen / total) * 80))
            if hasattr(self.admin, "progress_ratio"):
                pct = int(pct * float(self.admin.progress_ratio or 1.0))
            if hasattr(self.admin, "current_sql_file"):
                self.admin.current_sql_file = seen
            if hasattr(self.admin, "total_sql_files"):
                self.admin.total_sql_files = total
            if hasattr(self.admin, "progress_value"):
                self.admin.progress_value = pct
            self.setProgress(pct)

        if self.isCanceled():
            self.params.cancel_token.cancel()

    def _progress_cb_seed(
        self,
        seen: int,
        total: int,
        project_type: str,
        *,
        progress_base: int = 80,
    ) -> None:
        label = f"seed:{project_type}"
        self._last_progress_label = label
        if hasattr(self.admin, "schema_build_progress_hint"):
            msg = "Seeding {0} ({1}/{2})"
            msg_params = (project_type, seen, total)
            self.admin.schema_build_progress_hint = tools_qt.tr(msg, list_params=msg_params)
        span = max(100 - progress_base, 1)
        pct = progress_base + int(round((seen / max(total, 1)) * span))
        if hasattr(self.admin, "progress_value"):
            self.admin.progress_value = pct
        self.setProgress(pct)

    def finished(self, result: bool) -> None:
        super().finished(result)
        if self.timer is not None:
            try:
                self.timer.stop()
            except Exception:  # noqa: BLE001
                pass
        self.setProgress(100)

        dlg = self.manage_schemas_dlg
        if dlg is not None:
            try:
                dlg.setEnabled(True)
            except Exception:  # noqa: BLE001
                pass

        if self.on_done is not None and self.result is not None:
            if not result and self.result.ok:
                self.admin.error_count = getattr(self.admin, "error_count", 0) + 1
                if not lib_vars.session_vars.get("last_error_msg"):
                    msg = "Multilang schema task failed during baseline seed."
                    self._set_task_error(
                        self._adapter.last_error() if self._adapter else
                        tools_qt.tr(msg)
                    )
                
            try:
                self.on_done(self.result)
            except Exception as exc:  # noqa: BLE001
                msg = "Multilang on_done callback raised: {0}"
                msg_params = (str(exc),)
                tools_log.log_info(msg, msg_params=msg_params)

        locale_out = self.locale if self._language_only else ""
        self.task_finished.emit(bool(result), locale_out, self.error or "")

    def cancel(self) -> None:
        try:
            self.params.cancel_token.cancel()
        except Exception:  # noqa: BLE001
            pass
        super().cancel()
