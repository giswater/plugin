"""Lockstep coordinated network schema upgrades."""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import Literal

from .builder import BuildParams, BuildResult, SchemaBuilder, _parse_version
from .changelog import iter_semver_under
from .manifest import Manifest, load_manifest
from .manifest_registry import infer_parents_on_update, kind_update_roots
from .schema_catalog import (
    ClusterMember,
    NetworkGraph,
    discover_cluster,
    fetch_schema_sys_version_entry,
    make_conn_fetcher,
    version_text,
)
from .sql_runner import ConnectionLike

ActionKind = Literal["upgrade", "bump"]


@dataclass
class LockstepStep:
    target_version: str
    kind: str
    schema: str
    action: ActionKind
    from_version: str


@dataclass
class NetworkUpdateResult:
    ok: bool
    steps: list[LockstepStep] = field(default_factory=list)
    results: list[dict[str, object]] = field(default_factory=list)
    error: str = ""


def _kind_update_roots(dbmodel_path: str, kind: str) -> list[str]:
    return kind_update_roots(dbmodel_path, kind)


def has_patch_at_version(dbmodel_path: str, kind: str, version: tuple[int, int, int]) -> bool:
    major, minor, patch = version
    for root in _kind_update_roots(dbmodel_path, kind):
        folder = os.path.join(root, str(major), str(minor), str(patch))
        if not os.path.isdir(folder):
            continue
        for name in os.listdir(folder):
            if name.endswith(".sql"):
                return True
    return False


def _collect_target_versions(
    dbmodel_path: str,
    cluster: list[ClusterMember],
    target_version: str,
) -> list[tuple[int, int, int]]:
    target_v = _parse_version(target_version)
    found: set[tuple[int, int, int]] = set()
    for member in cluster:
        current_v = _parse_version(member.version)
        for root in _kind_update_roots(dbmodel_path, member.kind):
            for version in iter_semver_under(root):
                if current_v < version <= target_v:
                    found.add(version)
        # include target even when no folder yet (for bump-only alignment)
        if current_v < target_v:
            found.add(target_v)
    return sorted(found)


def plan_lockstep(
    graph: NetworkGraph,
    dbmodel_path: str,
    target_version: str,
) -> list[LockstepStep]:
    cluster = discover_cluster(graph, dbmodel_path)
    if not cluster:
        return []

    by_schema = {node.schema: node for node in graph.nodes}
    versions = _collect_target_versions(dbmodel_path, cluster, target_version)
    steps: list[LockstepStep] = []

    for version in versions:
        version_label = version_text(version)
        for member in cluster:
            kind = member.kind
            node = by_schema.get(member.schema)
            current = node.version if node else member.version
            if _parse_version(current) >= version:
                continue
            action: ActionKind = (
                "upgrade" if has_patch_at_version(dbmodel_path, kind, version) else "bump"
            )
            steps.append(
                LockstepStep(
                    target_version=version_label,
                    kind=kind,
                    schema=member.schema,
                    action=action,
                    from_version=current,
                )
            )
    return steps


def _infer_parents_for_kind(kind: str) -> str:
    return "true" if infer_parents_on_update(kind) else "false"


def resolve_lockstep_profile(manifest: Manifest, action: ActionKind) -> str:
    """Profile for one lockstep step. Fall back to ``update`` if the kind
    has not declared ``update_step`` / ``version_bump`` yet.
    """
    profile = "update_step" if action == "upgrade" else "version_bump"
    if profile not in manifest.profiles:
        return "update"
    return profile


def _run_step(
    conn: ConnectionLike,
    dbmodel_path: str,
    step: LockstepStep,
    *,
    locale: str,
    db_user: str,
) -> BuildResult:
    manifest = load_manifest(os.path.join(dbmodel_path, "manifests", f"{step.kind}.yaml"))
    profile = resolve_lockstep_profile(manifest, step.action)

    srid = "25831"
    try:
        with conn.raw.cursor() as cur:  # type: ignore[attr-defined]
            cur.execute(
                f'SELECT epsg, language FROM "{step.schema}".sys_version '
                "ORDER BY id DESC LIMIT 1"
            )
            row = cur.fetchone()
            if row:
                srid = str(row[0] or srid)
                locale = str(row[1] or locale)
    except Exception:  # noqa: BLE001
        conn.rollback()

    params = BuildParams(
        schema_name=step.schema,
        srid=srid,
        locale=locale,
        plugin_version=step.target_version,
        project_version=step.from_version,
        run_mode="upgrade_step" if step.action == "upgrade" else "upgrade",
        profile=profile,
        db_user=db_user,
        sql_root=dbmodel_path,
        infer_parents_from_config=_infer_parents_for_kind(step.kind),
    )
    builder = SchemaBuilder(conn, manifest, params)
    return builder.run()


def run_lockstep(
    conn: ConnectionLike,
    steps: list[LockstepStep],
    dbmodel_path: str,
    *,
    locale: str = "en_US",
    db_user: str = "",
) -> NetworkUpdateResult:
    result = NetworkUpdateResult(ok=True, steps=steps)
    for step in steps:
        build = _run_step(
            conn,
            dbmodel_path,
            step,
            locale=locale,
            db_user=db_user,
        )
        step_result = {
            "target_version": step.target_version,
            "kind": step.kind,
            "schema": step.schema,
            "action": step.action,
            "from_version": step.from_version,
            "ok": build.ok,
        }
        failure = build.first_failure()
        if failure is not None:
            step_result["error"] = failure.error
        result.results.append(step_result)
        if not build.ok:
            result.ok = False
            result.error = failure.error if failure else "unknown error"
            conn.rollback()
            return result
        conn.commit()
        refreshed = fetch_schema_sys_version_entry(step.schema, make_conn_fetcher(conn))
        step.from_version = str(refreshed.get("version") or step.target_version)
    return result


def refresh_cluster_versions(graph: NetworkGraph, fetcher) -> NetworkGraph:
    for node in graph.nodes:
        entry = fetch_schema_sys_version_entry(node.schema, fetcher)
        node.version = str(entry.get("version") or node.version)
    versions = [n.version for n in graph.nodes if n.version]
    graph.version_skew = len({n.version for n in graph.nodes if n.version}) > 1
    graph.min_version = min(versions, key=_parse_version) if versions else ""
    graph.max_version = max(versions, key=_parse_version) if versions else ""
    return graph


__all__ = [
    "LockstepStep",
    "NetworkUpdateResult",
    "has_patch_at_version",
    "plan_lockstep",
    "resolve_lockstep_profile",
    "run_lockstep",
]
