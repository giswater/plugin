"""``create`` subcommand."""

from __future__ import annotations

import argparse

from .. import conn as conn_mod
from ..engine import BuildParams, SchemaBuilder
from ..engine.manifest_registry import (
    integration_parent_types,
    integration_sql_exists,
    is_main_kind,
    profile_needs_parent,
    register_context,
)
from ..output import Out
from . import _helpers as h


def run(args: argparse.Namespace, out: Out) -> int:  # noqa: C901
    manifest = h.manifest_for(args, args.kind)
    if args.profile not in manifest.profiles:
        out.error(
            f"Unknown profile '{args.profile}' for kind '{args.kind}'. "
            f"Known: {sorted(manifest.profiles)}"
        )
        return 1

    if profile_needs_parent(args.profile):
        has_parent = bool(args.parent_schema or args.ws_schema or args.ud_schema)
        if not has_parent:
            out.error(
                f"kind={args.kind} profile={args.profile} requires "
                f"--parent-schema or --parent (integrate)."
            )
            return 1

    if args.kind == "audit" and args.profile == "integrate":
        args.profile = "activate"

    if args.kind == "cibs" and args.schema != "cibs":
        out.warn("kind=cibs usually uses schema name 'cibs' (singleton satellite).")
    if args.kind == "audit" and args.schema != "audit":
        out.warn("kind=audit usually uses schema name 'audit'.")

    target_repr = h.safe_target_repr(args)
    if target_repr:
        out.info(f"target: {target_repr}")
    out.info(f"manifest: {manifest.path}")
    out.info(f"profile: {args.profile}")

    am_target = getattr(args, "am_target", None) or ""
    parent_type = str(args.parent_type or "").lower()
    conn = None

    needs_parent_type = profile_needs_parent(args.profile) and args.kind not in ("utils",)
    needs_detect_in_check = args.check and h.needs_connection(args) and (
        (needs_parent_type and (args.parent_schema or args.ws_schema or args.ud_schema) and not parent_type)
        or (args.kind == "utils" and not args.main_version and (args.ws_schema or args.ud_schema))
    )
    if (h.needs_connection(args) and not args.check) or needs_detect_in_check:
        conn = h.open_conn(args, out)

    if needs_parent_type:
        parent_schema = args.parent_schema or args.ws_schema or args.ud_schema or ""
        if parent_type:
            pass
        elif conn is not None and parent_schema:
            parent_type = h.detect_project_type(conn, parent_schema)
            if parent_type:
                out.info(f"parent_type auto-detected: {parent_type}")
        if not parent_type:
            out.error(
                f"kind={args.kind} profile={args.profile}: could not detect parent_type. "
                "Pass --parent-type ws|ud."
            )
            if conn is not None:
                conn.close()
            return 1

        supported = integration_parent_types(args.dbmodel_path, args.kind)
        if supported and parent_type not in supported:
            out.error(
                f"kind={args.kind}: parent_type='{parent_type}' is not supported. "
                f"Supported: {list(supported)}."
            )
            if conn is not None:
                conn.close()
            return 1
        if supported and not integration_sql_exists(args.dbmodel_path, args.kind, parent_type):
            out.error(
                f"kind={args.kind}: missing integration SQL for parent_type='{parent_type}'."
            )
            if conn is not None:
                conn.close()
            return 1

    locale = args.locale
    srid = args.srid
    main_version = args.main_version or args.plugin_version
    if args.kind == "utils" and conn is not None and not args.main_version:
        ws_ver = h.detect_project_version(conn, args.ws_schema)
        if ws_ver:
            main_version = ws_ver
            out.info(f"main_project_version lifted from {args.ws_schema}: {ws_ver}")

    creation_profile = ""
    if is_main_kind(args.kind):
        _profile_map = {
            "empty": "empty",
            "sample_inv": "inventory",
            "sample_full": "sample",
        }
        creation_profile = _profile_map.get(args.profile, "")

    reg = register_context(
        args.profile,
        ws_schema=args.ws_schema or "",
        ud_schema=args.ud_schema or "",
        parent_schema=args.parent_schema or "",
        parent_type=parent_type,
    )

    params = BuildParams(
        schema_name=args.schema,
        srid=str(srid),
        locale=locale,
        plugin_version=args.plugin_version,
        project_version="0.0.0",
        run_mode="new_project",
        profile=args.profile,
        db_user=args.db_user or _conn_user(args),
        sql_root=args.dbmodel_path,
        ws_schema=args.ws_schema or "",
        ud_schema=args.ud_schema or "",
        parent_schema=(
            args.parent_schema
            or reg["register_parent_schema"]
            or args.ws_schema
            or args.ud_schema
            or ""
        ),
        parent_type=reg["parent_type"] or parent_type,
        am_target=am_target,
        main_project_version=main_version,
        creation_profile=creation_profile,
        register_is_new=reg["register_is_new"],
        infer_parents_from_config=reg["infer_parents_from_config"],
        register_parent_schema=reg["register_parent_schema"],
    )

    if args.check:
        return _print_check(out, manifest, params, target_repr)

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

    return h.report_result(args, out, manifest, params, result)


def _print_check(out: Out, manifest, params: BuildParams, target_repr: str) -> int:
    """Plan-only output. Never opens a DB connection."""
    builder = SchemaBuilder(h.NoopConn(), manifest, params)
    plan = builder.plan()
    out.result(
        {
            "ok": True,
            "mode": "check",
            "kind": manifest.kind,
            "schema": params.schema_name,
            "profile": params.profile,
            "target": target_repr or None,
            "plan": [{"phase": p.id, "files": n} for p, n in plan],
            "total_files": sum(n for _, n in plan),
        }
    )
    return 0


def _conn_user(args: argparse.Namespace) -> str:
    try:
        info = conn_mod.resolve(args.conn, args.config)
    except RuntimeError:
        return ""
    return info.user or ""
