"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

import csv

from .base_inspection_importer import InspectionImporter


class GenericUneImporter(InspectionImporter):
    """CSV (comma or semicolon) with an EN 13508-2 header row.

    Columns: asset_id, feature_type, code, severity, pk_start, pk_end, pk,
    clock_start, clock_end, inspection_id, inspection_date, observation.
    """

    def parse(self, path):
        with open(path, newline="", encoding="utf-8-sig") as handle:
            sample = handle.read(4096)
            handle.seek(0)
            delimiter = ";" if sample.count(";") > sample.count(",") else ","
            reader = csv.DictReader(handle, delimiter=delimiter)
            rows = []
            for raw in reader:
                lowered = {(key or "").strip().lower(): value for key, value in raw.items()}
                asset_id = self._int(lowered.get("asset_id") or lowered.get("arc_id") or lowered.get("node_id"))
                code = self._blank(lowered.get("code"))
                severity = self._int(lowered.get("severity"))
                if asset_id is None or not code or severity is None:
                    continue
                feature = (self._blank(lowered.get("feature_type")) or "ARC").upper()
                rows.append({
                    "asset_id": asset_id,
                    "feature_type": "NODE" if feature == "NODE" else "ARC",
                    "code": code.upper(),
                    "severity": severity,
                    "pk_start": self._num(lowered.get("pk_start")),
                    "pk_end": self._num(lowered.get("pk_end")),
                    "pk": self._num(lowered.get("pk")),
                    "clock_start": self._num(lowered.get("clock_start")),
                    "clock_end": self._num(lowered.get("clock_end")),
                    "inspection_id": self._int(lowered.get("inspection_id")),
                    "inspection_date": self._blank(lowered.get("inspection_date")),
                    "observation": self._blank(lowered.get("observation")),
                })
            return rows
