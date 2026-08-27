#!/usr/bin/env python3
"""Prepare giswater-cli releases.

Default mode is dry-run: it prints the file diffs and git commands without
touching the working tree. Use --execute to commit, tag, push and optionally
create the GitHub release.
"""

from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from release_lib import (
    REPO_URL,
    PlannedChange,
    ReleaseError,
    bump_cli_version_text,
    cli_version_from_module,
    cli_version_from_pyproject,
    close_unreleased_section,
    create_github_release,
    create_tag,
    ensure_clean,
    ensure_expected_branch,
    ensure_tag_available,
    ensure_ruff,
    extract_release_section,
    git,
    initial_release_notes,
    parse_cli_version,
    print_file_plan,
    read_text,
    ref_exists,
    release_notes,
    repo_root,
    stage_and_commit,
    write_change,
)

CLI_DOCS_URL = f"{REPO_URL}/blob/main/giswater_admin/README.md"


def prepare_cli_release(args: argparse.Namespace, root: Path, version) -> None:
    if args.initial_release:
        prepare_initial_cli_release(args, root, version)
        return
    prepare_standard_cli_release(args, root, version)


def prepare_initial_cli_release(args: argparse.Namespace, root: Path, version) -> None:
    """First PyPI release: changelog section already exists, only tag and bump."""
    execute = args.execute
    ensure_expected_branch(root, "main", execute=execute)
    ensure_clean(root, execute=execute)
    ensure_ruff(root)

    changelog_path = root / "giswater_admin" / "CHANGELOG.md"
    pyproject_path = root / "pyproject.toml"
    version_path = root / "giswater_admin" / "__version__.py"

    changelog = read_text(changelog_path)
    pyproject = read_text(pyproject_path)
    module_version = read_text(version_path)

    current_pyproject = cli_version_from_pyproject(pyproject)
    current_module = cli_version_from_module(module_version)
    if current_pyproject != version or current_module != version:
        raise ReleaseError(
            f"CLI version must be {version.text} in pyproject.toml and "
            f"giswater_admin/__version__.py before release "
            f"(found {current_pyproject.text} / {current_module.text})"
        )

    extract_release_section(changelog, version)
    release_body = initial_release_notes(
        changelog, version, docs_url=CLI_DOCS_URL
    )
    next_patch = version.next_patch

    next_pyproject = bump_cli_version_text(pyproject_path, pyproject, next_patch)
    next_module = bump_cli_version_text(version_path, module_version, next_patch)
    next_pyproject_change = PlannedChange(pyproject_path, pyproject, next_pyproject)
    next_module_change = PlannedChange(version_path, module_version, next_module)

    print("== Initial release (no CHANGELOG edit) ==")
    print(f"Tag {version.tag} at current commit, then bump to {next_patch.text}")
    print("== Next development version ==")
    print_file_plan([next_pyproject_change, next_module_change], root)

    if not execute:
        print_initial_cli_commands(args, version, next_patch)
        if args.create_github_release:
            create_github_release(root, version=version, notes=release_body, execute=False)
        return

    git(root, "fetch", args.remote, "--tags", execute=True)
    ensure_tag_available(root, version.tag, resume=args.resume)

    create_tag(root, tag=version.tag, execute=True, resume=args.resume)
    git(root, "push", args.remote, "main", version.tag, execute=True)

    write_change(next_pyproject_change)
    write_change(next_module_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[pyproject_path, version_path],
        message=f"chore(cli): start {next_patch.text} development",
    )
    git(root, "push", args.remote, "main", execute=True)

    if args.create_github_release:
        create_github_release(root, version=version, notes=release_body, execute=True)


def prepare_standard_cli_release(args: argparse.Namespace, root: Path, version) -> None:
    execute = args.execute
    ensure_expected_branch(root, "main", execute=execute)
    ensure_clean(root, execute=execute)
    ensure_ruff(root)

    changelog_path = root / "giswater_admin" / "CHANGELOG.md"
    pyproject_path = root / "pyproject.toml"
    version_path = root / "giswater_admin" / "__version__.py"

    changelog = read_text(changelog_path)
    pyproject = read_text(pyproject_path)
    module_version = read_text(version_path)

    current_pyproject = cli_version_from_pyproject(pyproject)
    current_module = cli_version_from_module(module_version)
    if current_pyproject != version or current_module != version:
        raise ReleaseError(
            f"CLI version must be {version.text} in pyproject.toml and "
            f"giswater_admin/__version__.py before release "
            f"(found {current_pyproject.text} / {current_module.text})"
        )

    new_changelog, _released_body, previous = close_unreleased_section(
        changelog,
        version=version,
        release_date=args.date,
        unreleased_base="main",
    )
    if previous is None:
        release_body = initial_release_notes(
            new_changelog, version, docs_url=CLI_DOCS_URL
        )
    else:
        release_body = release_notes(
            new_changelog,
            version,
            previous,
            docs_url=CLI_DOCS_URL,
        )
    next_patch = version.next_patch

    release_change = PlannedChange(changelog_path, changelog, new_changelog)
    next_pyproject = bump_cli_version_text(pyproject_path, pyproject, next_patch)
    next_module = bump_cli_version_text(version_path, module_version, next_patch)
    next_pyproject_change = PlannedChange(pyproject_path, pyproject, next_pyproject)
    next_module_change = PlannedChange(version_path, module_version, next_module)

    print("== Release changelog commit ==")
    print_file_plan([release_change], root)
    print("== Next development version ==")
    print_file_plan([next_pyproject_change, next_module_change], root)

    if not execute:
        print_standard_cli_commands(args, version, next_patch)
        if args.create_github_release:
            create_github_release(root, version=version, notes=release_body, execute=False)
        return

    git(root, "fetch", args.remote, "--tags", execute=True)
    ensure_tag_available(root, version.tag, resume=args.resume)

    write_change(release_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[changelog_path],
        message=f"chore(cli): release {version.text}",
    )

    create_tag(root, tag=version.tag, execute=True, resume=args.resume)
    git(root, "push", args.remote, "main", version.tag, execute=True)

    write_change(next_pyproject_change)
    write_change(next_module_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[pyproject_path, version_path],
        message=f"chore(cli): start {next_patch.text} development",
    )
    git(root, "push", args.remote, "main", execute=True)

    if args.create_github_release:
        create_github_release(root, version=version, notes=release_body, execute=True)


def create_release_only(args: argparse.Namespace, root: Path, version) -> None:
    from release_lib import initial_release_notes, previous_release_for

    ensure_ruff(root)

    changelog_path = root / "giswater_admin" / "CHANGELOG.md"
    changelog = read_text(changelog_path)
    try:
        previous = previous_release_for(changelog, version)
        notes = release_notes(changelog, version, previous, docs_url=CLI_DOCS_URL)
    except ReleaseError:
        notes = initial_release_notes(changelog, version, docs_url=CLI_DOCS_URL)

    if args.execute and not ref_exists(root, f"refs/tags/{version.tag}"):
        raise ReleaseError(f"Local tag {version.tag} does not exist")

    create_github_release(root, version=version, notes=notes, execute=args.execute)


def print_initial_cli_commands(args: argparse.Namespace, version, next_patch) -> None:
    print("== Commands dry-run ==")
    git(repo_root(), "fetch", args.remote, "--tags", execute=False)
    git(
        repo_root(),
        "tag",
        "-a",
        version.tag,
        "-m",
        f"Release {version.tag}",
        execute=False,
    )
    git(repo_root(), "push", args.remote, "main", version.tag, execute=False)
    git(repo_root(), "add", "pyproject.toml", "giswater_admin/__version__.py", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore(cli): start {next_patch.text} development",
        execute=False,
    )
    git(repo_root(), "push", args.remote, "main", execute=False)


def print_standard_cli_commands(args: argparse.Namespace, version, next_patch) -> None:
    print("== Commands dry-run ==")
    git(repo_root(), "fetch", args.remote, "--tags", execute=False)
    git(repo_root(), "add", "giswater_admin/CHANGELOG.md", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore(cli): release {version.text}",
        execute=False,
    )
    git(
        repo_root(),
        "tag",
        "-a",
        version.tag,
        "-m",
        f"Release {version.tag}",
        execute=False,
    )
    git(repo_root(), "push", args.remote, "main", version.tag, execute=False)
    git(repo_root(), "add", "pyproject.toml", "giswater_admin/__version__.py", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore(cli): start {next_patch.text} development",
        execute=False,
    )
    git(repo_root(), "push", args.remote, "main", execute=False)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Prepare giswater-cli release")
    parser.add_argument("version", help="Release version, e.g. 0.1.0 or cli-v0.2.0")
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Apply file changes and run git commands. Default is dry-run.",
    )
    parser.add_argument(
        "--initial-release",
        action="store_true",
        help="First PyPI release: tag without editing CHANGELOG (section must exist).",
    )
    parser.add_argument(
        "--create-github-release",
        action="store_true",
        help="Create a published GitHub Release using gh.",
    )
    parser.add_argument(
        "--github-release-only",
        action="store_true",
        help="Only create the GitHub Release from the existing CHANGELOG.md section.",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Continue if the release tag already exists.",
    )
    parser.add_argument(
        "--date",
        default=date.today().isoformat(),
        help="Release date for CHANGELOG.md. Default: today.",
    )
    parser.add_argument(
        "--remote",
        default="origin",
        help="Git remote to push to. Default: origin.",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    root = repo_root()
    try:
        version = parse_cli_version(args.version)
        if args.github_release_only:
            create_release_only(args, root, version)
            return 0
        prepare_cli_release(args, root, version)
    except ReleaseError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
