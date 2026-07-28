"""Tests for schema_catalog network graph discovery."""

from __future__ import annotations

from giswater_admin.engine.schema_catalog import (
    DatabaseNetwork,
    SchemaInventoryItem,
    SchemaListFilter,
    discover_cluster,
    discover_database_network,
    format_database_network,
    format_network_tree,
    graph_has_linked_dependents,
    list_schemas,
    resolve_network_graph,
    summarize_network_links,
)


def _entry(schema: str, kind: str, version: str, addparam: dict):
    return {
        "schema": schema,
        "kind": kind,
        "version": version,
        "addparam": addparam,
    }


def _patch_catalog(store: dict, monkeypatch=None):
    import giswater_admin.engine.schema_catalog as catalog

    class _Ctx:
        original_fetch = catalog.fetch_schema_sys_version_entry
        original_exists = catalog.schema_exists
        original_names = catalog.fetch_schema_names_with_sys_version

        def __enter__(self):
            catalog.fetch_schema_sys_version_entry = lambda schema, _f: store.get(schema, {})
            catalog.schema_exists = lambda name, _f: name in store or name == "audit"
            catalog.fetch_schema_names_with_sys_version = lambda _f: sorted(store)
            return catalog

        def __exit__(self, *args):
            catalog.fetch_schema_sys_version_entry = self.original_fetch
            catalog.schema_exists = self.original_exists
            catalog.fetch_schema_names_with_sys_version = self.original_names

    return _Ctx()


def _linked_store():
    return {
        "ws": _entry(
            "ws",
            "ws",
            "4.15.0",
            {
                "satellites": {
                    "utils": {"enabled": True, "schema": "utils"},
                    "cibs": {"enabled": True, "schema": "cibs"},
                }
            },
        ),
        "utils": _entry(
            "utils",
            "utils",
            "4.15.0",
            {
                "network_parents": {"ws": ["ws"], "ud": ["ud"]},
                "parent_schemas": ["ws", "ud"],
            },
        ),
        "cibs": _entry(
            "cibs",
            "cibs",
            "4.15.0",
            {"parent_schemas": ["ws", "ud"]},
        ),
        "ud": _entry(
            "ud",
            "ud",
            "4.15.0",
            {
                "satellites": {
                    "utils": {"enabled": True, "schema": "utils"},
                    "cibs": {"enabled": True, "schema": "cibs"},
                }
            },
        ),
    }


def test_discover_database_network_finds_full_cluster_without_anchor():
    store = _linked_store()

    def fetcher(sql: str, params=None):
        del sql, params
        return None

    with _patch_catalog(store):
        db = discover_database_network(fetcher)

    schemas = {node.schema for node in db.cluster.nodes}
    assert schemas == {"ws", "utils", "cibs", "ud"}
    assert db.other_schemas == []
    assert not db.cluster.version_skew


def test_resolve_network_graph_from_ws_discovers_ud_via_utils():
    store = _linked_store()

    def fetcher(sql: str, params=None):
        del sql, params
        return None

    with _patch_catalog(store):
        graph = resolve_network_graph("ws", fetcher)

    schemas = {node.schema for node in graph.nodes}
    assert schemas == {"ws", "utils", "cibs", "ud"}
    assert not graph.version_skew
    cluster = discover_cluster(graph)
    assert [member.kind for member in cluster] == ["utils", "cibs", "ws", "ud"]
    assert graph_has_linked_dependents(graph, "utils")


def test_isolated_schema_has_no_dependents():
    store = {
        "solo": _entry("solo", "ws", "4.15.0", {}),
    }

    def fetcher(sql: str, params=None):
        del sql, params
        return None

    with _patch_catalog(store):
        graph = resolve_network_graph("solo", fetcher)

    assert len(graph.nodes) == 1
    assert not graph_has_linked_dependents(graph, "solo")


def test_orphan_schemas_listed_as_other():
    store = _linked_store()
    store["ext_schema1"] = _entry("ext_schema1", "ws", "4.10.0", {})

    def fetcher(sql: str, params=None):
        del sql, params
        return None

    with _patch_catalog(store):
        db = discover_database_network(fetcher)

    assert {node.schema for node in db.cluster.nodes} == {"ws", "utils", "cibs", "ud"}
    assert len(db.other_schemas) == 1
    assert db.other_schemas[0].schema == "ext_schema1"

    text = format_database_network(db)
    assert "other schemas:" in text
    assert "ext_schema1" in text
    assert "not linked" in text


def test_network_show_ignores_parent_schemas_on_network_kinds():
    store = {
        "ws": _entry(
            "ws",
            "ws",
            "4.16.0",
            {
                "satellites": {
                    "utils": {"enabled": True, "schema": "utils"},
                    "cibs": {"enabled": True, "schema": "cibs"},
                },
                "parent_schemas": ["ud", "ws"],
            },
        ),
        "utils": _entry(
            "utils",
            "utils",
            "4.16.0",
            {"parent_schemas": ["ws", "ud"]},
        ),
        "cibs": _entry(
            "cibs",
            "cibs",
            "4.16.0",
            {"parent_schemas": ["ws", "ud"]},
        ),
        "ud": _entry(
            "ud",
            "ud",
            "4.16.0",
            {
                "satellites": {
                    "utils": {"enabled": True, "schema": "utils"},
                    "cibs": {"enabled": True, "schema": "cibs"},
                },
                "parent_schemas": ["ud", "ws"],
            },
        ),
    }

    def fetcher(sql: str, params=None):
        del sql, params
        return None

    with _patch_catalog(store):
        db = discover_database_network(fetcher)
        graph = db.cluster

    assert not any(edge.source == edge.target for edge in graph.edges)
    links = summarize_network_links(graph)
    assert links["integration"] == [
        {"network": "ud", "satellites": ["cibs", "utils"]},
        {"network": "ws", "satellites": ["cibs", "utils"]},
    ]
    assert links["satellites"][0]["parents"] == ["ud", "ws"]

    text = format_network_tree(graph)
    assert "cibs → cibs" not in text
    assert "utils → utils" not in text
    assert "integration:" in text
    assert "ws → cibs, utils" in text
    assert "anchor" not in text.lower()
    assert "suggested" not in text.lower()


def test_format_database_network_includes_audit_addon():
    store = _linked_store()

    def fetcher(sql: str, params=None):
        del sql, params
        return None

    with _patch_catalog(store):
        db = discover_database_network(fetcher)

    db = DatabaseNetwork(cluster=db.cluster, other_schemas=[], audit_schema="audit")
    text = format_database_network(db)
    assert "addons:" in text
    assert "audit" in text
    assert "no sys_version" in text


def test_list_schemas_filters_tier_main(monkeypatch) -> None:
    import giswater_admin.engine.schema_catalog as catalog

    inventory = {
        "ws": SchemaInventoryItem("ws", "ws", "main", "4.15.0", 25831, "en_US"),
        "utils": SchemaInventoryItem("utils", "utils", "addon", "4.15.0"),
    }
    monkeypatch.setattr(
        catalog,
        "fetch_schema_names_with_sys_version",
        lambda _f: ["ws", "utils"],
    )
    monkeypatch.setattr(
        catalog,
        "fetch_schema_inventory_entry",
        lambda name, _f: inventory.get(name),
    )

    items = list_schemas(lambda _s, _p=None: None, filter=SchemaListFilter(tier="main"))
    assert [item.schema for item in items] == ["ws"]


def test_list_schemas_filters_by_kind(monkeypatch) -> None:
    import giswater_admin.engine.schema_catalog as catalog

    inventory = {
        "ws": SchemaInventoryItem("ws", "ws", "main", "4.15.0"),
        "ud": SchemaInventoryItem("ud", "ud", "main", "4.15.0"),
        "cibs": SchemaInventoryItem("cibs", "cibs", "addon", "4.15.0"),
    }
    monkeypatch.setattr(
        catalog,
        "fetch_schema_names_with_sys_version",
        lambda _f: ["ws", "ud", "cibs"],
    )
    monkeypatch.setattr(
        catalog,
        "fetch_schema_inventory_entry",
        lambda name, _f: inventory.get(name),
    )

    items = list_schemas(
        lambda _s, _p=None: None,
        filter=SchemaListFilter(kinds=frozenset({"ws", "cibs"})),
    )
    assert [item.schema for item in items] == ["ws", "cibs"]


def test_version_column_requires_existing_column():
    from giswater_admin.engine import schema_catalog as catalog

    assert catalog._version_column_for_schema("ws_40", {"version"}) == "version"
    assert catalog._version_column_for_schema("ws_40", {"giswater"}) == "giswater"
    assert catalog._version_column_for_schema("ws_40", set()) == ""
    assert catalog._version_column_for_schema("utils", {"version"}) == "version"


def test_fetch_sys_version_addparam_skips_missing_column():
    from giswater_admin.engine import schema_catalog as catalog

    def fetcher(sql: str, params=None):
        if "pg_attribute" in sql:
            return [("utils", "giswater")]
        raise AssertionError(f"unexpected query: {sql}")

    assert catalog._fetch_sys_version_addparam("utils", fetcher) == {}
