"""Unit tests for Asset Manage CCTV inspection importers."""

from core.toolbars.am.importers.generic_une_importer import GenericUneImporter
from core.toolbars.am.importers.wincan_importer import WincanImporter


def test_generic_une_preserves_text_asset_ids(tmp_path):
    source = tmp_path / "inspection.csv"
    source.write_text(
        "asset_id;feature_type;code;severity;inspection_id\n"
        "ARC-A12;ARC;baa;4;101\n"
        "NODE-B7;NODE;bba;3;102\n",
        encoding="utf-8",
    )

    rows = GenericUneImporter().parse(source)

    assert [row["asset_id"] for row in rows] == ["ARC-A12", "NODE-B7"]
    assert [row["feature_type"] for row in rows] == ["ARC", "NODE"]


def test_wincan_preserves_text_asset_id(tmp_path):
    source = tmp_path / "inspection.xml"
    source.write_text(
        """
        <Inspection>
          <InspectionId>101</InspectionId>
          <PipeId>ARC-A12</PipeId>
          <Observation>
            <Code>BAA</Code>
            <Grade>4</Grade>
            <Distance>12.5</Distance>
          </Observation>
        </Inspection>
        """,
        encoding="utf-8",
    )

    rows = WincanImporter().parse(source)

    assert rows[0]["asset_id"] == "ARC-A12"
    assert rows[0]["inspection_id"] == 101
