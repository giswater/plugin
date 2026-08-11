"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
import traceback
from datetime import date
from itertools import count
from typing import Any
from datetime import datetime
from typing import Optional

from qgis.PyQt.QtCore import pyqtSignal

from ....libs import lib_vars, tools_db, tools_qt
from ...utils import tools_gw
from ...utils.import_inp import lerp_progress, to_yesno, nan_to_none, get_rows, execute_sql, toolsdb_execute_values
from ..task import GwTask


def get_geometry_from_link(inp, link) -> str:
    from swmm_api.input_file.section_labels import COORDINATES, VERTICES

    from_node = link.from_node
    if from_node not in inp[COORDINATES]:
        return "null"
    to_node = link.to_node
    if to_node not in inp[COORDINATES]:
        return "null"

    start_node_x, start_node_y = inp[COORDINATES][from_node].x, inp[COORDINATES][from_node].y
    end_node_x, end_node_y = inp[COORDINATES][to_node].x, inp[COORDINATES][to_node].y
    vertices = inp[VERTICES][link.name].vertices if link.name in inp[VERTICES] else []

    coordinates = f"{start_node_x} {start_node_y},"
    for v in vertices:
        coordinates += f"{v[0]} {v[1]},"
    coordinates += f"{end_node_x} {end_node_y}"

    return f"LINESTRING({coordinates})"


class GwImportInpTask(GwTask):

    message_logged = pyqtSignal(str, str)
    progress_changed = pyqtSignal(str, int, str, bool)  # (Process, Progress, Text, '\n')

    # Progress percentages
    PROGRESS_INIT = 0
    PROGRESS_VALIDATE = 5
    PROGRESS_OPTIONS = 10
    PROGRESS_CATALOGS = 30
    PROGRESS_NONVISUAL = 50
    PROGRESS_VISUAL = 90
    PROGRESS_MUNICIPALITY = 95
    PROGRESS_SOURCES = 97
    PROGRESS_END = 100

    def __init__(
        self,
        description: str,
        filepath,
        network,
        workcat,
        exploitation,
        sector,
        municipality,
        raingage,
        catalogs,
        state,
        state_type,
        manage_flwreg: dict[str, bool] = {"pumps": False, "orifices": False, "weirs": False, "outlets": False},
        force_commit: bool = False,
    ) -> None:
        super().__init__(description)
        self.filepath = filepath
        self.network = network
        self.workcat: str = workcat
        self.exploitation: int = exploitation
        self.sector: int = sector
        self.municipality: int = municipality
        self.default_raingage: Optional[str] = raingage
        self.catalogs: dict[str, Any] = catalogs
        self.state: int = state
        self.state_type: int = state_type
        self.manage_flwreg: dict[str, bool] = manage_flwreg
        self.force_commit: bool = force_commit
        self.update_municipality: bool = False
        self.log: list[str] = []
        self.mappings: dict[str, dict[str, str]] = {"curves": {}, "patterns": {}, "timeseries": {}}
        self.arccat_db: list[str] = []
        self.db_units = None
        self.exception: str = ""
        self.debug_mode: bool = False  # TODO: add checkbox or something to manage debug_mode, and put logs into tab_log
        self.flwreg_ids: dict[str, list] = {}

        self.node_ids: dict[str, str] = {}
        self.results: dict[str, int] = {}

    def run(self) -> bool:
        super().run()
        try:
            from swmm_api.input_file.section_labels import TITLE, FILES  # noqa: F401
        except ImportError:
            msg = "Python package 'swmm-api' is not installed. Please install it using pip or the 'qpip' QGIS plugin."
            self.exception = tools_qt.tr(msg)
            return False

        try:
            # Disable triggers except plan trigger
            self._enable_triggers(False, plan_trigger=True)

            message = "Validate inputs"
            msg = "Validating inputs..."
            self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_INIT, tools_qt.tr(msg), False)
            self._validate_inputs()
            msg = "done!"
            self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_VALIDATE, tools_qt.tr(msg), True)

            message = "Getting options"
            msg = "Importing options..."
            self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_VALIDATE, tools_qt.tr(msg), False)
            self._save_options()
            msg = "done!"
            self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_OPTIONS, tools_qt.tr(msg), True)

            if self.network.get(TITLE):
                message = "Getting options"
                msg = "Importing title..."
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_OPTIONS, tools_qt.tr(msg), False)
                self._save_title()
                msg = "done!"
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_OPTIONS, tools_qt.tr(msg), True)

            if self.network.get(FILES):
                message = "Getting options"
                msg = "Importing files..."
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_OPTIONS, tools_qt.tr(msg), False)
                self._save_files()
                msg = "done!"
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_OPTIONS, tools_qt.tr(msg), True)

            self._manage_nonvisual()

            self._manage_catalogs()

            self._manage_visual()

            if self.update_municipality:
                message = "Municipality"
                msg = "Updating municipality..."
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_VISUAL, tools_qt.tr(msg), False)
                self._update_municipality()
                msg = "done!"
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_MUNICIPALITY, tools_qt.tr(msg), True)

            self._manage_others()

            # Enable plan and topocontrol triggers
            self._enable_triggers(False, plan_trigger=True, geometry_trigger=True)

            if any(self.manage_flwreg.values()):
                message = "Flow regulators"
                msg = "Converting to flwreg..."
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_SOURCES, tools_qt.tr(msg), False)
                log_str = self._manage_flwreg()
                msg = "done!"
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_END, tools_qt.tr(msg), True)
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_END, tools_qt.tr(log_str), True)

            # Enable ALL triggers
            self._enable_triggers(True)

            execute_sql("select 1", commit=True, is_thread=True)
            msg = "imported"
            report_message = '\n'.join([f"{k.upper()} {tools_qt.tr(msg)}: {v}" for k, v in self.results.items()])
            message = "REPORT"
            self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_END, tools_qt.tr(report_message), True)
            msg = "ALL DONE! INP successfully imported."
            self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_END, tools_qt.tr(msg), True)
            return True
        except Exception:
            self.exception = traceback.format_exc()
            self._log_message(f"{traceback.format_exc()}")
            tools_db.dao.rollback()
            return False

    def _manage_catalogs(self) -> None:
        message = "Create catalogs"
        msg = "Creating workcat"
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(0, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        if self.state != 2:
            self._create_workcat_id()
        msg = "Creating new node catalogs"
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(20, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        self._create_new_node_catalogs()

        # Get existing catalogs in DB
        cat_arc_ids = get_rows("SELECT id FROM cat_arc", commit=self.force_commit, is_thread=True)
        if cat_arc_ids:
            self.arccat_db += [x[0] for x in cat_arc_ids]

        msg = "Creating new varc catalogs"
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(50, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        self._create_new_varc_catalogs()
        msg = "Creating new pipe catalogs"
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(70, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        self._create_new_conduit_catalogs()
        if any(self.manage_flwreg.values()):
            msg = "Creating new flwreg catalogs"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(90, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
            self._create_new_flwreg_catalogs()

    def _manage_nonvisual(self) -> None:
        from swmm_api.input_file.section_labels import PATTERNS, CURVES, TIMESERIES, CONTROLS, LID_CONTROLS
        message = "Non-visual objects"
        if self.network.get(PATTERNS):
            msg = "Importing patterns"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(0, self.PROGRESS_CATALOGS, self.PROGRESS_NONVISUAL), tools_qt.tr(msg), True)
            self._save_patterns()

        if self.network.get(CURVES):
            msg = "Importing curves"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(40, self.PROGRESS_CATALOGS, self.PROGRESS_NONVISUAL), tools_qt.tr(msg), True)
            self._save_curves()

        if self.network.get(TIMESERIES):
            msg = "Importing timeseries"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(60, self.PROGRESS_CATALOGS, self.PROGRESS_NONVISUAL), tools_qt.tr(msg), True)
            self._save_timeseries()

        if self.network.get(CONTROLS):
            msg = "Importing controls"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(80, self.PROGRESS_CATALOGS, self.PROGRESS_NONVISUAL), tools_qt.tr(msg), True)
            self._save_controls()

        if self.network.get(LID_CONTROLS):
            msg = "Importing LIDs"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(80, self.PROGRESS_CATALOGS, self.PROGRESS_NONVISUAL), tools_qt.tr(msg), True)
            self._save_lids()

    def _manage_visual(self) -> None:
        from swmm_api.input_file.section_labels import (
            JUNCTIONS, OUTFALLS, DIVIDERS, STORAGE, CONDUITS, PUMPS,
            ORIFICES, WEIRS, OUTLETS, RAINGAGES
        )
        message = "Visual objects"
        if self.network.get(JUNCTIONS):
            msg = "Importing junctions"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(0, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_junctions()

        if self.network.get(OUTFALLS):
            msg = "Importing outfalls"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(30, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_outfalls()

        if self.network.get(DIVIDERS):
            msg = "Importing dividers"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(40, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_dividers()

        if self.network.get(STORAGE):
            msg = "Importing storage units"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(45, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_storage()

        if self.network.get(PUMPS):
            msg = "Importing pumps"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(50, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_pumps()

        if self.network.get(ORIFICES):
            msg = "Importing orifices"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(60, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_orifices()

        if self.network.get(WEIRS):
            msg = "Importing weirs"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(65, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_weirs()

        if self.network.get(OUTLETS):
            msg = "Importing outlets"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(70, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_outlets()

        if self.network.get(CONDUITS):
            msg = "Importing conduits"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(80, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_conduits()

        if self.network.get(RAINGAGES):
            msg = "Importing raingages"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(95, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_raingages()

    def _manage_others(self) -> None:
        from swmm_api.input_file.section_labels import INFLOWS, DWF, SUBCATCHMENTS
        message = "Others"
        if self.network.get(INFLOWS):
            msg = "Importing inflows"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(0, self.PROGRESS_VISUAL, self.PROGRESS_END), tools_qt.tr(msg), True)
            self._save_inflows()

        if self.network.get(DWF):
            msg = "Importing DWF"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(20, self.PROGRESS_VISUAL, self.PROGRESS_END), tools_qt.tr(msg), True)
            self._save_dwf()

        if self.network.get(SUBCATCHMENTS):
            msg = "Importing subcatchments"
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(40, self.PROGRESS_VISUAL, self.PROGRESS_END), tools_qt.tr(msg), True)
            self._save_subcatchments()

    def _enable_triggers(self, enable: bool, plan_trigger: bool = False, geometry_trigger: bool = False) -> None:
        op = "ENABLE" if enable else "DISABLE"
        queries = [
            f'ALTER TABLE arc {op} TRIGGER ALL;',
            f'ALTER TABLE node {op} TRIGGER ALL;',
            f'ALTER TABLE element {op} TRIGGER ALL;',
        ]
        if plan_trigger:
            queries.append('ALTER TABLE arc ENABLE TRIGGER gw_trg_plan_psector_after_arc;')
            queries.append('ALTER TABLE node ENABLE TRIGGER gw_trg_plan_psector_after_node;')
        if geometry_trigger:
            queries.append('ALTER TABLE node ENABLE TRIGGER gw_trg_topocontrol_node;')
        for sql in queries:
            result = tools_db.execute_sql(sql, commit=self.force_commit, is_thread=True)
            if not result:
                return

    def _manage_flwreg(self) -> str:
        """ Execute database function 'gw_fct_import_swmm_flwreg' """

        import json

        extras = ""
        if self.manage_flwreg["pumps"]:
            extras += f'''"pump": {{
                "featureClass": "{self.catalogs['features']['pumps']}",
                "catalog": "{self.catalogs['pumps']}",
                "ids": {json.dumps(self.flwreg_ids["pumps"])}
            }},'''
        if self.manage_flwreg["orifices"]:
            extras += f'''"orifice": {{
                "featureClass": "{self.catalogs['features']['orifices']}",
                "catalog": "{self.catalogs['orifices']}",
                "ids": {json.dumps(self.flwreg_ids["orifices"])}
            }},'''
        if self.manage_flwreg["weirs"]:
            extras += f'''"weir": {{
                "featureClass": "{self.catalogs['features']['weirs']}",
                "catalog": "{self.catalogs['weirs']}",
                "ids": {json.dumps(self.flwreg_ids["weirs"])}
            }},'''
        if self.manage_flwreg["outlets"]:
            extras += f'''"outlet": {{
                "featureClass": "{self.catalogs['features']['outlets']}",
                "catalog": "{self.catalogs['outlets']}",
                "ids": {json.dumps(self.flwreg_ids["outlets"])}
            }},'''
        extras += f'''"state": {self.state},'''

        if extras:
            extras = extras[:-1]
            body = tools_gw.create_body(extras=extras)
            json_result = tools_gw.execute_procedure('gw_fct_import_swmm_flwreg', body, commit=self.force_commit,
                                                    is_thread=True)
            if not json_result or json_result.get('status') != 'Accepted':
                message = "Error executing gw_fct_import_swmm_flwreg - {0}"
                raise ValueError(message.format(json_result.get('NOSQLERR')))
            try:
                if json_result['body']['data']['info']:
                    info = json_result['body']['data']['info']
                    if isinstance(info, list):
                        logs = [x.get('message') for x in info]
                        logs_str = '\n'.join(logs)
                        return logs_str
            except KeyError:
                pass
            return ""
        return "No flowregs to manage"

    def _validate_inputs(self) -> None:
        if self.workcat in (None, ""):
            message = "Please enter a Workcat_id to proceed with this import."
            raise ValueError(message)

        if self.exploitation in (None, ""):
            message = "Please select an exploitation to proceed with this import."
            raise ValueError(message)

        if self.sector in (None, ""):
            message = "Please select a sector to proceed with this import."
            raise ValueError(message)

        if self.municipality in (None, ""):
            message = "Please select a municipality to proceed with this import."
            raise ValueError(message)
        if self.municipality == 999999:
            self.municipality = 0
            self.update_municipality = True

    def _save_options(self):
        """
            Import options to table 'config_param_user'.
        """
        from swmm_api.input_file.section_labels import OPTIONS, REPORT
        params_map = {

        }

        # List to accumulate parameters for batch update
        update_params = []

        options_dict: dict = self.network[OPTIONS]

        # Iterate over each option
        for k, v in options_dict.items():
            parameter = params_map.get(k.lower(), k.lower())
            parameter = f"inp_options_{parameter}"
            value = f"{v}"
            if type(v) is bool:
                value = to_yesno(v)
            update_params.append((value, parameter))

        report_dict: dict = self.network[REPORT]

        # Iterate over each option
        for k, v in report_dict.items():
            parameter = params_map.get(k.lower(), k.lower())
            parameter = f"inp_report_{parameter}"
            value = f"{v}"
            if type(v) is bool:
                value = to_yesno(v)
            update_params.append((value, parameter))

        # SQL query for batch update
        sql = """
            UPDATE config_param_user
            SET value = data.value
            FROM (VALUES %s) AS data(value, parameter)
            WHERE config_param_user.parameter::text = data.parameter::text;
        """
        template = "(%s, %s)"

        if self.debug_mode:
            print("OPTIONS:")
            print(update_params)

        # Execute batch update
        toolsdb_execute_values(sql, update_params, template, fetch=False, commit=self.force_commit)

    def _save_title(self):
        from swmm_api.input_file.section_labels import TITLE
        title = self.network[TITLE].txt

        sql = """
            UPDATE config_param_system
            SET value = jsonb_set(value::jsonb, '{descript}', %s)::text
            WHERE parameter = 'admin_schema_info';
        """

        title = title.replace('\n', '\\n')
        params = (f'''"{title}"''',)

        execute_sql(sql, params, is_thread=True)

    def _save_files(self):
        """
            Import options to table 'config_param_user'.
        """
        from swmm_api.input_file.section_labels import FILES

        params = []
        for k, v in self.network[FILES].items():
            actio_type, file_type = k.split(' ')[0], k.split(' ')[1]
            fname = v
            params.append((actio_type, file_type, fname))

        # SQL query for batch update
        sql = """
            INSERT INTO inp_files (actio_type, file_type, fname)
            VALUES %s
        """
        template = "(%s, %s, %s)"

        # Execute batch update
        toolsdb_execute_values(sql, params, template, fetch=False, commit=self.force_commit)
        self.results["files"] = len(self.network[FILES])

    def _create_workcat_id(self):
        sql = """
            INSERT INTO cat_work (id, descript, builtdate, active)
            VALUES (%s, %s, %s, TRUE)
        """
        description = f"Importing the file {self.filepath.name}"
        builtdate: date = date.today()

        execute_sql(
            sql,
            (self.workcat, description, builtdate),
            commit=self.force_commit,
            is_thread=True,
        )

    def _create_new_node_catalogs(self):
        cat_node_ids = get_rows("SELECT id FROM cat_node", commit=self.force_commit, is_thread=True)
        nodecat_db: list[str] = []
        if cat_node_ids:
            nodecat_db = [x[0] for x in cat_node_ids]

        node_catalogs = ["junctions", "outfalls", "dividers", "storage"]

        for node_type in node_catalogs:
            if node_type not in self.catalogs:
                continue

            if self.catalogs[node_type] in nodecat_db:
                continue

            nodetype_id: str = self.catalogs["features"][node_type]

            sql = """
                INSERT INTO cat_node (id, node_type)
                VALUES (%s, %s)
            """
            execute_sql(
                sql,
                (self.catalogs[node_type], nodetype_id),
                commit=self.force_commit,
                is_thread=True,
            )
            nodecat_db.append(self.catalogs[node_type])

    def _create_new_varc_catalogs(self) -> None:
        varc_catalogs: list[str] = ["pumps", "orifices", "weirs", "outlets"]

        # cat_mat_arc has an INSERT rule.
        # So it's not possible to use ON CONFLICT.
        # So, we perform a conditional INSERT here.
        execute_sql(
            """
            INSERT INTO cat_material (id, descript, feature_type, n)
            SELECT 'Unknown', 'Unknown', '{NODE,ARC,CONNEC,ELEMENT,GULLY}', 0.013
            WHERE NOT EXISTS (
                SELECT 1
                FROM cat_material
                WHERE id = 'Unknown'
            );
            """,
            commit=self.force_commit,
            is_thread=True,
        )

        for varc_type in varc_catalogs:
            if varc_type not in self.catalogs:
                continue

            if self.manage_flwreg.get(varc_type):
                # Create the 'VARC' if it doesn't exist
                execute_sql("""
                    INSERT INTO cat_feature (
                        id, feature_class, feature_type, shortcut_key, parent_layer,
                        child_layer, descript, link_path, code_autofill, active,
                        addparam, inventory_vdefault
                    ) VALUES (
                        'VARC', 'VARC', 'ARC', NULL, 've_arc',
                        've_arc_varc', 'Virtual Arc', NULL, true, true,
                        NULL, NULL
                    ) ON CONFLICT DO NOTHING;
                """, commit=self.force_commit, is_thread=True)
                # Just create the 'VARC' catalog to temporarly insert them as varcs
                execute_sql("""
                    INSERT INTO cat_arc (id, arc_type, shape, geom1)
                    VALUES ('VARC', 'VARC', 'VIRTUAL', 0) ON CONFLICT DO NOTHING;
                """,
                commit=self.force_commit, is_thread=True
                )
                continue

            if self.catalogs[varc_type] in self.arccat_db:
                continue

            sql = """
                INSERT INTO cat_arc (id, arc_type, shape, geom1)
                VALUES (%s, %s, 'VIRTUAL', 0)
            """
            _id = self.catalogs[varc_type]
            arctype_id = self.catalogs["features"][varc_type]
            execute_sql(sql, (_id, arctype_id), commit=self.force_commit, is_thread=True)
            self.arccat_db.append(_id)

    def _create_new_conduit_catalogs(self):
        if "conduits" in self.catalogs:
            conduit_catalog = self.catalogs["conduits"].items()
            for (shape, geom1, geom2, geom3, geom4), catalog in conduit_catalog:
                if catalog in self.arccat_db:
                    continue

                arctype_id = self.catalogs["features"]["conduits"]

                sql = """
                    INSERT INTO cat_arc (id, arc_type, shape, geom1, geom2, geom3, geom4)
                    VALUES (%s, %s, %s, %s, %s, %s, %s);
                """
                params = (catalog, arctype_id, shape, geom1, geom2, geom3, geom4)

                if shape == 'CUSTOM':
                    sql = """
                        INSERT INTO cat_arc (id, arc_type, shape, geom1, curve_id)
                        VALUES (%s, %s, %s, %s, %s);
                    """
                    params = (catalog, arctype_id, shape, geom1, geom2)

                execute_sql(
                    sql, params, commit=self.force_commit, is_thread=True
                )
                self.arccat_db.append(catalog)

    def _create_new_flwreg_catalogs(self):
        cat_flwreg_ids = get_rows("""SELECT ce.id, ce.element_type
                                        FROM cat_element ce
                                        JOIN cat_feature cf ON (ce.element_type = cf.id)
                                        WHERE cf.feature_class = 'FRELEM'""", commit=self.force_commit, is_thread=True)
        flwregcat_db: list[str] = []
        if cat_flwreg_ids:
            flwregcat_db = [x[0] for x in cat_flwreg_ids]

        flwreg_catalogs: list[str] = ["pumps", "orifices", "weirs", "outlets"]
        for flwreg_type in flwreg_catalogs:
            if flwreg_type not in self.catalogs:
                continue

            if not self.manage_flwreg.get(flwreg_type):
                continue

            if self.catalogs[flwreg_type] in flwregcat_db:
                continue

            flwregtype_id: str = self.catalogs["features"][flwreg_type]
            sql = """
                INSERT INTO cat_element (id, element_type)
                VALUES (%s, %s)
            """
            execute_sql(
                sql,
                (self.catalogs[flwreg_type], flwregtype_id),
                commit=self.force_commit,
                is_thread=True,
            )
            flwregcat_db.append(self.catalogs[flwreg_type])

    def _save_patterns(self):
        from swmm_api.input_file.section_labels import PATTERNS

        pattern_rows = get_rows("SELECT pattern_id FROM inp_pattern", commit=self.force_commit, is_thread=True)
        patterns_db: list[str] = []
        if pattern_rows:
            patterns_db = [x[0] for x in pattern_rows]

        self.results["patterns"] = 0
        for pattern_name, pattern in self.network[PATTERNS].items():
            if pattern_name in patterns_db:
                for i in count(2):
                    new_name = f"{pattern_name}_{i}"
                    if new_name in patterns_db:
                        continue
                    message = 'The pattern "{0}" has been renamed to "{1}" to avoid a collision with an existing pattern.'
                    self._log_message(tools_qt.tr(message, list_params=(pattern_name, new_name)))
                    self.mappings["patterns"][pattern_name] = new_name
                    pattern_name = new_name
                    break

            pattern_type = pattern.cycle
            execute_sql(
                "INSERT INTO inp_pattern (pattern_id, pattern_type) VALUES (%s, %s)",
                (pattern_name, pattern_type),
                commit=self.force_commit,
                is_thread=True,
            )

            fields_str = "pattern_id"
            values_str = "%s"
            values = (pattern_name,)
            for idx, f in enumerate(pattern.factors):
                fields_str += f",factor_{idx + 1}"
                values_str += ",%s"
                values += (f,)

            sql = (
                f"INSERT INTO inp_pattern_value ({fields_str}) "
                f"VALUES ({values_str})"
            )
            execute_sql(sql, values, commit=self.force_commit, is_thread=True)
            self.results["patterns"] += 1

    def _save_curves(self) -> None:
        from swmm_api.input_file.section_labels import CURVES

        curve_rows = get_rows("SELECT id FROM inp_curve", commit=self.force_commit, is_thread=True)
        curves_db: set[str] = set()
        if curve_rows:
            curves_db = {x[0] for x in curve_rows}

        self.results["curves"] = 0
        for curve_name, curve in self.network[CURVES].items():
            if curve.kind is None:
                message = 'The "{0}" curve does not have a specified curve type and was not imported.'
                self._log_message(tools_qt.tr(message, list_params=(curve_name,)))
                continue

            if curve_name in curves_db:
                for i in count(2):
                    new_name = f"{curve_name}_{i}"
                    if new_name in curves_db:
                        continue
                    message = 'The curve "{0}" has been renamed to "{1}" to avoid a collision with an existing curve.'
                    self._log_message(tools_qt.tr(message, list_params=(curve_name, new_name)))
                    self.mappings["curves"][curve_name] = new_name
                    curve_name = new_name
                    break

            curve_type: str = curve.kind

            execute_sql(
                "INSERT INTO inp_curve (id, curve_type) VALUES (%s, %s)",
                (curve_name, curve_type),
                commit=self.force_commit,
                is_thread=True,
            )

            for x, y in curve.points:
                execute_sql(
                    "INSERT INTO inp_curve_value (curve_id, x_value, y_value) VALUES (%s, %s, %s)",
                    (curve_name, x, y),
                    commit=self.force_commit,
                    is_thread=True,
                )
            self.results["curves"] += 1

    def _save_timeseries(self) -> None:
        from swmm_api.input_file.section_labels import TIMESERIES
        from swmm_api.input_file.sections import TimeseriesData, TimeseriesFile

        ts_rows = get_rows("SELECT id FROM inp_timeseries", commit=self.force_commit, is_thread=True)
        ts_db: set[str] = set()
        if ts_rows:
            ts_db = {x[0] for x in ts_rows}

        def format_ts(ts_data: tuple) -> tuple:
            ts_data_f = tuple()
            if not ts_data:
                return ts_data_f

            def format_time(time, value) -> tuple:
                if isinstance(time, float):
                    total_minutes = int(time * 60)
                    hh = total_minutes // 60
                    mm = total_minutes % 60
                    return (f"{hh:02}:{mm:02}", value)
                if isinstance(time, datetime):
                    date_str = time.strftime("%m/%d/%Y")
                    time_str = time.strftime("%H:%M")
                    return (f"{date_str}", f"{time_str}", value)
                return tuple()

            ts_data_f = format_time(ts_data[0], ts_data[1])
            return ts_data_f

        self.results["timeseries"] = 0
        for ts_name, ts in self.network[TIMESERIES].items():
            if ts is None:
                message = 'The timeseries "{0}" was not imported.'
                self._log_message(tools_qt.tr(message, list_params=(ts_name,)))
                continue

            if ts_name in ts_db:
                for i in count(2):
                    new_name = f"{ts_name}_{i}"
                    if new_name in ts_db:
                        continue
                    message = 'The timeseries "{0}" has been renamed to "{1}" to avoid a collision with an existing timeseries.'
                    self._log_message(tools_qt.tr(message, list_params=(ts_name, new_name)))
                    self.mappings["timeseries"][ts_name] = new_name
                    ts_name = new_name
                    break

            fname = None
            times_type = None
            if type(ts) is TimeseriesFile:  # TODO: import timeseries from file?
                fname = ts.filename
                times_type = "FILE"
            elif type(ts) is TimeseriesData:
                times_type = "ABSOLUTE" if isinstance(ts.data[0][0], datetime) else "RELATIVE"

            execute_sql(
                "INSERT INTO inp_timeseries (id, timser_type, times_type, fname) VALUES (%s, 'Other', %s, %s)",
                (ts_name, times_type, fname),
                commit=self.force_commit,
                is_thread=True,
            )

            if times_type == "FILE":  # TODO: import timeseries from file?
                continue

            for ts_data in ts.data:
                ts_data_f = format_ts(ts_data)
                if len(ts_data_f) == 2:
                    fields = "timser_id, time, value"
                    values = "%s, %s, %s"
                elif len(ts_data_f) == 3:
                    fields = "timser_id, date, hour, value"
                    values = "%s, %s, %s, %s"
                else:
                    continue

                execute_sql(
                    f"INSERT INTO inp_timeseries_value ({fields}) VALUES ({values})",
                    (ts_name,) + ts_data_f,
                    commit=self.force_commit,
                    is_thread=True,
                )
            self.results["timeseries"] += 1

    def _save_controls(self) -> None:
        from swmm_api.input_file.section_labels import CONTROLS

        controls_rows = get_rows("SELECT text FROM inp_controls", commit=self.force_commit, is_thread=True)
        controls_db: set[str] = set()
        if controls_rows:
            controls_db = {x[0] for x in controls_rows}

        self.results["controls"] = 0
        for control_name, control in self.network[CONTROLS].items():
            text = control.to_inp_line()
            if text in controls_db:
                msg = "The control '{0}' is already on database. Skipping..."
                msg_params = (control_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            sql = "INSERT INTO inp_controls (sector_id, text, active) VALUES (%s, %s, true)"
            params = (self.sector, text)
            execute_sql(sql, params, commit=self.force_commit, is_thread=True)
            self.results["controls"] += 1

    def _save_lids(self) -> None:
        from swmm_api.input_file.section_labels import LID_CONTROLS

        lid_rows = get_rows("SELECT lidco_id FROM inp_lid", commit=self.force_commit, is_thread=True)
        lids_db: set[str] = set()
        if lid_rows:
            lids_db = {x[0] for x in lid_rows}

        self.results["lids"] = 0
        for lid_name, lid in self.network[LID_CONTROLS].items():
            if lid_name in lids_db:
                # Manage if lid already exists
                for i in count(2):
                    new_name = f"{lid_name}_{i}"
                    if new_name in lids_db:
                        continue
                    message = 'The lid "{0}" has been renamed to "{1}" to avoid a collision with an existing lid.'
                    self._log_message(tools_qt.tr(message, list_params=(lid_name, new_name)))
                    self.mappings["lids"][lid_name] = new_name
                    lid_name = new_name
                    break

            lid_type: str = lid.lid_kind
            sql = "INSERT INTO inp_lid (lidco_id, lidco_type) VALUES (%s, %s)"
            params = (lid_name, lid_type)
            execute_sql(sql, params, commit=self.force_commit, is_thread=True)

            # Insert lid_values
            sql = """
                INSERT INTO inp_lid_value (lidco_id, lidlayer, value_2, value_3, value_4, value_5, value_6, value_7, value_8)
                VALUES %s
            """
            template = "(%s, %s, %s, %s, %s, %s, %s, %s, %s)"
            params = []
            for k, v in lid.layer_dict.items():
                if k == 'SURFACE':
                    lid_values = (lid_name, k, v.StorHt, v.VegFrac, v.Rough, v.Slope, v.Xslope, None, None)
                elif k == 'SOIL':
                    lid_values = (lid_name, k, v.Thick, v.Por, v.FC, v.WP, v.Ksat, v.Kcoeff, v.Suct)
                elif k == 'PAVEMENT':
                    lid_values = (lid_name, k, v.Thick, v.Vratio, v.FracImp, v.Perm, v.Vclog, v.regeneration_interval, v.regeneration_fraction)
                elif k == 'STORAGE':
                    lid_values = (lid_name, k, v.Height, v.Vratio, v.Seepage, v.Vclog, v.Covrd, None, None)
                elif k == 'DRAIN':
                    lid_values = (lid_name, k, v.Coeff, v.Expon, v.Offset, v.Delay, v.open_level, v.close_level, v.Qcurve)
                elif k == 'DRAINMAT':
                    lid_values = (lid_name, k, v.Thick, v.Vratio, v.Rough, None, None, None, None)
                else:
                    continue
                params.append(lid_values)
            toolsdb_execute_values(sql, params, template, commit=self.force_commit)
            self.results["lids"] += 1

    def _save_junctions(self) -> None:
        from swmm_api.input_file.section_labels import JUNCTIONS, COORDINATES

        feature_class = self.catalogs['features']['junctions']

        node_sql = """ 
            INSERT INTO node (
                the_geom, code, node_type, nodecat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, elev, ymax
            ) VALUES %s
            RETURNING node_id, code
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.split('_')[-1].lower()} (
                node_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_junction (
                node_id, y0, ysur, apond
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s)"
        )

        node_params = []

        inp_dict = {}

        for j_name, j in self.network[JUNCTIONS].items():
            if j_name not in self.network[COORDINATES]:
                msg = "ERROR: JUNCTION '{0}' has no coordinates in [COORDINATES] section."
                msg_params = (j_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            x, y = self.network[COORDINATES][j_name].x, self.network[COORDINATES][j_name].y
            srid = lib_vars.data_epsg
            node_type = feature_class
            nodecat_id = self.catalogs["junctions"]
            epa_type = "JUNCTION"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            node_params.append(
                (
                    x, y, srid,  # the_geom
                    j_name,  # code
                    node_type,
                    nodecat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                    j.elevation,
                    j.depth_max,
                )
            )
            inp_dict[j_name] = {
                "y0": j.depth_init,
                "ysur": j.depth_surcharge,
                "apond": j.area_ponded,
                "outfallparam": None,
            }

        # Insert into parent table
        junctions = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(junctions)
        self.results["junctions"] = len(junctions) if junctions else 0
        if not junctions:
            self._log_message("Junctions couldn't be inserted!")
            return

        man_params = []
        inp_params = []

        for j in junctions:
            node_id = j[0]
            code = j[1]

            self.node_ids[code] = node_id

            man_params.append(
                (node_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (node_id, inp_data["y0"], inp_data["ysur"], inp_data["apond"])
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_outfalls(self) -> None:
        from swmm_api.input_file.section_labels import OUTFALLS, COORDINATES

        feature_class = self.catalogs['features']['outfalls']

        node_sql = """ 
            INSERT INTO node (
                the_geom, code, node_type, nodecat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, elev
            ) VALUES %s
            RETURNING node_id, code
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.split('_')[-1].lower()} (
                node_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_outfall (
                node_id, outfall_type, stage, curve_id, timser_id, gate, route_to
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s)"
        )

        node_params = []

        inp_dict = {}

        for o_name, o in self.network[OUTFALLS].items():
            if o_name not in self.network[COORDINATES]:
                msg = "ERROR: OUTFALL '{0}' has no coordinates in [COORDINATES] section."
                msg_params = (o_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            x, y = self.network[COORDINATES][o_name].x, self.network[COORDINATES][o_name].y
            srid = lib_vars.data_epsg
            nodecat_id = self.catalogs["outfalls"]
            epa_type = "OUTFALL"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            elevation = o.elevation
            node_params.append(
                (
                    x, y, srid,  # the_geom
                    o_name,  # code
                    feature_class,
                    nodecat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                    elevation
                )
            )
            inp_dict[o_name] = {
                "outfall_type": o.kind,
                "stage": o.data if o.kind == 'FIXED' else None,
                "curve_id": o.data if o.kind == 'TIDAL' else None,
                "timser_id": o.data if o.kind == 'TIMESERIES' else None,
                "gate": to_yesno(o.has_flap_gate),
                "route_to": nan_to_none(o.route_to)
            }

        # Insert into parent table
        outfalls = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(outfalls)
        self.results["outfalls"] = len(outfalls) if outfalls else 0
        if not outfalls:
            msg = "Outfalls couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []

        for o in outfalls:
            node_id = o[0]
            code = o[1]

            self.node_ids[code] = node_id

            man_params.append(
                (node_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (node_id, inp_data["outfall_type"], inp_data["stage"], inp_data["curve_id"], inp_data["timser_id"], inp_data["gate"], inp_data["route_to"])
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_dividers(self) -> None:
        from swmm_api.input_file.section_labels import DIVIDERS, COORDINATES

        feature_class = self.catalogs['features']['dividers']

        node_sql = """ 
            INSERT INTO node (
                the_geom, code, node_type, nodecat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, elev
            ) VALUES %s
            RETURNING node_id, code
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.split('_')[-1].lower()} (
                node_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_divider (
                node_id, divider_type, arc_id, curve_id, qmin, ht, cd, y0, ysur, apond
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        node_params = []

        inp_dict = {}

        for d_name, d in self.network[DIVIDERS].items():
            if d_name not in self.network[COORDINATES]:
                msg = "ERROR: DIVIDER '{0}' has no coordinates in [COORDINATES] section."
                msg_params = (d_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            x, y = self.network[COORDINATES][d_name].x, self.network[COORDINATES][d_name].y
            srid = lib_vars.data_epsg
            nodecat_id = self.catalogs["dividers"]
            epa_type = "DIVIDER"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            elevation = d.elevation
            node_params.append(
                (
                    x, y, srid,  # the_geom
                    d_name,  # code
                    feature_class,
                    nodecat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                    elevation,
                )
            )
            inp_dict[d_name] = {
                "divider_type": d.kind,
                "arc_id": d.link,
                "curve_id": d.data if d.kind == "TABULAR" else None,
                "qmin": (d.data[0] if isinstance(d.data, tuple) else d.data) if d.kind in ("WEIR", "CUTOFF") else None,
                "ht": d.data[1] if d.kind == "WEIR" else None,
                "cd": d.data[2] if d.kind == "WEIR" else None,
                "y0": d.depth_init,
                "ysur": d.depth_surcharge,
                "apond": d.area_ponded,
            }

        # Insert into parent table
        dividers = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(dividers)
        self.results["dividers"] = len(dividers) if dividers else 0
        if not dividers:
            msg = "Dividers couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []

        for d in dividers:
            node_id = d[0]
            code = d[1]

            self.node_ids[code] = node_id

            man_params.append(
                (node_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (node_id, inp_data["divider_type"], None, inp_data["curve_id"],
                 inp_data["qmin"], inp_data["ht"], inp_data["cd"], inp_data["y0"], inp_data["ysur"], inp_data["apond"])
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_storage(self) -> None:
        from swmm_api.input_file.section_labels import STORAGE, COORDINATES

        feature_class = self.catalogs['features']['storage']

        node_sql = """ 
            INSERT INTO node (
                the_geom, code, node_type, nodecat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, elev
            ) VALUES %s
            RETURNING node_id, code
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.split('_')[-1].lower()} (
                node_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_storage (
                node_id, storage_type, curve_id, a1, a2, a0, fevap, sh, hc, imd, y0, ysur
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        node_params = []

        inp_dict = {}

        for s_name, s in self.network[STORAGE].items():
            if s_name not in self.network[COORDINATES]:
                msg = "ERROR: STORAGE '{0}' has no coordinates in [COORDINATES] section."
                msg_params = (s_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            x, y = self.network[COORDINATES][s_name].x, self.network[COORDINATES][s_name].y
            srid = lib_vars.data_epsg
            nodecat_id = self.catalogs["storage"]
            epa_type = "STORAGE"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            elevation = s.elevation
            node_params.append(
                (
                    x, y, srid,  # the_geom
                    s_name,  # code
                    feature_class,
                    nodecat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                    elevation,
                )
            )
            inp_dict[s_name] = {
                "storage_type": s.kind,
                "curve_id": s.data if s.kind == "TABULAR" else None,
                "a1": s.data[0] if s.kind == "FUNCTIONAL" else None,
                "a2": s.data[1] if s.kind == "FUNCTIONAL" else None,
                "a0": s.data[2] if s.kind == "FUNCTIONAL" else None,
                "fevap": s.frac_evaporation,
                "sh": s.suction_head,
                "hc": s.hydraulic_conductivity,
                "imd": s.moisture_deficit_init,
                "y0": s.depth_init,
                "ysur": s.depth_surcharge,
            }

        # Insert into parent table
        storage = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(storage)
        self.results["storage"] = len(storage) if storage else 0
        if not storage:
            msg = "Storage units couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []

        for s in storage:
            node_id = s[0]
            code = s[1]

            self.node_ids[code] = node_id

            man_params.append(
                (node_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (node_id, inp_data["storage_type"], inp_data["curve_id"], inp_data["a1"], inp_data["a2"], inp_data["a0"],
                 inp_data["fevap"], inp_data["sh"], inp_data["hc"], inp_data["imd"], inp_data["y0"], inp_data["ysur"],
                )
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_pumps(self) -> None:
        from swmm_api.input_file.section_labels import PUMPS

        feature_class = self.catalogs['features']['pumps']
        arccat_id = self.catalogs["pumps"]
        # Set 'fake' catalogs if it will be converted to flwreg
        if self.manage_flwreg["pumps"]:
            feature_class = "VARC"
            arccat_id = "VARC"

        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arc_type, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, dma_id
            ) VALUES %s
            RETURNING arc_id, code
        """
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 0)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.lower()} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_pump (
                arc_id, curve_id, status, startup, shutoff
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s)"
        )

        arc_params = []

        inp_dict = {}

        for p_name, p in self.network[PUMPS].items():
            geometry = get_geometry_from_link(self.network, p)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[p.from_node]
                node_2 = self.node_ids[p.to_node]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            epa_type = "PUMP"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            arc_params.append(
                (
                    geometry, srid,  # the_geom
                    p_name,  # code
                    node_1,
                    node_2,
                    feature_class,
                    arccat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                )
            )
            inp_dict[p_name] = {
                "curve_id": p.curve_name,
                "status": p.status,
                "startup": p.depth_on,
                "shutoff": p.depth_off,
            }

        # Insert into parent table
        pumps = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(pumps)
        self.results["pumps"] = len(pumps) if pumps else 0
        if not pumps:
            msg = "Pumps couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []
        self.flwreg_ids["pumps"] = []

        for p in pumps:
            arc_id = p[0]
            code = p[1]
            man_params.append(
                (arc_id,)
            )
            if self.manage_flwreg["pumps"]:
                self.flwreg_ids["pumps"].append(arc_id)

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["curve_id"], inp_data["status"], inp_data["startup"], inp_data["shutoff"])
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_orifices(self) -> None:
        from swmm_api.input_file.section_labels import ORIFICES, XSECTIONS

        feature_class = self.catalogs['features']['orifices']
        arccat_id = self.catalogs["orifices"]
        # Set 'fake' catalogs if it will be converted to flwreg
        if self.manage_flwreg["orifices"]:
            feature_class = "VARC"
            arccat_id = "VARC"

        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arc_type, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, dma_id
            ) VALUES %s
            RETURNING arc_id, code
        """
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 0)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.lower()} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_orifice (
                arc_id, ori_type, offsetval, cd, orate, flap, shape, geom1, geom2, geom3, geom4
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        arc_params = []

        inp_dict = {}

        for o_name, o in self.network[ORIFICES].items():
            geometry = get_geometry_from_link(self.network, o)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[o.from_node]
                node_2 = self.node_ids[o.to_node]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            xs = self.network[XSECTIONS][o_name]
            epa_type = "ORIFICE"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            arc_params.append(
                (
                    geometry, srid,  # the_geom
                    o_name,  # code
                    node_1,
                    node_2,
                    feature_class,
                    arccat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                )
            )
            inp_dict[o_name] = {
                "ori_type": o.orientation,
                "offsetval": o.offset,
                "cd": o.discharge_coefficient,
                "orate": o.hours_to_open,
                "flap": to_yesno(o.has_flap_gate),
                "shape": xs.shape,
                "geom1": xs.height,
                "geom2": xs.parameter_2,
                "geom3": xs.parameter_3,
                "geom4": xs.parameter_4,
            }

        # Insert into parent table
        orifices = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(orifices)
        self.results["orifices"] = len(orifices) if orifices else 0
        if not orifices:
            msg = "Orifices couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []
        self.flwreg_ids["orifices"] = []

        for o in orifices:
            arc_id = o[0]
            code = o[1]
            man_params.append(
                (arc_id,)
            )
            if self.manage_flwreg["orifices"]:
                self.flwreg_ids["orifices"].append(arc_id)

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["ori_type"], inp_data["offsetval"], inp_data["cd"], inp_data["orate"], inp_data["flap"],
                 inp_data["shape"], inp_data["geom1"], inp_data["geom2"], inp_data["geom3"], inp_data["geom4"],
                )
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_weirs(self) -> None:
        from swmm_api.input_file.section_labels import WEIRS, XSECTIONS

        feature_class = self.catalogs['features']['weirs']
        arccat_id = self.catalogs["weirs"]
        # Set 'fake' catalogs if it will be converted to flwreg
        if self.manage_flwreg["weirs"]:
            feature_class = "VARC"
            arccat_id = "VARC"

        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arc_type, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, dma_id
            ) VALUES %s
            RETURNING arc_id, code
        """  # --"depth", arc_id, annotation, observ, "comment", label_x, label_y, label_rotation, staticpressure, feature_type
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 0)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.lower()} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_weir (
                arc_id, weir_type, offsetval, cd, ec, cd2, flap, geom1, geom2, geom3, geom4, surcharge, road_width, road_surf, coef_curve
            ) VALUES %s
        """  # --
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        arc_params = []

        inp_dict = {}

        for w_name, w in self.network[WEIRS].items():
            geometry = get_geometry_from_link(self.network, w)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[w.from_node]
                node_2 = self.node_ids[w.to_node]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            xs = self.network[XSECTIONS][w_name]
            epa_type = "WEIR"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            arc_params.append(
                (
                    geometry, srid,  # the_geom
                    w_name,  # code
                    node_1,
                    node_2,
                    feature_class,
                    arccat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                )
            )
            inp_dict[w_name] = {
                "weir_type": w.form,
                "offsetval": w.height_crest,
                "cd": w.discharge_coefficient,
                "ec": w.n_end_contractions,
                "cd2": w.discharge_coefficient_end,
                "flap": to_yesno(w.has_flap_gate),
                "geom1": xs.height,
                "geom2": xs.parameter_2,
                "geom3": xs.parameter_3,
                "geom4": xs.parameter_4,
                "surcharge": to_yesno(w.can_surcharge),
                "road_width": nan_to_none(w.road_width),
                "road_surf": nan_to_none(w.road_surface),
                "coef_curve": nan_to_none(w.coefficient_curve),
            }

        # Insert into parent table
        weirs = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(weirs)
        self.results["weirs"] = len(weirs) if weirs else 0
        if not weirs:
            msg = "Weirs couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []
        self.flwreg_ids["weirs"] = []

        for w in weirs:
            arc_id = w[0]
            code = w[1]
            man_params.append(
                (arc_id,)
            )
            if self.manage_flwreg["weirs"]:
                self.flwreg_ids["weirs"].append(arc_id)

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["weir_type"], inp_data["offsetval"], inp_data["cd"], inp_data["ec"], inp_data["cd2"],
                 inp_data["flap"], inp_data["geom1"], inp_data["geom2"], inp_data["geom3"], inp_data["geom4"],
                 inp_data["surcharge"], inp_data["road_width"], inp_data["road_surf"], inp_data["coef_curve"],
                )
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_outlets(self) -> None:
        from swmm_api.input_file.section_labels import OUTLETS, JUNCTIONS

        feature_class = self.catalogs['features']['outlets']
        arccat_id = self.catalogs["outlets"]
        # Set 'fake' catalogs if it will be converted to flwreg
        if self.manage_flwreg["outlets"]:
            feature_class = "VARC"
            arccat_id = "VARC"

        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arc_type, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, dma_id
            ) VALUES %s
            RETURNING arc_id, code
        """
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, 0)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.lower()} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_outlet (
                arc_id, outlet_type, offsetval, curve_id, cd1, cd2, flap
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s)"
        )

        arc_params = []

        inp_dict = {}

        for o_name, o in self.network[OUTLETS].items():
            geometry = get_geometry_from_link(self.network, o)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[o.from_node]
                node_2 = self.node_ids[o.to_node]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            epa_type = "OUTLET"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            arc_params.append(
                (
                    geometry, srid,  # the_geom
                    o_name,  # code
                    node_1,
                    node_2,
                    feature_class,
                    arccat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                )
            )
            inp_dict[o_name] = {
                "outlet_type": o.curve_type,
                "offsetval": o.offset if o.offset != '*' else self.network[JUNCTIONS][o.from_node].elevation,
                "curve_id": o.curve_description if o.curve_type in ("TABULAR/DEPTH", "TABULAR/HEAD") else None,  # TODO: use enum
                "cd1": o.curve_description[0] if o.curve_type in ("FUNCTIONAL/DEPTH", "FUNCTIONAL/HEAD") else None,
                "cd2": o.curve_description[1] if o.curve_type in ("FUNCTIONAL/DEPTH", "FUNCTIONAL/HEAD") else None,
                "flap": to_yesno(o.has_flap_gate),
            }

        # Insert into parent table
        outlets = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(outlets)
        self.results["outlets"] = len(outlets) if outlets else 0
        if not outlets:
            msg = "Outlets couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []
        self.flwreg_ids["outlets"] = []

        for o in outlets:
            arc_id = o[0]
            code = o[1]
            man_params.append(
                (arc_id,)
            )
            if self.manage_flwreg["outlets"]:
                self.flwreg_ids["outlets"].append(arc_id)

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["outlet_type"], inp_data["offsetval"], inp_data["curve_id"],
                 inp_data["cd1"], inp_data["cd2"], inp_data["flap"],
                )
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_conduits(self) -> None:
        from swmm_api.input_file.section_labels import CONDUITS, XSECTIONS, LOSSES

        feature_class = self.catalogs['features']['conduits']
        # TODO: get rid of dma_id
        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arc_type, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, dma_id
            ) VALUES %s
            RETURNING arc_id, code
        """
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO man_{feature_class.split('_')[-1].lower()} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_conduit (
                arc_id, barrels, culvert, kentry, kexit, kavg, flap, q0, qmax, seepage, custom_n
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        arc_params = []

        inp_dict = {}

        for c_name, c in self.network[CONDUITS].items():
            geometry = get_geometry_from_link(self.network, c)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[c.from_node]
                node_2 = self.node_ids[c.to_node]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            xs = self.network[XSECTIONS][c_name]
            if xs.shape == "CUSTOM":
                arccat_id = self.catalogs["conduits"][(xs.shape, xs.height, xs.curve_name, xs.parameter_3, xs.parameter_4)]
            else:
                arccat_id = self.catalogs["conduits"][(xs.shape, xs.height, xs.parameter_2, xs.parameter_3, xs.parameter_4)]
            epa_type = "CONDUIT"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            dma_id = 0  # TODO: get rid of dma_id
            arc_params.append(
                (
                    geometry,
                    srid,
                    c_name,
                    node_1,
                    node_2,
                    feature_class,
                    arccat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                    dma_id,  # TODO: get rid of dma_id
                )
            )
            inp_dict[c_name] = {
                "barrels": xs.n_barrels,
                "culvert": nan_to_none(xs.culvert),
                "kentry": None,
                "kexit": None,
                "kavg": None,
                "flap": None,
                "q0": c.flow_initial,
                "qmax": nan_to_none(c.flow_max),
                "seepage": None,
                "custom_n": None,
            }
            if c_name in self.network[LOSSES]:
                loss = self.network[LOSSES][c_name]
                inp_dict[c_name]["kentry"] = loss.entrance
                inp_dict[c_name]["kexit"] = loss.exit
                inp_dict[c_name]["kavg"] = loss.average
                inp_dict[c_name]["flap"] = to_yesno(loss.has_flap_gate)
                inp_dict[c_name]["seepage"] = loss.seepage_rate

        # Insert into parent table
        conduits = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(conduits)
        self.results["conduits"] = len(conduits) if conduits else 0
        if not conduits:
            msg = "Conduits couldn't be inserted!"
            self._log_message(tools_qt.tr(msg)) 
            return

        man_params = []
        inp_params = []

        for c in conduits:
            arc_id = c[0]
            code = c[1]
            man_params.append(
                (arc_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["barrels"], inp_data["culvert"], inp_data["kentry"], inp_data["kexit"], inp_data["kavg"],
                 inp_data["flap"], inp_data["q0"], inp_data["qmax"], inp_data["seepage"], inp_data["custom_n"],
                 )
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_raingages(self) -> None:
        from swmm_api.input_file.section_labels import RAINGAGES, SYMBOLS

        node_sql = """ 
            INSERT INTO raingage (
                the_geom, expl_id, muni_id, rg_id, form_type, intvl, scf, rgage_type, timser_id, fname, sta, units
            ) VALUES %s
            RETURNING rg_id
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )
        node_params = []

        for rg_name, rg in self.network[RAINGAGES].items():
            if rg_name not in self.network[SYMBOLS]:
                msg = "ERROR: RAINGAGE '{0}' has no coordinates in [SYMBOLS] section."
                msg_params = (rg_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            x, y = self.network[SYMBOLS][rg_name].x, self.network[SYMBOLS][rg_name].y
            srid = lib_vars.data_epsg
            expl_id = self.exploitation
            muni_id = self.municipality
            form_type = rg.form
            intvl = rg.interval
            scf = rg.SCF
            rgage_type = rg.source
            timser_id = nan_to_none(rg.timeseries)
            fname = nan_to_none(rg.filename)
            sta = nan_to_none(rg.station)
            units = nan_to_none(rg.units)
            node_params.append(
                (
                    x, y, srid,  # the_geom
                    expl_id,
                    muni_id,
                    rg_name,  # code
                    form_type,
                    intvl,
                    scf,
                    rgage_type,
                    timser_id,
                    fname,
                    sta,
                    units
                )
            )

        # Insert into parent table
        raingages = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            print(raingages)
        self.results["raingages"] = len(raingages) if raingages else 0
        if not raingages:
            msg = "Raingages couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

    def _save_inflows(self):
        from swmm_api.input_file.section_labels import INFLOWS

        sql = """
            INSERT INTO inp_inflows (node_id, timser_id, sfactor, base, pattern_id)
            VALUES %s
            RETURNING order_id
        """
        template = "(%s, %s, %s, %s, %s)"
        params = []
        for i_name, i in self.network[INFLOWS].items():
            try:
                node_id = self.node_ids[i.node]
            except KeyError:
                continue
            timser_id = i.time_series if i.time_series not in ('""', '') else None
            sfactor = i.scale_factor
            base = i.base_value
            pattern_id = nan_to_none(i.pattern)
            params.append((node_id, timser_id, sfactor, base, pattern_id))
        inflows = toolsdb_execute_values(sql, params, template, fetch=True, commit=self.force_commit)
        self.results["inflows"] = len(inflows) if inflows else 0

    def _save_dwf(self):
        from swmm_api.input_file.section_labels import DWF

        sql = """
            INSERT INTO inp_dwf (dwfscenario_id, node_id, value, pat1, pat2, pat3, pat4)
            VALUES %s
            RETURNING dwfscenario_id, node_id
        """
        template = "(1, %s, %s, %s, %s, %s, %s)"
        params = []
        for dwf_name, dwf in self.network[DWF].items():
            try:
                node_id = self.node_ids[dwf.node]
            except KeyError:
                continue
            value = dwf.base_value
            pat1 = nan_to_none(dwf.pattern1)
            pat2 = nan_to_none(dwf.pattern2)
            pat3 = nan_to_none(dwf.pattern3)
            pat4 = nan_to_none(dwf.pattern4)
            params.append((node_id, value, pat1, pat2, pat3, pat4))
        dwfs = toolsdb_execute_values(sql, params, template, fetch=True, commit=self.force_commit)
        self.results["dwf"] = len(dwfs) if dwfs else 0

    def _save_subcatchments(self):
        from swmm_api.input_file.section_labels import SUBCATCHMENTS, SUBAREAS, INFILTRATION, ADJUSTMENTS, POLYGONS
        from swmm_api.input_file.sections import InfiltrationHorton, InfiltrationGreenAmpt, InfiltrationCurveNumber

        sql = """
            INSERT INTO inp_subcatchment (
                the_geom, subc_id, outlet_id, rg_id, area, imperv, width, slope, clength, snow_id, nimp, nperv, simp, sperv, zero, 
                routeto, rted, maxrate, minrate, decay, drytime, maxinfil, suction, conduct, initdef, curveno, 
                conduct_2, drytime_2, sector_id, hydrology_id, descript, nperv_pattern_id, dstore_pattern_id, 
                infil_pattern_id, minelev
            )
            VALUES %s
            RETURNING subc_id, hydrology_id
        """
        template = "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        params = []

        def get_attr(obj, attr: str):
            return getattr(obj, attr) if obj and hasattr(obj, attr) else None

        def get_adjustment(attr: str, subc_name: str):
            try:
                return self.network[ADJUSTMENTS][(attr, subc_name)]
            except (KeyError, AttributeError):
                return None

        def get_subc_geom(subc):
            coordinates = []
            # Get coordinates from [POLYGONS] section
            if subc.name in self.network[POLYGONS]:
                coordinates = self.network[POLYGONS][subc.name].polygon
            # If there are no coordinates or there are less than 3 distinct points, it isn't a valid polygon.
            if not coordinates or len(list(dict.fromkeys(coordinates))) < 3:
                return None

            # Ensure the polygon is closed by repeating the first coordinate if necessary
            if coordinates[0] != coordinates[-1]:
                coordinates.append(coordinates[0])

            # Create a WKT string for the polygon
            wkt = f"POLYGON(({', '.join(f'{x} {y}' for x, y in coordinates)}))"
            return wkt

        for subc_name, subc in self.network[SUBCATCHMENTS].items():
            subarea = self.network[SUBAREAS].get(subc_name)

            infiltration = self.network[INFILTRATION].get(subc_name)

            # [SUBCATCHMENTS]
            subc_id = subc_name
            outlet_id = self.node_ids[subc.outlet] if subc.outlet in self.node_ids else None  # TODO: show warning if outlet is * or not found in nodes
            rg_id = self.default_raingage if subc.rain_gage == '*' else subc.rain_gage  # TODO: show warning if raingage is *
            area = subc.area
            imperv = subc.imperviousness
            width = subc.width
            slope = subc.slope
            clength = subc.curb_length
            snow_id = nan_to_none(subc.snow_pack)
            # [SUBAREAS]
            nimp = get_attr(subarea, "n_imperv")
            nperv = get_attr(subarea, "n_perv")
            simp = get_attr(subarea, "storage_imperv")
            sperv = get_attr(subarea, "storage_perv")
            zero = get_attr(subarea, "pct_zero")
            routeto = get_attr(subarea, "route_to")
            rted = get_attr(subarea, "pct_routed")
            # [INFILTRATION] -- InfiltrationHorton
            maxrate = get_attr(infiltration, "rate_max")
            minrate = get_attr(infiltration, "rate_min")
            decay = get_attr(infiltration, "decay")
            drytime = get_attr(infiltration, "time_dry") if isinstance(infiltration, InfiltrationHorton) else None
            maxinfil = get_attr(infiltration, "volume_max")
            # [INFILTRATION] -- InfiltrationGreenAmpt
            suction = get_attr(infiltration, "suction_head")
            conduct = get_attr(infiltration, "hydraulic_conductivity") if isinstance(infiltration, InfiltrationGreenAmpt) else None
            initdef = get_attr(infiltration, "moisture_deficit_init")
            # [INFILTRATION] -- InfiltrationCurveNumber
            curveno = get_attr(infiltration, "curve_no")
            conduct_2 = get_attr(infiltration, "hydraulic_conductivity") if isinstance(infiltration, InfiltrationCurveNumber) else None
            drytime_2 = get_attr(infiltration, "time_dry") if isinstance(infiltration, InfiltrationCurveNumber) else None
            # Giswater columns
            sector_id = self.sector
            hydrology_id = 1  # TODO: get/create from cat_hydrology, depending on infiltration kind
            the_geom = get_subc_geom(subc)
            srid = lib_vars.data_epsg
            descript = None
            nperv_pattern_id = get_adjustment("N-PERV", subc_name)
            dstore_pattern_id = get_adjustment("DSTORE", subc_name)
            infil_pattern_id = get_adjustment("INFIL", subc_name)
            minelev = None
            params.append(
                (the_geom, srid, subc_id, outlet_id, rg_id, area, imperv, width, slope, clength, snow_id, nimp, nperv, simp, sperv, zero,
                 routeto, rted, maxrate, minrate, decay, drytime, maxinfil, suction, conduct, initdef, curveno,
                 conduct_2, drytime_2, sector_id, hydrology_id, descript, nperv_pattern_id, dstore_pattern_id,
                 infil_pattern_id, minelev)
            )
        subcatchments = toolsdb_execute_values(sql, params, template, fetch=True, commit=self.force_commit)
        self.results["subcatchments"] = len(subcatchments) if subcatchments else 0

    def _update_municipality(self):
        """ Update the muni_id of all features getting the spatial intersection with the municipality """

        sql = f"""
            UPDATE node n 
            SET muni_id = (SELECT m.muni_id FROM v_municipality m WHERE ST_Intersects(m.the_geom, n.the_geom) LIMIT 1) 
            WHERE workcat_id = '{self.workcat}' AND sector_id = {self.sector}
            AND EXISTS (SELECT 1 FROM v_municipality m WHERE ST_Intersects(m.the_geom, n.the_geom));

            UPDATE arc a 
            SET muni_id = (SELECT m.muni_id FROM v_municipality m WHERE ST_Intersects(m.the_geom, a.the_geom) LIMIT 1) 
            WHERE workcat_id = '{self.workcat}' AND sector_id = {self.sector}
            AND EXISTS (SELECT 1 FROM v_municipality m WHERE ST_Intersects(m.the_geom, a.the_geom));
        """
        execute_sql(sql, commit=self.force_commit, is_thread=True)

    def _log_message(self, message: str):
        self.log.append(message)
        self.progress_changed.emit("", None, f"{message}", True)
