"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

import xml.etree.ElementTree as ET

from .base_inspection_importer import InspectionImporter


class WincanImporter(InspectionImporter):
    """WinCan VX XML. Reads Observation nodes (Code, Grade, Distance, Clock)."""

    def _local(self, tag):
        return tag.rsplit("}", 1)[-1].lower()

    def _child_text(self, element, names):
        wanted = {name.lower() for name in names}
        for child in element.iter():
            if self._local(child.tag) in wanted and child.text and child.text.strip():
                return child.text.strip()
        for name in wanted:
            if element.get(name):
                return element.get(name)
        return None

    def parse(self, path):
        tree = ET.parse(path)
        rows = []
        inspection_id = None
        inspection_date = None
        asset_id = None
        for element in tree.iter():
            name = self._local(element.tag)
            if name in ("inspection", "section"):
                inspection_id = self._int(self._child_text(element, ("inspectionid", "id"))) or inspection_id
                inspection_date = self._blank(self._child_text(element, ("inspectiondate", "date"))) or inspection_date
                asset_id = self._int(self._child_text(element, ("pipeid", "assetid", "sectionid"))) or asset_id
            if name != "observation":
                continue
            code = self._blank(self._child_text(element, ("code", "opccode", "maincode")))
            severity = self._int(self._child_text(element, ("grade", "severity", "characterisation1")))
            if not code or severity is None:
                continue
            distance = self._num(self._child_text(element, ("distance", "pk", "position")))
            rows.append({
                "asset_id": self._int(self._child_text(element, ("pipeid", "assetid"))) or asset_id,
                "feature_type": "ARC",
                "code": code.upper(),
                "severity": severity,
                "pk_start": self._num(self._child_text(element, ("startposition", "pk_start"))) or distance,
                "pk_end": self._num(self._child_text(element, ("endposition", "pk_end"))),
                "pk": distance,
                "clock_start": self._num(self._child_text(element, ("clockposition", "clock", "clock_start"))),
                "clock_end": self._num(self._child_text(element, ("clock_end",))),
                "inspection_id": inspection_id,
                "inspection_date": inspection_date,
                "observation": self._blank(self._child_text(element, ("remark", "observation", "text"))),
            })
        return [row for row in rows if row["asset_id"] is not None]
