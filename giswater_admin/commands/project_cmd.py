"""Create QGIS project files through a headless PyQGIS subprocess."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys

from .. import conn as conn_mod
from ..output import Out
from . import _helpers as h


_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_$]*$")


def _python_names_near_qgis() -> tuple[str, ...]:
    if sys.platform == "win32":
        return (
            "python-qgis-ltr.bat",
            "python-qgis.bat",
            "python-qgis-ltr.exe",
            "python-qgis.exe",
            "python3.exe",
            "python.exe",
        )
    return ("python", "python3", "python3.12", "python3.11", "python3.10", "python3.9")


def _siblings_of(path: Path) -> list[str]:
    return [str(path.with_name(name)) for name in _python_names_near_qgis()]


def _macos_candidates() -> list[str]:
    applications = Path("/Applications")
    if not applications.is_dir():
        return []
    found: list[str] = []
    for app in sorted(applications.glob("QGIS*.app"), reverse=True):
        macos = app / "Contents" / "MacOS"
        found.extend(str(macos / name) for name in _python_names_near_qgis())
    return found


def _linux_candidates() -> list[str]:
    found: list[str] = []
    for path in (
        Path("/usr/bin"),
        Path("/usr/local/bin"),
        Path.home() / ".local" / "bin",
    ):
        if not path.is_dir():
            continue
        found.extend(str(path / name) for name in _python_names_near_qgis())
    flatpak = Path("/var/lib/flatpak/exports/bin/qgis")
    if flatpak.exists():
        found.extend(_siblings_of(flatpak))
    return found


def _windows_candidates() -> list[str]:
    found: list[str] = []
    roots: list[Path] = []
    for env_name in ("ProgramFiles", "ProgramFiles(x86)", "OSGEO4W_ROOT", "OSGEO4W64"):
        value = os.environ.get(env_name)
        if value:
            roots.append(Path(value))
    roots.extend([
        Path(r"C:\OSGeo4W"),
        Path(r"C:\OSGeo4W64"),
        Path(r"C:\Program Files"),
        Path(r"C:\Program Files (x86)"),
    ])

    seen_roots: set[Path] = set()
    for root in roots:
        try:
            resolved = root.resolve()
        except OSError:
            continue
        if resolved in seen_roots or not resolved.is_dir():
            continue
        seen_roots.add(resolved)

        for bin_dir in (resolved / "bin", resolved):
            if bin_dir.is_dir():
                found.extend(str(bin_dir / name) for name in _python_names_near_qgis())

        try:
            children = sorted(resolved.glob("QGIS*"), reverse=True)
        except OSError:
            children = []
        for install in children:
            bin_dir = install / "bin"
            if bin_dir.is_dir():
                found.extend(str(bin_dir / name) for name in _python_names_near_qgis())
    return found


def _platform_candidates() -> list[str]:
    if sys.platform == "darwin":
        return _macos_candidates()
    if sys.platform == "win32":
        return _windows_candidates()
    return _linux_candidates()


def _which_qgis_wrappers() -> list[str]:
    names = (
        "python-qgis-ltr",
        "python-qgis",
        "python-qgis-ltr.bat",
        "python-qgis.bat",
        "qgis_process",
        "qgis_process.bat",
        "qgis",
    )
    found: list[str] = []
    for name in names:
        path = shutil.which(name)
        if not path:
            continue
        found.append(path)
        if Path(path).name.lower().startswith("qgis"):
            found.extend(_siblings_of(Path(path)))
    return found


def _qgis_python_candidates() -> list[str]:
    candidates: list[str] = []
    env_python = os.environ.get("QGIS_PYTHON")
    if env_python:
        candidates.append(env_python)
    candidates.append(sys.executable)
    candidates.extend(_which_qgis_wrappers())
    candidates.extend(_platform_candidates())
    return candidates


def _is_windows_launcher(path: Path) -> bool:
    return sys.platform == "win32" and path.suffix.lower() in {".bat", ".cmd"}


def _run_qgis_python(
    python_exe: str,
    script_args: list[str],
    *,
    env: dict[str, str] | None = None,
    capture: bool = False,
    timeout: float | None = None,
) -> subprocess.CompletedProcess[str]:
    """Run a QGIS Python / OSGeo4W launcher with portable Windows .bat handling."""
    path = Path(python_exe)
    kwargs: dict = {
        "check": False,
        "text": True,
        "timeout": timeout,
        "env": env,
    }
    if capture:
        kwargs["stdout"] = subprocess.PIPE
        kwargs["stderr"] = subprocess.PIPE
    else:
        kwargs["stdout"] = subprocess.DEVNULL
        kwargs["stderr"] = subprocess.DEVNULL

    if _is_windows_launcher(path):
        # cmd.exe needs a single command string for .bat + args.
        quoted = subprocess.list2cmdline([python_exe, *script_args])
        return subprocess.run(quoted, shell=True, **kwargs)
    return subprocess.run([python_exe, *script_args], **kwargs)


def _probe_import_qgis(candidate: str) -> bool:
    if not Path(candidate).exists():
        return False
    try:
        probe = _run_qgis_python(candidate, ["-c", "import qgis"], timeout=15)
    except (OSError, subprocess.TimeoutExpired):
        return False
    return probe.returncode == 0


def _qgis_python() -> str:
    seen: set[str] = set()
    for candidate in _qgis_python_candidates():
        if not candidate or candidate in seen:
            continue
        seen.add(candidate)
        if _probe_import_qgis(candidate):
            return candidate

    raise RuntimeError(
        "PyQGIS is required for 'gw project create'. "
        "Install QGIS or set QGIS_PYTHON to the Python shipped with QGIS, e.g. "
        "macOS: /Applications/QGIS-LTR.app/Contents/MacOS/python ; "
        "Linux: /usr/bin/python3 (with python3-qgis) ; "
        r"Windows: C:\OSGeo4W\bin\python-qgis.bat"
    )


def _validate_identifier(value: str, label: str) -> None:
    if not _IDENTIFIER_RE.fullmatch(value):
        raise RuntimeError(f"Invalid {label}: {value!r}")


def run_create(args: argparse.Namespace, out: Out) -> int:
    schema = str(args.schema)
    filename = str(args.name or schema)
    _validate_identifier(schema, "schema")
    _validate_identifier(filename, "project name")

    conn_info = conn_mod.resolve(args.conn, args.config)
    conn = h.open_conn(args, out, require_superuser=False)
    try:
        actual_type = h.detect_project_type(conn, schema)
    finally:
        conn.close()

    if not actual_type:
        out.error(f"Schema '{schema}' is not a Giswater main schema.")
        return 1
    if actual_type != args.type:
        out.error(
            f"Schema '{schema}' has project_type '{actual_type}', not '{args.type}'."
        )
        return 1

    output_dir = Path(args.out).expanduser().resolve()
    output_path = output_dir / f"{filename}.qgs"
    if output_path.exists() and not args.force:
        out.error(f"Output exists: {output_path}. Pass --force to overwrite it.")
        return 1

    runner = Path(__file__).resolve().parents[1] / "engine" / "qgs_runner.py"
    plugin_root = Path(__file__).resolve().parents[2]
    env = os.environ.copy()
    env["QT_QPA_PLATFORM"] = env.get("QT_QPA_PLATFORM", "offscreen")
    env["GW_QGS_CONNECTION"] = json.dumps(conn_info.__dict__)
    env["GW_QGS_OPTIONS"] = json.dumps({
        "schema": schema,
        "project_type": args.type,
        "output_dir": str(output_dir),
        "filename": filename,
        "export_passwd": bool(args.export_passwd),
        "force": bool(args.force),
        "plugin_root": str(plugin_root),
    })

    out.info(f"Creating QGIS project: {output_path}")
    try:
        process = _run_qgis_python(
            _qgis_python(),
            [str(runner)],
            env=env,
            capture=True,
        )
    except RuntimeError as exc:
        out.error(str(exc))
        return 1
    if process.returncode != 0:
        detail = process.stderr.strip() or process.stdout.strip() or "unknown PyQGIS error"
        out.error(detail)
        return 1

    payload = None
    for line in reversed(process.stdout.splitlines()):
        try:
            payload = json.loads(line)
            break
        except json.JSONDecodeError:
            continue
    if not isinstance(payload, dict) or not payload.get("ok"):
        out.error("PyQGIS runner did not return a valid success result.")
        return 1

    out.result(payload)
    return 0
