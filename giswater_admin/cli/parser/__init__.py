"""Assemble the top-level ``gw`` argument parser."""

from __future__ import annotations

import argparse

from .db import register as register_db
from .global_ import global_parent
from .manifest import register as register_manifest
from .meta import register as register_meta
from .network import register as register_network
from .project import register as register_project
from .schema_group import register as register_schema


def build_parser() -> argparse.ArgumentParser:
    parent = global_parent()
    parser = argparse.ArgumentParser(
        prog="gw",
        description=(
            "Giswater headless dbmodel schema lifecycle CLI. "
            "Global options (--json, --quiet, --dbmodel-path) go AFTER the subcommand."
        ),
    )
    sub = parser.add_subparsers(dest="command", required=True)

    register_meta(sub)
    register_schema(sub, parent)
    register_project(sub, parent)
    register_network(sub, parent)
    register_db(sub, parent)
    register_manifest(sub, parent)

    return parser
