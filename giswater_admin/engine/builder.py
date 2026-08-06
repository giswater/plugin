"""
Schema build orchestrator.

The plugin task wraps a :class:`SchemaBuilder`; the CLI calls it
directly. No Qt, no QGIS, no global state.
"""

from __future__ import annotations

import datetime as _dt
import logging
import os
from dataclasses import dataclass, field
from typing import Any, Callable, Optional

from . import sql_runner
from .cancel import CancelToken
from .manifest import Manifest, Phase, Step
from .templating import apply_subs, render

logger = logging.getLogger(__name__)


ProgressCb = Callable[[int, int, str, Optional[sql_runner.FileExec]], None]

# DDL phases run as role_system so created objects are owned by role_system.
# load_base is excluded: init.sql creates roles/schema as the installer (needs CREATE
# on the database) and ends with SET ROLE role_system for the rest of the phase.
# updates/load_sample are excluded: legacy patches use DISABLE TRIGGER ALL, which
# requires superuser to touch RI_ConstraintTrigger system triggers.
# reload_fct_ftrg is excluded: upgrade patches applied as superuser may re-own
# functions; only the installer can CREATE OR REPLACE them on the next upgrade.
_ROLE_SYSTEM_PHASES = frozenset()
# init.sql ends with SET ROLE role_system; restore installer before superuser phases.
_RESET_ROLE_AFTER_PHASES = frozenset({"load_base"})

# On a fresh database role_system does not exist yet; init.sql creates it.
# pg_has_role(..., 'role_system', ...) errors if the role is missing — guard first.
_ENSURE_ROLE_SYSTEM_SQL = """
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_system')
     AND NOT pg_has_role(current_user, 'role_system', 'member')
     AND (SELECT rolsuper FROM pg_roles WHERE rolname = current_user) IS TRUE THEN
    EXECUTE 'GRANT role_system TO ' || quote_ident(current_user);
  END IF;
END $$;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_system') THEN
    EXECUTE 'SET ROLE role_system';
  END IF;
END $$;
"""

_RESET_ROLE_SQL = "RESET ROLE;"


@dataclass
class BuildParams:
    """Runtime inputs. Drives substitutions, version filtering, and dir walks."""

    schema_name: str
    srid: str = "25831"
    locale: str = "en_US"
    profile: str = "empty"
    plugin_version: str = "0.0.0"
    project_version: str = "0.0.0"
    run_mode: str = "new_project"  # new_project | upgrade | upgrade_step
    db_user: str = ""

    sql_root: str = ""
    today: str = ""

    # Linked / parent schemas.
    aux_schema_name: str = ""
    ws_schema: str = ""
    ud_schema: str = ""
    parent_schema: str = ""
    parent_type: str = ""  # "ws" or "ud" (auto-detected by CLI for cm)

    # Per-kind specifics.
    am_target: str = ""
    main_project_version: str = ""
    db_name: str = ""

    # sys_version registration (manifest sql_function payloads).
    creation_profile: str = ""
    copy_source_schema: str = ""
    register_is_new: str = "false"
    infer_parents_from_config: str = "false"
    register_parent_schema: str = ""

    # Cooperative cancel.
    cancel_token: CancelToken = field(default_factory=CancelToken)

    def __post_init__(self) -> None:
        if not self.today:
            object.__setattr__(self, "today", _dt.date.today().strftime("%d-%m-%Y"))
        if not self.main_project_version:
            object.__setattr__(self, "main_project_version", self.plugin_version)

    def as_ctx(self) -> dict[str, Any]:
        return {
            "schema_name": self.schema_name,
            "srid": self.srid,
            "locale": self.locale,
            "project_version": self.project_version,
            "plugin_version": self.plugin_version,
            "main_project_version": self.main_project_version,
            "db_user": self.db_user,
            "db_name": self.db_name,
            "run_mode": self.run_mode,
            "aux_schema_name": self.aux_schema_name,
            "ws_schema": self.ws_schema,
            "ud_schema": self.ud_schema,
            "parent_schema": self.parent_schema,
            "parent_type": self.parent_type,
            "am_target": self.am_target,
            "today": self.today,
            "profile": self.profile,
            "creation_profile": self.creation_profile,
            "copy_source_schema": self.copy_source_schema,
            "register_is_new": self.register_is_new,
            "infer_parents_from_config": self.infer_parents_from_config,
            "register_parent_schema": self.register_parent_schema,
        }

    def integration_parent_schema(self) -> str:
        """WS/UD network schema when running an integrate_* profile."""
        if self.profile == "integrate_ws":
            return (
                self.register_parent_schema
                or self.parent_schema
                or self.ws_schema
                or ""
            ).strip()
        if self.profile == "integrate_ud":
            return (
                self.register_parent_schema
                or self.parent_schema
                or self.ud_schema
                or ""
            ).strip()
        if self.profile == "integrate":
            return (
                self.register_parent_schema
                or self.parent_schema
                or ""
            ).strip()
        return ""

    def base_subs(self) -> dict[str, str]:
        """
        File-content substitutions. Mirrors legacy ``_read_execute_file`` +
        ``_read_execute_cm_file`` behaviour.

        Integrate profiles run parent-network SQL (``integration/*.sql``) where
        ``SCHEMA_NAME`` must be the ws/ud anchor, not the ``utils`` satellite.
        """
        schema_name = self.schema_name
        parent = self.integration_parent_schema()
        if parent:
            schema_name = parent
        return {
            "SCHEMA_NAME": schema_name,
            "SRID_VALUE": str(self.srid),
            "SCHEMA_SRID": str(self.srid),
            "AUX_SCHEMA_NAME": self.aux_schema_name or "",
            "PARENT_SCHEMA": self.parent_schema or "",
            "PARENT_TYPE": self.parent_type or "",
            "BD_NAME": self.db_name or "",
        }


@dataclass
class PhaseResult:
    phase_id: str
    files: list[sql_runner.FileExec] = field(default_factory=list)
    skipped: bool = False
    skipped_reason: str = ""

    @property
    def ok(self) -> bool:
        if self.skipped:
            return True
        return all(f.ok for f in self.files)


@dataclass
class BuildResult:
    profile: str
    phases: list[PhaseResult] = field(default_factory=list)
    cancelled: bool = False

    @property
    def ok(self) -> bool:
        if self.cancelled:
            return False
        return all(p.ok for p in self.phases)

    def first_failure(self) -> sql_runner.FileExec | None:
        for pr in self.phases:
            for fx in pr.files:
                if not fx.ok:
                    return fx
        return None


class SchemaBuilder:
    """Run one manifest profile against a database connection."""

    def __init__(
        self,
        conn: sql_runner.ConnectionLike,
        manifest: Manifest,
        params: BuildParams,
        progress_cb: ProgressCb | None = None,
        commit_each_file: bool = False,
    ) -> None:
        self.conn = conn
        self.manifest = manifest
        self.params = params
        self.progress_cb: ProgressCb = progress_cb or (lambda *_a, **_k: None)
        self.commit_each_file = commit_each_file
        self._ctx = params.as_ctx()
        # Manifest-level substitutions are layered on top of the engine's
        # baseline (SCHEMA_NAME etc.) and rendered with the context.
        rendered_manifest_subs = render(manifest.substitutions, self._ctx) or {}
        self._subs = {**params.base_subs(), **rendered_manifest_subs}

    # ------------------------------------------------------------------ public

    def run(self) -> BuildResult:
        phase_ids = self.manifest.profile(self.params.profile)
        result = BuildResult(profile=self.params.profile)

        plan = self._plan(phase_ids)
        total = sum(item[1] for item in plan)
        seen = 0

        for phase, count in plan:
            if self._is_cancelled():
                result.cancelled = True
                break
            self.progress_cb(seen, total, f"phase:{phase.id}", None)
            pr = self._run_phase(phase, seen, total)
            result.phases.append(pr)
            seen += count
            if not pr.ok:
                break  # stop on first failure

        if self._is_cancelled() and not result.cancelled:
            result.cancelled = True
        self.progress_cb(seen, total, "done", None)
        return result

    # ----------------------------------------------------------------- planning

    def plan(self) -> list[tuple[Phase, int]]:
        """Public planning helper used by ``--check``."""
        return self._plan(self.manifest.profile(self.params.profile))

    def _plan(self, phase_ids: tuple[str, ...]) -> list[tuple[Phase, int]]:
        plan: list[tuple[Phase, int]] = []
        for pid in phase_ids:
            phase = self.manifest.phase(pid)
            count = self._count_files(phase)
            plan.append((phase, count))
        return plan

    def _count_files(self, phase: Phase) -> int:
        if phase.type == "sql_dir":
            return sum(len(self._files_for_step(s)) for s in phase.steps)
        if phase.type == "version_walk":
            return sum(
                len(self._files_in(os.path.join(folder, sub), recursive=False))
                for _, folders in self._walk_versions(phase)
                for folder in folders
                for sub in (phase.subdirs or ("",))
            )
        if phase.type == "dir_walk":
            recursive = bool(phase.range.get("recursive", False))
            return sum(
                len(self._files_in(folder, recursive=recursive))
                for folder in self._walk_dirs(phase)
            )
        if phase.type == "sql_file":
            return sum(1 for s in phase.steps if self._resolve_file(s))
        if phase.type == "sql_function":
            return 1
        if phase.type == "sql_inline":
            return 1
        return 0

    # ------------------------------------------------------------------- phases

    def _run_phase(self, phase: Phase, seen: int, total: int) -> PhaseResult:
        use_role_system = phase.id in _ROLE_SYSTEM_PHASES
        if use_role_system:
            fx = sql_runner.execute_inline(
                self.conn,
                _ENSURE_ROLE_SYSTEM_SQL,
                label=f"phase:{phase.id}:set_role_system",
                commit=self.commit_each_file,
            )
            if not fx.ok:
                return PhaseResult(phase_id=phase.id, files=[fx])

        pr: PhaseResult | None = None
        try:
            if phase.type == "sql_dir":
                pr = self._run_sql_dir(phase, seen, total)
            elif phase.type == "version_walk":
                pr = self._run_version_walk(phase, seen, total)
            elif phase.type == "dir_walk":
                pr = self._run_dir_walk(phase, seen, total)
            elif phase.type == "sql_file":
                pr = self._run_sql_file(phase, seen, total)
            elif phase.type == "sql_function":
                pr = self._run_sql_function(phase, seen, total)
            elif phase.type == "sql_inline":
                pr = self._run_sql_inline(phase, seen, total)
            else:
                raise ValueError(f"Unsupported phase type: {phase.type}")
        finally:
            if pr is None:
                pass
            elif use_role_system:
                reset_fx = sql_runner.execute_inline(
                    self.conn,
                    _RESET_ROLE_SQL,
                    label=f"phase:{phase.id}:reset_role",
                    commit=self.commit_each_file,
                )
                pr.files.append(reset_fx)
            elif phase.id in _RESET_ROLE_AFTER_PHASES and pr.files:
                reset_fx = sql_runner.execute_inline(
                    self.conn,
                    _RESET_ROLE_SQL,
                    label=f"phase:{phase.id}:reset_role",
                    commit=self.commit_each_file,
                )
                pr.files.append(reset_fx)
        assert pr is not None
        return pr

    def _run_sql_dir(self, phase: Phase, seen: int, total: int) -> PhaseResult:
        pr = PhaseResult(phase_id=phase.id)
        any_file = False
        for step in phase.steps:
            subs = self._step_subs(step)
            files = self._files_for_step(step)
            if files:
                any_file = True
            for path in files:
                if self._is_cancelled():
                    return pr
                seen += 1
                fx = sql_runner.execute_file(self.conn, path, subs, self.commit_each_file)
                pr.files.append(fx)
                self.progress_cb(seen, total, path, fx)
                if not fx.ok:
                    return pr
        if not any_file and phase.optional:
            pr.skipped = True
            pr.skipped_reason = "no files found"
        return pr

    def _run_version_walk(self, phase: Phase, seen: int, total: int) -> PhaseResult:
        pr = PhaseResult(phase_id=phase.id)
        any_file = False
        for _, folders in self._walk_versions(phase):
            for folder in folders:
                for sub in (phase.subdirs or ("",)):
                    target = os.path.join(folder, sub) if sub else folder
                    for path in self._files_in(target, recursive=False):
                        if self._is_cancelled():
                            return pr
                        any_file = True
                        seen += 1
                        fx = sql_runner.execute_file(self.conn, path, self._subs, self.commit_each_file)
                        pr.files.append(fx)
                        self.progress_cb(seen, total, path, fx)
                        if not fx.ok:
                            return pr
        if not any_file and phase.optional:
            pr.skipped = True
            pr.skipped_reason = "no version folders matched"
        return pr

    def _run_dir_walk(self, phase: Phase, seen: int, total: int) -> PhaseResult:
        pr = PhaseResult(phase_id=phase.id)
        recursive = bool(phase.range.get("recursive", False))
        any_file = False
        for folder in self._walk_dirs(phase):
            for path in self._files_in(folder, recursive=recursive):
                if self._is_cancelled():
                    return pr
                any_file = True
                seen += 1
                fx = sql_runner.execute_file(self.conn, path, self._subs, self.commit_each_file)
                pr.files.append(fx)
                self.progress_cb(seen, total, path, fx)
                if not fx.ok:
                    return pr
        if not any_file and phase.optional:
            pr.skipped = True
            pr.skipped_reason = "no subfolders matched"
        return pr

    def _run_sql_file(self, phase: Phase, seen: int, total: int) -> PhaseResult:
        pr = PhaseResult(phase_id=phase.id)
        for step in phase.steps:
            path = self._resolve_file(step)
            if not path:
                if phase.optional:
                    pr.skipped = True
                    pr.skipped_reason = f"file not found: {step.source}"
                    continue
                pr.files.append(
                    sql_runner.FileExec(
                        path=render(step.source, self._ctx),
                        ok=False,
                        error="file not found",
                    )
                )
                return pr
            if self._is_cancelled():
                return pr
            seen += 1
            subs = self._step_subs(step)
            fx = sql_runner.execute_file(self.conn, path, subs, self.commit_each_file)
            pr.files.append(fx)
            self.progress_cb(seen, total, path, fx)
            if not fx.ok:
                return pr
        return pr

    def _run_sql_function(self, phase: Phase, seen: int, total: int) -> PhaseResult:
        pr = PhaseResult(phase_id=phase.id)
        fn = render(phase.function, self._ctx)
        payload = render(phase.payload, self._ctx)
        fx = sql_runner.execute_function_call(
            self.conn,
            fn,
            payload,
            self.commit_each_file,
        )
        pr.files.append(fx)
        self.progress_cb(seen + 1, total, f"<fn:{fn}>", fx)
        return pr

    def _run_sql_inline(self, phase: Phase, seen: int, total: int) -> PhaseResult:
        pr = PhaseResult(phase_id=phase.id)
        # Inline SQL goes through both the manifest-level {{ var }} renderer
        # and the file-content substitution layer, so authors can use either.
        sql = apply_subs(render(phase.sql, self._ctx), self._subs)
        fx = sql_runner.execute_inline(
            self.conn, sql, label=f"phase:{phase.id}", commit=self.commit_each_file
        )
        pr.files.append(fx)
        self.progress_cb(seen + 1, total, f"<inline:{phase.id}>", fx)
        return pr

    # ---------------------------------------------------------- filesystem util

    def _files_for_step(self, step: Step) -> list[str]:
        rendered = render(step.source, self._ctx)
        folder = os.path.join(self.params.sql_root, rendered)
        files = self._files_in(folder, step.recursive)
        if not files and step.fallback_source and self.params.locale != "no_TR":
            fb = os.path.join(self.params.sql_root, render(step.fallback_source, self._ctx))
            files = self._files_in(fb, step.recursive)
        return files

    def _files_in(self, folder: str, recursive: bool) -> list[str]:
        return sql_runner.list_sql_files(folder, recursive=recursive)

    def _resolve_file(self, step: Step) -> str | None:
        primary = os.path.join(self.params.sql_root, render(step.source, self._ctx))
        if os.path.isfile(primary):
            return primary
        if step.fallback_source and self.params.locale != "no_TR":
            fb = os.path.join(self.params.sql_root, render(step.fallback_source, self._ctx))
            if os.path.isfile(fb):
                return fb
        return None

    def _integration_parent_schema(self) -> str:
        """Network schema for integration SQL (ws/ud parent, not the satellite)."""
        parent = self.params.integration_parent_schema()
        if parent:
            return parent
        for key in ("parent_schema", "ws_schema", "ud_schema"):
            value = str(self._ctx.get(key) or "").strip()
            if value:
                return value
        return ""

    def _step_subs(self, step: Step) -> dict[str, str]:
        if not step.schema_override and not step.aux_override:
            return self._subs
        s = dict(self._subs)
        if step.schema_override:
            rendered = render(step.schema_override, self._ctx).strip()
            if not rendered or "{{" in rendered:
                rendered = self._integration_parent_schema()
            if rendered:
                s["SCHEMA_NAME"] = rendered
        if step.aux_override:
            s["AUX_SCHEMA_NAME"] = render(step.aux_override, self._ctx)
        return s

    # ------------------------------------------------------------- walks (dir)

    def _walk_dirs(self, phase: Phase) -> list[str]:
        """Alphabetical folder walk under ``phase.root``, filtered by range."""
        root = os.path.join(self.params.sql_root, render(phase.root or "", self._ctx))
        if not os.path.isdir(root):
            return []
        entries = sorted(
            e
            for e in os.listdir(root)
            if os.path.isdir(os.path.join(root, e)) and not e.startswith(".")
        )
        rng = phase.range or {}
        mode = render(rng.get("mode", self.params.run_mode), self._ctx)
        from_excl = render(rng.get("from_exclusive", ""), self._ctx)
        to_incl = render(rng.get("to_inclusive", ""), self._ctx)
        out: list[str] = []
        for e in entries:
            full = os.path.join(root, e)
            if mode == "upgrade":
                if from_excl and not (e > from_excl):
                    continue
                if to_incl and not (e <= to_incl):
                    continue
            elif mode in ("new_project", "all"):
                if to_incl and not (e <= to_incl):
                    continue
            else:
                raise ValueError(f"Unsupported dir_walk range.mode: {mode}")
            out.append(full)
        return out

    # --------------------------------------------------------- walks (version)

    def _walk_versions(
        self, phase: Phase
    ) -> list[tuple[tuple[int, int, int], list[str]]]:
        """Walk semver ``M/m/p`` folders under one root or several.

        With single ``root``: returns each present version with a one-element
        list. With ``roots: [a, b, ...]``: returns per-version the list of
        patch paths from each declared root that contains that version, in
        declaration order. Versions missing from a given root are silently
        skipped for that root (still included if at least one root has them).
        Resulting list is sorted ascending by semver.
        """
        if phase.roots:
            roots = [render(r, self._ctx) for r in phase.roots]
        else:
            roots = [render(phase.root or "updates", self._ctx)]

        # version -> list of patch_path indexed by root order (None if absent)
        versions: dict[tuple[int, int, int], list[str | None]] = {}
        for ri, rrel in enumerate(roots):
            rabs = os.path.join(self.params.sql_root, rrel)
            if not os.path.isdir(rabs):
                continue
            for entry in os.listdir(rabs):
                major_path = os.path.join(rabs, entry)
                if not (entry.isdigit() and os.path.isdir(major_path)):
                    continue
                for entry2 in os.listdir(major_path):
                    minor_path = os.path.join(major_path, entry2)
                    if not (entry2.isdigit() and os.path.isdir(minor_path)):
                        continue
                    for entry3 in os.listdir(minor_path):
                        patch_path = os.path.join(minor_path, entry3)
                        if not (entry3.isdigit() and os.path.isdir(patch_path)):
                            continue
                        key = (int(entry), int(entry2), int(entry3))
                        if key not in versions:
                            versions[key] = [None] * len(roots)
                        versions[key][ri] = patch_path

        plugin_v = _parse_version(self.params.plugin_version)
        project_v = _parse_version(self.params.project_version)
        mode = render(phase.range.get("mode", self.params.run_mode), self._ctx)

        out: list[tuple[tuple[int, int, int], list[str]]] = []
        for v in sorted(versions.keys()):
            if mode == "new_project":
                if not (v <= plugin_v):
                    continue
            elif mode == "upgrade":
                if not (project_v < v <= plugin_v):
                    continue
            elif mode == "upgrade_step":
                if v != plugin_v or not (project_v < v):
                    continue
            elif mode == "all":
                pass
            else:
                raise ValueError(f"Unsupported version_walk range.mode: {mode}")
            paths = [p for p in versions[v] if p is not None]
            out.append((v, paths))
        return out

    # ----------------------------------------------------------- cancel helper

    def _is_cancelled(self) -> bool:
        return bool(self.params.cancel_token.cancelled)


def _parse_version(s: str) -> tuple[int, int, int]:
    parts = (s or "0.0.0").split(".")
    nums: list[int] = []
    for p in parts[:3]:
        try:
            nums.append(int(p))
        except ValueError:
            nums.append(0)
    while len(nums) < 3:
        nums.append(0)
    return nums[0], nums[1], nums[2]


def drop_schema(
    conn: sql_runner.ConnectionLike,
    schema: str,
    *,
    cascade: bool = False,
    commit: bool = True,
) -> sql_runner.FileExec:
    """Drop a schema. Used by both CLI ``drop`` and plugin delete handlers."""
    safe = schema.replace('"', '').replace(';', '')
    cascade_kw = "CASCADE" if cascade else "RESTRICT"
    sql = f'DROP SCHEMA IF EXISTS "{safe}" {cascade_kw};'
    return sql_runner.execute_inline(conn, sql, label=f"drop:{safe}", commit=commit)
