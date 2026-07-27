#!/usr/bin/env python3
"""HTTP client for the translations API (auth, GET baseline, POST detections).

Authentication matches scripts/i18n_export_zips.py::

  POST {base_url}/api/auth/sign-in/username
  {"username": "...", "password": "..."}
  POST {base_url}/api/auth/log-out

Configurable endpoints (defaults are placeholders until the API is deployed)::

  GET  /api/i18n/messages          (full baseline, no query params)
  POST /api/i18n/clear_pending_detections  (empty body; before cat_* uploads)
  POST /api/i18n/cat_changed_text
  POST /api/i18n/cat_delete_text
  POST /api/i18n/cat_new_text
"""

from __future__ import annotations

import json
import os
from typing import Any

import requests

SIGN_IN_PATH = "/api/auth/sign-in/username"
LOG_OUT_PATH = "/api/auth/log-out"
DEFAULT_MESSAGES_PATH = "/api/i18n/messages"
DEFAULT_CLEAR_PENDING_PATH = "/api/i18n/clear_pending_detections"
DEFAULT_CHANGED_PATH = "/api/i18n/cat_changed_text"
DEFAULT_DELETED_PATH = "/api/i18n/cat_delete_text"
DEFAULT_NEW_PATH = "/api/i18n/cat_new_text"
EXPECTED_CLEARED_KINDS = ("new", "changed", "deleted")

DEFAULT_DETECTIONS_BATCH_SIZE = 1000

# Authoritative table-specific PK columns (docs/i18n-api/get-messages.md).
TABLE_SPECIFIC_PK_COLUMNS: dict[str, tuple[str, ...]] = {
    "dbconfig_form_fields": ("formname", "formtype", "tabname", "source"),
    "dbconfig_form_fields_feat": ("feature_type", "formtype", "tabname", "source"),
    "dbconfig_form_fields_json": ("formname", "formtype", "tabname", "source", "hint"),
    "dbparam_user": ("source",),
    "dbconfig_param_system": ("source",),
    "dbconfig_typevalue": ("formname", "source"),
    "dblabel": ("source",),
    "dbmessage": ("source",),
    "dbfprocess": ("source",),
    "dbconfig_csv": ("source",),
    "dbconfig_form_tabs": ("formname", "source"),
    "dbconfig_report": ("source",),
    "dbconfig_toolbox": ("source",),
    "dbfunction": ("source",),
    "dbtypevalue": ("typevalue", "source"),
    "dbconfig_form_tableview": ("columnname", "source"),
    "dbtable": ("source",),
    "dbplan_price": ("source",),
    "dbconfig_visit_parameter": ("source",),
    "dbconfig_engine": ("parameter", "method"),
    "dbjson": ("source", "hint"),
    "dbstyle": ("source", "layername", "hint"),
    "pydialog": ("dialog_name", "toolbar_name", "source"),
    "pymessage": ("source",),
    "pytoolbar": ("source",),
}

# Non-PK, non-*_en_us baseline columns required for insert/export (POST extra_columns).
TABLE_EXTRA_COLUMNS: dict[str, tuple[str, ...]] = {
    "dbjson": ("text",),
    "dbconfig_form_fields_json": ("text",),
    "dbconfig_form_fields_feat": ("formname",),
    "dbstyle": ("org_text",),
}


_PY_TABLES = frozenset({"pymessage", "pytoolbar", "pydialog"})
_PY_PRIMARY_KEY_COLUMNS: dict[str, tuple[str, ...]] = {
    "pymessage": ("source", "source_code"),
    "pytoolbar": ("source", "source_code"),
    "pydialog": ("dialog_name", "toolbar_name", "source", "project_type", "source_code"),
}


def shared_pk_columns(table_name: str) -> tuple[str, ...]:
    return ("project_type", "context", "source_code")


def normalize_pk_value(value: Any, *, strip: bool = True) -> str:
    if value is None:
        return ""
    if isinstance(value, bool):
        return "true" if value else "false"
    text = str(value)
    return text.strip() if strip else text


def _preserve_source_whitespace(table_name: str, column: str) -> bool:
    """pymessage/pytoolbar source is the literal Python string and may start with spaces."""
    return table_name in ("pymessage", "pytoolbar") and column == "source"


def catalog_primary_key_columns(table_name: str) -> tuple[str, ...]:
    if table_name in _PY_TABLES:
        return _PY_PRIMARY_KEY_COLUMNS[table_name]
    specific = TABLE_SPECIFIC_PK_COLUMNS.get(table_name, ("source",))
    return (*specific, *shared_pk_columns(table_name))


def primary_keys_from_row(table_name: str, row: dict[str, Any]) -> dict[str, str]:
    """Build the primary_keys object used for detection_key hashing.

    Values are taken from ``row`` as found. Callers that create *new* rows may
    fill defaults before calling; deleted/changed rows must keep baseline PKs.
    """
    return {
        column: normalize_pk_value(
            row.get(column, ""),
            strip=not _preserve_source_whitespace(table_name, column),
        )
        for column in catalog_primary_key_columns(table_name)
    }


def _normalize_extra_column_value(value: Any) -> str | None:
    """Normalize a scalar extra_columns value (stored as string or null)."""
    if value is None:
        return None
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (dict, list)):
        return json.dumps(value, separators=(",", ":"), ensure_ascii=False)
    if isinstance(value, (int, float)):
        return str(value)
    return str(value)


def extra_columns_from_row(
    table_name: str,
    row: dict[str, Any],
    *,
    kind: str,
) -> dict[str, str | None]:
    """Build extra_columns from declared table spec; empty dict when none declared."""
    declared = TABLE_EXTRA_COLUMNS.get(table_name, ())
    if not declared:
        return {}
    extra: dict[str, str | None] = {}
    for column in declared:
        if column in row:
            extra[column] = _normalize_extra_column_value(row.get(column))
        elif kind == "new":
            extra[column] = _normalize_extra_column_value(None)
    return extra


def validate_detection_record(record: dict[str, Any], *, kind: str) -> None:
    """Validate a detection record before POST (mirrors server extra_columns rules)."""
    table_name = str(record.get("table_name", "") or "")
    extra = record.get("extra_columns")
    if extra is None:
        extra = {}
    if not isinstance(extra, dict):
        raise ValueError(f"extra_columns must be a JSON object for table {table_name!r}")

    declared = TABLE_EXTRA_COLUMNS.get(table_name, ())
    pk_columns = set(catalog_primary_key_columns(table_name))

    for key, value in extra.items():
        if key.endswith("_en_us"):
            raise ValueError(
                f"extra_columns must not contain *_en_us key {key!r} on table {table_name!r}"
            )
        if key in pk_columns:
            raise ValueError(
                f"extra_columns must not contain PK column {key!r} on table {table_name!r}"
            )
        if declared and key not in declared:
            raise ValueError(
                f"unknown extra_columns key {key!r} for table {table_name!r}; "
                f"allowed: {', '.join(declared)}"
            )
        if value is not None and not isinstance(value, (str, int, float, bool)):
            raise ValueError(
                f"extra_columns.{key} must be a scalar (string, number, boolean, or null)"
            )

    if kind == "new" and declared:
        for column in declared:
            if column not in extra:
                raise ValueError(
                    f"missing required extra_columns.{column} for new {table_name!r} detection"
                )

    if declared:
        for column in declared:
            if column in record and column not in pk_columns and not column.endswith("_en_us"):
                raise ValueError(
                    f"column {column!r} must be nested under extra_columns, not flat, "
                    f"for table {table_name!r}"
                )


def resolve_setting(cli_value: str | None, env_name: str, default: str | None = None) -> str | None:
    if cli_value is not None and cli_value != "":
        return cli_value
    env_value = os.environ.get(env_name)
    if env_value is not None and env_value != "":
        return env_value
    return default


class TranslationsApiClient:
    """Authenticated session for translations API GET/POST calls.

    Every request sends ``Connection: close`` and closes the response once the
    body is consumed so sockets are not left open after each call or when the
    client context exits.
    """

    def __init__(
        self,
        base_url: str,
        username: str,
        password: str,
        *,
        timeout: float = 120,
        log_out_path: str = LOG_OUT_PATH,
    ) -> None:
        if not username or not password:
            raise ValueError(
                "API credentials are required. Set TRANSLATIONS_API_USER and "
                "TRANSLATIONS_API_PASSWORD (or pass --user / --password)."
            )
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self._log_out_path = log_out_path
        self._logged_out = False
        self._session = requests.Session()
        self._sign_in(username, password)

    def _sign_in(self, username: str, password: str) -> None:
        url = f"{self.base_url}{SIGN_IN_PATH}"
        response = self._request(
            "post",
            url,
            error_message=f"Failed to reach auth API at {url}",
            json={"username": username, "password": password},
            headers=self._request_headers(content_type="application/json"),
        )
        try:
            self._raise_for_status(response, f"Login failed for {url}")
        finally:
            self._close_response(response)

    def _url(self, path: str) -> str:
        return f"{self.base_url}{path}" if path.startswith("/") else path

    def _request(
        self,
        method: str,
        url: str,
        *,
        error_message: str,
        **kwargs: Any,
    ) -> requests.Response:
        """Perform one session request and translate connection failures."""
        try:
            request = getattr(self._session, method)
            return request(url, timeout=self.timeout, **kwargs)
        except requests.RequestException as exc:
            raise RuntimeError(f"{error_message}: {exc}") from exc

    @staticmethod
    def _request_headers(
        *,
        accept: str = "application/json",
        content_type: str | None = None,
    ) -> dict[str, str]:
        headers = {"Accept": accept, "Connection": "close"}
        if content_type:
            headers["Content-Type"] = content_type
        return headers

    @staticmethod
    def _close_response(response: requests.Response) -> None:
        response.close()

    @staticmethod
    def _raise_for_status(response: requests.Response, message: str) -> None:
        if response.status_code >= 400:
            raise RuntimeError(f"{message} (HTTP {response.status_code}): {response.text}")

    @staticmethod
    def _json_response(
        response: requests.Response,
        *,
        empty_value: Any = None,
        error_message: str,
        fallback_to_text: bool = False,
    ) -> Any:
        if not response.content:
            return empty_value
        try:
            return response.json()
        except json.JSONDecodeError as exc:
            if fallback_to_text:
                return response.text
            raise RuntimeError(error_message) from exc

    def get_bytes(self, path: str, *, accept: str) -> bytes:
        url = self._url(path)
        response = self._request(
            "get",
            url,
            error_message=f"Failed to reach {url}",
            headers=self._request_headers(accept=accept),
        )
        try:
            self._raise_for_status(response, f"Request failed for {url}")
            body = response.content
            if not body:
                raise RuntimeError(f"Empty response from {url}")
            return body
        finally:
            self._close_response(response)

    def get_json(self, path: str, *, params: dict[str, Any] | None = None) -> Any:
        url = self._url(path)
        response = self._request(
            "get",
            url,
            error_message=f"GET failed for {url}",
            params=params,
            headers=self._request_headers(),
        )
        try:
            self._raise_for_status(response, f"GET {url} returned")
            return self._json_response(
                response,
                error_message=f"Invalid JSON from GET {url}",
            )
        finally:
            self._close_response(response)

    def post_json(self, path: str, payload: Any, *, with_status: bool = False) -> Any:
        url = self._url(path)
        response = self._request(
            "post",
            url,
            error_message=f"POST failed for {url}",
            json=payload,
            headers=self._request_headers(content_type="application/json"),
        )
        try:
            self._raise_for_status(response, f"POST {url} returned")
            parsed = self._json_response(
                response,
                error_message=f"Invalid JSON from POST {url}",
                fallback_to_text=True,
            )
            if with_status:
                return response.status_code, parsed
            return parsed
        finally:
            self._close_response(response)

    def log_out(self) -> None:
        """Invalidate the server session (best-effort; safe to call more than once)."""
        if self._logged_out:
            return
        self._logged_out = True
        url = self._url(self._log_out_path)
        try:
            response = self._request(
                "post",
                url,
                error_message=f"Logout failed for {url}",
                headers=self._request_headers(),
            )
        except RuntimeError:
            return
        try:
            self._raise_for_status(response, f"Logout failed for {url}")
        except RuntimeError:
            return
        finally:
            self._close_response(response)

    def close(self) -> None:
        self.log_out()
        self._session.close()

    def __enter__(self) -> TranslationsApiClient:
        return self

    def __exit__(self, *_args: Any) -> None:
        self.close()


def fetch_i18n_messages(
    api: TranslationsApiClient,
    path: str = DEFAULT_MESSAGES_PATH,
) -> list[dict[str, Any]]:
    """Fetch the full i18n baseline from the API (no query filters)."""
    payload = api.get_json(path)
    if payload is None:
        return []
    if isinstance(payload, list):
        return [row for row in payload if isinstance(row, dict)]
    if isinstance(payload, dict):
        rows = payload.get("rows") or payload.get("data") or payload.get("messages")
        if isinstance(rows, list):
            return [row for row in rows if isinstance(row, dict)]
    raise RuntimeError("Unexpected i18n messages payload: expected list or {rows|data|messages: [...]}")


def clear_pending_detections(
    api: TranslationsApiClient,
    path: str = DEFAULT_CLEAR_PENDING_PATH,
    *,
    dry_run: bool = False,
) -> list[str]:
    """POST empty body to clear pending new/changed/deleted detections.

    Must run before ``cat_*_text`` uploads so prior pending rows do not linger.
    """
    if dry_run:
        print(f"DRY-RUN POST {path}: {{}}")
        return list(EXPECTED_CLEARED_KINDS)

    url = api._url(path)
    status, payload = api.post_json(path, {}, with_status=True)
    if status != 200 or not isinstance(payload, dict):
        raise RuntimeError(
            f"clear_pending_detections: POST {url} returned unexpected response "
            f"(HTTP {status}): {payload!r}"
        )
    cleared = payload.get("cleared")
    if cleared != list(EXPECTED_CLEARED_KINDS):
        raise RuntimeError(
            f"clear_pending_detections: POST {url} did not clear expected kinds "
            f"{list(EXPECTED_CLEARED_KINDS)!r}; got {payload!r}"
        )
    print(f"POST {path}: HTTP {status} -> cleared={cleared}")
    return list(cleared)


def post_detection(
    api: TranslationsApiClient,
    path: str,
    records: list[dict[str, Any]],
    *,
    kind: str | None = None,
) -> dict[str, Any]:
    """POST detection records and validate the API response."""
    label = kind or path
    url = api._url(path)
    status, payload = api.post_json(path, {"records": records}, with_status=True)
    if status == 204 or payload is None or payload == "":
        return {
            "kind": label,
            "status": status,
            "url": url,
            "response": {"inserted": 0, "updated": 0, "errors": []},
        }
    if not isinstance(payload, dict):
        return {
            "kind": label,
            "status": status,
            "url": url,
            "response": {"inserted": 0, "updated": 0, "errors": []},
        }
    errors = payload.get("errors") or []
    if errors:
        raise RuntimeError(
            f"{label}: POST {url} returned errors: {json.dumps(payload, ensure_ascii=False)}"
        )
    return {"kind": label, "status": status, "url": url, "response": payload}


def upload_detection_records(
    api: TranslationsApiClient,
    path: str,
    records: list[dict[str, Any]],
    *,
    dry_run: bool = False,
    kind: str | None = None,
    batch_size: int | None = None,
) -> int:
    if not records:
        print("No records to upload")
        return 0
    if dry_run:
        print(f"DRY-RUN POST {path}: {len(records)} record(s)")
        return len(records)

    if batch_size is None:
        batch_size = int(
            os.environ.get("I18N_DETECTIONS_BATCH_SIZE", str(DEFAULT_DETECTIONS_BATCH_SIZE))
        )
        print(f"Batch size not set, using default: {batch_size}")
    batch_size = max(1, batch_size)
    total_inserted = 0
    total_updated = 0
    label = kind or path
    batch_count = (len(records) + batch_size - 1) // batch_size
    for batch_no, offset in enumerate(range(0, len(records), batch_size), start=1):
        chunk = records[offset: offset + batch_size]
        for record in chunk:
            validate_detection_record(record, kind=kind or "new")
        result = post_detection(api, path, chunk, kind=kind)
        response = result["response"]
        inserted = int(response.get("inserted") or 0)
        updated = int(response.get("updated") or 0)
        total_inserted += inserted
        total_updated += updated
        print(
            f"POST {label} batch {batch_no}/{batch_count}: HTTP {result['status']} -> "
            f"inserted={inserted} updated={updated} "
            f"errors={response.get('errors', [])}"
        )

    if batch_size < len(records):
        print(
            f"POST {label} total: inserted={total_inserted} updated={total_updated} "
            f"records={len(records)}"
        )
    return len(records)
