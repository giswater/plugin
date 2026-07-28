"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
import json
import os
import ast

from enum import Enum
from functools import partial
from pathlib import Path
from typing import Optional
from itertools import islice
from math import isnan

from psycopg2.extras import execute_values

from qgis.PyQt.QtWidgets import QMenu, QComboBox

from ...libs import tools_log, tools_qgis, tools_qt, lib_vars, tools_db
from ... import global_vars


class ProjectType(Enum):
    WS = "ws"
    UD = "ud"


class GwInpConfig:
    """ Class to store the configuration of the import INP process, as well as serializing/deserializing it """

    def __init__(self, file_path: Optional[Path] = None, workcat: Optional[str] = None, exploitation: Optional[int] = None,
                 sector: Optional[int] = None, municipality: Optional[int] = None, dscenario: Optional[str] = None,
                 raingage: Optional[str] = None, catalogs: Optional[dict] = None, psector: Optional[bool] = None) -> None:
        self.file_path: Optional[Path] = file_path
        self.workcat: Optional[str] = workcat
        self.exploitation: Optional[int] = exploitation
        self.sector: Optional[int] = sector
        self.municipality: Optional[int] = municipality
        self.dscenario: Optional[str] = dscenario
        self.raingage: Optional[str] = raingage
        self.catalogs: Optional[dict] = catalogs
        self.psector: Optional[bool] = psector

    def serialize(self) -> dict:
        return_dict = {
            "file_path": str(self.file_path),
            "workcat": self.workcat,
            "exploitation": self.exploitation,
            "sector": self.sector,
            "municipality": self.municipality,
            "catalogs": self.catalogs,
            "psector": self.psector
        }
        if self.dscenario:
            return_dict["dscenario"] = self.dscenario
        if self.raingage:
            return_dict["raingage"] = self.raingage
        return return_dict

    def deserialize(self, data: dict) -> None:
        self.file_path = data.get("file_path")
        self.workcat = data.get("workcat")
        self.exploitation = data.get("exploitation")
        self.sector = data.get("sector")
        self.municipality = data.get("municipality")
        self.dscenario = data.get("dscenario")
        self.catalogs = data.get("catalogs")
        self.psector = data.get("psector")

    def write_to_file(self, file_path: Path) -> None:
        """Write the serialized configuration to a file."""
        data = self.serialize()
        # Convert tuple keys to strings
        data_serializable = self.convert_keys(data)
        with file_path.open("w") as file:
            json.dump(data_serializable, file, indent=4)

    def read_from_file(self, file_path: Path) -> None:
        """Read the configuration from a file and deserialize it."""
        with file_path.open("r") as file:
            try:
                data = json.load(file)
            except json.JSONDecodeError as e:
                msg = "Error reading configuration file: {0}"
                msg_params = (e,)
                tools_log.log_error(msg, msg_params=msg_params)
                return
        self.deserialize(data)

    def convert_keys(self, obj):
        """ Recursively converts keys to strings in a dictionary. """
        if isinstance(obj, dict):
            return {str(k): self.convert_keys(v) for k, v in obj.items()}
        return obj


def lerp_progress(subtask_progress: int, global_min: int, global_max: int) -> int:
    global_progress = global_min + ((subtask_progress - 0) / (100 - 0)) * (global_max - global_min)

    return int(global_progress)


def batched(iterable, n):
    # batched('ABCDEFG', 3) --> ABC DEF G
    if n < 1:
        raise ValueError("n must be at least one")
    it = iter(iterable)
    while batch := tuple(islice(it, n)):
        yield batch


def to_yesno(x: bool):
    return "YES" if x else "NO"


def nan_to_none(x):
    return None if (isinstance(x, float) and isnan(x)) else x


def execute_sql(sql, params=None, /, log_sql=False, **kwargs) -> bool:
    sql = tools_db._get_sql(sql, log_sql, params)
    is_thread = kwargs.pop('is_thread', True)
    result: bool = tools_db.execute_sql(
        sql,
        log_sql=log_sql,
        is_thread=is_thread,
        **kwargs,
    )
    if lib_vars.session_vars.get("last_error"):
        raise lib_vars.session_vars["last_error"]
    return result


def get_row(sql, params=None, /, **kwargs):
    is_thread = kwargs.pop('is_thread', True)
    result = tools_db.get_row(sql, params=params, is_thread=is_thread, **kwargs)
    if lib_vars.session_vars.get("last_error"):
        raise lib_vars.session_vars["last_error"]
    return result


def get_rows(sql, params=None, /, **kwargs):
    is_thread = kwargs.pop('is_thread', True)
    result = tools_db.get_rows(sql, params=params, is_thread=is_thread, **kwargs)
    if lib_vars.session_vars.get("last_error"):
        raise lib_vars.session_vars["last_error"]
    return result


# TODO: refactor into toolsdb and tools_pgdao
def toolsdb_execute_values(
    sql, argslist, template=None, page_size=100, fetch=False, commit=True
):
    if tools_db.dao is None:
        msg = "The connection to the database is broken: {0}"
        msg_params = (sql,)
        tools_log.log_warning(msg, msg_params=msg_params)
        return None

    tools_db.dao.last_error = None
    result = None

    try:
        cur = tools_db.dao.get_cursor()
        result = execute_values(cur, sql, argslist, template, page_size, fetch)
        if commit:
            tools_db.dao.commit()
    except Exception as e:
        tools_db.dao.last_error = e
        if commit:
            tools_db.dao.rollback()

    lib_vars.session_vars["last_error"] = tools_db.dao.last_error
    if lib_vars.session_vars.get("last_error"):
        raise lib_vars.session_vars["last_error"]

    return result


def create_load_menu(self_cls):
    """Create a drop-down menu for the load button"""

    menu = QMenu(self_cls.dlg_config)
    action_load_last = menu.addAction("Load from last import")
    action_load_from_file = menu.addAction("Load from file...")

    # Connect actions to their respective slots
    action_load_last.triggered.connect(partial(_load_last_config, self_cls))
    action_load_from_file.triggered.connect(partial(_load_config_from_file, self_cls))

    return menu


def _load_last_config(self_cls):
    """Load the last saved configuration"""

    load_config(self_cls)


def _load_config_from_file(self_cls):
    """Load configuration from a file"""

    config_folder = f'{lib_vars.user_folder_dir}{os.sep}core{os.sep}temp'
    config_path: Optional[Path] = tools_qt.get_file("Select a configuration file", config_folder, "JSON files (*.json)")

    if config_path:
        config = GwInpConfig()
        config.read_from_file(config_path)
        load_config(self_cls, config)


def save_config_to_file(self_cls):
    """Save configuration to a file"""

    config_path: Optional[Path] = tools_qt.get_file("Select a configuration file", "", "JSON files (*.json)")

    if config_path:
        workcat, exploitation, sector, municipality, dscenario, catalogs, psector = self_cls._get_config_values()
        save_config(self_cls, workcat=workcat, exploitation=exploitation, sector=sector, municipality=municipality, dscenario=dscenario, catalogs=catalogs, psector=psector, _config_path=config_path)


def save_config(self_cls, workcat: Optional[str] = None, exploitation: Optional[int] = None, sector: Optional[int] = None,
                    municipality: Optional[int] = None, dscenario: Optional[str] = None, raingage: Optional[str] = None, catalogs: Optional[dict] = None, psector: Optional[bool] = None, _config_path: Optional[Path] = None) -> None:

    try:
        if _config_path is None:
            config_folder = f'{lib_vars.user_folder_dir}{os.sep}core{os.sep}temp'
            if not os.path.exists(config_folder):
                os.makedirs(config_folder)
            file_name = "import_epanet_config.json" if global_vars.project_type == ProjectType.WS.value else "import_swmm_config.json"
            path_temp_file = f"{config_folder}{os.sep}{file_name}"
            config_path: Path = Path(path_temp_file)
        else:
            config_path = _config_path
        config = GwInpConfig(file_path=self_cls.file_path, workcat=workcat, exploitation=exploitation, sector=sector,
                                municipality=municipality, dscenario=dscenario, raingage=raingage, catalogs=catalogs, psector=psector)
        config.write_to_file(config_path)
        msg = "Configuration saved to {0}"
        msg_params = (config_path,)
        tools_log.log_info(msg, msg_params=msg_params)
    except Exception as e:
        msg = "Error saving the configuration"
        param = str(e)
        tools_qgis.show_warning(msg, dialog=self_cls.dlg_config, parameter=param)


def load_config(self_cls, config: Optional[GwInpConfig] = None) -> Optional[GwInpConfig]:

    if config is None:
        config_folder = f'{lib_vars.user_folder_dir}{os.sep}core{os.sep}temp'
        file_name = "import_epanet_config.json" if global_vars.project_type == ProjectType.WS.value else "import_swmm_config.json"
        path_temp_file = f"{config_folder}{os.sep}{file_name}"
        config_path: Path = Path(path_temp_file)
        if not os.path.exists(config_path):
            return None
        config = GwInpConfig()
        config.read_from_file(config_path)
    if not config.file_path:
        return None

    if str(self_cls.file_path) != str(config.file_path):
        msg = "The configuration file doesn't match the selected INP file. Some options may not be loaded or may be incorrect. Do you want to continue?"
        result = tools_qt.show_question(msg, force_action=True)
        if result:
            config.file_path = self_cls.file_path
        else:
            return

    # Fill 'Basic' tab widgets
    tools_qt.set_widget_text(self_cls.dlg_config, 'txt_workcat', config.workcat)
    if global_vars.project_type == ProjectType.WS.value:
        tools_qt.set_widget_text(self_cls.dlg_config, 'txt_dscenario', config.dscenario)
    elif global_vars.project_type == ProjectType.UD.value:
        tools_qt.set_widget_text(self_cls.dlg_config, 'txt_raingage', config.raingage)
    tools_qt.set_combo_value(self_cls.dlg_config.cmb_expl, config.exploitation, 0)
    tools_qt.set_combo_value(self_cls.dlg_config.cmb_sector, config.sector, 0)
    tools_qt.set_combo_value(self_cls.dlg_config.cmb_muni, config.municipality, 0)
    tools_qt.set_checked(self_cls.dlg_config, "chk_psector", config.psector)

    # Fill tables from catalogs
    if global_vars.project_type == ProjectType.WS.value:
        _set_combo_values_from_epanet_catalogs(self_cls, config.catalogs)
    elif global_vars.project_type == ProjectType.UD.value:
        _set_combo_values_from_swmm_catalogs(self_cls, config.catalogs)

    msg = "Configuration loaded successfully"
    tools_qgis.show_success(msg, dialog=self_cls.dlg_config)

    return config


def fill_txt_info(self_cls, dialog):
    """Fill the text information in the dialog"""

    epa_software = "EPANET" if global_vars.project_type == ProjectType.WS.value else "SWMM"
    info_str = f'''<h3>{tools_qt.tr('IMPORT INP')} ({epa_software})</h3>'''
    info_str += "<p>"
    info_str += f'''{tools_qt.tr('This wizard will help with the process of importing a network from a {0} INP file into the Giswater database.', list_params=(epa_software,))}<br><br>'''
    info_str += f'''{tools_qt.tr('There are multple tabs in order to configure all the necessary catalogs.')}<br><br>'''
    info_str += f'''{tools_qt.tr("The first tab is the 'Basic' tab, where you can select the exploitation, sector, municipality, and other basic information.")}<br><br>'''
    info_str += f'''{tools_qt.tr("The second tab is the 'Features' tab, where you can select the corresponding feature classes for each type of feature on the network.")}<br>'''
    if epa_software == "EPANET":
        info_str += f'''{tools_qt.tr('Here you can choose how the pumps and valves will be imported, either left as arcs (virual arcs) or converted to nodes.')}<br><br>'''
        info_str += f'''{tools_qt.tr("The third tab is the 'Materials' tab, where you can select the corresponding material for each roughness value.")}<br><br>'''
    elif epa_software == "SWMM":
        info_str += f'''{tools_qt.tr('Here you can choose how the pumps, weirs, orifices, and outlets will be imported, either left as arcs (virual arcs) or converted to flwreg.')}<br><br>'''
        info_str += f'''{tools_qt.tr("The third tab is the 'Materials' tab, where you can select the corresponding roughness value for each material.")}<br><br>'''
    info_str += f'''{tools_qt.tr("The fourth tab is the 'Nodes' tab, where you can select the catalog for each type of node on the network.")}<br><br>'''
    info_str += f'''{tools_qt.tr("The fifth tab is the 'Arcs' tab, where you can select the catalog for each type of arc on the network.")}<br><br>'''
    if epa_software == "SWMM":
        info_str += f'''{tools_qt.tr('If you chose to import the flow regulators as flwreg objects, the sixth tab is where you can select the catalog for each flow regulator (pumps, weirs, orifices, outlets) on the network.')}<br>{tools_qt.tr('If not, you can ignore the tab.')}<br><br>'''
    info_str += f'''{tools_qt.tr("Once you have configured all the necessary catalogs, you can click on the 'Accept' button to start the import process.")}<br>{tools_qt.tr('It will then show the log of the process in the last tab.')}<br><br>'''
    info_str += f'''{tools_qt.tr('You can save the current configuration to a file and load it later, or load the last saved configuration.')}<br><br>'''
    info_str += f'''{tools_qt.tr('If you have any questions, please contact the Giswater team via')}<a href='https://github.com/giswater/plugin/issues'>{tools_qt.tr('GitHub Issues')}</a> {tools_qt.tr('or')}<a href='https://giswater.org/contact/'>{tools_qt.tr('our website')}</a>.<br>'''
    info_str += "</p>"
    tools_qt.set_widget_text(dialog, 'txt_info', info_str)


def _set_combo_values_from_epanet_catalogs(self_cls, catalogs):
    # Set features
    for feature_type, (combo,) in self_cls.tbl_elements["features"].items():
        feat_catalog = catalogs.get("features", {}).get(str(feature_type))
        if feat_catalog:
            combo.setCurrentText(feat_catalog)

    # Set materials
    for roughness, (combo,) in self_cls.tbl_elements["materials"].items():
        material_catalog = catalogs.get("materials", {}).get(str(roughness))
        if material_catalog:
            combo.setCurrentText(material_catalog)

    # Set nodes and arcs tables
    elements = [
        ("junctions", catalogs.get("junctions")),
        ("reservoirs", catalogs.get("reservoirs")),
        ("tanks", catalogs.get("tanks")),
        ("pumps", catalogs.get("pumps")),
        ("valves", catalogs.get("valves")),
        ("prv", catalogs.get("prv")),
        ("psv", catalogs.get("psv")),
        ("pbv", catalogs.get("pbv")),
        ("fcv", catalogs.get("fcv")),
        ("tcv", catalogs.get("tcv")),
        ("gpv", catalogs.get("gpv")),
    ]

    for element_type, element_catalog in elements:
        if element_type == "pipes":
            continue

        if element_type not in self_cls.tbl_elements:
            continue

        combo: QComboBox = self_cls.tbl_elements[element_type][0]
        if element_catalog:
            if combo.findText(element_catalog) == -1:
                combo.setCurrentText('Create new')
                self_cls.tbl_elements[element_type][1].setText(element_catalog)
                continue
            combo.setCurrentText(element_catalog)

    if catalogs.get("pipes") is not None:
        for dint_rough_str, pipe_catalog in catalogs["pipes"].items():
            dint_rough_tuple = tuple(map(float, dint_rough_str.strip("()").split(", ")))
            if dint_rough_tuple not in self_cls.tbl_elements["pipes"]:
                continue

            combo: QComboBox = self_cls.tbl_elements["pipes"][dint_rough_tuple][0]
            if pipe_catalog:
                if combo.findText(pipe_catalog) == -1:
                    combo.setCurrentText('Create new')
                    self_cls.tbl_elements["pipes"][dint_rough_tuple][1].setText(pipe_catalog)
                    continue
                combo.setCurrentText(pipe_catalog)


def _set_combo_values_from_swmm_catalogs(self_cls, catalogs):
    # Set features
    for feature_type, (combo,) in self_cls.tbl_elements["features"].items():
        feat_catalog = catalogs.get("features", {}).get(str(feature_type))
        if feat_catalog:
            combo.setCurrentText(feat_catalog)

    # Set materials
    for roughness, (combo,) in self_cls.tbl_elements["materials"].items():
        material_catalog = catalogs.get("materials", {}).get(str(roughness))
        if material_catalog:
            combo.setCurrentText(material_catalog)

    # Set nodes and arcs tables
    elements = [
        ("junctions", catalogs.get("junctions")),
        ("outfalls", catalogs.get("outfalls")),
        ("storage", catalogs.get("storage")),
        ("dividers", catalogs.get("dividers")),
        ("conduits", catalogs.get("conduits")),
        ("pumps", catalogs.get("pumps")),
        ("weirs", catalogs.get("weirs")),
        ("orifices", catalogs.get("orifices")),
        ("outlets", catalogs.get("outlets")),
    ]

    for element_type, element_catalog in elements:
        if element_type == "conduits":
            continue

        if element_type not in self_cls.tbl_elements:
            continue

        combo: QComboBox = self_cls.tbl_elements[element_type][0]
        if element_catalog:
            if combo.findText(element_catalog) == -1:
                combo.setCurrentText('Create new')
                self_cls.tbl_elements[element_type][1].setText(element_catalog)
                continue
            combo.setCurrentText(element_catalog)

    if catalogs.get("conduits") is not None:
        for tuple_str, conduits_catalog in catalogs["conduits"].items():
            catalog_tuple = ast.literal_eval(tuple_str)

            if catalog_tuple not in self_cls.tbl_elements["conduits"]:
                continue

            combo: QComboBox = self_cls.tbl_elements["conduits"][catalog_tuple][0]
            if conduits_catalog:
                if combo.findText(conduits_catalog) == -1:
                    combo.setCurrentText('Create new')
                    self_cls.tbl_elements["conduits"][catalog_tuple][1].setText(conduits_catalog)
                    continue
                combo.setCurrentText(conduits_catalog)
