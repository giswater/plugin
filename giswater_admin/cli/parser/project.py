"""Register ``gw project`` subcommands."""

from __future__ import annotations

import argparse

from ...commands import project_cmd
from ..context import CommandSpec, set_command_spec
from .global_ import add_conn_args


def register(sub: argparse._SubParsersAction, parent: argparse.ArgumentParser) -> None:  # noqa: SLF001
    project = sub.add_parser("project", help="Create QGIS project files.")
    psub = project.add_subparsers(dest="project_action", required=True)

    create = psub.add_parser(
        "create",
        help="Create a .qgs file from a Giswater main schema.",
        parents=[parent],
    )
    create.add_argument("--schema", required=True, help="Existing ws/ud schema.")
    create.add_argument("--type", required=True, choices=["ws", "ud"])
    create.add_argument("--out", required=True, help="Output directory.")
    create.add_argument("--name", default=None, help="Output filename without .qgs.")
    create.add_argument(
        "--export-passwd",
        action="store_true",
        help="Store the database password in layer URIs.",
    )
    create.add_argument("--force", action="store_true", help="Overwrite an existing .qgs file.")
    add_conn_args(create)
    set_command_spec(create, CommandSpec(project_cmd.run_create))
