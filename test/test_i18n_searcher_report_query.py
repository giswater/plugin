"""Tests for quoted AS-alias extraction from config_report.query_text."""

from __future__ import annotations

import sys
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))

from i18n_api_client import (  # noqa: E402
    TABLE_EXTRA_COLUMNS,
    catalog_primary_key_columns,
)
from i18n_searcher import _extract_quoted_as_aliases  # noqa: E402


class TestReportQueryAliasExtraction(unittest.TestCase):

    def test_extracts_quoted_aliases_left_to_right(self):
        query = (
            'SELECT w.exploitation as "Exploitation", w.dma as "Dma", '
            'period as "Period" FROM v_om_waterbalance w'
        )
        self.assertEqual(
            _extract_quoted_as_aliases(query),
            ["Exploitation", "Dma", "Period"],
        )

    def test_hint_index_matches_alias_order(self):
        aliases = _extract_quoted_as_aliases(
            'SELECT name as "Exploitation", node_type as "Node type", '
            'count(*) as "Units" FROM ve_node'
        )
        hints = [f"queryText_{i}" for i, _ in enumerate(aliases)]
        self.assertEqual(hints, ["queryText_0", "queryText_1", "queryText_2"])
        self.assertEqual(aliases[0], "Exploitation")
        self.assertEqual(aliases[1], "Node type")

    def test_unescapes_doubled_quotes(self):
        query = 'SELECT 1 AS "Total ""inlet"""'
        self.assertEqual(_extract_quoted_as_aliases(query), ['Total "inlet"'])

    def test_skips_unquoted_aliases_and_empty_sql(self):
        self.assertEqual(
            _extract_quoted_as_aliases(
                "SELECT e.name as exploitation, vec.connec_id FROM ve_connec vec"
            ),
            [],
        )
        self.assertEqual(_extract_quoted_as_aliases(""), [])
        self.assertEqual(_extract_quoted_as_aliases("   "), [])

    def test_skips_empty_quoted_alias(self):
        self.assertEqual(_extract_quoted_as_aliases('SELECT 1 AS ""'), [])

    def test_catalog_pk_and_blob_extra_columns(self):
        self.assertEqual(
            catalog_primary_key_columns("dbconfig_report_query"),
            ("source", "hint", "project_type", "context", "source_code"),
        )
        self.assertEqual(TABLE_EXTRA_COLUMNS["dbconfig_report_query"], ("text",))


if __name__ == "__main__":
    unittest.main()
