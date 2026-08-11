"""``update`` subcommand: upgrade an existing schema in place."""

from __future__ import annotations

import argparse

from ..engine import BuildParams, SchemaBuilder, changelog_versions_as_dicts, format_upgrade_changelog
from ..engine.manifest_registry import infer_parents_on_update
from ..engine.schema_catalog import (
    discover_database_network,
    graph_has_linked_dependents,
    make_conn_fetcher,
)
from ..output import Out
from . import _helpers as h


def run(args: argparse.Namespace, out: Out) -> int:
    conn = h.open_conn(args, out) if h.needs_connection(args) else None

    if conn is not None and not getattr(args, "force", False):
        fetcher = make_conn_fetcher(conn)
        db = discover_database_network(fetcher, schema_filter=args.schema)
        graph = db.cluster
        if graph_has_linked_dependents(graph, args.schema):
            peers = sorted(
                {
                    node.schema
                    for node in graph.nodes
                    if node.schema != args.schema
                }
            )
            target = args.to_version or args.plugin_version or ""
            out.error(
                f"Schema '{args.schema}' is part of an interconnected network "
                f"({', '.join(peers)}). "
                f"Use {graph.suggested_update_command(target)} instead, or pass --force."
            )
            conn.close()
            return 1

    # Infer kind + project_version + epsg from sys_version unless overridden.
    kind = args.kind
    project_version = "0.0.0"
    srid = "25831"
    if conn is not None:
        if not kind:
            kind = h.detect_project_type(conn, args.schema)
            if not kind:
                out.error(
                    f"Could not detect project_type for schema '{args.schema}'. "
                    "Pass --kind."
                )
                conn.close()
                return 1
            out.info(f"kind auto-detected: {kind}")
        project_version = h.detect_project_version(conn, args.schema) or "0.0.0"
        srid = h.detect_project_epsg(conn, args.schema, default=srid)
        out.info(f"current project_version: {project_version}")
        out.info(f"schema epsg: {srid}")
        from ..engine.version_guard import assert_no_downgrade

        err = assert_no_downgrade(
            project_version,
            args.to_version or args.plugin_version or getattr(args, "version", "") or "",
            label=f"schema '{args.schema}'",
        )
        if err:
            out.error(err)
            conn.close()
            return 1

    if not kind:
        out.error("kind is required when running with --check and no connection.")
        return 1

    manifest = h.manifest_for(args, kind)
    if "update" not in manifest.profiles:
        out.error(f"Manifest '{kind}' has no 'update' profile.")
        if conn is not None:
            conn.close()
        return 1

    target_version = args.to_version or args.plugin_version or getattr(args, "version", None)
    params = BuildParams(
        schema_name=args.schema,
        # Patches still substitute SRID_VALUE (e.g. geometry typemods on views).
        srid=srid,
        locale=args.locale,
        plugin_version=target_version,
        project_version=project_version,
        run_mode="upgrade",
        profile="update",
        db_user=_safe_user(args),
        sql_root=args.dbmodel_path,
        infer_parents_from_config="true" if infer_parents_on_update(kind) else "false",
    )

    if args.check:
        builder = SchemaBuilder(h.NoopConn(), manifest, params)
        plan = builder.plan()
        payload = {
            "ok": True,
            "mode": "check",
            "kind": kind,
            "schema": args.schema,
            "from_version": project_version,
            "to_version": target_version,
            "plan": [{"phase": p.id, "files": n} for p, n in plan],
            "total_files": sum(n for _, n in plan),
        }
        if kind in ("ws", "ud"):
            payload["changelog_versions"] = changelog_versions_as_dicts(
                args.dbmodel_path,
                kind,
                project_version,
                target_version,
            )
            payload["changelog"] = format_upgrade_changelog(
                args.dbmodel_path,
                kind,
                project_version,
                target_version,
            )
            if payload["changelog"]:
                out.info(payload["changelog"])
        out.result(payload)
        if conn is not None:
            conn.close()
        return 0

    assert conn is not None
    try:
        builder = SchemaBuilder(conn, manifest, params, progress_cb=h.progress_cb_for_args(out, args))
        result = builder.run()
        if result.ok:
            conn.commit()
        else:
            conn.rollback()
    finally:
        conn.close()

    code = h.report_result(args, out, manifest, params, result)
    # Inject extras into stdout when in JSON mode by re-using report_result is overkill;
    # surfacing the version pair via stderr is sufficient for the CLI contract.
    out.info(f"upgraded {args.schema}: {project_version} -> {target_version}: ok={result.ok}")
    return code


def _safe_user(args):
    from .. import conn as conn_mod  # noqa: WPS433 - local to avoid cycle
    try:
        return conn_mod.resolve(args.conn, args.config).user or "postgres"
    except RuntimeError:
        return "postgres"
