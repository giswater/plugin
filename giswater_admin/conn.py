"""
Connection resolution. Layered sources, evaluated in order:

  1. ``--conn`` — URL, ``service=NAME``, or a bare pg_service name
  2. ``--config /path/to/yaml`` with host/port/user/password/dbname/service
  3. User config (``gw config set database.conn`` or ``database.config``)
  4. Environment: PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE,
     PGSERVICE (psycopg2 will read PGSERVICE for free when nothing else
     is set)

The returned :class:`ConnInfo` is intentionally a plain dataclass — the
psycopg2 adapter consumes its fields directly. We never carry passwords
through ``safe_repr()``.
"""

from __future__ import annotations

import os
import re
from dataclasses import dataclass
from urllib.parse import unquote, urlparse

_SERVICE_NAME_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.-]*$")

_NO_CONNECTION_MSG = (
    "No connection info. Pass --conn, --config, run "
    "'gw config set database.conn URL' (or database.config PATH), "
    "or set PGDATABASE/PGSERVICE."
)


@dataclass
class ConnInfo:
    host: str = ""
    port: str = ""
    user: str = ""
    password: str = ""
    dbname: str = ""
    service: str = ""

    def safe_repr(self) -> str:
        if self.service:
            return f"service={self.service}"
        host = self.host or "localhost"
        port = self.port or "5432"
        user = self.user or "?"
        db = self.dbname or "?"
        return f"{user}@{host}:{port}/{db}"


def resolve(conn_url: str | None, config_path: str | None) -> ConnInfo:
    """Pick the highest-priority source that yields enough info."""
    if conn_url:
        return _from_conn_arg(conn_url)
    if config_path:
        return _from_config(config_path)
    user_conn = _user_config_conn_url()
    if user_conn:
        return _from_conn_arg(user_conn)
    user_config = _user_config_file()
    if user_config:
        return _from_config(user_config)
    info = _from_env()
    if not info.dbname and not info.service:
        raise RuntimeError(_NO_CONNECTION_MSG)
    return info


def _from_conn_arg(value: str) -> ConnInfo:
    text = value.strip()
    if text.lower().startswith("service="):
        name = text.split("=", 1)[1].strip()
        if not _SERVICE_NAME_RE.fullmatch(name):
            raise RuntimeError(f"--conn service= needs a pg_service name (got: {value!r})")
        return ConnInfo(service=name)
    if "://" in text:
        return _from_url(text)
    if _SERVICE_NAME_RE.fullmatch(text):
        return ConnInfo(service=text)
    raise RuntimeError(
        f"--conn must be a postgres URL, service=NAME, or a pg_service name (got: {value!r})"
    )


def _from_url(url: str) -> ConnInfo:
    if "://" not in url:
        raise RuntimeError(f"--conn must be a URL (got: {url!r})")
    p = urlparse(url)
    if p.scheme not in ("postgres", "postgresql"):
        raise RuntimeError(f"--conn scheme must be postgres[ql] (got: {p.scheme!r})")
    if "@" not in (p.netloc or "") and ":" in (p.netloc or ""):
        raise RuntimeError(
            "Connection URL must include host after '@'. "
            "Expected: postgresql://user:password@host:port/dbname "
            f"(got: {url!r})"
        )
    port = ""
    if p.port is not None:
        port = str(p.port)
    return ConnInfo(
        host=p.hostname or "",
        port=port,
        user=unquote(p.username) if p.username else "",
        password=unquote(p.password) if p.password else "",
        dbname=(p.path or "").lstrip("/"),
    )


def _from_config(path: str) -> ConnInfo:
    try:
        import yaml  # type: ignore[import-untyped]
    except ImportError as e:  # pragma: no cover
        raise RuntimeError("PyYAML required for --config") from e
    if not os.path.isfile(path):
        raise RuntimeError(f"--config file not found: {path}")
    with open(path, "r", encoding="utf-8") as f:
        body = yaml.safe_load(f) or {}
    if not isinstance(body, dict):
        raise RuntimeError(f"--config root must be a mapping: {path}")
    return ConnInfo(
        host=str(body.get("host", "")),
        port=str(body.get("port", "")),
        user=str(body.get("user", "")),
        password=str(body.get("password", "")),
        dbname=str(body.get("dbname", "")),
        service=str(body.get("service", "")),
    )


def _from_env() -> ConnInfo:
    return ConnInfo(
        host=os.environ.get("PGHOST", ""),
        port=os.environ.get("PGPORT", ""),
        user=os.environ.get("PGUSER", ""),
        password=os.environ.get("PGPASSWORD", ""),
        dbname=os.environ.get("PGDATABASE", ""),
        service=os.environ.get("PGSERVICE", ""),
    )


def _user_config_conn_url() -> str | None:
    from .install.config import get_config_value

    value = get_config_value("database.conn")
    if value is None or value == "":
        return None
    return str(value)


def _user_config_file() -> str | None:
    from .install.config import get_config_value

    value = get_config_value("database.config")
    if value is None or value == "":
        return None
    return str(value)


def has_pg_env() -> bool:
    return bool(
        os.environ.get("PGUSER")
        or os.environ.get("PGDATABASE")
        or os.environ.get("PGSERVICE")
    )


def has_user_config() -> bool:
    return bool(_user_config_conn_url() or _user_config_file())


def has_connection_source() -> bool:
    return has_pg_env() or has_user_config()


def open_connection(info: ConnInfo, *, autocommit: bool = False):
    """Open a psycopg2 connection through the adapter."""
    from .adapters.psycopg2_adapter import Psycopg2Adapter
    return Psycopg2Adapter.open(info, autocommit=autocommit)
