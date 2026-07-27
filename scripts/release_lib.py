"""Shared helpers for Giswater plugin and CLI release scripts."""

from __future__ import annotations

import difflib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path


REPO_URL = "https://github.com/giswater/plugin"
GH_REPO = "giswater/plugin"
DOCS_URL = "https://docs.giswater.org/latest/en/docs/index.html"
CLI_RUFF_PATHS = ("giswater_admin", "scripts")


@dataclass(frozen=True)
class Version:
    major: int
    minor: int
    patch: int
    tag_prefix: str = "v"

    @property
    def text(self) -> str:
        return f"{self.major}.{self.minor}.{self.patch}"

    @property
    def tag(self) -> str:
        return f"{self.tag_prefix}{self.text}"

    @property
    def release_branch(self) -> str:
        return f"release/{self.major}.{self.minor}"

    @property
    def is_minor_release(self) -> bool:
        return self.patch == 0

    @property
    def next_minor(self) -> Version:
        return Version(self.major, self.minor + 1, 0, self.tag_prefix)

    @property
    def next_patch(self) -> Version:
        return Version(self.major, self.minor, self.patch + 1, self.tag_prefix)


@dataclass
class PlannedChange:
    path: Path
    old_text: str
    new_text: str

    @property
    def changed(self) -> bool:
        return self.old_text != self.new_text


class ReleaseError(RuntimeError):
    pass


def parse_version(raw: str, *, tag_prefix: str = "v") -> Version:
    match = re.fullmatch(r"v?(\d+)\.(\d+)\.(\d+)", raw.strip())
    if not match:
        raise ReleaseError(f"Invalid version '{raw}'. Expected X.Y.Z or vX.Y.Z")
    return Version(*(int(part) for part in match.groups()), tag_prefix=tag_prefix)


def parse_cli_version(raw: str) -> Version:
    cleaned = raw.strip()
    if cleaned.startswith("cli-v"):
        cleaned = cleaned[4:]
    return parse_version(cleaned, tag_prefix="cli-v")


def repo_root() -> Path:
    return Path(__file__).resolve().parents[1]


def run(
    args: list[str],
    *,
    cwd: Path,
    execute: bool,
    check: bool = True,
    capture: bool = False,
) -> str:
    rendered = " ".join(shell_quote(arg) for arg in args)
    if not execute:
        root = repo_root()
        if cwd != root:
            try:
                rel_cwd = cwd.relative_to(root)
                print(f"$ (cd {shell_quote(str(rel_cwd))} && {rendered})")
            except ValueError:
                print(f"$ (cd {shell_quote(str(cwd))} && {rendered})")
        else:
            print(f"$ {rendered}")
        return ""

    completed = subprocess.run(
        args,
        cwd=str(cwd),
        text=True,
        capture_output=capture,
        check=False,
    )
    if check and completed.returncode:
        stderr = completed.stderr.strip() if completed.stderr else ""
        stdout = completed.stdout.strip() if completed.stdout else ""
        detail = "\n".join(part for part in (stdout, stderr) if part)
        raise ReleaseError(f"Command failed: {rendered}\n{detail}")
    if capture:
        return completed.stdout.strip()
    return ""


def git(
    root: Path,
    *args: str,
    execute: bool = True,
    check: bool = True,
    capture: bool = False,
) -> str:
    return run(["git", *args], cwd=root, execute=execute, check=check, capture=capture)


def shell_quote(value: str) -> str:
    if re.fullmatch(r"[A-Za-z0-9_./:=@%+-]+", value):
        return value
    return "'" + value.replace("'", "'\"'\"'") + "'"


def current_branch(root: Path) -> str:
    return git(root, "branch", "--show-current", capture=True)


def ensure_clean(root: Path, *, execute: bool) -> None:
    status = git(root, "status", "--porcelain", capture=True)
    if not status:
        return
    if execute:
        raise ReleaseError("Working tree is not clean:\n" + status)
    print("WARNING: working tree is not clean; dry-run continues:\n" + status)


def ensure_ruff(root: Path, *, paths: tuple[str, ...] = CLI_RUFF_PATHS) -> None:
    """Run ruff on CLI-related paths before tagging or publishing."""
    config = root / "ruff.toml"
    if not config.is_file():
        raise ReleaseError(f"Missing ruff config: {config}")
    try:
        subprocess.run(
            [sys.executable, "-m", "ruff", "--version"],
            cwd=str(root),
            capture_output=True,
            check=True,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        raise ReleaseError(
            "ruff is required for CLI releases. Install with: pip install ruff"
        ) from exc
    result = subprocess.run(
        [sys.executable, "-m", "ruff", "check", *paths, "--config", str(config)],
        cwd=str(root),
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        output = "\n".join(
            line for line in (result.stdout + result.stderr).splitlines() if line.strip()
        )
        raise ReleaseError(
            f"ruff check failed ({', '.join(paths)}). "
            f"Fix lint issues before releasing.\n{output}"
        )
    print(f"== ruff check OK ({', '.join(paths)})")


def ensure_expected_branch(root: Path, expected: str, *, execute: bool) -> None:
    branch = current_branch(root)
    if branch == expected:
        return
    message = f"Expected branch '{expected}', current branch is '{branch}'"
    if execute:
        raise ReleaseError(message)
    print(f"WARNING: {message}; dry-run continues")


def ref_exists(root: Path, ref: str) -> bool:
    subprocess_result = subprocess.run(
        ["git", "rev-parse", "--verify", "--quiet", ref],
        cwd=str(root),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return subprocess_result.returncode == 0


def local_or_remote_branch_exists(root: Path, remote: str, branch: str) -> bool:
    return ref_exists(root, f"refs/heads/{branch}") or ref_exists(
        root, f"refs/remotes/{remote}/{branch}"
    )


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_change(change: PlannedChange) -> None:
    if change.changed:
        change.path.write_text(change.new_text, encoding="utf-8")


def unified_diff(change: PlannedChange, root: Path) -> str:
    rel = change.path.relative_to(root)
    return "".join(
        difflib.unified_diff(
            change.old_text.splitlines(keepends=True),
            change.new_text.splitlines(keepends=True),
            fromfile=f"a/{rel}",
            tofile=f"b/{rel}",
        )
    )


def find_headings(changelog: str) -> list[tuple[str, int]]:
    pattern = re.compile(r"^## \[(Unreleased|\d+\.\d+\.\d+)\](?: - .*)?$", re.M)
    return [(match.group(1), match.start()) for match in pattern.finditer(changelog)]


def release_versions_from_headings(changelog: str, *, tag_prefix: str = "v") -> list[Version]:
    versions: list[Version] = []
    for name, _ in find_headings(changelog):
        if name != "Unreleased":
            versions.append(parse_version(name, tag_prefix=tag_prefix))
    return versions


def latest_released_version(changelog: str, *, tag_prefix: str = "v") -> Version:
    versions = release_versions_from_headings(changelog, tag_prefix=tag_prefix)
    if not versions:
        raise ReleaseError("CHANGELOG.md has no released versions")
    return versions[0]


def split_changelog_link_block(changelog: str) -> tuple[str, str]:
    match = re.search(r"\n\[unreleased\]: .*\Z", changelog, re.S | re.I)
    if not match:
        raise ReleaseError("CHANGELOG.md has no [unreleased] link block")
    return changelog[: match.start()].rstrip() + "\n", changelog[match.start() + 1:]


def rebuild_changelog_links(
    changelog_body: str,
    *,
    version: Version,
    unreleased_base: str,
    previous_for_oldest: str | None = None,
) -> str:
    versions = release_versions_from_headings(
        changelog_body, tag_prefix=version.tag_prefix
    )
    if not versions:
        raise ReleaseError("Cannot rebuild changelog links without release headings")

    lines = [
        f"[unreleased]: {REPO_URL}/compare/{versions[0].tag}...{unreleased_base}"
    ]
    for idx, current in enumerate(versions):
        if idx + 1 < len(versions):
            previous = versions[idx + 1].tag
            lines.append(
                f"[{current.text}]: {REPO_URL}/compare/{previous}...{current.tag}"
            )
        elif previous_for_oldest:
            lines.append(
                f"[{current.text}]: {REPO_URL}/compare/{previous_for_oldest}...{current.tag}"
            )
        else:
            lines.append(f"[{current.text}]: {REPO_URL}/releases/tag/{current.tag}")
    return changelog_body.rstrip() + "\n\n" + "\n".join(lines) + "\n"


def close_unreleased_section(
    changelog: str,
    *,
    version: Version,
    release_date: str,
    unreleased_base: str,
) -> tuple[str, str, Version | None]:
    body, _link_block = split_changelog_link_block(changelog)
    if f"## [{version.text}]" in body:
        raise ReleaseError(f"CHANGELOG.md already contains section {version.text}")

    headings = find_headings(body)
    if not headings or headings[0][0] != "Unreleased":
        raise ReleaseError("CHANGELOG.md must start its entries with ## [Unreleased]")

    unreleased_start = headings[0][1]
    header_match = re.match(
        r"## \[Unreleased\]\n", body[unreleased_start:], flags=re.M
    )
    if not header_match:
        raise ReleaseError("Could not parse ## [Unreleased] header")

    prefix = body[:unreleased_start]

    if len(headings) == 1:
        unreleased_content = body[
            unreleased_start + len(header_match.group(0)):].strip()
        if not unreleased_content:
            raise ReleaseError("Unreleased section is empty; nothing to release")
        new_body = (
            prefix
            + "## [Unreleased]\n\n"
            + f"## [{version.text}] - {release_date}\n\n"
            + unreleased_content
            + "\n\n"
        )
        new_changelog = rebuild_changelog_links(
            new_body,
            version=version,
            unreleased_base=unreleased_base,
        )
        return new_changelog, unreleased_content, None

    previous_version = parse_version(headings[1][0], tag_prefix=version.tag_prefix)
    next_heading_start = headings[1][1]
    unreleased_content = body[
        unreleased_start + len(header_match.group(0)):next_heading_start
    ].strip()
    suffix = body[next_heading_start:].lstrip("\n")

    if not unreleased_content:
        raise ReleaseError("Unreleased section is empty; nothing to release")

    new_body = (
        prefix
        + "## [Unreleased]\n\n"
        + f"## [{version.text}] - {release_date}\n\n"
        + unreleased_content
        + "\n\n"
        + suffix
    )
    new_changelog = rebuild_changelog_links(
        new_body,
        version=version,
        unreleased_base=unreleased_base,
    )
    return new_changelog, unreleased_content, previous_version


def extract_release_section(changelog: str, version: Version) -> str:
    body, _link_block = split_changelog_link_block(changelog)
    pattern = re.compile(rf"^## \[{re.escape(version.text)}\] - .*$", re.M)
    match = pattern.search(body)
    if not match:
        raise ReleaseError(f"Could not find CHANGELOG.md section for {version.text}")
    next_match = re.search(r"^## \[", body[match.end():], re.M)
    end = match.end() + next_match.start() if next_match else len(body)
    section = body[match.end():end].strip()
    if not section:
        raise ReleaseError(f"CHANGELOG.md section for {version.text} is empty")
    return section


def release_notes(
    changelog: str,
    version: Version,
    previous: Version,
    *,
    docs_url: str | None = DOCS_URL,
) -> str:
    section = extract_release_section(changelog, version)
    notes = (
        "## \U0001f53d Read the summarized changelog here \U0001f53d\n\n"
        f"{section}\n\n"
        f"**Full Changelog**: {REPO_URL}/compare/{previous.tag}...{version.tag}\n"
    )
    if docs_url:
        notes += (
            "\n### \U0001f4c3 Check the official documentation here: "
            f"[\u26d3\ufe0f\u200d\U0001f4a5 Giswater Documentation ]({docs_url})\n"
        )
    return notes


def initial_release_notes(
    changelog: str,
    version: Version,
    *,
    docs_url: str | None = DOCS_URL,
) -> str:
    section = extract_release_section(changelog, version)
    notes = (
        "## \U0001f53d Read the summarized changelog here \U0001f53d\n\n"
        f"{section}\n\n"
        f"**Full Changelog**: {REPO_URL}/releases/tag/{version.tag}\n"
    )
    if docs_url:
        notes += (
            "\n### \U0001f4c3 Check the official documentation here: "
            f"[\u26d3\ufe0f\u200d\U0001f4a5 Giswater CLI Documentation ]({docs_url})\n"
        )
    return notes


def previous_release_for(changelog: str, version: Version) -> Version:
    versions = release_versions_from_headings(
        changelog, tag_prefix=version.tag_prefix
    )
    for idx, current in enumerate(versions):
        if current == version:
            if idx + 1 >= len(versions):
                raise ReleaseError(
                    f"No previous changelog version found for {version.text}"
                )
            return versions[idx + 1]
    raise ReleaseError(f"CHANGELOG.md has no section for {version.text}")


def update_metadata_version(metadata: str, version: Version) -> str:
    lines = metadata.splitlines()
    out: list[str] = []
    idx = 0
    saw_version = False
    saw_changelog = False

    while idx < len(lines):
        line = lines[idx]
        if line.startswith("version="):
            out.append(f"version={version.text}")
            saw_version = True
            idx += 1
            continue
        if line.startswith("Changelog="):
            out.append(f"Changelog=Version {version.text}")
            saw_changelog = True
            idx += 1
            while idx < len(lines) and (
                lines[idx].startswith((" ", "\t")) or lines[idx] == ""
            ):
                idx += 1
            out.append("")
            continue
        out.append(line)
        idx += 1

    if not saw_version:
        raise ReleaseError("metadata.txt has no version= line")
    if not saw_changelog:
        raise ReleaseError("metadata.txt has no Changelog= line")
    return "\n".join(out).rstrip() + "\n"


def metadata_version(metadata: str) -> Version:
    match = re.search(r"^version=(\d+\.\d+\.\d+)$", metadata, re.M)
    if not match:
        raise ReleaseError("metadata.txt has no valid version=X.Y.Z line")
    return parse_version(match.group(1))


def cli_version_from_pyproject(text: str) -> Version:
    match = re.search(r'(?m)^version = "(\d+\.\d+\.\d+)"', text)
    if not match:
        raise ReleaseError("pyproject.toml has no version = \"X.Y.Z\" line")
    return parse_cli_version(match.group(1))


def cli_version_from_module(text: str) -> Version:
    match = re.search(r'(?m)^__version__ = "(\d+\.\d+\.\d+)"', text)
    if not match:
        raise ReleaseError("giswater_admin/__version__.py has no __version__ line")
    return parse_cli_version(match.group(1))


def bump_cli_version_text(path: Path, text: str, version: Version) -> str:
    if path.name == "pyproject.toml":
        pattern = r'(?m)^version = "[^"]+"'
        replacement = f'version = "{version.text}"'
    elif path.name == "__version__.py":
        pattern = r'(?m)^__version__ = "[^"]+"'
        replacement = f'__version__ = "{version.text}"'
    else:
        raise ReleaseError(f"Unsupported CLI version file: {path}")
    updated, count = re.subn(pattern, replacement, text, count=1)
    if count != 1:
        raise ReleaseError(f"Could not update version in {path}")
    return updated


def print_file_plan(changes: list[PlannedChange], root: Path) -> None:
    for change in changes:
        if not change.changed:
            print(f"No changes for {change.path.relative_to(root)}")
            continue
        print(unified_diff(change, root))


def stage_and_commit(
    root: Path,
    *,
    execute: bool,
    paths: list[Path],
    message: str,
) -> None:
    rel_paths = [str(path.relative_to(root)) for path in paths]
    git(root, "add", *rel_paths, execute=execute)
    git(root, "commit", "-m", message, execute=execute)


def ensure_tag_available(root: Path, tag: str, *, resume: bool) -> None:
    if ref_exists(root, f"refs/tags/{tag}") and not resume:
        raise ReleaseError(f"Tag {tag} already exists. Use --resume to continue.")


def ensure_branch_available(
    root: Path, remote: str, branch: str, *, resume: bool
) -> None:
    if local_or_remote_branch_exists(root, remote, branch) and not resume:
        raise ReleaseError(f"Branch {branch} already exists. Use --resume to continue.")


def create_tag(
    root: Path,
    *,
    tag: str,
    execute: bool,
    resume: bool,
) -> None:
    if ref_exists(root, f"refs/tags/{tag}"):
        if resume:
            print(f"Tag {tag} already exists; --resume keeps it")
            return
        raise ReleaseError(f"Tag {tag} already exists")
    git(root, "tag", "-a", tag, "-m", f"Release {tag}", execute=execute)


def create_or_switch_branch(
    root: Path,
    *,
    remote: str,
    branch: str,
    start_point: str,
    execute: bool,
    resume: bool,
) -> None:
    if resume and ref_exists(root, f"refs/heads/{branch}"):
        git(root, "switch", branch, execute=execute)
        return
    if resume and ref_exists(root, f"refs/remotes/{remote}/{branch}"):
        git(root, "switch", "--track", f"{remote}/{branch}", execute=execute)
        return
    git(root, "switch", "-c", branch, start_point, execute=execute)


def create_github_release(
    root: Path,
    *,
    version: Version,
    notes: str,
    execute: bool,
) -> None:
    if not execute:
        print("--- GitHub release notes ---")
        print(notes.rstrip())
        print("--- End GitHub release notes ---")
        if shutil.which("gh"):
            run(
                [
                    "gh",
                    "release",
                    "create",
                    version.tag,
                    "--title",
                    version.tag,
                    "--notes-file",
                    "/tmp/release-notes.md",
                ],
                cwd=root,
                execute=False,
            )
        else:
            print(
                "$ POST https://api.github.com/repos/"
                f"{GH_REPO}/releases "
                f"(tag_name={version.tag}, name={version.tag})"
            )
        return

    if shutil.which("gh") is None:
        create_github_release_with_api(version, notes)
        return

    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as handle:
        handle.write(notes)
        notes_file = handle.name
    try:
        run(
            [
                "gh",
                "release",
                "create",
                version.tag,
                "--title",
                version.tag,
                "--notes-file",
                notes_file,
            ],
            cwd=root,
            execute=True,
        )
    finally:
        Path(notes_file).unlink(missing_ok=True)


def create_github_release_with_api(version: Version, notes: str) -> None:
    token = os.environ.get("GITHUB_TOKEN")
    if not token:
        raise ReleaseError(
            "gh is not installed. Install gh or export GITHUB_TOKEN to create "
            "the GitHub Release via API."
        )

    payload = {
        "tag_name": version.tag,
        "name": version.tag,
        "body": notes,
        "draft": False,
        "prerelease": False,
    }
    request = urllib.request.Request(
        f"https://api.github.com/repos/{GH_REPO}/releases",
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "X-GitHub-Api-Version": "2022-11-28",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request) as response:
            release = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        message = exc.read().decode("utf-8", errors="replace")
        raise ReleaseError(f"GitHub release API failed: {exc.code}\n{message}") from exc

    print(f"Created GitHub Release: {release.get('html_url', version.tag)}")


def git_output(root: Path, *args: str) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )
    return result.stdout.strip()


def git_output_optional(root: Path, *args: str) -> str | None:
    result = subprocess.run(
        ["git", *args],
        cwd=root,
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    value = result.stdout.strip()
    return value or None


# Keep in sync with path filters in .github/workflows/test-db.yml.
DBMODEL_CI_PATHSPECS = (
    "dbmodel",
    "giswater_admin",
    "scripts/gw_e2e",
    "scripts/gw_bootstrap_network.sh",
    ".github/workflows/test-db.yml",
)


def dbmodel_unchanged_since_tag(
    root: Path, since_tag: str, end: str = "HEAD"
) -> bool:
    completed = subprocess.run(
        ["git", "diff", "--quiet", since_tag, end, "--", *DBMODEL_CI_PATHSPECS],
        cwd=root,
        check=False,
    )
    return completed.returncode == 0


def resolve_dbmodel_ci_sha(
    root: Path,
    *,
    since_tag: str,
    end: str,
) -> str:
    """Return the last commit in since_tag..end that can trigger PostgreSQL Tests."""
    commit = git_output_optional(
        root,
        "log",
        "-1",
        "--format=%H",
        f"{since_tag}..{end}",
        "--",
        *DBMODEL_CI_PATHSPECS,
    )
    if commit:
        return commit
    raise ReleaseError(
        f"dbmodel/ changed since {since_tag} but no commit in that range touches "
        "dbmodel CI paths; cannot pick a verification commit"
    )


RELEASE_METADATA_FILES = frozenset({"CHANGELOG.md", "metadata.txt"})


def is_release_metadata_only_commit(root: Path, sha: str) -> bool:
    """True when a commit only touches release bookkeeping files."""
    names = git_output_optional(
        root,
        "diff-tree",
        "--no-commit-id",
        "--name-only",
        "-r",
        sha,
    )
    if not names:
        return True
    return set(names.splitlines()).issubset(RELEASE_METADATA_FILES)


def is_git_ancestor(root: Path, ancestor: str, descendant: str) -> bool:
    completed = subprocess.run(
        ["git", "merge-base", "--is-ancestor", ancestor, descendant],
        cwd=root,
        check=False,
    )
    return completed.returncode == 0


def resolve_dbmodel_ci_verification_sha(
    root: Path,
    *,
    since_tag: str,
    end: str,
) -> str:
    """Return the commit whose push CI validates dbmodel changes.

    GitHub Actions runs on the push tip, not on every commit in a push.
    Walk back release-metadata-only commits on top of end so we verify
    the pushed tip that actually ran CI, not an intermediate dbmodel commit.
    """
    # Ensure dbmodel changed in the range before picking a verification SHA.
    resolve_dbmodel_ci_sha(root, since_tag=since_tag, end=end)

    verify_sha = end
    while verify_sha != since_tag and is_release_metadata_only_commit(
        root, verify_sha
    ):
        parent = git_output_optional(root, "rev-parse", f"{verify_sha}^")
        if not parent:
            break
        if not is_git_ancestor(root, since_tag, parent) or not is_git_ancestor(
            root, parent, end
        ):
            break
        verify_sha = parent
    return verify_sha


def ensure_dbmodel_ci_green(
    root: Path,
    *,
    execute: bool,
    cli_release: bool = False,
    sha: str | None = None,
) -> None:
    """Require PostgreSQL Tests workflow checks before release."""
    script = root / "scripts" / "verify_dbmodel_ci_checks.sh"
    if not script.is_file():
        raise ReleaseError(f"Missing {script}")

    head = sha or git_output(root, "rev-parse", "HEAD")
    if cli_release:
        commit = head
        cmd = ["bash", str(script), "--sha", commit, "--cli-release"]
        if not execute:
            print(
                "Would verify dbmodel CI checks on "
                f"{commit} (CLI; skip if dbmodel unchanged)"
            )
            print(f"$ {' '.join(cmd)}")
            return
    else:
        since_tag = git_output(root, "describe", "--tags", "--abbrev=0", head)
        if dbmodel_unchanged_since_tag(root, since_tag, head):
            message = (
                f"dbmodel/ unchanged since {since_tag}; skipping dbmodel CI verify"
            )
            if execute:
                print(message)
            else:
                print(f"Would skip dbmodel CI verify ({message})")
            return

        commit = resolve_dbmodel_ci_verification_sha(
            root, since_tag=since_tag, end=head
        )
        cmd = ["bash", str(script), "--sha", commit]
        if not execute:
            if commit != head:
                print(
                    "Would verify dbmodel CI checks on "
                    f"{commit} (push tip; HEAD {head[:12]} is release metadata)"
                )
            else:
                print(
                    "Would verify dbmodel CI checks on "
                    f"{commit} (push tip)"
                )
            print(f"$ {' '.join(cmd)}")
            return

        if commit != head:
            print(
                f"HEAD {head[:12]} is release metadata; "
                f"verifying dbmodel CI on push tip {commit[:12]}"
            )

    if shutil.which("gh") is None:
        raise ReleaseError(
            "gh CLI is required to verify dbmodel CI checks before release. "
            "Install gh or run the release from GitHub Actions."
        )

    run(cmd, cwd=root, execute=True)
