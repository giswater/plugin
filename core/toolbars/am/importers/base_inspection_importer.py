"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-


class InspectionImporter:
    """Parse a CCTV file into observation dicts and insert them into AM."""

    def parse(self, path):
        raise NotImplementedError

    @staticmethod
    def _blank(value):
        if value is None:
            return None
        text = str(value).strip()
        return text or None

    @staticmethod
    def _num(value):
        text = InspectionImporter._blank(value)
        if text is None:
            return None
        return float(text.replace(",", "."))

    @staticmethod
    def _int(value):
        number = InspectionImporter._num(value)
        if number is None:
            return None
        return int(number)
