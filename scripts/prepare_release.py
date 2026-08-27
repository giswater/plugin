#!/usr/bin/env python3
"""Prepare Giswater plugin releases.

Default mode is dry-run: it prints the file diffs and git commands without
touching the working tree. Use --execute to commit, tag, branch, push and
optionally create the GitHub release.
"""

from __future__ import annotations

import argparse
import sys
from datetime import date
from pathlib import Path

from release_lib import (
    PlannedChange,
    ReleaseError,
    close_unreleased_section,
    create_github_release,
    create_or_switch_branch,
    create_tag,
    ensure_branch_available,
    ensure_clean,
    ensure_dbmodel_ci_green,
    ensure_expected_branch,
    ensure_tag_available,
    git,
    metadata_version,
    parse_version,
    previous_release_for,
    print_file_plan,
    read_text,
    release_notes,
    repo_root,
    stage_and_commit,
    update_metadata_version,
    write_change,
)


def prepare_minor_release(args: argparse.Namespace, root: Path, version) -> None:
    execute = args.execute
    ensure_expected_branch(root, "main", execute=execute)
    if execute:
        ensure_clean(root, execute=True)
    else:
        ensure_clean(root, execute=False)

    changelog_path = root / "CHANGELOG.md"
    metadata_path = root / "metadata.txt"
    changelog = read_text(changelog_path)
    metadata = read_text(metadata_path)

    if metadata_version(metadata) != version:
        raise ReleaseError(
            f"metadata.txt version must be {version.text} before release"
        )

    next_main = version.next_minor
    next_patch = version.next_patch

    new_changelog, _released_body, previous = close_unreleased_section(
        changelog,
        version=version,
        release_date=args.date,
        unreleased_base="main",
    )
    release_body = release_notes(new_changelog, version, previous)

    release_change = PlannedChange(changelog_path, changelog, new_changelog)
    main_metadata_change = PlannedChange(
        metadata_path,
        metadata,
        update_metadata_version(metadata, next_main),
    )
    release_metadata_change = PlannedChange(
        metadata_path,
        metadata,
        update_metadata_version(metadata, next_patch),
    )

    print("== Release changelog commit ==")
    print_file_plan([release_change], root)
    print("== Main next-version metadata ==")
    print_file_plan([main_metadata_change], root)
    print("== Release branch next-version metadata ==")
    print_file_plan([release_metadata_change], root)

    if not execute:
        print_minor_commands(args, root, version)
        ensure_dbmodel_ci_green(root, execute=False)
        if args.create_github_release:
            create_github_release(root, version=version, notes=release_body, execute=False)
        return

    git(root, "fetch", args.remote, "--tags", execute=True)
    git(root / "libs", "fetch", args.remote, "--tags", execute=True)
    ensure_tag_available(root, version.tag, resume=args.resume)
    if not args.skip_libs_tag:
        ensure_tag_available(root / "libs", version.tag, resume=args.resume)
    ensure_branch_available(
        root, args.remote, version.release_branch, resume=args.resume
    )

    write_change(release_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[changelog_path],
        message=f"chore(release): prepare {version.text}",
    )

    if not args.skip_libs_tag:
        create_tag(root / "libs", tag=version.tag, execute=True, resume=args.resume)
        git(root / "libs", "push", args.remote, version.tag, execute=True)

    ensure_dbmodel_ci_green(root, execute=True)

    create_tag(root, tag=version.tag, execute=True, resume=args.resume)
    git(root, "push", args.remote, "main", version.tag, execute=True)

    create_or_switch_branch(
        root,
        remote=args.remote,
        branch=version.release_branch,
        start_point=version.tag,
        execute=True,
        resume=args.resume,
    )
    git(root, "push", "-u", args.remote, version.release_branch, execute=True)

    git(root, "switch", "main", execute=True)
    write_change(main_metadata_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[metadata_path],
        message=f"chore: start {next_main.text} development",
    )
    git(root, "push", args.remote, "main", execute=True)

    git(root, "switch", version.release_branch, execute=True)
    write_change(release_metadata_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[metadata_path],
        message=f"chore: start {next_patch.text} development",
    )
    git(root, "push", args.remote, version.release_branch, execute=True)

    if args.create_github_release:
        create_github_release(root, version=version, notes=release_body, execute=True)


def print_minor_commands(args: argparse.Namespace, root: Path, version) -> None:
    del root
    next_main = version.next_minor
    next_patch = version.next_patch
    print("== Commands dry-run ==")
    git(repo_root(), "fetch", args.remote, "--tags", execute=False)
    git(repo_root() / "libs", "fetch", args.remote, "--tags", execute=False)
    git(repo_root(), "add", "CHANGELOG.md", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore(release): prepare {version.text}",
        execute=False,
    )
    if not args.skip_libs_tag:
        git(
            repo_root() / "libs",
            "tag",
            "-a",
            version.tag,
            "-m",
            f"Release {version.tag}",
            execute=False,
        )
        git(repo_root() / "libs", "push", args.remote, version.tag, execute=False)
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
    git(
        repo_root(),
        "switch",
        "-c",
        version.release_branch,
        version.tag,
        execute=False,
    )
    git(repo_root(), "push", "-u", args.remote, version.release_branch, execute=False)
    git(repo_root(), "switch", "main", execute=False)
    git(repo_root(), "add", "metadata.txt", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore: start {next_main.text} development",
        execute=False,
    )
    git(repo_root(), "push", args.remote, "main", execute=False)
    git(repo_root(), "switch", version.release_branch, execute=False)
    git(repo_root(), "add", "metadata.txt", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore: start {next_patch.text} development",
        execute=False,
    )
    git(repo_root(), "push", args.remote, version.release_branch, execute=False)


def prepare_patch_release(args: argparse.Namespace, root: Path, version) -> None:
    execute = args.execute
    ensure_expected_branch(root, version.release_branch, execute=execute)
    ensure_clean(root, execute=execute)

    changelog_path = root / "CHANGELOG.md"
    metadata_path = root / "metadata.txt"
    changelog = read_text(changelog_path)
    metadata = read_text(metadata_path)

    if metadata_version(metadata) != version:
        raise ReleaseError(
            f"metadata.txt version must be {version.text} before release"
        )

    new_changelog, _released_body, previous = close_unreleased_section(
        changelog,
        version=version,
        release_date=args.date,
        unreleased_base=version.release_branch,
    )
    release_body = release_notes(new_changelog, version, previous)
    next_patch = version.next_patch

    release_change = PlannedChange(changelog_path, changelog, new_changelog)
    next_metadata_change = PlannedChange(
        metadata_path,
        metadata,
        update_metadata_version(metadata, next_patch),
    )

    print("== Release changelog commit ==")
    print_file_plan([release_change], root)
    print("== Release branch next-version metadata ==")
    print_file_plan([next_metadata_change], root)

    if not execute:
        print_patch_commands(args, version)
        ensure_dbmodel_ci_green(root, execute=False)
        if args.create_github_release:
            create_github_release(root, version=version, notes=release_body, execute=False)
        return

    git(root, "fetch", args.remote, "--tags", execute=True)
    git(root / "libs", "fetch", args.remote, "--tags", execute=True)
    ensure_tag_available(root, version.tag, resume=args.resume)
    if not args.skip_libs_tag:
        ensure_tag_available(root / "libs", version.tag, resume=args.resume)

    write_change(release_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[changelog_path],
        message=f"chore(release): prepare {version.text}",
    )

    if not args.skip_libs_tag:
        create_tag(root / "libs", tag=version.tag, execute=True, resume=args.resume)
        git(root / "libs", "push", args.remote, version.tag, execute=True)

    ensure_dbmodel_ci_green(root, execute=True)

    create_tag(root, tag=version.tag, execute=True, resume=args.resume)
    git(root, "push", args.remote, version.release_branch, version.tag, execute=True)

    write_change(next_metadata_change)
    stage_and_commit(
        root,
        execute=True,
        paths=[metadata_path],
        message=f"chore: start {next_patch.text} development",
    )
    git(root, "push", args.remote, version.release_branch, execute=True)

    if args.create_github_release:
        create_github_release(root, version=version, notes=release_body, execute=True)


def create_release_only(args: argparse.Namespace, root: Path, version) -> None:
    from release_lib import ref_exists

    changelog = read_text(root / "CHANGELOG.md")
    previous = previous_release_for(changelog, version)
    notes = release_notes(changelog, version, previous)

    if args.execute and not ref_exists(root, f"refs/tags/{version.tag}"):
        raise ReleaseError(f"Local tag {version.tag} does not exist")

    create_github_release(root, version=version, notes=notes, execute=args.execute)


def print_patch_commands(args: argparse.Namespace, version) -> None:
    print("== Commands dry-run ==")
    git(repo_root(), "fetch", args.remote, "--tags", execute=False)
    git(repo_root() / "libs", "fetch", args.remote, "--tags", execute=False)
    git(repo_root(), "add", "CHANGELOG.md", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore(release): prepare {version.text}",
        execute=False,
    )
    if not args.skip_libs_tag:
        git(
            repo_root() / "libs",
            "tag",
            "-a",
            version.tag,
            "-m",
            f"Release {version.tag}",
            execute=False,
        )
        git(repo_root() / "libs", "push", args.remote, version.tag, execute=False)
    git(
        repo_root(),
        "tag",
        "-a",
        version.tag,
        "-m",
        f"Release {version.tag}",
        execute=False,
    )
    git(repo_root(), "push", args.remote, version.release_branch, version.tag, execute=False)
    git(repo_root(), "add", "metadata.txt", execute=False)
    git(
        repo_root(),
        "commit",
        "-m",
        f"chore: start {version.next_patch.text} development",
        execute=False,
    )
    git(repo_root(), "push", args.remote, version.release_branch, execute=False)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Prepare Giswater release")
    parser.add_argument("version", help="Release version, e.g. 4.9.0 or 4.9.1")
    parser.add_argument(
        "--execute",
        action="store_true",
        help="Apply file changes and run git commands. Default is dry-run.",
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
        "--skip-libs-tag",
        action="store_true",
        help="Do not create/push the matching tag in libs.",
    )
    parser.add_argument(
        "--resume",
        action="store_true",
        help="Continue if expected tags already exist.",
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
        version = parse_version(args.version)
        if args.github_release_only:
            create_release_only(args, root, version)
            return 0
        if version.is_minor_release:
            prepare_minor_release(args, root, version)
        else:
            prepare_patch_release(args, root, version)
    except ReleaseError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
