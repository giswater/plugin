"""
Engine public API. Importing this module must NOT pull in qgis/Qt.
"""

from __future__ import annotations

from .builder import BuildParams, BuildResult, PhaseResult, SchemaBuilder, drop_schema
from .cancel import CancelToken
from .changelog import (
    VersionChangelog,
    changelog_versions_as_dicts,
    collect_pending_versions,
    collect_upgrade_changelogs,
    format_upgrade_changelog,
    network_update_roots,
    parse_changelog_file,
    read_version_sections,
)
from .manifest import Manifest, Phase, Step, load_manifest
from .manifest_registry import (
    addon_kinds,
    all_kinds,
    kind_update_roots,
    load_kind_manifest,
    main_kinds,
    update_kind_order,
)
from .network_update import (
    LockstepStep,
    NetworkUpdateResult,
    has_patch_at_version,
    plan_lockstep,
    resolve_lockstep_profile,
    run_lockstep,
)
from .schema_catalog import (
    ClusterMember,
    NetworkGraph,
    NetworkNode,
    discover_cluster,
    format_network_tree,
    graph_has_linked_dependents,
    make_conn_fetcher,
    resolve_network_graph,
)
from .sql_runner import ConnectionLike, FileExec

__all__ = [
    "addon_kinds",
    "all_kinds",
    "BuildParams",
    "BuildResult",
    "CancelToken",
    "ClusterMember",
    "ConnectionLike",
    "FileExec",
    "LockstepStep",
    "Manifest",
    "NetworkGraph",
    "NetworkNode",
    "NetworkUpdateResult",
    "Phase",
    "PhaseResult",
    "SchemaBuilder",
    "Step",
    "update_kind_order",
    "VersionChangelog",
    "changelog_versions_as_dicts",
    "collect_pending_versions",
    "collect_upgrade_changelogs",
    "discover_cluster",
    "drop_schema",
    "format_network_tree",
    "format_upgrade_changelog",
    "graph_has_linked_dependents",
    "has_patch_at_version",
    "kind_update_roots",
    "load_kind_manifest",
    "load_manifest",
    "main_kinds",
    "make_conn_fetcher",
    "network_update_roots",
    "parse_changelog_file",
    "plan_lockstep",
    "read_version_sections",
    "resolve_lockstep_profile",
    "resolve_network_graph",
    "run_lockstep",
]
