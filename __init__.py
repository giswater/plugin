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
import os
import sys
from pathlib import Path

plugin_path = os.path.abspath(os.path.join(os.path.dirname(__file__)))
sys.path.append(plugin_path)

# Keep QPIP deps importable if QPIP is disabled/uninstalled (QPIP removes this path on unload).
_py_ver = f"{sys.version_info.major}.{sys.version_info.minor}"
_deps_path = Path(plugin_path).parent.parent / "dependencies" / _py_ver
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
