"""Adapters for ``gw schema main|addon`` subcommands."""

from __future__ import annotations

import argparse
import copy

from ..cli.version_args import normalize_version_args
from ..engine.manifest_registry import (
    default_schema_name,
    integrate_profile,
    is_main_kind,
    resolve_create_profile,
    resolve_integrate_cli_profile,
)
from ..engine.schema_catalog import (
    discover_database_network,
    graph_has_linked_dependents,
    make_conn_fetcher,
)
from ..engine.version_guard import assert_no_downgrade
from ..output import Out
from . import create as cmd_create
from . import drop as cmd_drop
from . import update as cmd_update

_MAIN_PROFILE_MAP = {
    "empty": "empty",
    "sample": "sample_full",
    "inventory": "sample_inv",
}

# Fields that legacy ``create`` expects but new ``schema`` parsers omit.
_CREATE_LEGACY_DEFAULTS = {
    "srid": "25831",
    "locale": "en_US",
    "ws_schema": None,
    "ud_schema": None,
    "parent_schema": None,
    "parent_type": None,
    "am_target": None,
    "main_version": None,
    "db_user": None,
    "copy_source_schema": None,
    "with_checkproject": False,
}


def _legacy_args(args: argparse.Namespace, **overrides) -> argparse.Namespace:
    legacy = copy.copy(args)
    for key, default in _CREATE_LEGACY_DEFAULTS.items():
        if not hasattr(legacy, key):
            setattr(legacy, key, default)
    for key, value in overrides.items():
        setattr(legacy, key, value)
    normalize_version_args(legacy)
    return legacy


def _resolve_name(args: argparse.Namespace, schema_type: str) -> str:
    return str(getattr(args, "name", None) or default_schema_name(schema_type))


def _resolve_target_version(args: argparse.Namespace) -> str | None:
    return (
        getattr(args, "version", None)
        or getattr(args, "to_version", None)
        or getattr(args, "plugin_version", None)
    )


def run_main_create(args: argparse.Namespace, out: Out) -> int:
    schema_type = args.type.lower()
    if not is_main_kind(schema_type):
        out.error(f"schema main create: --type must be ws|ud, got '{args.type}'.")
        return 1
    profile = _MAIN_PROFILE_MAP.get(args.profile, args.profile)
    name = _resolve_name(args, schema_type)
    legacy = _legacy_args(
        args,
        kind=schema_type,
        schema=name,
        profile=profile,
        locale=getattr(args, "lang", None) or getattr(args, "locale", "en_US"),
    )
    return cmd_create.run(legacy, out)


def run_addon_create(args: argparse.Namespace, out: Out) -> int:
    from . import _helpers as h  # noqa: WPS433

    schema_type = args.type.lower()
    if not h.validate_tier_kind(args.dbmodel_path, schema_type, tier="addon", out=out):
        return 1

    name = _resolve_name(args, schema_type)
    cli_profile = getattr(args, "profile", None) or "empty"
    if schema_type == "am" and cli_profile == "inventory":
        out.error("schema addon create: inventory profile is not supported for am.")
        return 1

    profile = resolve_create_profile(schema_type, cli_profile)
    manifest = h.manifest_for(args, schema_type)
    if profile not in manifest.profiles:
        out.error(
            f"schema addon create --type {schema_type}: profile '{profile}' "
            f"not in manifest. Known: {sorted(manifest.profiles)}"
        )
        return 1

    legacy = _legacy_args(args, kind=schema_type, schema=name, profile=profile)
    return cmd_create.run(legacy, out)


def run_addon_integrate(args: argparse.Namespace, out: Out) -> int:
    from . import _helpers as h  # noqa: WPS433

    schema_type = args.type.lower()
    if not h.validate_tier_kind(args.dbmodel_path, schema_type, tier="addon", out=out):
        return 1

    manifest = h.manifest_for(args, schema_type)
    parent = args.parent
    name = _resolve_name(args, schema_type)
    cli_profile = getattr(args, "profile", None) or "empty"

    if schema_type == "am" and cli_profile == "inventory":
        out.error("schema addon integrate: inventory profile is not supported for am.")
        return 1

    profile = resolve_integrate_cli_profile(schema_type, cli_profile)
    parent_schema = parent
    ws_schema = None
    ud_schema = None
    parent_type = ""

    if profile is None:
        if h.needs_connection(args) and not args.check:
            conn = h.open_conn(args, out)
            try:
                parent_type = h.detect_project_type(conn, parent) or ""
            finally:
                conn.close()
        elif args.check:
            parent_type = "ws"

        profile = integrate_profile(manifest, parent_type or "ws")
        if not profile:
            out.error(
                f"schema addon integrate --type {schema_type}: no integrate profile "
                f"for parent type '{parent_type or '?'}'. "
                f"Manifest profiles: {sorted(manifest.profiles)}"
            )
            return 1

        if parent_type == "ud":
            ud_schema = parent
            if schema_type != "utils":
                parent_schema = parent
        else:
            ws_schema = parent
            if schema_type == "utils":
                parent_schema = None
            else:
                parent_schema = parent

    legacy = _legacy_args(
        args,
        kind=schema_type,
        schema=name if schema_type != "utils" else "utils",
        profile=profile,
        parent_schema=parent_schema or parent,
        parent_type=parent_type or None,
        ws_schema=ws_schema,
        ud_schema=ud_schema,
    )
    return cmd_create.run(legacy, out)


def run_main_update(args: argparse.Namespace, out: Out) -> int:
    name = args.name
    target = _resolve_target_version(args)
    normalize_version_args(args)

    conn = None
    from . import _helpers as h  # noqa: WPS433

    if h.needs_connection(args) and not args.check:
        conn = h.open_conn(args, out)
        fetcher = make_conn_fetcher(conn)
        db = discover_database_network(fetcher, schema_filter=name)
        graph = db.cluster
        if graph_has_linked_dependents(graph, name):
            peers = sorted(n.schema for n in graph.nodes if n.schema != name)
            hint = graph.suggested_update_command(target or "")
            out.error(
                f"Schema '{name}' is part of an interconnected network "
                f"({', '.join(peers)}). Use {hint} instead."
            )
            conn.close()
            return 1
        current = h.detect_project_version(conn, name) or "0.0.0"
        err = assert_no_downgrade(current, target or "", label=f"schema '{name}'")
        if err:
            out.error(err)
            conn.close()
            return 1
        conn.close()

    legacy = _legacy_args(
        args,
        schema=name,
        kind=None,
        to_version=target,
        force=False,
    )
    return cmd_update.run(legacy, out)


def run_addon_update(args: argparse.Namespace, out: Out) -> int:
    from . import _helpers as h  # noqa: WPS433

    schema_type = args.type.lower()
    if not h.validate_tier_kind(args.dbmodel_path, schema_type, tier="addon", out=out):
        return 1

    name = _resolve_name(args, schema_type)
    target = _resolve_target_version(args)
    normalize_version_args(args)

    if h.needs_connection(args) and not args.check:
        conn = h.open_conn(args, out)
        fetcher = make_conn_fetcher(conn)
        db = discover_database_network(fetcher, schema_filter=name)
        graph = db.cluster
        if graph_has_linked_dependents(graph, name):
            hint = graph.suggested_update_command(target or "")
            out.error(
                f"Addon '{name}' is integrated in a network. Use {hint} instead."
            )
            conn.close()
            return 1
        current = h.detect_project_version(conn, name) or "0.0.0"
        err = assert_no_downgrade(current, target or "", label=f"addon '{name}'")
        if err:
            out.error(err)
            conn.close()
            return 1
        conn.close()

    legacy = _legacy_args(
        args,
        schema=name,
        kind=schema_type,
        to_version=target,
        force=False,
    )
    return cmd_update.run(legacy, out)


def run_main_drop(args: argparse.Namespace, out: Out) -> int:
    legacy = _legacy_args(args, schema=args.name)
    return cmd_drop.run(legacy, out)


def run_addon_drop(args: argparse.Namespace, out: Out) -> int:
    from . import _helpers as h  # noqa: WPS433

    schema_type = args.type.lower()
    if not h.validate_tier_kind(args.dbmodel_path, schema_type, tier="addon", out=out):
        return 1

    name = _resolve_name(args, schema_type)
    legacy = _legacy_args(args, schema=name)
    return cmd_drop.run(legacy, out)


def run_schema_list(args: argparse.Namespace, out: Out) -> int:
    from . import network as cmd_network  # noqa: WPS433

    return cmd_network._run_schema_list(args, out)
