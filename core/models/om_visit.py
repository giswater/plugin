# -*- coding: utf-8 -*-
"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""

__author__ = 'Luigi Pirelli'
__date__ = 'January 2018'
__copyright__ = '(C) 2018, Luigi Pirelli'

# This will get replaced with a git SHA1 when you do a git archive

__revision__ = '$Format:%H$'

from .models_manager import GwTable, GwGenericDescriptor


class GwOmVisit(GwTable):
    """ Class to serialize table 'om_visit' """

    id = GwGenericDescriptor(-1)
    visitcat_id = GwGenericDescriptor(None)
    ext_code = GwGenericDescriptor(None)
    startdate = GwGenericDescriptor(None)
    enddate = GwGenericDescriptor(None)
    user_name = GwGenericDescriptor(None)
    webclient_id = GwGenericDescriptor(None)
    expl_id = GwGenericDescriptor(None)
    the_geom = GwGenericDescriptor(None)
    descript = GwGenericDescriptor(None)
    status = GwGenericDescriptor(None)
    visit_type = GwGenericDescriptor(None)

    def __init__(self):

        GwTable.__init__(self, 'om_visit', 'id')

