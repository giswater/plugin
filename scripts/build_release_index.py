"""Rebuild config/releases.json, the index of releases predating CHANGELOG.md.

The About dialog lists every Giswater release ever published. Releases from
4.5.0 on have a section in CHANGELOG.md and are read from there; older ones
never had one, so their tag, date, URL and published notes are frozen in
config/releases.json.

The index is historical: prepare_release.py writes every new release into
CHANGELOG.md, so nothing is ever appended here. This script exists to document
where the data came from and to rebuild it if the tags are ever rewritten.

Usage:
    python3 scripts/build_release_index.py [--token GITHUB_TOKEN]
"""
import argparse
import json
import re
import urllib.request

from release_lib import (
    GH_REPO,
    read_text,
    release_versions_from_headings,
    repo_root,
)

API = "https://api.github.com/repos/{0}/releases?per_page=100&page={1}"


def fetch_releases(token=None):
    """Every published release of the plugin, newest first."""

    headers = {"Accept": "application/vnd.github+json", "User-Agent": "giswater"}
    if token:
        headers["Authorization"] = "Bearer {0}".format(token)

    releases = []
    for page in range(1, 20):
        request = urllib.request.Request(API.format(GH_REPO, page), headers=headers)
        with urllib.request.urlopen(request, timeout=30) as response:
            batch = json.load(response)
        if not batch:
            break
        releases.extend(batch)
        if len(batch) < 100:
            break
    return releases


def clean_notes(body):
    """Drop what only makes sense on the release page itself.

    GitHub renders :shortcode: as an emoji and Qt does not, so they would
    show up as literal text. The "read the changelog here" banner points at
    the very notes it introduces.
    """

    banner = re.compile(r"^#*\s*read the summarized changelog here\s*$", re.I)
    lines = []
    for line in body.strip().splitlines():
        line = re.sub(r":[a-z0-9_+-]+:", "", line).rstrip()
        if banner.match(re.sub(r"[\U0001F300-\U0001FAFF\u2600-\u27BF]", "", line).strip()):
            continue
        if not line.strip() and (not lines or not lines[-1].strip()):
            continue  # collapse the blank runs left behind
        lines.append(line)
    return "\n".join(lines).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--token", help="GitHub token, for a higher rate limit")
    args = parser.parse_args()

    root = repo_root()
    index_path = root / "config" / "releases.json"
    changelog = read_text(root / "CHANGELOG.md")
    documented = {
        version.text for version in release_versions_from_headings(changelog)
    }
    entries = []
    for release in fetch_releases(args.token):
        tag = release["tag_name"]
        if release.get("draft") or tag.startswith("cli-"):
            continue
        if tag.lstrip("v") in documented:
            continue  # CHANGELOG.md is the source for this one
        entries.append({
            "tag": tag,
            "date": (release.get("published_at") or "")[:10],
            "url": release["html_url"],
            "notes": clean_notes(release.get("body") or ""),
        })

    entries.sort(key=lambda entry: entry["date"], reverse=True)
    index_path.write_text(
        json.dumps(entries, indent=1, ensure_ascii=False) + "\n", encoding="utf-8"
    )
    print("{0} releases written to {1}".format(len(entries), index_path))


if __name__ == "__main__":
    main()
