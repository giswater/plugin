# `dbconfig_report_query` — API caller notes

Post one detection per double-quoted `AS` alias inside `config_report.query_text`.
Do not send unquoted identifiers (`w.exploitation`, `period`). Do not send
`filterparam` JSON (`dbjson`) or report title/description (`dbconfig_report`).

Endpoints: `POST /api/i18n/cat_new_text`, `cat_changed_text`, `cat_delete_text`.
Same envelope as other catalogs. `detection_key` is SHA-256 of
`(table_name, primary_keys, kind)` — see `post-detections.md`.

## Identity

| Field | Rule |
|---|---|
| `table_name` | `dbconfig_report_query` |
| Shared PK | `project_type`, `context`, `source_code` |
| Table PK | `source` (origin `config_report.id` as text), `hint` |
| `context` / `table_org` | always `config_report` |
| `source_code` | `giswater` |
| `project_type` | `ws` or `ud` |
| `hint` | `queryText_0`, `queryText_1`, … left-to-right in the SQL |
| `text_values.lb_en_us` | unescaped alias (`"Total inlet"` → `Total inlet`) |
| `extra_columns.text` | full origin `query_text` (SQL string, not jsonb) |

Full PK:

```
source, hint, project_type, context, source_code
```

`extra_columns.text` is required on **new**. On **changed**/**deleted** send it
when you have it. A change may be alias-only or blob-only (SQL drifted,
`lb_en_us` unchanged — still POST `changed` with identical English maps).

## What to extract

From `config_report.query_text`, only double-quoted aliases after `AS`/`as`:

```sql
SELECT w.exploitation as "Exploitation", w.dma as "Dma", period as "Period",
total_in::numeric(20,2) as "Total inlet",
total_out::numeric(20,2) as "Total outlet",
total::numeric(20,2) as "Total injected",
auth as "Authorized Vol.",
loss as "Losses Vol.",
(case when total > 0 then 100*(1-auth/total)::numeric(20,2) else 0.00 end) as "NRW"
FROM v_om_waterbalance w
```

| hint | `lb_en_us` |
|---|---|
| `queryText_0` | Exploitation |
| `queryText_1` | Dma |
| `queryText_2` | Period |
| `queryText_3` | Total inlet |
| `queryText_4` | Total outlet |
| `queryText_5` | Total injected |
| `queryText_6` | Authorized Vol. |
| `queryText_7` | Losses Vol. |
| `queryText_8` | NRW |

Skip: unquoted names, string literals, `WHERE` predicates, empty `query_text`.
If the alias contains `"`, store it unescaped (`Foo "bar"`); SQL form is `""`.

## GET baseline

`GET /api/i18n/messages` rows look like this. Diff against them. Nested
`extra_columns.text` is present so you can detect blob drift when `lb_en_us`
is unchanged.

```json
{
  "table_name": "dbconfig_report_query",
  "project_type": "ws",
  "context": "config_report",
  "source_code": "giswater",
  "source": "1",
  "hint": "queryText_3",
  "lb_en_us": "Total inlet",
  "text": "SELECT w.exploitation as \"Exploitation\", ... as \"NRW\" FROM v_om_waterbalance w",
  "extra_columns": {
    "text": "SELECT w.exploitation as \"Exploitation\", ... as \"NRW\" FROM v_om_waterbalance w"
  }
}
```

## POST new

One record per alias. Same `extra_columns.text` on every hint that shares the query.

```json
{
  "detection_key": "<sha256>",
  "table_name": "dbconfig_report_query",
  "source_code": "giswater",
  "detected_version": "4.2.0",
  "table_org": "config_report",
  "schema_org": "ws_trans",
  "project_type": "ws",
  "context": "config_report",
  "source": "1",
  "hint": "queryText_3",
  "extra_columns": {
    "text": "SELECT w.exploitation as \"Exploitation\", w.dma as \"Dma\", period as \"Period\", total_in::numeric(20,2) as \"Total inlet\", total_out::numeric(20,2) as \"Total outlet\", total::numeric(20,2) as \"Total injected\", auth as \"Authorized Vol.\", loss as \"Losses Vol.\", (case when total > 0 then 100*(1-auth/total)::numeric(20,2) else 0.00 end) as \"NRW\" FROM v_om_waterbalance w"
  },
  "text_values": {
    "lb_en_us": "Total inlet"
  }
}
```

## POST changed

Alias changed:

```json
{
  "table_name": "dbconfig_report_query",
  "source": "1",
  "hint": "queryText_3",
  "project_type": "ws",
  "context": "config_report",
  "source_code": "giswater",
  "extra_columns": {
    "text": "SELECT ... as \"Total inlets\" ..."
  },
  "old_text_values": { "lb_en_us": "Total inlet" },
  "new_text_values": { "lb_en_us": "Total inlets" }
}
```

Blob-only (SQL drifted, alias same): identical `old_text_values` / `new_text_values`
plus the new `extra_columns.text`.

## POST deleted

Literal gone from the query, or the report row was removed. PK only;
`text_values` holds the last-known `lb_en_us`. `extra_columns` optional.
