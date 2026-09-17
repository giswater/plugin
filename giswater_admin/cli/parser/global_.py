"""Shared argparse flags for ``gw`` subcommands."""

from __future__ import annotations

import argparse

from ...install.dbmodel_paths import REPO_ROOT


def global_parent(*, needs_dbmodel: bool = True) -> argparse.ArgumentParser:
    parent = argparse.ArgumentParser(add_help=False)
    parent.add_argument("--json", action="store_true",
                        help="Machine-readable output on stdout.")
    parent.add_argument("--quiet", action="store_true",
                        help="Suppress info-level progress on stderr.")
    parent.add_argument("-v", "--verbose", action="store_true",
                        help="Log each executed SQL path on stderr (exec: lines).")
    parent.add_argument("-d", "--debug", action="store_true",
                        help="Like -v plus DEBUG logs with SQL previews (giswater_admin loggers).")
    parent.add_argument("--timing", action="store_true",
                        help="Print timing summary on stderr; with -v, include ms per file.")
    parent.add_argument("--timing-threshold-ms", type=int, default=0, metavar="N",
                        help="With -v --timing, only log files taking at least N ms.")
    parent.add_argument("--timing-top", type=int, default=20, metavar="K",
                        help="Number of slowest files in timing summary (default: 20).")
    parent.add_argument("--timing-detail", action="store_true",
                        help="With --json --timing, include per-file timings in output.")
    if needs_dbmodel:
        parent.add_argument(
            "--dbmodel-path",
            default=None,
            help=(
                "dbmodel root (default: config/cache, repo sibling dbmodel/, "
                f"or {REPO_ROOT}/dbmodel in a checkout)."
            ),
        )
    return parent


def add_conn_args(sp: argparse.ArgumentParser) -> None:
    g = sp.add_argument_group("connection")
    g.add_argument("--conn", default=None,
                   help="postgres URL, service=NAME, or a pg_service name")
    g.add_argument("--config", default=None,
                   help="YAML with host/port/user/password/dbname/service.")


def add_version_arg(sp: argparse.ArgumentParser) -> None:
    sp.add_argument(
        "--version",
        default=None,
        dest="version",
        help="Target Giswater schema version X.Y.Z (default: active dbmodel).",
    )
    sp.add_argument(
        "--plugin-version",
        default=None,
        help=argparse.SUPPRESS,
    )
    sp.add_argument(
        "--to-version",
        default=None,
        help=argparse.SUPPRESS,
    )
