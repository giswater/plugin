"""Smoke tests for the ``gw`` argument parser."""

from __future__ import annotations

from giswater_admin.cli.main import main
from giswater_admin.cli.parser import build_parser


def test_build_parser_has_core_subcommands() -> None:
    parser = build_parser()
    commands = parser._subparsers._actions[-1].choices  # noqa: SLF001
    for name in (
        "version",
        "config",
        "dbmodel",
        "schema",
        "project",
        "network",
        "db",
        "manifest",
    ):
        assert name in commands
    for legacy in ("create", "update", "drop", "status", "init-db", "update-network", "audit"):
        assert legacy not in commands


def test_schema_main_create_parses() -> None:
    args = build_parser().parse_args(
        ["schema", "main", "create", "--type", "ws", "--name", "demo", "--check"]
    )
    assert args.type == "ws"
    assert args.name == "demo"
    assert args.check is True


def test_schema_list_parses() -> None:
    args = build_parser().parse_args(
        ["schema", "list", "--tier", "main", "--type", "ws", "--type", "ud"]
    )
    assert args.tier == "main"
    assert args.schema_types == ["ws", "ud"]


def test_project_create_parses() -> None:
    args = build_parser().parse_args(
        [
            "project",
            "create",
            "--schema",
            "ws_sample",
            "--type",
            "ws",
            "--out",
            "/tmp/qgs",
            "--force",
        ]
    )
    assert args.schema == "ws_sample"
    assert args.type == "ws"
    assert args.out == "/tmp/qgs"
    assert args.force is True


def test_network_update_parses() -> None:
    args = build_parser().parse_args(
        ["network", "update", "--version", "4.16.0", "--check"]
    )
    assert args.version == "4.16.0"
    assert args.check is True


def test_main_version_exit_zero() -> None:
    assert main(["version"]) == 0


def test_main_help_does_not_crash(capsys) -> None:
    try:
        build_parser().parse_args(["--help"])
    except SystemExit as exc:
        assert exc.code == 0
