"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
import sys

from datetime import timedelta
from functools import partial
from pathlib import Path
from time import time
from typing import Optional

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import Qt, QTimer
from qgis.PyQt.QtWidgets import (
    QComboBox,
    QLabel,
    QTableWidget,
    QTableWidgetItem,
    QTextEdit,
)
from qgis.PyQt.sip import isdeleted

from .....libs import tools_db, tools_os, tools_qgis, tools_qt
from ....ui.dialog import GwDialog
from ....ui.ui_manager import GwInpConfigImportUi, GwInpParsingUi
if sys.version_info >= (3, 10):
    from ....threads.import_inp.import_swmm_task import GwImportInpTask
    from ....utils.import_inp import GwInpConfig, create_load_menu, load_config, save_config, save_config_to_file, fill_txt_info
    from ....threads.import_inp import parse_swmm_task
else:
    GwImportInpTask = None
    GwInpConfig, create_load_menu, load_config, save_config, save_config_to_file, fill_txt_info = None, None, None, None, None, None
    parse_swmm_task = None
from ....utils import tools_gw

CREATE_NEW = "Create new"
SPATIAL_INTERSECT = "Get from spatial intersect"
TESTING_MODE = False


class GwImportSwmm:
    """Button 22: Import INP"""

    def __init__(self) -> None:
        self.file_path: Optional[Path] = None
        self.cur_process = None
        self.cur_text = None
        self.catalog_source = {
            "pumps": "db_arcs",
            "orifices": "db_arcs",
            "weirs": "db_arcs",
            "outlets": "db_arcs"
        }

    def clicked_event(self) -> None:
        """Start the Import INP workflow"""
        if sys.version_info < (3, 10):
            msg = ("Import INP is only available on Python 3.10 or higher. "
                  "Please update your QGIS's Python version.")
            tools_qgis.show_warning(msg)
            return

        try:
            tools_os.get_dep("swmm_api")
            from ....threads.import_inp import parse_swmm_task

            global Catalogs, GwParseInpTask  # noqa: F824
            Catalogs = parse_swmm_task.Catalogs
            GwParseInpTask = parse_swmm_task.GwParseInpTask

            self.file_path: Optional[Path] = self._get_file()

            if not self.file_path:
                return

            self.parse_inp_file(self.file_path)

        except ImportError:
            msg = ("Couldn't import swmm_api package. "
                    "Try to reload the Giswater plugin. "
                    "If the issue persists restart QGIS.")
            tools_qgis.show_message(msg)

    def _get_file(self) -> Optional[Path]:
        """ Get the INP file path from the user. """
        file_path = tools_qt.get_file(
            "Select INP file", "", "INP files (*.inp)"
        )

        # Check if the file extension is .inp
        if file_path and file_path.suffix == ".inp":
            return file_path
        else:
            msg = "The file selected is not an INP file"
            tools_qgis.show_warning(msg)
            return

    def parse_inp_file(self, file_path: Path) -> None:
        """Parse INP file, showing a log to the user"""

        # Create and show parsing dialog
        self.dlg_inp_parsing = GwInpParsingUi(self)
        tools_gw.load_settings(self.dlg_inp_parsing)
        self.dlg_inp_parsing.rejected.connect(
            partial(tools_gw.save_settings, self.dlg_inp_parsing)
        )
        tools_gw.open_dialog(self.dlg_inp_parsing, dlg_name="parse_inp")

        global GwParseInpTask  # noqa: F824
        title = "Parse INP task"
        self.parse_inp_task = GwParseInpTask(
            tools_qt.tr(title), file_path, self.dlg_inp_parsing
        )
        QgsApplication.taskManager().addTask(self.parse_inp_task)
        QgsApplication.taskManager().triggerTask(self.parse_inp_task)

        # Create timer
        self.t0: float = time()
        self.timer: QTimer = QTimer()
        self.timer.timeout.connect(
            partial(self._update_parsing_dialog, self.dlg_inp_parsing)
        )
        self.timer.start(1000)
        self.parse_inp_task.taskCompleted.connect(self.timer.stop)
        self.parse_inp_task.taskCompleted.connect(self.dlg_inp_parsing.close)
        self.parse_inp_task.taskCompleted.connect(self.open_config_dialog)

    def open_config_dialog(self) -> None:
        """Open the config INP import dialog"""

        self.dlg_config = GwInpConfigImportUi(self)
        tools_gw.load_settings(self.dlg_config)

        # Manage save/load buttons
        self.dlg_config.btn_save.clicked.connect(partial(save_config_to_file, self))
        # Make btn_load a drop-down button with the options: Load last, Load from file
        menu = create_load_menu(self)
        self.dlg_config.btn_load.setMenu(menu)

        # Manage signals
        self.dlg_config.rejected.connect(
            partial(tools_gw.save_settings, self.dlg_config)
        )
        self.dlg_config.rejected.connect(self._cleanup_signals)
        self.dlg_config.btn_reload.clicked.connect(self._fill_combo_boxes)
        self.dlg_config.btn_cancel.clicked.connect(self.dlg_config.reject)
        self.dlg_config.btn_accept.clicked.connect(self._importinp_accept)
        self.dlg_config.btn_accept.clicked.connect(self._cleanup_signals)
        self.dlg_config.chk_psector.stateChanged.connect(self._manage_psector)

        # Get catalogs from thread
        self.catalogs: parse_swmm_task.Catalogs = self.parse_inp_task.catalogs

        fill_txt_info(self, self.dlg_config)
        self._fill_tables()

        self._fill_combo_boxes()

        self._manage_widgets_visibility()

        tools_gw.open_dialog(self.dlg_config, dlg_name="inp_config_import")

    def _manage_psector(self):
        """ Manage the psector checkbox and the workcat and exploitation combo """
        checked = tools_qt.is_checked(self.dlg_config, "chk_psector")
        if checked:
            # Check if there is a current psector
            result = tools_gw.get_config_value('plan_psector_current')
            if result is None or result[0] is None:
                msg = "No current psector selected"
                tools_qgis.show_message(msg, dialog=self.dlg_config)
                self.dlg_config.chk_psector.click()
                return
            # Get psector values
            psector_id = result[0]
            sql = "SELECT name, workcat_id, expl_id FROM v_ui_plan_psector WHERE psector_id = %s"
            row = tools_db.get_row(sql, params=(psector_id,))
            if row is None:
                msg = "Error getting current psector"
                tools_qgis.show_message(msg)
                return
            psector_name = row['name']
            workcat_id = row['workcat_id']
            exploitation_id = row['expl_id']
            sql = "SELECT name FROM exploitation WHERE expl_id = %s"
            row = tools_db.get_row(sql, params=(exploitation_id,))
            if row is None:
                msg = "Error getting exploitation"
                tools_qgis.show_message(msg)
                return
            exploitation_name = row['name']
            # Set text
            self.dlg_config.chk_psector.setText(psector_name)
            tools_qt.set_widget_text(self.dlg_config, "txt_workcat", workcat_id)
            tools_qt.set_combo_value(self.dlg_config.cmb_expl, exploitation_name, 1, add_new=True)
            # Disable workcat and exploitation combo
            tools_qt.set_widget_enabled(self.dlg_config, "txt_workcat", False)
            tools_qt.set_widget_enabled(self.dlg_config, "cmb_expl", False)
        else:
            # Enable workcat and exploitation combo
            tools_qt.set_widget_enabled(self.dlg_config, "txt_workcat", True)
            tools_qt.set_widget_enabled(self.dlg_config, "cmb_expl", True)

            # Clear workcat and exploitation combo
            tools_qt.set_widget_text(self.dlg_config, "txt_workcat", "")
            self.dlg_config.cmb_expl.clear()

            # Populate workcat combo
            expl_value: str = self.dlg_config.cmb_expl.currentText()
            rows = tools_db.get_rows("""
                SELECT expl_id, name
                FROM exploitation
                WHERE expl_id > 0
            """)
            self.dlg_config.cmb_expl.clear()
            tools_qt.fill_combo_values(self.dlg_config.cmb_expl, rows, add_empty=False, selected_id=expl_value, index_to_compare=1)
            self.dlg_config.chk_psector.setText("")

    def _manage_widgets_visibility(self):
        # Hide 'Demand dscenario' widget for UD
        tools_qt.set_widget_visible(self.dlg_config, "lbl_dscenario", False)
        tools_qt.set_widget_visible(self.dlg_config, "txt_dscenario", False)

        # Disable the whole dialog if testing mode
        if TESTING_MODE:
            tools_gw.set_tabs_enabled(self.dlg_config, hide_btn_accept=False, change_btn_cancel=False)

        # Default raingage widget
        subcatchments = self.catalogs.inp_subcatchments
        has_empty = any([x[1] for x in subcatchments if x[1] == '*'] if subcatchments else [])
        if not has_empty:
            tools_qt.set_widget_visible(self.dlg_config, 'lbl_raingage', False)
            tools_qt.set_widget_visible(self.dlg_config, 'txt_raingage', False)

    def _importinp_accept(self):
        # Manage force commit mode
        force_commit = tools_qt.is_checked(self.dlg_config, "chk_force_commit")
        if force_commit is None:
            force_commit = False

        manage_flwreg = {
            "pumps": self.catalog_source["pumps"] == "db_flwreg",
            "orifices": self.catalog_source["orifices"] == "db_flwreg",
            "weirs": self.catalog_source["weirs"] == "db_flwreg",
            "outlets": self.catalog_source["outlets"] == "db_flwreg"
        }
        if TESTING_MODE:

            # Delete the network before importing
            queries = [
                'SELECT gw_fct_admin_manage_migra($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":25831}, "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"action":"TRUE"}, "aux_params":null}}$$);',
                'UPDATE arc SET node_1 = NULL, node_2 = NULL;',
                'DELETE FROM ext_rtc_scada_x_data;',
                'DELETE FROM inp_inflows CASCADE;',
                'DELETE FROM inp_dwf CASCADE;',
                'DELETE FROM connec CASCADE;',
                'DELETE FROM node CASCADE;',
                'DELETE FROM element_x_gully CASCADE;',
                'DELETE FROM gully CASCADE;',
                'DELETE FROM inp_subcatchment CASCADE;',
                'DELETE FROM raingage CASCADE;',
                'DELETE FROM inp_conduit CASCADE;',
                'DELETE FROM inp_frpump CASCADE;',
                'DELETE FROM inp_frorifice CASCADE;',
                'DELETE FROM inp_frweir CASCADE;',
                'DELETE FROM inp_froutlet CASCADE;',
                'DELETE FROM inp_pump CASCADE;',
                'DELETE FROM inp_orifice CASCADE;',
                'DELETE FROM inp_outlet CASCADE;',
                'DELETE FROM inp_outfall CASCADE;',
                'DELETE FROM inp_storage CASCADE;',
                'DELETE FROM inp_curve_value CASCADE;',
                'DELETE FROM inp_curve CASCADE;',
                'DELETE FROM inp_pattern_value CASCADE;',
                'DELETE FROM inp_pattern CASCADE;',
                'DELETE FROM inp_timeseries_value CASCADE;',
                'DELETE FROM inp_timeseries CASCADE;',
                'DELETE FROM inp_controls CASCADE;',
                'DELETE FROM inp_files CASCADE;',
                'DELETE FROM arc CASCADE;',
                # "DELETE FROM cat_work WHERE id = 'import_inp_test';",
                "DELETE FROM cat_dscenario WHERE expl_id = 1;",
                "DELETE FROM cat_arc CASCADE;"
                "DELETE FROM cat_material CASCADE;",
                "DELETE FROM ve_address CASCADE;",
                "DELETE FROM ve_streetaxis CASCADE;",
                # "DELETE FROM sector WHERE sector_id = 1;",
                # "DELETE FROM ve_municipality WHERE muni_id = 1;",
                # "DELETE FROM exploitation WHERE expl_id = 1;",
                "INSERT INTO cat_material (id, descript, feature_type, n) VALUES ('PVC', 'PVC', '{ARC}', 0.011), ('Brick', 'Brick', '{ARC}', 0.014);",
                # "INSERT INTO exploitation (expl_id, name, macroexpl_id, descript, active) VALUES (1, 'expl_1_import_inp_test', 0, 'Created by import inp in TESTING MODE', true);",
                # "INSERT INTO ve_municipality (muni_id, name, observ, active) VALUES (1, 'muni_1_import_inp_test', 'Created by import inp in TESTING MODE', true);",
                # "INSERT INTO sector (sector_id, name, macrosector_id, descript, active) VALUES (1, 'sector_1_import_inp_test', 0, 'Created by import inp in TESTING MODE', true);"
            ]
            for sql in queries:
                result = tools_db.execute_sql(sql, commit=force_commit)
                if not result:
                    return

            # Set variables
            workcat = "import_inp_test"
            exploitation = 1
            sector = 0
            municipality = 999999  # Spatial intersect
            raingage = None
            catalogs = {
                'conduits': {
                    ('CIRCULAR', 0.2, 0.0, 0.0, 0.0): 'CC020',
                    ('CIRCULAR', 0.315, 0.0, 0.0, 0.0): 'CC0315',
                    ('CIRCULAR', 0.4, 0.0, 0.0, 0.0): 'CC040',
                    ('CIRCULAR', 0.6, 0.0, 0.0, 0.0): 'CC060',
                    ('CIRCULAR', 0.8, 0.0, 0.0, 0.0): 'CC080',
                    ('CIRCULAR', 1.0, 0.0, 0.0, 0.0): 'CC100',
                    ('EGG', 1.5, 0.0, 0.0, 0.0): 'EGG150',
                    ('EGG', 1.5, 1.0, 0.0, 0.0): 'EGG150-1',
                    ('FORCE_MAIN', 0.18, 100.0, 0.0, 0.0): 'FM18',
                    ('FORCE_MAIN', 0.25, 100.0, 0.0, 0.0): 'FM25',
                    ('RECT_CLOSED', 1.5, 1.5, 0.0, 0.0): 'RC150',
                    ('RECT_CLOSED', 2.0, 2.0, 0.0, 0.0): 'RC200',
                    ('RECT_OPEN', 1.0, 1.0, 0.0, 0.0): 'RO100',
                    ('RECT_OPEN', 2.0, 2.0, 0.0, 0.0): 'RO200'
                },
                'materials': {
                    0.011: 'PVC',
                    0.014: 'Brick'
                },
                'features': {
                    'junctions': 'CIRC_MANHOLE',
                    'outfalls': 'RECT_MANHOLE',
                    'storage': 'SEWER_STORAGE',
                    'dividers': 'JUNCTION',
                    'conduits': 'CONDUIT',
                    'pumps': 'VARC',
                    'weirs': 'VARC',
                    'orifices': 'VARC',
                    'outlets': 'VARC'
                },
                'junctions': 'C_MANHOLE_100',
                'outfalls': 'R_MANHOLE_100',
                'storage': 'SEW_STORAGE-01',
                'dividers': 'INP-DIVIDER',
                'pumps': 'INP-PUMP',
                'weirs': 'INP-WEIR',
                'orifices': 'INP-ORIFICE',
                'outlets': 'INP-OUTLET'
            }

            # Save options to the configuration file
            save_config(self, workcat=workcat, exploitation=exploitation, sector=sector, municipality=municipality, raingage=raingage, catalogs=catalogs)

            # Show tab log
            self.dlg_config.mainTab.setCurrentIndex(self.dlg_config.mainTab.count() - 1)

            # Set background task 'Import INP'
            msg = "Import INP (TESTING MODE)"
            self.import_inp_task = GwImportInpTask(
                tools_qt.tr(msg),
                self.file_path,
                self.parse_inp_task.network,
                workcat,
                exploitation,
                sector,
                municipality,
                raingage,
                catalogs,
                2,  # state
                3,  # state_type
                manage_flwreg=manage_flwreg,
                force_commit=force_commit
            )

            # Create timer
            self.t0: float = time()
            self.timer: QTimer = QTimer()
            self.timer.timeout.connect(
                partial(self._update_config_dialog, self.dlg_config)
            )
            self.timer.start(1000)
            self.import_inp_task.message_logged.connect(self._message_logged)
            self.import_inp_task.progress_changed.connect(self._progress_changed)
            self.import_inp_task.taskCompleted.connect(self.timer.stop)

            # Run task
            QgsApplication.taskManager().addTask(self.import_inp_task)
            QgsApplication.taskManager().triggerTask(self.import_inp_task)
            return

        # Get the configuration values from the dialog
        workcat, exploitation, sector, municipality, raingage, _, psector = self._get_config_values()

        # Workcat
        if workcat == "":
            msg = "Please enter a Workcat_id to proceed with this import."
            tools_qt.show_info_box(msg)
            return

        sql: str = "SELECT id FROM cat_work WHERE id = %s"
        row = tools_db.get_row(sql, params=(workcat,))
        if row is not None and not psector:
            msg = 'The Workcat_id "{0}" is already in use. Please enter a different ID.'
            msg_params = (workcat,)
            tools_qt.show_info_box(msg, msg_params=msg_params)
            return

        # Exploitation
        if exploitation == "":
            msg = "Please select an exploitation to proceed with this import."
            tools_qt.show_info_box(msg)
            return

        # Sector
        if sector == "":
            msg = "Please select a sector to proceed with this import."
            tools_qt.show_info_box(msg)
            return

        # Municipality
        if municipality == "":
            msg = "Please select a municipality to proceed with this import."
            tools_qt.show_info_box(msg)
            return

        # Raingage
        if self.dlg_config.txt_raingage.isVisible() and raingage in ("", "null", None):
            msg = "Please select a default raingage to proceed with this import."
            tools_qt.show_info_box(msg)
            return

        # Tables (Arcs and Nodes)
        catalogs = {"conduits": {}, "materials": {}, "features": {}}

        for _input, result in [
            (self.tbl_elements, catalogs),
            (self.tbl_elements["conduits"], catalogs["conduits"]),
            (self.tbl_elements["materials"], catalogs["materials"]),
            (self.tbl_elements["features"], catalogs["features"]),
        ]:
            for element in _input:
                if type(_input[element]) is not tuple:
                    continue

                combo = _input[element][0]
                combo_value = combo.currentText()

                if combo_value == "":
                    msg = "Please select a catalog item for all elements in the tabs: Features, Nodes, Arcs, Materials."
                    tools_qt.show_info_box(msg)
                    return

                new_catalog = None

                if len(_input[element]) > 1:
                    new_catalog_cell = _input[element][1]
                    new_catalog = new_catalog_cell.text().strip()

                    if combo_value == CREATE_NEW and new_catalog == "":
                        msg = 'Please enter a new catalog name when the "{0}" option is selected.'
                        msg_params = (CREATE_NEW,)
                        tools_qt.show_info_box(msg, msg_params=msg_params)
                        return

                result[element] = (
                    new_catalog if combo_value == CREATE_NEW else combo_value
                )

        # Save options to the configuration file
        save_config(self, workcat=workcat, exploitation=exploitation, sector=sector, municipality=municipality, raingage=raingage, catalogs=catalogs, psector=psector)

        # Show tab log
        self.dlg_config.mainTab.setCurrentIndex(self.dlg_config.mainTab.count() - 1)

        # Set state and state_type
        if psector:
            state = 2
            state_type = 3
        else:
            state = 1
            state_type = 2

        # Set background task 'Import INP'
        msg = "Import INP"
        self.import_inp_task = GwImportInpTask(
            tools_qt.tr(msg),
            self.file_path,
            self.parse_inp_task.network,
            workcat,
            exploitation,
            sector,
            municipality,
            raingage,
            catalogs,
            state,
            state_type,
            manage_flwreg=manage_flwreg,
            force_commit=force_commit
        )

        # Create timer
        self.t0: float = time()
        self.timer: QTimer = QTimer()
        self.timer.timeout.connect(
            partial(self._update_config_dialog, self.dlg_config)
        )
        self.timer.start(1000)
        self.import_inp_task.message_logged.connect(self._message_logged)
        self.import_inp_task.progress_changed.connect(self._progress_changed)
        self.import_inp_task.taskCompleted.connect(self.timer.stop)

        QgsApplication.taskManager().addTask(self.import_inp_task)
        QgsApplication.taskManager().triggerTask(self.import_inp_task)

    def _fill_tables(self):
        # Fill nodes table
        tbl_nodes: QTableWidget = self.dlg_config.tbl_nodes

        node_elements = [
            ("junctions", self.catalogs.inp_junctions, "JUNCTION"),
            ("outfalls", self.catalogs.inp_outfalls, "OUTFALL"),
            ("dividers", self.catalogs.inp_dividers, "DIVIDER"),
            ("storage", self.catalogs.inp_storage, "STORAGE"),
        ]

        self.tbl_elements = {}

        for element, rec_catalog, tag in node_elements:
            if rec_catalog is not None:
                row: int = tbl_nodes.rowCount()
                tbl_nodes.setRowCount(row + 1)

                first_column = QTableWidgetItem(tag)
                first_column.setFlags(Qt.ItemFlag.ItemIsEnabled)
                tbl_nodes.setItem(row, 0, first_column)

                combo_cat = QComboBox()
                tbl_nodes.setCellWidget(row, 1, combo_cat)

                new_cat_name = QTableWidgetItem("")
                new_cat_name.setFlags(Qt.ItemFlag.NoItemFlags)
                tbl_nodes.setItem(row, 2, new_cat_name)
                combo_cat.currentTextChanged.connect(
                    partial(self._toggle_enabled_new_catalog_field, new_cat_name)
                )

                self.tbl_elements[element] = (combo_cat, new_cat_name)

        # Fill arcs table with the pipes
        tbl_arcs: QTableWidget = self.dlg_config.tbl_arcs
        tbl_arcs.setColumnCount(8)
        tbl_arcs.setHorizontalHeaderLabels(["EPA type", "SHAPE", "geom1", "geom2", "geom3", "geom4", "Arc catalog", "New catalog name"])

        if self.catalogs.inp_conduits:
            self.tbl_elements["conduits"] = {}

            for cat_tuple, rec_catalog in self.catalogs.inp_conduits.items():
                row: int = tbl_arcs.rowCount()
                tbl_arcs.setRowCount(row + 1)

                first_column = QTableWidgetItem("CONDUIT")
                first_column.setFlags(Qt.ItemFlag.ItemIsEnabled)
                tbl_arcs.setItem(row, 0, first_column)

                for idx, prop in enumerate(cat_tuple):
                    value = str(prop) if prop is not None else ''
                    item = QTableWidgetItem(value)
                    item.setFlags(Qt.ItemFlag.ItemIsEnabled)
                    tbl_arcs.setItem(row, idx + 1, item)

                combo_cat = QComboBox()
                tbl_arcs.setCellWidget(row, 6, combo_cat)

                new_cat_name = QTableWidgetItem("")
                new_cat_name.setFlags(Qt.ItemFlag.NoItemFlags)
                tbl_arcs.setItem(row, 7, new_cat_name)
                combo_cat.currentTextChanged.connect(
                    partial(self._toggle_enabled_new_catalog_field, new_cat_name)
                )

                self.tbl_elements["conduits"][cat_tuple] = (
                    combo_cat,
                    new_cat_name,
                )

        # Fill materials table
        tbl_material: QTableWidget = self.dlg_config.tbl_material

        if self.catalogs.roughness_catalog:
            self.tbl_elements["materials"] = {}
            roughnesses = {roughness for roughness in self.catalogs.roughness_catalog}

            for roughness in roughnesses:
                row: int = tbl_material.rowCount()
                tbl_material.setRowCount(row + 1)

                first_column = QTableWidgetItem(str(roughness))
                first_column.setFlags(Qt.ItemFlag.ItemIsEnabled)
                tbl_material.setItem(row, 0, first_column)

                combo_mat = QComboBox()
                tbl_material.setCellWidget(row, 1, combo_mat)

                self.tbl_elements["materials"][roughness] = (combo_mat,)

        # Fill Features table
        tbl_feature: QTableWidget = self.dlg_config.tbl_feature

        feature_types = [
            ("JUNCTIONS", self.catalogs.inp_junctions, ("MANHOLE",), "NODE"),
            ("OUTFALLS", self.catalogs.inp_outfalls, ("MANHOLE",), "NODE"),
            ("DIVIDERS", self.catalogs.inp_dividers, ("MANHOLE",), "NODE"),
            ("STORAGE", self.catalogs.inp_storage, ("STORAGE",), "NODE"),
            ("CONDUITS", self.catalogs.inp_conduits, ("CONDUIT",), "ARC"),
            ("PUMPS", self.catalogs.inp_pumps, ("VARC", "FRPUMP"), ("ARC", "FLWREG")),
            ("ORIFICES", self.catalogs.inp_orifice, ("VARC", "FRORIFICE"), ("ARC", "FLWREG")),
            ("WEIRS", self.catalogs.inp_weir, ("VARC", "FRWEIR"), ("ARC", "FLWREG")),
            ("OUTLETS", self.catalogs.inp_outlet, ("VARC", "FROUTLET"), ("ARC", "FLWREG")),
        ]

        self.tbl_elements["features"] = {}

        for tag, rec_catalog, feature_class, feature_type in feature_types:
            if rec_catalog is None:
                continue

            if tag == "CONDUITS" and not rec_catalog:
                continue

            row: int = tbl_feature.rowCount()
            tbl_feature.setRowCount(row + 1)

            first_column = QTableWidgetItem(tag)
            first_column.setFlags(Qt.ItemFlag.ItemIsEnabled)
            tbl_feature.setItem(row, 0, first_column)

            combo_feat = QComboBox()
            tbl_feature.setCellWidget(row, 1, combo_feat)

            self.tbl_elements["features"][tag.lower()] = (combo_feat,)

    def _fill_combo_boxes(self):
        # Fill exploitation combo
        cmb_expl: QComboBox = self.dlg_config.cmb_expl
        expl_value: str = cmb_expl.currentText()

        rows = tools_db.get_rows("""
            SELECT expl_id, name
            FROM exploitation
            WHERE expl_id > 0
        """)
        cmb_expl.clear()
        tools_qt.fill_combo_values(cmb_expl, rows, add_empty=False, selected_id=expl_value, index_to_compare=1)

        # Fill sector combo
        cmb_sector: QComboBox = self.dlg_config.cmb_sector
        sector_value: str = cmb_sector.currentText()

        rows = tools_db.get_rows("""
            SELECT sector_id, name
            FROM sector
            WHERE sector_id = 0
        """)
        cmb_sector.clear()
        tools_qt.fill_combo_values(cmb_sector, rows, add_empty=False, selected_id=sector_value, index_to_compare=1)

        # Fill municipality combo
        cmb_muni: QComboBox = self.dlg_config.cmb_muni
        muni_value: str = cmb_muni.currentText()

        rows = tools_db.get_rows("""
            SELECT muni_id, name
            FROM v_municipality
            WHERE muni_id > 0
        """)
        tools_qt.fill_combo_values(cmb_muni, rows)
        # Add a separator and a "Get from spatial intersect" option
        cmb_muni.insertSeparator(cmb_muni.count())
        cmb_muni.addItem(SPATIAL_INTERSECT, [999999, SPATIAL_INTERSECT])
        # Restore the selection if it still exists
        index = cmb_muni.findText(muni_value)
        if index >= 0:
            cmb_muni.setCurrentIndex(index)

        self.catalogs = Catalogs.from_network_model(self.parse_inp_task.network)

        # Get flow regulators catalog source
        catalog_source = self.catalog_source.get("pumps", "db_arcs")
        pump_catalog = getattr(self.catalogs, catalog_source)
        catalog_source = self.catalog_source.get("orifices", "db_arcs")
        orifice_catalog = getattr(self.catalogs, catalog_source)
        catalog_source = self.catalog_source.get("weirs", "db_arcs")
        weir_catalog = getattr(self.catalogs, catalog_source)
        catalog_source = self.catalog_source.get("outlets", "db_arcs")
        outlet_catalog = getattr(self.catalogs, catalog_source)

        # Fill nodes and arcs tables
        elements = [
            ("junctions", self.catalogs.inp_junctions, self.catalogs.db_nodes),
            ("outfalls", self.catalogs.inp_outfalls, self.catalogs.db_nodes),
            ("dividers", self.catalogs.inp_dividers, self.catalogs.db_nodes),
            ("storage", self.catalogs.inp_storage, self.catalogs.db_nodes),
            ("conduits", self.catalogs.inp_conduits, self.catalogs.db_arcs),
            ("pumps", self.catalogs.inp_pumps, pump_catalog),
            ("orifices", self.catalogs.inp_orifice, orifice_catalog),
            ("weirs", self.catalogs.inp_weir, weir_catalog),
            ("outlets", self.catalogs.inp_outlet, outlet_catalog),
        ]

        for element_type, element_catalog, db_catalog in elements:
            if element_type == "conduits":
                continue

            if element_type not in self.tbl_elements:
                continue

            combo: QComboBox = self.tbl_elements[element_type][0]
            old_value: str = combo.currentText()

            combo.clear()
            combo.addItems(["", CREATE_NEW])
            if len(element_catalog) > 0:
                combo.insertSeparator(combo.count())
                title = "Recommended catalogs:"
                combo.addItem(tools_qt.tr(title))
                combo.model().item(combo.count() - 1).setEnabled(False)
                combo.addItems(element_catalog)
            if len(db_catalog) > len(element_catalog):
                combo.insertSeparator(combo.count())
                title = "Other catalogs:"
                combo.addItem(tools_qt.tr(title))
                combo.model().item(combo.count() - 1).setEnabled(False)
                combo.addItems(cat for cat in db_catalog if cat not in element_catalog)
            combo.setCurrentText(old_value)

        if self.catalogs.inp_conduits is not None:
            for pipe_type, pipe_catalog in self.catalogs.inp_conduits.items():
                if pipe_type not in self.tbl_elements["conduits"]:
                    continue

                combo: QComboBox = self.tbl_elements["conduits"][pipe_type][0]
                old_value: str = combo.currentText()

                combo.clear()
                combo.addItems(["", CREATE_NEW])
                if len(pipe_catalog) > 0:
                    combo.insertSeparator(combo.count())
                    title = "Recommended catalogs:"
                    combo.addItem(tools_qt.tr(title))
                    combo.model().item(combo.count() - 1).setEnabled(False)
                    combo.addItems(pipe_catalog)
                if len(self.catalogs.db_arcs) > len(pipe_catalog):
                    combo.insertSeparator(combo.count())
                    title = "Other catalogs:"
                    combo.addItem(tools_qt.tr(title))
                    combo.model().item(combo.count() - 1).setEnabled(False)
                    combo.addItems(
                        cat for cat in self.catalogs.db_arcs if cat not in pipe_catalog
                    )
                combo.setCurrentText(old_value)

        # Fill materials
        for roughness, (combo,) in self.tbl_elements["materials"].items():
            material_catalog = [
                mat
                for mat, roughnesses in self.catalogs.db_materials.items()
                if roughness == roughnesses
            ]

            old_value: str = combo.currentText()
            combo.clear()
            combo.addItem("")
            if len(material_catalog) > 0:
                combo.insertSeparator(combo.count())
                title = "Recommended materials:"
                combo.addItem(tools_qt.tr(title))   
                combo.model().item(combo.count() - 1).setEnabled(False)
                combo.addItems(material_catalog)
            if len(self.catalogs.db_materials) > len(material_catalog):
                combo.insertSeparator(combo.count())
                title = "Other materials:"
                combo.addItem(tools_qt.tr(title))
                combo.model().item(combo.count() - 1).setEnabled(False)
                combo.addItems(
                    mat
                    for mat in self.catalogs.db_materials
                    if mat not in material_catalog
                )
            combo.setCurrentText(old_value)

        # Fill features
        feature_types = {
            "junctions": ("NODE", ("MANHOLE",)),
            "outfalls": ("NODE", ("MANHOLE",)),
            "dividers": ("NODE", ("MANHOLE",)),
            "storage": ("NODE", ("STORAGE",)),
            "conduits": ("ARC", ("CONDUIT",)),
            "pumps": (("ARC"), ("ELEMENT", "FRELEM")),
            "orifices": (("ARC"), ("ELEMENT", "FRELEM")),
            "weirs": (("ARC"), ("ELEMENT", "FRELEM")),
            "outlets": (("ARC"), ("ELEMENT", "FRELEM")),
        }
        for element_type, (combo,) in self.tbl_elements["features"].items():
            system_catalog = [
                feat_id
                for feat_id, (feature_class, _) in self.catalogs.db_features.items()
                if feature_class in feature_types[element_type][0]
            ]
            feat_catalog = [
                feat_id
                for feat_id, (_, feat_type) in self.catalogs.db_features.items()
                if feat_type in feature_types[element_type][1]
            ]

            combo.blockSignals(True)
            old_value: str = combo.currentText()
            combo.clear()
            combo.addItem("")
            if len(feat_catalog) > 0:
                combo.insertSeparator(combo.count())
                title = "Recommended feature ids:"
                combo.addItem(tools_qt.tr(title))
                combo.model().item(combo.count() - 1).setEnabled(False)
                combo.addItems(feat_catalog)
            if len(system_catalog) > len(feat_catalog):
                combo.insertSeparator(combo.count())
                title = "Other feature ids:"
                combo.addItem(tools_qt.tr(title))
                combo.model().item(combo.count() - 1).setEnabled(False)
                combo.addItems(
                    feat for feat in system_catalog if feat not in feat_catalog
                )
            combo.setCurrentText(old_value)
            combo.blockSignals(False)

            # Connect a signal to set flow regulators in the corresponding table
            if element_type in ("pumps", "orifices", "weirs", "outlets"):
                tools_gw.connect_signal(combo.currentTextChanged,
                                        partial(self._update_table_based_on_feature_type, element_type, combo),
                                        'import_inp', f'cmb_{element_type.lower()}_update_table_based_on_feature_type')

    def _update_table_based_on_feature_type(self, element_type: str, combo: QComboBox):
        if element_type not in ("pumps", "orifices", "weirs", "outlets"):
            return

        feature_type = combo.currentText()
        if feature_type == "":
            return

        sql = f"""
            SELECT feature_type FROM cat_feature WHERE id = '{feature_type.upper()}';
        """
        feature_type = tools_db.get_row(sql)
        if feature_type is None:
            return

        feature_type = feature_type[0]
        tbl = self.dlg_config.tbl_arcs if feature_type == "ARC" else self.dlg_config.tbl_flwreg
        other_tbl = self.dlg_config.tbl_flwreg if feature_type == "ARC" else self.dlg_config.tbl_arcs

        # Update the catalog source based on the feature type
        self.catalog_source[element_type] = "db_arcs" if feature_type == "ARC" else "db_flwreg"

        # Fill table with pumps and valves
        elements = [
            ("pumps", self.catalogs.inp_pumps, "PUMP"),
            ("orifices", self.catalogs.inp_orifice, "ORIFICE"),
            ("weirs", self.catalogs.inp_weir, "WEIR"),
            ("outlets", self.catalogs.inp_outlet, "OUTLET"),
        ]

        # Find the tag for the given element_type
        tag = None
        for element, rec_catalog, element_tag in elements:
            if element == element_type:
                tag = element_tag
                break
        if tag is None:
            return

        # Remove existing row for the element in the current table
        for row in range(tbl.rowCount()):
            if tbl.item(row, 0) and tbl.item(row, 0).text() == tag:
                tbl.removeRow(row)
                break
        # Remove existing row for the element in the other table
        for row in range(other_tbl.rowCount()):
            if other_tbl.item(row, 0) and other_tbl.item(row, 0).text() == tag:
                other_tbl.removeRow(row)
                break

        for element, rec_catalog, tag in elements:
            if element != element_type:
                continue

            if rec_catalog is None:
                continue

            # Disconnect old combo signal
            tools_gw.disconnect_signal('import_inp', f'tbl_{element.lower()}_cmb_{element.lower()}_toggle_enabled_new_catalog_field')

            # Add a new row
            row: int = tbl.rowCount()
            tbl.setRowCount(row + 1)

            # Fill the first column
            first_column = QTableWidgetItem(tag)
            first_column.setFlags(Qt.ItemFlag.ItemIsEnabled)
            tbl.setItem(row, 0, first_column)

            # Create the combo box and put it in the second or fourth column
            combo_cat = QComboBox()
            combo_idx = 6 if feature_type == "ARC" else 1
            tbl.setCellWidget(row, combo_idx, combo_cat)

            # Fill the "NEW CATALOG" column
            new_cat_name = QTableWidgetItem("")
            new_cat_name.setFlags(Qt.ItemFlag.NoItemFlags)
            tbl.setItem(row, combo_idx + 1, new_cat_name)

            # Connect signal to the new combo
            tools_gw.connect_signal(combo_cat.currentTextChanged,
                                    partial(self._toggle_enabled_new_catalog_field, new_cat_name),
                                    'import_inp', f'tbl_{feature_type.lower()}_cmb_{element.lower()}_toggle_enabled_new_catalog_field')

            self.tbl_elements[element] = (combo_cat, new_cat_name)

        # Reload the combo boxes
        self._fill_combo_boxes()

    def _get_config_values(self):
        workcat = tools_qt.get_text(self.dlg_config, "txt_workcat", return_string_null=False)
        exploitation = tools_qt.get_combo_value(self.dlg_config, "cmb_expl")
        sector = tools_qt.get_combo_value(self.dlg_config, "cmb_sector")
        municipality = tools_qt.get_combo_value(self.dlg_config, "cmb_muni")
        raingage = tools_qt.get_text(self.dlg_config, "txt_raingage", return_string_null=False)
        psector = tools_qt.is_checked(self.dlg_config, "chk_psector")

        # Tables (Arcs and Nodes)
        catalogs = {"conduits": {}, "materials": {}, "features": {}}

        for _input, result in [
            (self.tbl_elements, catalogs),
            (self.tbl_elements["conduits"], catalogs["conduits"]),
            (self.tbl_elements["materials"], catalogs["materials"]),
            (self.tbl_elements["features"], catalogs["features"]),
        ]:
            for element in _input:
                if type(_input[element]) is not tuple:
                    continue

                combo = _input[element][0]
                combo_value = combo.currentText()

                if combo_value == "":
                    continue
                if combo_value == CREATE_NEW:
                    new_name = _input[element][1].text().strip()
                    if new_name == "":
                        continue
                    combo_value = new_name

                new_catalog = None

                if len(_input[element]) > 1:
                    new_catalog_cell = _input[element][1]
                    new_catalog = new_catalog_cell.text().strip()

                    if combo_value == CREATE_NEW:
                        if new_catalog == "":
                            continue
                        combo_value = new_catalog

                result[element] = (
                    new_catalog if combo_value == CREATE_NEW else combo_value
                )

        return workcat, exploitation, sector, municipality, raingage, catalogs, psector

    def _toggle_enabled_new_catalog_field(
        self, field: QTableWidgetItem, text: str
    ) -> None:
        field.setFlags(
            Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsEditable
            if text == CREATE_NEW
            else Qt.ItemFlag.NoItemFlags
        )

    def _update_parsing_dialog(self, dialog: GwDialog) -> None:
        if not dialog.isVisible():
            self.timer.stop()
            return

        tools_gw.fill_tab_log(
            dialog,
            {"info": {"values": [{"message": msg} for msg in self.parse_inp_task.log]}},
        )
        self._calculate_elapsed_time(dialog)

        if isdeleted(self.parse_inp_task) or not self.parse_inp_task.isActive():
            self.timer.stop()
            self.dlg_inp_parsing.progressBar.setVisible(False)

    def _update_config_dialog(self, dialog: GwDialog):
        if not dialog.isVisible():
            self.timer.stop()
            return

        self._calculate_elapsed_time(dialog)

        if isdeleted(self.import_inp_task) or not self.import_inp_task.isActive():
            self.timer.stop()
            self.dlg_config.progressBar.setVisible(False)

    def _calculate_elapsed_time(self, dialog: GwDialog) -> None:
        tf: float = time()  # Final time
        td: float = tf - self.t0  # Delta time
        msg = "Exec. time: {0}"
        msg_params = (timedelta(seconds=round(td)),)
        self._update_time_elapsed(tools_qt.tr(msg, list_params=msg_params), dialog)

    def _update_time_elapsed(self, text: str, dialog: GwDialog) -> None:
        lbl_time: QLabel = dialog.findChild(QLabel, "lbl_time")
        lbl_time.setText(text)

    def _message_logged(self, message: str, end: str = "\n"):

        data = {"info": {"values": [{"message": message}]}}
        tools_gw.fill_tab_log(self.dlg_config, data, reset_text=True, close=False, end=end, call_set_tabs_enabled=False)

    def _progress_changed(self, process: str, progress: int, text: str, new_line: bool) -> None:
        # Progress bar
        if progress is not None:
            self.dlg_config.progressBar.setValue(progress)

        # TextEdit log
        txt_infolog = self.dlg_config.findChild(QTextEdit, 'tab_log_txt_infolog')
        cur_text = tools_qt.get_text(self.dlg_config, txt_infolog, return_string_null=False)
        title = "Generate INP algorithm"
        if process and process not in (self.cur_process, title, tools_qt.tr(title)):
            cur_text = f"{cur_text}\n" \
                       f"--------------------\n" \
                       f"{process}\n" \
                       f"--------------------\n\n"
            self.cur_process = process
            self.cur_text = None

        # Generate INP log is cumulative, so it's saved until the process ends
        if process in (title, tools_qt.tr(title)) and not self.cur_text:
            self.cur_text = cur_text

        if self.cur_text:
            cur_text = self.cur_text

        end_line = '\n' if new_line else ''
        txt_infolog.setText(f"{cur_text}{text}{end_line}")
        txt_infolog.show()
        # Scroll to the bottom
        scrollbar = txt_infolog.verticalScrollBar()
        scrollbar.setValue(scrollbar.maximum())

    def _cleanup_signals(self):
        """Cleanup all import_inp signals when dialog closes"""
        try:
            # Disconnect all import_inp section signals
            tools_gw.disconnect_signal('import_inp')
        except Exception:
            pass
