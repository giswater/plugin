"""Register ``gw schema`` subcommands."""

from __future__ import annotations

import argparse

from ...commands import schema_cmd
from ..context import CommandSpec, set_command_spec
from .global_ import add_conn_args, add_version_arg


def _spec(handler, *, needs_dbmodel=True, needs_schema_version=True) -> CommandSpec:
    return CommandSpec(handler, needs_dbmodel=needs_dbmodel, needs_schema_version=needs_schema_version)


def _add_schema_common(sp: argparse.ArgumentParser) -> None:
    add_conn_args(sp)
    add_version_arg(sp)
    sp.add_argument("--locale", default="en_US", help=argparse.SUPPRESS)
    sp.add_argument("--lang", default=None, help="Locale for ws/ud (e.g. es_ES).")
    sp.add_argument("--check", action="store_true", help="Plan only; do not execute.")


def register(sub: argparse._SubParsersAction, parent: argparse.ArgumentParser) -> None:  # noqa: SLF001
    sp = sub.add_parser("schema", help="Create, update, integrate and drop Giswater schemas.")
    ssub = sp.add_subparsers(dest="schema_tier", required=True)

    # ── main ──────────────────────────────────────────────────────────
    main = ssub.add_parser("main", help="ws/ud project schemas.")
    msub = main.add_subparsers(dest="schema_action", required=True)

    sp_mc = msub.add_parser("create", help="Create a ws or ud schema.", parents=[parent])
    sp_mc.add_argument("--type", required=True, choices=["ws", "ud"])
    sp_mc.add_argument("--name", default=None, help="Schema name (default: same as --type).")
    sp_mc.add_argument(
        "--profile",
        default="empty",
        choices=["empty", "sample", "inventory", "dev"],
    )
    sp_mc.add_argument("--srid", default="25831")
    _add_schema_common(sp_mc)
    set_command_spec(sp_mc, _spec(schema_cmd.run_main_create))

    sp_mu = msub.add_parser("update", help="Upgrade one ws/ud schema.", parents=[parent])
    sp_mu.add_argument("--name", required=True)
    _add_schema_common(sp_mu)
    set_command_spec(sp_mu, _spec(schema_cmd.run_main_update))

    sp_md = msub.add_parser("drop", help="Drop one ws/ud schema.", parents=[parent])
    sp_md.add_argument("--name", required=True)
    sp_md.add_argument("--yes", action="store_true")
    sp_md.add_argument("--cascade", action="store_true")
    add_conn_args(sp_md)
    sp_md.add_argument("--check", action="store_true")
    set_command_spec(sp_md, _spec(schema_cmd.run_main_drop, needs_schema_version=False))

    # ── addon ─────────────────────────────────────────────────────────
    addon = ssub.add_parser("addon", help="Shared satellite schemas (utils, cibs, …).")
    asub = addon.add_subparsers(dest="schema_action", required=True)

    sp_ac = asub.add_parser("create", help="Bootstrap an addon schema.", parents=[parent])
    sp_ac.add_argument(
        "--type",
        required=True,
        metavar="KIND",
        help="Addon kind (any manifest under dbmodel/manifests/, e.g. utils, publi).",
    )
    sp_ac.add_argument("--name", default=None)
    sp_ac.add_argument(
        "--profile",
        default="empty",
        choices=["empty", "sample", "inventory"],
        help="empty|sample for am; ignored for most other addons.",
    )
    sp_ac.add_argument(
        "--srid",
        default=None,
        help="EPSG for geometry columns. Default: unique ws/ud sys_version.epsg, else 25831.",
    )
    _add_schema_common(sp_ac)
    set_command_spec(sp_ac, _spec(schema_cmd.run_addon_create))

    sp_ai = asub.add_parser("integrate", help="Wire an addon into a ws/ud parent.", parents=[parent])
    sp_ai.add_argument(
        "--type",
        required=True,
        metavar="KIND",
        help="Addon kind (see `gw manifest list`).",
    )
    sp_ai.add_argument(
        "--parent",
        required=True,
        help="Parent schema name (WS or UD; am requires WS project_type in sys_version).",
    )
    sp_ai.add_argument("--name", default=None)
    sp_ai.add_argument(
        "--profile",
        default="empty",
        choices=["empty", "sample", "inventory"],
        help="empty|sample for am integrate (sample seeds parent catalogs).",
    )
    sp_ai.add_argument(
        "--srid",
        default=None,
        help="EPSG for geometry columns. Default: parent sys_version.epsg, else 25831.",
    )
    _add_schema_common(sp_ai)
    set_command_spec(sp_ai, _spec(schema_cmd.run_addon_integrate))

    sp_au = asub.add_parser("update", help="Upgrade a standalone addon.", parents=[parent])
    sp_au.add_argument(
        "--type",
        required=True,
        metavar="KIND",
        help="Addon kind (see `gw manifest list`).",
    )
    sp_au.add_argument("--name", default=None)
    _add_schema_common(sp_au)
    set_command_spec(sp_au, _spec(schema_cmd.run_addon_update))

    sp_ad = asub.add_parser("drop", help="Drop an addon schema.", parents=[parent])
    sp_ad.add_argument(
        "--type",
        required=True,
        metavar="KIND",
        help="Addon kind (see `gw manifest list`).",
    )
    sp_ad.add_argument("--name", default=None)
    sp_ad.add_argument("--yes", action="store_true")
    sp_ad.add_argument("--cascade", action="store_true")
    add_conn_args(sp_ad)
    sp_ad.add_argument("--check", action="store_true")
    set_command_spec(sp_ad, _spec(schema_cmd.run_addon_drop, needs_schema_version=False))

    # ── list (read-only inventory) ────────────────────────────────────
    sp_list = ssub.add_parser(
        "list",
        help="List Giswater schemas in the database (read-only).",
        parents=[parent],
    )
    sp_list.add_argument(
        "--tier",
        default="all",
        choices=["all", "main", "addon"],
        help="main=ws/ud, addon=any non-main manifest kind.",
    )
    sp_list.add_argument(
        "--type",
        action="append",
        dest="schema_types",
        metavar="KIND",
        help="Filter by project type (repeatable; see `gw manifest list`).",
    )
    add_conn_args(sp_list)
    set_command_spec(
        sp_list,
        CommandSpec(schema_cmd.run_schema_list, needs_dbmodel=False),
    )
