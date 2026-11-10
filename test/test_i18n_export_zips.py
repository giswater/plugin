"""Tests for translations.json coverage bars and README rendering."""

from __future__ import annotations

import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPTS))

from i18n_export_zips import (  # noqa: E402
    BAR_WIDTH,
    DEFAULT_README_TEMPLATE,
    STATS_PLACEHOLDER,
    coverage_bar,
    render_coverage_markdown,
    render_coverage_mermaid,
    sort_catalog_for_stats,
    write_translations_readme,
)


class TestCoverageBar(unittest.TestCase):

    def test_zero_is_empty(self):
        bar = coverage_bar(0)
        self.assertEqual(len(bar), BAR_WIDTH)
        self.assertEqual(bar, "░" * BAR_WIDTH)

    def test_full_is_filled(self):
        bar = coverage_bar(100)
        self.assertEqual(len(bar), BAR_WIDTH)
        self.assertEqual(bar, "█" * BAR_WIDTH)

    def test_76_65_rounds_to_fifteen(self):
        bar = coverage_bar(76.65)
        self.assertEqual(bar, ("█" * 15) + ("░" * 5))


class TestCatalogSort(unittest.TestCase):

    def test_sorts_percent_desc_then_name_none_last(self):
        catalog = [
            {"locale": "xx_XX", "name": "Missing", "percent": None},
            {"locale": "ca_ES", "name": "Català (Espanya)", "percent": 76.65},
            {"locale": "aa_AA", "name": "Also full", "percent": 100.0},
            {"locale": "es_ES", "name": "Español (España)", "percent": 100.0},
            {"locale": "fr_FR", "name": "François (France)", "percent": 3.44},
        ]
        locales = [entry["locale"] for entry in sort_catalog_for_stats(catalog)]
        self.assertEqual(locales, ["aa_AA", "es_ES", "ca_ES", "fr_FR", "xx_XX"])


class TestMermaidChart(unittest.TestCase):

    def test_quoted_locales_with_underscore_do_not_break_fence(self):
        catalog = [
            {"locale": "es_ES", "name": "Español (España)", "percent": 100.0},
            {"locale": "uk_UA", "name": "Ukrainian (Ukraine)", "percent": 78.29},
        ]
        chart = render_coverage_mermaid(catalog)
        self.assertTrue(chart.startswith("```mermaid\n"))
        self.assertTrue(chart.endswith("```"))
        self.assertEqual(chart.count("```"), 2)
        self.assertIn('x-axis ["es_ES", "uk_UA"]', chart)
        self.assertIn("bar [100, 78.29]", chart)
        self.assertNotIn("```mermaid", chart.split("```mermaid", 1)[1])


class TestReadmeTemplate(unittest.TestCase):

    def test_template_has_placeholder(self):
        template = DEFAULT_README_TEMPLATE.read_text(encoding="utf-8")
        self.assertIn(STATS_PLACEHOLDER, template)
        self.assertIn("# Giswater translations", template)

    def test_replaces_placeholder_and_keeps_surrounding_prose(self):
        catalog = [
            {"locale": "es_ES", "name": "Español (España)", "percent": 100.0},
            {"locale": "fr_FR", "name": "François (France)", "percent": 3.44},
            {"locale": "xx_XX", "name": "Unknown", "percent": None},
        ]
        with tempfile.TemporaryDirectory() as tmp:
            template_path = Path(tmp) / "template.md"
            out_path = Path(tmp) / "README.md"
            template_path.write_text(
                "# Title\n\nbefore\n\n" + STATS_PLACEHOLDER + "\n\nafter\n",
                encoding="utf-8",
            )
            write_translations_readme(out_path, catalog, template_path)
            rendered = out_path.read_text(encoding="utf-8")

        self.assertTrue(rendered.startswith("# Title\n"))
        self.assertIn("before", rendered)
        self.assertIn("after", rendered)
        self.assertNotIn(STATS_PLACEHOLDER, rendered)
        self.assertIn("| es_ES | Español (España) |", rendered)
        self.assertIn("`████████████████████` 100.00%", rendered)
        self.assertIn("| xx_XX | Unknown | — |", rendered)
        self.assertIn("```mermaid", rendered)
        self.assertIn('x-axis ["es_ES", "fr_FR"]', rendered)
        self.assertTrue(rendered.endswith("after\n"))

    def test_missing_placeholder_raises(self):
        catalog = [{"locale": "es_ES", "name": "Español", "percent": 100.0}]
        with tempfile.TemporaryDirectory() as tmp:
            template_path = Path(tmp) / "template.md"
            out_path = Path(tmp) / "README.md"
            template_path.write_text("# Title\n", encoding="utf-8")
            with self.assertRaises(ValueError):
                write_translations_readme(out_path, catalog, template_path)

    def test_coverage_markdown_skips_mermaid_when_all_percent_missing(self):
        markdown = render_coverage_markdown(
            [{"locale": "xx_XX", "name": "Missing", "percent": None}]
        )
        self.assertIn("| xx_XX | Missing | — |", markdown)
        self.assertNotIn("```mermaid", markdown)


if __name__ == "__main__":
    unittest.main()
