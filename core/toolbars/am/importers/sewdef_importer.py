"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

from .generic_une_importer import GenericUneImporter


class SewdefImporter(GenericUneImporter):
    """SEWDEF text export. Same columns as the UNE CSV, semicolon-separated."""
