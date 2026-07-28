"""Discover interconnected Giswater schemas from sys_version.addparam."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from typing import Any, Callable, Literal, Optional

from .sql_runner import ConnectionLike

RowFetcher = Callable[[str, Optional[list]], Optional[list[tuple]]]

_NETWORK_KINDS = ("ws", "ud")
MAIN_KINDS = _NETWORK_KINDS
# Backward-compatible defaults when dbmodel_path is unavailable (tests, legacy imports).
_FALLBACK_ADDON_KINDS = ("utils", "cibs", "am", "cm", "audit")
ADDON_KINDS = _FALLBACK_ADDON_KINDS
_FALLBACK_UPDATE_KIND_ORDER = ("utils", "cibs", "ws", "ud", "am", "cm", "audit")
UPDATE_KIND_ORDER = _FALLBACK_UPDATE_KIND_ORDER


def _is_addon_kind(kind: str) -> bool:
    normalized = _normalize_kind(kind)
    return bool(normalized) and normalized not in _NETWORK_KINDS


@dataclass
class NetworkNode:
    schema: str
    kind: str
    version: str
    enabled: bool = True
    addparam_summary: dict[str, Any] = field(default_factory=dict)


@dataclass
class NetworkEdge:
    source: str
    target: str
    relation: str


@dataclass
class NetworkGraph:
    anchor: str
    nodes: list[NetworkNode]
    edges: list[NetworkEdge]
    version_skew: bool = False
    min_version: str = ""
    max_version: str = ""

    @property
    def schema_names(self) -> list[str]:
        return [n.schema for n in self.nodes]

    def node_for(self, schema: str) -> NetworkNode | None:
        for node in self.nodes:
            if node.schema == schema:
                return node
        return None

    def suggested_update_command(self, to_version: str = "") -> str:
        if to_version:
            return f"gw network update --version {to_version}"
        return "gw network update --version <X.Y.Z>"


@dataclass
class DatabaseNetwork:
    cluster: NetworkGraph
    other_schemas: list[NetworkNode] = field(default_factory=list)
    audit_schema: str | None = None


@dataclass
class ClusterMember:
    kind: str
    schema: str
    version: str


@dataclass(frozen=True)
class SchemaListFilter:
    tier: Literal["all", "main", "addon"] = "all"
    kinds: frozenset[str] = frozenset()


@dataclass
class SchemaInventoryItem:
    schema: str
    kind: str
    tier: str
    version: str
    epsg: int | None = None
    lang: str | None = None


_TIER_SORT = {"main": 0, "addon": 1, "other": 2}


def _normalize_kind(kind: str) -> str:
    return str(kind or "").strip().lower()


def _kind_tier(kind: str) -> str:
    normalized = _normalize_kind(kind)
    if normalized in _NETWORK_KINDS:
        return "main"
    if normalized:
        return "addon"
    return "other"


def fetch_schema_inventory_entry(
    schema_name: str,
    fetcher: RowFetcher,
) -> SchemaInventoryItem | None:
    if not schema_exists(schema_name, fetcher):
        return None

    columns = _sys_version_columns_by_schema([schema_name], fetcher).get(schema_name, set())
    version_col = _version_column_for_schema(schema_name, columns)
    if not version_col:
        return None
    select_cols = ["project_type", version_col]
    if "epsg" in columns:
        select_cols.append("epsg")
    if "language" in columns:
        select_cols.append("language")

    row = fetcher(
        f"SELECT {', '.join(select_cols)} "
        f"FROM {_quote_ident(schema_name)}.sys_version "
        "ORDER BY id DESC LIMIT 1",
        None,
    )
    if not row or not row[0]:
        return None

    values = row[0]
    kind = _normalize_kind(str(values[0] or ""))
    version = str(values[1] or "")
    epsg: int | None = None
    lang: str | None = None
    idx = 2
    if "epsg" in columns:
        if idx < len(values) and values[idx] is not None:
            try:
                epsg = int(values[idx])
            except (TypeError, ValueError):
                epsg = None
        idx += 1
    if "language" in columns:
        if idx < len(values) and values[idx] is not None:
            lang = str(values[idx])

    return SchemaInventoryItem(
        schema=schema_name,
        kind=kind,
        tier=_kind_tier(kind),
        version=version,
        epsg=epsg,
        lang=lang,
    )


def list_schemas(
    fetcher: RowFetcher,
    *,
    filter: SchemaListFilter | None = None,
) -> list[SchemaInventoryItem]:
    flt = filter or SchemaListFilter()
    kind_filter = frozenset(_normalize_kind(k) for k in flt.kinds if k)

    items: list[SchemaInventoryItem] = []
    for schema_name in fetch_schema_names_with_sys_version(fetcher):
        entry = fetch_schema_inventory_entry(schema_name, fetcher)
        if entry is None:
            continue
        if flt.tier == "main" and entry.tier != "main":
            continue
        if flt.tier == "addon" and entry.tier != "addon":
            continue
        if kind_filter and entry.kind not in kind_filter:
            continue
        items.append(entry)

    return sorted(
        items,
        key=lambda item: (
            _TIER_SORT.get(item.tier, 9),
            item.kind,
            item.schema,
        ),
    )


def schema_list_payload(items: list[SchemaInventoryItem]) -> dict[str, Any]:
    return {
        "ok": True,
        "schemas": [
            {
                "schema": item.schema,
                "kind": item.kind,
                "tier": item.tier,
                "version": item.version,
                "epsg": item.epsg,
                "lang": item.lang,
            }
            for item in items
        ],
    }


def format_schema_list(
    items: list[SchemaInventoryItem],
    *,
    database: str = "",
) -> str:
    if not items:
        title = f"Giswater schemas @ {database}" if database else "Giswater schemas"
        return f"{title}\n(no schemas match filters)"

    lines: list[str] = []
    title = f"Giswater schemas @ {database}" if database else "Giswater schemas"
    lines.append(title)
    lines.append("")
    lines.append("schemas:")
    for item in items:
        kind_label = item.kind.upper() if item.kind else "?"
        epsg = item.epsg if item.epsg is not None else "-"
        lang = item.lang or "-"
        lines.append(
            f"  {item.schema:<12} {kind_label:<6} {item.tier:<6} "
            f"{item.version or '-':<8} epsg={epsg} lang={lang}"
        )
    return "\n".join(lines)


def _quote_ident(name: str) -> str:
    return '"' + str(name).replace('"', '""') + '"'


def _parse_addparam(addparam: Any) -> dict[str, Any]:
    if isinstance(addparam, dict):
        return addparam
    if addparam:
        try:
            parsed = json.loads(addparam)
            if isinstance(parsed, dict):
                return parsed
        except (TypeError, ValueError):
            pass
    return {}


def _version_tuple(version: str) -> tuple[int, int, int]:
    parts = str(version or "0").split(".")
    nums: list[int] = []
    for part in parts[:3]:
        try:
            nums.append(int(part))
        except ValueError:
            nums.append(0)
    while len(nums) < 3:
        nums.append(0)
    return nums[0], nums[1], nums[2]


def version_text(version: tuple[int, int, int]) -> str:
    return ".".join(str(x) for x in version)


def make_conn_fetcher(conn: ConnectionLike) -> RowFetcher:
    raw = getattr(conn, "raw", None)

    def _fetch(sql: str, params: Optional[list] = None) -> Optional[list[tuple]]:
        if raw is None:
            return None
        try:
            with raw.cursor() as cur:
                if params:
                    cur.execute(sql, params)
                else:
                    cur.execute(sql)
                return cur.fetchall()
        except Exception:  # noqa: BLE001
            try:
                conn.rollback()
            except Exception:  # noqa: BLE001
                pass
            return None

    return _fetch


def schema_exists(name: str, fetcher: RowFetcher) -> bool:
    row = fetcher("SELECT to_regnamespace(%s) IS NOT NULL", [name])
    return bool(row and row[0] and row[0][0])


def fetch_schema_names_with_sys_version(fetcher: RowFetcher) -> list[str]:
    rows = fetcher(
        """
        SELECT n.nspname
        FROM pg_catalog.pg_namespace n
        JOIN pg_catalog.pg_class c ON c.relnamespace = n.oid
        WHERE c.relname = 'sys_version'
          AND c.relkind = 'r'
          AND n.nspname NOT LIKE 'pg_%'
          AND n.nspname <> 'information_schema'
        ORDER BY n.nspname
        """,
        None,
    )
    if not rows:
        return []
    return [str(row[0]) for row in rows]


def _version_column_for_schema(schema_name: str, columns: set[str]) -> str:
    if schema_name.lower() not in _NETWORK_KINDS:
        for col in ("version", "giswater"):
            if col in columns:
                return col
    else:
        for col in ("giswater", "version"):
            if col in columns:
                return col
    return ""


def _fetch_sys_version_addparam(
    schema_name: str,
    fetcher: RowFetcher,
    *,
    columns: set[str] | None = None,
) -> dict[str, Any]:
    if columns is None:
        columns = _sys_version_columns_by_schema([schema_name], fetcher).get(schema_name, set())
    if "addparam" not in columns:
        return {}
    row = fetcher(
        f"SELECT addparam FROM {_quote_ident(schema_name)}.sys_version "
        "ORDER BY id DESC LIMIT 1",
        None,
    )
    if not row or not row[0]:
        return {}
    return _parse_addparam(row[0][0])


def _sys_version_columns_by_schema(
    schema_names: list[str],
    fetcher: RowFetcher,
) -> dict[str, set[str]]:
    if not schema_names:
        return {}
    rows = fetcher(
        """
        SELECT n.nspname, a.attname
        FROM pg_catalog.pg_namespace n
        JOIN pg_catalog.pg_class c ON c.relnamespace = n.oid
        JOIN pg_catalog.pg_attribute a ON a.attrelid = c.oid
        WHERE c.relname = 'sys_version'
          AND c.relkind IN ('r', 'p')
          AND n.nspname = ANY(%s::text[])
          AND a.attname = ANY(ARRAY['giswater', 'version', 'addparam', 'epsg', 'language'])
          AND a.attnum > 0
          AND NOT a.attisdropped
        """,
        [schema_names],
    )
    result: dict[str, set[str]] = {name: set() for name in schema_names}
    if not rows:
        return result
    for schema_name, column_name in rows:
        result.setdefault(str(schema_name), set()).add(str(column_name))
    return result


def fetch_schema_sys_version_entry(
    schema_name: str,
    fetcher: RowFetcher,
) -> dict[str, Any]:
    if not schema_exists(schema_name, fetcher):
        return {}

    columns = _sys_version_columns_by_schema([schema_name], fetcher).get(schema_name, set())
    version_col = _version_column_for_schema(schema_name, columns)
    if not version_col:
        return {"schema": schema_name, "kind": "", "version": "", "addparam": {}}
    select_cols = ["project_type", version_col]
    if "addparam" in columns:
        select_cols.append("addparam")

    row = fetcher(
        f"SELECT {', '.join(select_cols)} "
        f"FROM {_quote_ident(schema_name)}.sys_version "
        "ORDER BY id DESC LIMIT 1",
        None,
    )
    if not row or not row[0]:
        return {"schema": schema_name, "kind": "", "version": "", "addparam": {}}

    values = row[0]
    addparam = values[2] if len(values) > 2 else None
    return {
        "schema": schema_name,
        "kind": str(values[0] or ""),
        "version": str(values[1] or ""),
        "addparam": _parse_addparam(addparam),
    }


def _legacy_parent_satellites(schema_name: str, fetcher: RowFetcher) -> list[tuple[str, str]]:
    linked: list[tuple[str, str]] = []
    row = fetcher(
        f"SELECT value FROM {_quote_ident(schema_name)}.config_param_system "
        "WHERE parameter = 'admin_cibs_schema' LIMIT 1",
        None,
    )
    if row and row[0] and str(row[0][0]).lower() in ("true", "t", "1"):
        linked.append(("cibs", "cibs"))
    return linked


def _satellite_schema_name(
    kind: str,
    satellites: dict[str, Any],
    fetcher: RowFetcher,
) -> Optional[str]:
    meta = satellites.get(kind) or satellites.get(kind.upper())
    if not isinstance(meta, dict):
        return None
    if meta.get("enabled") is False:
        return None
    schema_name = str(meta.get("schema") or kind)
    if schema_exists(schema_name, fetcher):
        return schema_name
    return None


def _expand_satellites_from_parent(
    parent_schema: str,
    addparam: dict[str, Any],
    fetcher: RowFetcher,
) -> list[tuple[str, str, str]]:
    """Return [(kind, satellite_schema, parent_schema), ...]."""
    out: list[tuple[str, str, str]] = []
    satellites = addparam.get("satellites") or {}
    if isinstance(satellites, dict):
        for kind in satellites:
            kind_norm = _normalize_kind(str(kind))
            if not kind_norm or kind_norm in _NETWORK_KINDS:
                continue
            schema_name = _satellite_schema_name(kind_norm, satellites, fetcher)
            if schema_name:
                out.append((kind_norm, schema_name, parent_schema))

    kind = str(addparam.get("kind") or "").upper()
    if kind in ("WS", "UD"):
        for sat_kind, sat_schema in _legacy_parent_satellites(parent_schema, fetcher):
            if not any(item[0] == sat_kind and item[1] == sat_schema for item in out):
                out.append((sat_kind, sat_schema, parent_schema))
    return out


def _expand_parents_from_satellite(
    satellite_schema: str,
    addparam: dict[str, Any],
    fetcher: RowFetcher,
) -> list[tuple[str, str, str]]:
    """Return [(parent_kind, parent_schema, satellite_schema), ...]."""
    entry = fetch_schema_sys_version_entry(satellite_schema, fetcher)
    sat_kind = str(entry.get("kind") or "").lower()
    if sat_kind in _NETWORK_KINDS:
        return []

    out: list[tuple[str, str, str]] = []
    network = addparam.get("network_parents") or {}
    if isinstance(network, dict):
        for kind in _NETWORK_KINDS:
            values = network.get(kind) or []
            if isinstance(values, list):
                for parent in values:
                    if parent and schema_exists(str(parent), fetcher):
                        out.append((kind, str(parent), satellite_schema))

    parents = addparam.get("parent_schemas") or []
    if isinstance(parents, list):
        for parent_schema in parents:
            if not parent_schema or str(parent_schema) == satellite_schema:
                continue
            entry = fetch_schema_sys_version_entry(str(parent_schema), fetcher)
            parent_kind = str(entry.get("kind") or "").lower()
            if parent_kind in _NETWORK_KINDS and schema_exists(str(parent_schema), fetcher):
                triple = (parent_kind, str(parent_schema), satellite_schema)
                if triple not in out:
                    out.append(triple)

    if str(satellite_schema) == "utils":
        for kind, param in (("ws", "ws_current_schema"), ("ud", "ud_current_schema")):
            row = fetcher(
                "SELECT value FROM utils.config_param_system WHERE parameter = %s LIMIT 1",
                [param],
            )
            if row and row[0] and row[0][0]:
                parent = str(row[0][0])
                if schema_exists(parent, fetcher):
                    triple = (kind, parent, satellite_schema)
                    if triple not in out:
                        out.append(triple)
    return out


def _node_from_entry(entry: dict[str, Any], *, enabled: bool = True) -> NetworkNode:
    ap = entry.get("addparam") or {}
    summary: dict[str, Any] = {}
    for key in ("satellites", "parent_schemas", "network_parents"):
        if ap.get(key):
            summary[key] = ap.get(key)
    return NetworkNode(
        schema=str(entry.get("schema") or ""),
        kind=str(entry.get("kind") or "").lower(),
        version=str(entry.get("version") or ""),
        enabled=enabled,
        addparam_summary=summary,
    )


def _collect_edges_from_entries(
    entries: dict[str, dict[str, Any]],
    fetcher: RowFetcher,
) -> list[NetworkEdge]:
    edges: list[NetworkEdge] = []
    seen_edges: set[tuple[str, str, str]] = set()

    def _add_edge(source: str, target: str, relation: str) -> None:
        if source == target:
            return
        key = (source, target, relation)
        if key in seen_edges:
            return
        seen_edges.add(key)
        edges.append(NetworkEdge(source=source, target=target, relation=relation))

    for schema_name, entry in entries.items():
        ap = entry.get("addparam") or {}
        node_kind = str(entry.get("kind") or "").lower()

        if node_kind in _NETWORK_KINDS:
            for kind, sat_schema, parent_schema in _expand_satellites_from_parent(
                schema_name, ap, fetcher
            ):
                _add_edge(parent_schema, sat_schema, f"satellite:{kind}")
                _add_edge(sat_schema, parent_schema, f"parent_of:{kind}")

        if _is_addon_kind(node_kind):
            for parent_kind, parent_schema, sat_schema in _expand_parents_from_satellite(
                schema_name, ap, fetcher
            ):
                _add_edge(sat_schema, parent_schema, f"parent_of:{parent_kind}")
                _add_edge(parent_schema, sat_schema, f"satellite:{parent_kind}")

    return edges


def _connected_components(
    schemas: set[str],
    edges: list[NetworkEdge],
) -> list[set[str]]:
    parent: dict[str, str] = {schema: schema for schema in schemas}

    def _find(node: str) -> str:
        while parent[node] != node:
            parent[node] = parent[parent[node]]
            node = parent[node]
        return node

    def _union(left: str, right: str) -> None:
        root_left = _find(left)
        root_right = _find(right)
        if root_left != root_right:
            parent[root_right] = root_left

    for edge in edges:
        if edge.source in schemas and edge.target in schemas:
            _union(edge.source, edge.target)

    grouped: dict[str, set[str]] = {}
    for schema in schemas:
        grouped.setdefault(_find(schema), set()).add(schema)
    return list(grouped.values())


def _pick_main_cluster(
    components: list[set[str]],
    entries: dict[str, dict[str, Any]],
) -> set[str]:
    if not components:
        return set()

    def _score(component: set[str]) -> tuple[int, int, int]:
        kinds = {
            str(entries[schema].get("kind") or "").lower()
            for schema in component
            if schema in entries
        }
        has_utils = "utils" in component or "utils" in kinds
        has_network = bool(set(_NETWORK_KINDS) & kinds)
        has_satellite = bool(kinds - set(_NETWORK_KINDS))
        return (
            1 if has_utils else 0,
            1 if has_network and has_satellite else 0,
            len(component),
        )

    return max(components, key=_score)


def _graph_from_nodes_edges(
    nodes: list[NetworkNode],
    edges: list[NetworkEdge],
    *,
    anchor: str = "",
) -> NetworkGraph:
    versions = [node.version for node in nodes if node.version]
    version_skew = len({node.version for node in nodes if node.version}) > 1
    min_version = min(versions, key=_version_tuple) if versions else ""
    max_version = max(versions, key=_version_tuple) if versions else ""
    return NetworkGraph(
        anchor=anchor,
        nodes=nodes,
        edges=edges,
        version_skew=version_skew,
        min_version=min_version,
        max_version=max_version,
    )


def discover_database_network(
    fetcher: RowFetcher,
    *,
    schema_filter: str | None = None,
) -> DatabaseNetwork:
    """Scan every sys_version schema and derive the main Giswater network."""
    all_names = fetch_schema_names_with_sys_version(fetcher)
    entries = {
        name: fetch_schema_sys_version_entry(name, fetcher)
        for name in all_names
    }
    entries = {name: entry for name, entry in entries.items() if entry}

    edges = _collect_edges_from_entries(entries, fetcher)
    components = _connected_components(set(entries), edges)
    main = _pick_main_cluster(components, entries)

    if schema_filter:
        schema_filter = str(schema_filter).strip()
        if schema_filter and schema_filter not in main:
            for component in components:
                if schema_filter in component:
                    main = component
                    break

    cluster_nodes = [_node_from_entry(entries[name]) for name in sorted(main)]
    cluster_edges = [
        edge for edge in edges if edge.source in main and edge.target in main
    ]
    cluster_graph = _graph_from_nodes_edges(cluster_nodes, cluster_edges)

    other_schemas = [
        _node_from_entry(entries[name])
        for name in sorted(set(entries) - main)
    ]

    audit_schema: str | None = None
    if schema_exists("audit", fetcher) and "audit" not in entries:
        audit_schema = "audit"

    return DatabaseNetwork(
        cluster=cluster_graph,
        other_schemas=other_schemas,
        audit_schema=audit_schema,
    )


def resolve_network_graph(
    anchor_schema: str,
    fetcher: RowFetcher,
) -> NetworkGraph:
    """Return the network cluster, optionally tagged with *anchor_schema*."""
    db = discover_database_network(fetcher, schema_filter=anchor_schema or None)
    graph = db.cluster
    anchor_schema = str(anchor_schema or "").strip()

    if anchor_schema:
        if graph.node_for(anchor_schema) is not None:
            graph.anchor = anchor_schema
            return graph
        for node in db.other_schemas:
            if node.schema == anchor_schema:
                return _graph_from_nodes_edges([node], [], anchor=anchor_schema)
        return NetworkGraph(anchor=anchor_schema, nodes=[], edges=[])

    return graph


def discover_cluster(
    graph: NetworkGraph,
    dbmodel_path: str | None = None,
) -> list[ClusterMember]:
    """Ordered cluster members for lockstep updates."""
    by_kind: dict[str, ClusterMember] = {}
    for node in graph.nodes:
        kind = node.kind.lower()
        if kind not in by_kind:
            by_kind[kind] = ClusterMember(kind=kind, schema=node.schema, version=node.version)

    if dbmodel_path:
        from .manifest_registry import all_kinds, update_kind_order

        if all_kinds(dbmodel_path):
            kind_order = list(update_kind_order(dbmodel_path))
        else:
            kind_order = list(_FALLBACK_UPDATE_KIND_ORDER)
    else:
        kind_order = list(_FALLBACK_UPDATE_KIND_ORDER)

    for kind in by_kind:
        if kind not in kind_order:
            kind_order.append(kind)

    out: list[ClusterMember] = []
    for kind in kind_order:
        member = by_kind.get(kind)
        if member is not None:
            out.append(member)
    return out


def graph_has_linked_dependents(graph: NetworkGraph, schema: str) -> bool:
    """True when *schema* belongs to a multi-node network."""
    if len(graph.nodes) <= 1:
        return False
    return any(
        edge.source == schema or edge.target == schema
        for edge in graph.edges
    )


def _satellites_of_network(graph: NetworkGraph, network_schema: str) -> list[str]:
    satellite_schemas = {n.schema for n in graph.nodes if _is_addon_kind(n.kind)}
    return sorted(
        {
            edge.target
            for edge in graph.edges
            if edge.source == network_schema
            and edge.relation.startswith("satellite:")
            and edge.target in satellite_schemas
        }
    )


def _parents_of_satellite(graph: NetworkGraph, satellite_schema: str) -> list[str]:
    network_schemas = {n.schema for n in graph.nodes if n.kind in _NETWORK_KINDS}
    return sorted(
        {
            edge.source
            for edge in graph.edges
            if edge.target == satellite_schema
            and edge.relation.startswith("satellite:")
            and edge.source in network_schemas
        }
    )


def summarize_network_links(graph: NetworkGraph) -> dict[str, Any]:
    """Compact integration view for CLI/JSON output."""
    networks = sorted(
        (n for n in graph.nodes if n.kind in _NETWORK_KINDS),
        key=lambda n: n.schema,
    )
    satellites = sorted(
        (n for n in graph.nodes if _is_addon_kind(n.kind)),
        key=lambda n: n.schema,
    )
    return {
        "networks": [
            {
                "schema": node.schema,
                "kind": node.kind,
                "version": node.version,
            }
            for node in networks
        ],
        "satellites": [
            {
                "schema": node.schema,
                "kind": node.kind,
                "version": node.version,
                "parents": _parents_of_satellite(graph, node.schema),
            }
            for node in satellites
        ],
        "integration": [
            {
                "network": node.schema,
                "satellites": _satellites_of_network(graph, node.schema),
            }
            for node in networks
            if _satellites_of_network(graph, node.schema)
        ],
    }


def database_network_payload(db: DatabaseNetwork) -> dict[str, Any]:
    """Structured JSON payload for ``network show --json``."""
    graph = db.cluster
    return {
        "ok": True,
        "version_skew": graph.version_skew,
        "min_version": graph.min_version,
        "max_version": graph.max_version,
        "cluster": {
            "nodes": [
                {
                    "schema": node.schema,
                    "kind": node.kind,
                    "version": node.version,
                    "enabled": node.enabled,
                }
                for node in graph.nodes
            ],
            "links": summarize_network_links(graph),
        },
        "other_schemas": [
            {
                "schema": node.schema,
                "kind": node.kind,
                "version": node.version,
                "linked": False,
            }
            for node in db.other_schemas
        ],
        "audit_schema": db.audit_schema,
    }


def format_database_network(
    db: DatabaseNetwork,
    *,
    database: str = "",
) -> str:
    """Human-readable database network summary."""
    graph = db.cluster
    if not graph.nodes and not db.other_schemas and not db.audit_schema:
        return "Giswater network\n(no schemas discovered)"

    lines: list[str] = []
    title = f"Giswater network @ {database}" if database else "Giswater network"
    lines.append(title)

    if graph.nodes:
        links = summarize_network_links(graph)
        if links["networks"]:
            lines.append("")
            lines.append("networks:")
            for item in links["networks"]:
                lines.append(
                    f"  {item['schema']:<12} {item['kind'].upper():<6} {item['version']}"
                )

        if links["satellites"]:
            lines.append("")
            lines.append("satellites:")
            for item in links["satellites"]:
                parents = ", ".join(item["parents"]) if item["parents"] else "-"
                lines.append(
                    f"  {item['schema']:<12} {item['kind'].upper():<6} {item['version']}"
                    f"  ← {parents}"
                )

        if db.audit_schema:
            lines.append("")
            lines.append("addons:")
            lines.append(f"  {db.audit_schema:<12} AUDIT  (no sys_version)")

        if links["integration"]:
            lines.append("")
            lines.append("integration:")
            for item in links["integration"]:
                sats = ", ".join(item["satellites"])
                lines.append(f"  {item['network']} → {sats}")

        lines.append("")
        if graph.version_skew:
            lines.append(
                f"version_skew: yes ({graph.min_version} .. {graph.max_version})"
            )
        elif graph.min_version:
            lines.append(f"version_skew: no ({graph.min_version})")
        else:
            lines.append("version_skew: no")

    if db.other_schemas:
        lines.append("")
        lines.append("other schemas:")
        for node in db.other_schemas:
            kind = node.kind.upper() if node.kind else "?"
            version = node.version or "-"
            lines.append(
                f"  {node.schema:<12} {kind:<6} {version:<8} not linked"
            )

    return "\n".join(lines)


def format_network_tree(graph: NetworkGraph) -> str:
    """Backward-compatible wrapper around :func:`format_database_network`."""
    return format_database_network(DatabaseNetwork(cluster=graph))


__all__ = [
    "ADDON_KINDS",
    "ClusterMember",
    "DatabaseNetwork",
    "MAIN_KINDS",
    "NetworkEdge",
    "NetworkGraph",
    "NetworkNode",
    "SchemaInventoryItem",
    "SchemaListFilter",
    "UPDATE_KIND_ORDER",
    "database_network_payload",
    "discover_cluster",
    "discover_database_network",
    "fetch_schema_inventory_entry",
    "fetch_schema_names_with_sys_version",
    "fetch_schema_sys_version_entry",
    "format_database_network",
    "format_network_tree",
    "format_schema_list",
    "graph_has_linked_dependents",
    "list_schemas",
    "make_conn_fetcher",
    "resolve_network_graph",
    "schema_exists",
    "schema_list_payload",
    "summarize_network_links",
    "version_text",
]
