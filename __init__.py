# -*- coding: utf-8 -*-
"""
/***************************************************************************
        begin                : 2016-01-05
        copyright            : (C) 2016 by BGEO SL
        email                : derill@bgeo.es
        git sha              : $Format:%H$
 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
 This script initializes the plugin, making it known to QGIS.
"""
import sys
from pathlib import Path

# QPIP path hack needs QgsApplication. Importing qgis at module level
# breaks headless CLI pytest: the repo is a package (this __init__.py),
# so collecting test/engine walks here. QGIS itself always has qgis.core.
try:
    from qgis.core import QgsApplication
except ImportError:
    QgsApplication = None

if QgsApplication is not None:
    # Keep QPIP deps importable if QPIP is disabled/uninstalled (QPIP removes this path on unload).
    _profile_path = QgsApplication.qgisSettingsDirPath()
    _py_ver = f"{sys.version_info.major}.{sys.version_info.minor}"
    _deps_path = Path(_profile_path) / "python" / "dependencies" / _py_ver
    _deps_path_str = str(_deps_path)
    if _deps_path.is_dir() and _deps_path_str not in sys.path:
        sys.path.insert(0, _deps_path_str)
        sys.path_importer_cache.clear()


# noinspection PyPep8Naming
def classFactory(iface):  # pylint: disable=invalid-name
    """ Load Giswater class from file giswater.
    :param iface: A QGIS interface instance.
    :type iface: QgsInterface
    """
    from .main import Giswater
    return Giswater(iface)
