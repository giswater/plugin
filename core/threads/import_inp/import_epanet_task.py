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

from qgis.PyQt.QtCore import pyqtSignal

from ....libs import lib_vars, tools_db, tools_os, tools_qt
from ...utils import tools_gw
from ..task import GwTask
from ...utils.import_inp import lerp_progress, batched, get_row, get_rows, execute_sql, toolsdb_execute_values


def get_geometry_from_link(link) -> str:

    start_node_x, start_node_y = link.start_node.coordinates
    end_node_x, end_node_y = link.end_node.coordinates
    vertices = link.vertices

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
        dscenario,
        catalogs,
        state,
        state_type,
        manage_nodarcs: dict[str, bool] = {"pumps": False, "valves": False},
        force_commit: bool = False,
    ) -> None:
        super().__init__(description)
        self.filepath = filepath
        self.network = network
        self.workcat: str = workcat
        self.exploitation: int = exploitation
        self.sector: int = sector
        self.municipality: int = municipality
        self.dscenario: str = dscenario
        self.dscenario_id: int = None
        self.catalogs: dict[str, Any] = catalogs
        self.state: int = state
        self.state_type: int = state_type
        self.force_commit: bool = force_commit
        self.update_municipality: bool = False
        self.manage_nodarcs: dict[str, bool] = manage_nodarcs
        self.log: list[str] = []
        self.mappings: dict[str, dict[str, str]] = {"curves": {}, "patterns": {}}
        self.arccat_db: list[str] = []
        self.db_units = None
        self.exception: str = ""
        self.debug_mode: bool = False  # TODO: add checkbox or something to manage debug_mode

        self.node_ids: dict[str, str] = {}
        self.arc_ids: dict[str, str] = {}

    def run(self) -> bool:
        super().run()
        try:
            from wntr.epanet.util import FlowUnits, HydParam, from_si  # noqa: F401
            from wntr.network.model import WaterNetworkModel  # noqa: F401
        except ImportError:
            self.exception = (
                "Python package 'wntr' is not installed. "
                "Please install it using pip or the 'qpip' QGIS plugin."
            )
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

            message = "Getting options"
            msg = "Getting units..."
            self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_OPTIONS, tools_qt.tr(msg), False)
            self._get_units()
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

            if self.network.num_sources > 0:
                message = "Sources"
                msg = "Importing sources..."
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_MUNICIPALITY, tools_qt.tr(msg), False)
                self._save_sources()
                msg = "done!"
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_SOURCES, tools_qt.tr(msg), True)

            # Enable plan and topocontrol triggers
            self._enable_triggers(False, plan_trigger=True, geometry_trigger=True)

            if any(self.manage_nodarcs.values()):
                message = "Nodarcs"
                msg = "Managing nodarcs (pumps/valves as nodes)..."
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_SOURCES, tools_qt.tr(msg), False)
                log_str = self._manage_nodarcs()
                msg = "done!"
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_END, tools_qt.tr(msg), True)
                self.progress_changed.emit(tools_qt.tr(message), self.PROGRESS_END, log_str, True)

            # Enable ALL triggers
            self._enable_triggers(True)

            execute_sql("select 1", commit=True, is_thread=True)
            msg = "\n\nALL DONE! INP successfully imported."
            self.progress_changed.emit("", self.PROGRESS_END, tools_qt.tr(msg), True)
            return True
        except Exception:
            self.exception = traceback.format_exc()
            self._log_message(f"{traceback.format_exc()}")
            tools_db.dao.rollback()
            return False

    def _manage_catalogs(self) -> None:
        message = "Create catalogs"
        msg = "Creating workcat..."
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(0, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        if self.state != 2:
            self._create_workcat_id()
        msg = "Creating demand dscenario..."
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(10, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        self._create_demand_dscenario()
        msg = "Creating new node catalogs..."
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(20, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        self._create_new_node_catalogs()

        # Get existing catalogs in DB
        cat_arc_ids = get_rows("SELECT id FROM cat_arc", commit=self.force_commit, is_thread=True)
        if cat_arc_ids:
            self.arccat_db += [x[0] for x in cat_arc_ids]

        msg = "Creating new varc catalogs..."
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(50, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        self._create_new_varc_catalogs()
        msg = "Creating new pipe catalogs..."
        self.progress_changed.emit(tools_qt.tr(message), lerp_progress(70, self.PROGRESS_OPTIONS, self.PROGRESS_CATALOGS), tools_qt.tr(msg), True)
        self._create_new_pipe_catalogs()

        # Get man tables
        self.man_tables: dict[str, str] = {}
        for k, v in self.catalogs['features'].items():
            sql = f"SELECT feature_class FROM cat_feature WHERE id = '{v}';"
            row = get_row(sql, commit=self.force_commit, is_thread=True)
            if not row:
                msg = "Feature class not found: {0}"
                msg_params = (v,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            feature_class = row[0]
            self.man_tables[k] = f"man_{feature_class.lower()}"

    def _manage_nonvisual(self) -> None:
        message = "Non-visual objects"
        if self.network.num_patterns > 0:
            msg = "Importing patterns..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(0, self.PROGRESS_CATALOGS, self.PROGRESS_NONVISUAL), tools_qt.tr(msg), True)
            self._save_patterns()

        if self.network.num_curves > 0:
            msg = "Importing curves..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(40, self.PROGRESS_CATALOGS, self.PROGRESS_NONVISUAL), tools_qt.tr(msg), True)
            self._save_curves()

    def _manage_visual(self) -> None:
        message = "Visual objects"
        if self.network.num_junctions > 0:
            msg = "Importing junctions..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(0, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_junctions()

        if self.network.num_reservoirs > 0:
            msg = "Importing reservoirs..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(30, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_reservoirs()

        if self.network.num_tanks > 0:
            msg = "Importing tanks..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(40, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_tanks()

        if self.network.num_pumps > 0:
            msg = "Importing pumps..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(50, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_pumps()

        if self.network.num_valves > 0:
            msg = "Importing valves..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(60, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_valves()

        if self.network.num_pipes > 0:
            msg = "Importing pipes..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(70, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_pipes()

        if self.network.num_controls > 0:
            msg = "Importing controls and rules..."
            self.progress_changed.emit(tools_qt.tr(message), lerp_progress(90, self.PROGRESS_NONVISUAL, self.PROGRESS_VISUAL), tools_qt.tr(msg), True)
            self._save_controls_and_rules()

    def _enable_triggers(self, enable: bool, plan_trigger: bool = False, geometry_trigger: bool = False) -> None:
        op = "ENABLE" if enable else "DISABLE"
        queries = [
            f'ALTER TABLE arc {op} TRIGGER ALL;',
            f'ALTER TABLE node {op} TRIGGER ALL;',
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

    def _get_units(self) -> None:
        units = self.network.options.hydraulic.inpfile_units
        if not units:
            msg = "Units not specified in the INP file."
            raise ValueError(tools_qt.tr(msg))
        self.db_units = units

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
            "hydraulic" -> inp_options_%
            "energy" -> inp_energy_%
            "reaction" -> inp_reactions_%
            "report" -> inp_report_%
            "time" -> inp_times_%
            "quality" -> inp_options_quality_mode??
        """
        # Define prefixes for each category
        prefix_map = {
            "time": "inp_times_",
            "hydraulic": "inp_options_",
            "report": "inp_report_",
            "quality": "inp_options_",
            "reaction": "inp_reactions_",
            "energy": "inp_energy_",
            # "graphics": "inp_graphics_",
            # "user": "inp_user_"
        }
        params_map = {
            "energy": {
                "global_price": "price",
                "global_pattern": "price_pattern",
                "global_efficiency": "pump_effic",
            },
            "time": {
            },
            "quality": {
                "parameter": "quality_mode",
                "trace_node": "node_id",
            },
            "reaction": {
                "bulk_coeff": "global_bulk",
                "wall_coeff": "global_wall",
                "limiting_potential": "limit_concentration",
                "roughness_correl": "wall_coeff_correlation",
            },
            "hydraulic": {
                "hydraulics_filename": "hydraulics_fname",
                "unbalanced_value": "unbalanced_n",
                "headerror": "max_headerror",
                "flowchange": "max_flowchange",
                "inpfile_units": "units",
            },
            "report": {
                "f-factor": "f_factor",
                "report_filename": "file",
            }
        }

        # List to accumulate parameters for batch update
        update_params = []

        options_dict = dict(self.network.options)

        def process_options(options, category):
            """Recursively process options, including nested dictionaries."""
            for key, value in options.items():
                if isinstance(value, dict):
                    # Recursively process nested dictionaries
                    process_options(value, category)
                else:
                    if category == "report" and type(value) is bool:
                        value = "YES" if value else "NO"
                        if key in ("nodes", "links"):
                            value = "ALL" if value else "NONE"
                    elif category == "time" and key not in ("pattern_start", "statistic"):
                        value = f"{int(value) // 3600}:{(int(value) % 3600) // 60:02d}" if value is not None else None
                    prefix = prefix_map.get(category, "inp_options_")
                    param_name = params_map[category].get(key.lower(), key.lower())
                    param_name = f"{prefix}{param_name}"
                    update_params.append((str(value) if value is not None else value, param_name))

        # Iterate over each category and its options
        for category, options in options_dict.items():
            if category in ("graphics", "user"):
                continue

            process_options(options, category)

        # SQL query for batch update
        sql = """
            UPDATE config_param_user
            SET value = data.value
            FROM (VALUES %s) AS data(value, parameter)
            WHERE config_param_user.parameter::text = data.parameter::text;
        """
        template = "(%s, %s)"

        if self.debug_mode:
            msg = "DEBUG: OPTIONS:"
            self._log_message(tools_qt.tr(msg))

            msg = "DEBUG: {0}"
            msg_params = (str(update_params),)
            self._log_message(tools_qt.tr(msg, list_params=msg_params))

        # Execute batch update
        toolsdb_execute_values(sql, update_params, template, fetch=False, commit=self.force_commit)

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

    def _create_demand_dscenario(self):
        extras = '"parameters": {'
        extras += f'"name": "{self.dscenario}",'
        extras += '"descript": "Demand dscenario used when importing INP file",'
        extras += '"parent": null,'
        extras += '"type": "DEMAND",'
        extras += '"active": "true",'
        extras += f'"expl": "{self.exploitation}"'
        extras += '}'
        body = tools_gw.create_body(extras=extras)
        json_result = tools_gw.execute_procedure('gw_fct_create_dscenario_empty', body, commit=self.force_commit, is_thread=True)
        if not json_result or json_result.get('status') != 'Accepted':
            message = "Error executing gw_fct_create_dscenario_empty"
            raise ValueError(message)

        self.dscenario_id = json_result['body']['data'].get('dscenario_id')
        if self.dscenario_id is None:
            message = "Function gw_fct_create_dscenario_empty returned no dscenario_id"
            raise ValueError(message)

    def _create_new_node_catalogs(self):
        cat_node_ids = get_rows("SELECT id FROM cat_node", commit=self.force_commit, is_thread=True)
        nodecat_db: list[str] = []
        if cat_node_ids:
            nodecat_db = [x[0] for x in cat_node_ids]

        node_catalogs = ["junctions", "reservoirs", "tanks"]
        # If VARCs will be transformed to nodes, ensure target node catalogs exist
        for k, v in self.manage_nodarcs.items():
            if not v:
                continue
            # Append any nodarc key that has feature and catalog definitions
            if k in self.catalogs and k in self.catalogs.get("features", {}):
                node_catalogs.append(k)

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
        varc_catalogs: list[str] = ["pumps", "valves"]

        # cat_mat_arc has an INSERT rule.
        # So it's not possible to use ON CONFLICT.
        # So, we perform a conditional INSERT here.
        execute_sql(
            """
            INSERT INTO cat_material (id, descript, feature_type)
            SELECT 'UNKNOWN', 'Unknown', '{NODE,ARC,CONNEC,ELEMENT}'
            WHERE NOT EXISTS (
                SELECT 1
                FROM cat_material
                WHERE id = 'UNKNOWN'
            );
            """,
            commit=self.force_commit,
            is_thread=True,
        )

        for varc_type in varc_catalogs:
            if varc_type not in self.catalogs:
                continue

            if self.manage_nodarcs.get(varc_type):
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
                    INSERT INTO cat_arc (id, arc_type, matcat_id, dint)
                    VALUES ('VARC', 'VARC', 'UNKNOWN', 999) ON CONFLICT DO NOTHING;
                """,
                commit=self.force_commit, is_thread=True)
                continue

            if self.catalogs[varc_type] in self.arccat_db:
                continue

            # cat_mat_arc has an INSERT rule.
            # So it's not possible to use ON CONFLICT.
            # So, we perform a conditional INSERT here.
            execute_sql(
                """
                INSERT INTO cat_material (id, descript, feature_type)
                SELECT 'UNKNOWN', 'Unknown', '{NODE,ARC,CONNEC,ELEMENT}'
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM cat_material
                    WHERE id = 'UNKNOWN'
                );
                """,
                commit=self.force_commit,
                is_thread=True,
            )

            sql = """
                INSERT INTO cat_arc (id, arc_type, matcat_id, dint)
                VALUES (%s, %s, 'UNKNOWN', 999) ON CONFLICT DO NOTHING;
            """
            _id = self.catalogs[varc_type]
            arctype_id = self.catalogs["features"][varc_type]
            execute_sql(sql, (_id, arctype_id), commit=self.force_commit, is_thread=True)
            self.arccat_db.append(_id)

    def _create_new_pipe_catalogs(self):
        if "pipes" in self.catalogs:
            pipe_catalog = self.catalogs["pipes"].items()
            for (pipe_dint, pipe_roughness), catalog in pipe_catalog:
                if catalog in self.arccat_db:
                    continue

                arctype_id = self.catalogs["features"]["pipes"]

                material = self.catalogs["materials"][pipe_roughness]

                sql = """
                    INSERT INTO cat_arc (id, arc_type, matcat_id, dint)
                    VALUES (%s, %s, %s, %s);
                """
                if self.debug_mode:
                    msg = "DEBUG: catalog: {0}, arctype_id: {1}, material: {2}, pipe_dint: {3}"
                    msg_params = (catalog, arctype_id, material, pipe_dint)
                    self._log_message(tools_qt.tr(msg, list_params=msg_params))
                execute_sql(
                    sql, (catalog, arctype_id, material, pipe_dint), commit=self.force_commit, is_thread=True
                )
                self.arccat_db.append(catalog)

    def _save_patterns(self):
        pattern_rows = get_rows("SELECT pattern_id FROM inp_pattern", commit=self.force_commit, is_thread=True)
        patterns_db: list[str] = []
        if pattern_rows:
            patterns_db = [x[0] for x in pattern_rows]

        for pattern_name, pattern in self.network.patterns.items():
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

            execute_sql(
                "INSERT INTO inp_pattern (pattern_id) VALUES (%s)",
                (pattern_name,),
                commit=self.force_commit,
                is_thread=True,
            )

            sql = (
                "INSERT INTO inp_pattern_value (pattern_id, factor_1, factor_2, factor_3, factor_4, factor_5, factor_6, factor_7, factor_8, factor_9, factor_10, factor_11, factor_12) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
            )
            for b in batched(pattern.multipliers, 12):
                # Fill up the last batch
                while len(b) < 12:
                    b: tuple[Any] = b + (None,)
                values = (pattern_name,) + b
                execute_sql(sql, values, commit=self.force_commit, is_thread=True)

    def _save_curves(self) -> None:
        from wntr.epanet.util import FlowUnits, HydParam, from_si

        curve_rows = get_rows("SELECT id FROM inp_curve", commit=self.force_commit, is_thread=True)
        curves_db: set[str] = set()
        if curve_rows:
            curves_db = {x[0] for x in curve_rows}

        for curve_name, curve in self.network.curves.items():
            if curve.curve_type is None:
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

            curve_type: str = curve.curve_type
            if curve.curve_type == "HEAD":
                curve_type = "PUMP"

            execute_sql(
                "INSERT INTO inp_curve (id, curve_type) VALUES (%s, %s)",
                (curve_name, curve_type),
                commit=self.force_commit,
                is_thread=True,
            )

            for x, y in curve.points:
                if curve_type != "VOLUME":
                    x = from_si(FlowUnits[self.db_units], x, HydParam.Flow)
                execute_sql(
                    "INSERT INTO inp_curve_value (curve_id, x_value, y_value) VALUES (%s, %s, %s)",
                    (curve_name, x, y),
                    commit=self.force_commit,
                    is_thread=True,
                )

    def _replace_codes_with_ids(self, text: str, req: tuple) -> str:
        """Replace INP codes (node/arc names) with database IDs in control/rule text."""

        result = text
        for obj in req:
            code = obj.name
            if code in self.node_ids:
                result = result.replace(str(code), str(self.node_ids[code]))
            elif code in self.arc_ids:
                result = result.replace(str(code), str(self.arc_ids[code]))
        return result

    def _save_controls_and_rules(self) -> None:
        from wntr.epanet.util import FlowUnits, HydParam, from_si
        from wntr.network.controls import Control, Rule, SimTimeCondition, TimeOfDayCondition, ValueCondition
        from wntr.network.model import Valve, Tank, Junction, Link
        from wntr.network.base import LinkStatus
        np = tools_os.get_dep("numpy")
        try:
            from wntr.network.controls import Comparison
        except ImportError:
            Comparison = None

        def get_setting(control_action, control_name: str):
            """Get the properly formatted setting value for a control action."""
            value = control_action._value
            attribute = control_action._attribute.lower()

            if attribute == 'status':
                setting = LinkStatus(value).name
            elif attribute == 'base_speed':
                setting = str(value)
            elif attribute == 'setting' and isinstance(control_action._target_obj, Valve):
                valve = control_action._target_obj
                valve_type = valve.valve_type
                if valve_type in ('PRV', 'PSV', 'PBV'):
                    setting = str(from_si(FlowUnits[self.db_units], value, HydParam.Pressure))
                elif valve_type == 'FCV':
                    setting = str(from_si(FlowUnits[self.db_units], value, HydParam.Flow))
                elif valve_type == 'TCV':
                    setting = str(value)
                elif valve_type == 'GPV':
                    setting = value
                else:
                    msg = 'Valve type not recognized: {0}'
                    msg_params = (valve_type,)
                    raise ValueError(tools_qt.tr(msg, list_params=msg_params))
            elif attribute == 'setting':
                setting = value
            else:
                setting = None
                msg = "Could not write control {0} - skipping"
                msg_params = (control_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))

            return setting

        controls_rows = get_rows("SELECT text FROM inp_controls", commit=self.force_commit, is_thread=True)
        controls_db: set[str] = set()
        if controls_rows:
            controls_db = {x[0] for x in controls_rows}

        rules_rows = get_rows("SELECT text FROM inp_rules", commit=self.force_commit, is_thread=True)
        rules_db: set[str] = set()
        if rules_rows:
            rules_db = {x[0] for x in rules_rows}

        for control_name, control in self.network.controls():
            control_dict = control.to_dict()
            priority = control.priority

            if type(control) is Control:
                then_actions = control_dict.get("then_actions", [])
                else_actions = control_dict.get("else_actions", [])

                if len(then_actions) != 1 or len(else_actions) != 0:
                    msg = "Too many actions on CONTROL '{0}'"
                    msg_params = (control_name,)
                    self._log_message(tools_qt.tr(msg, list_params=msg_params))
                    continue

                control_action = control._then_actions[0]

                # Skip if target is not a Link
                if not isinstance(control_action.target()[0], Link):
                    continue

                # Get setting value
                setting = get_setting(control_action, control_name)
                if setting is None:
                    continue

                link_obj = control_action._target_obj
                link_type = link_obj.link_type
                link_name = link_obj.name
                link_id = self.arc_ids.get(link_name, link_name)
                # Add _n2a because in go2epa valves/pumps are transformed to nodes
                if link_type.lower() in ['valve', 'pump']:
                    link_id = f"{link_id}_n2a"

                # Format based on condition type
                if isinstance(control._condition, (SimTimeCondition, TimeOfDayCondition)):
                    threshold_time = control._condition._threshold / 3600.0
                    compare = 'CLOCKTIME' if isinstance(control._condition, TimeOfDayCondition) else 'TIME'
                    text = f"{link_type} {link_id} {setting} AT {compare} {threshold_time:g}"

                elif isinstance(control._condition, ValueCondition):
                    source_obj = control._condition._source_obj
                    node_type = source_obj.node_type
                    node_name = source_obj.name
                    node_id = self.node_ids.get(node_name, node_name)

                    # Determine comparison direction
                    relation = control._condition._relation
                    if Comparison:
                        is_below = relation in [np.less, np.less_equal, Comparison.le, Comparison.lt]
                    else:
                        is_below = relation in [np.less, np.less_equal]
                    compare = 'BELOW' if is_below else 'ABOVE'

                    # Convert threshold based on node type
                    threshold = control._condition._threshold
                    if isinstance(source_obj, Tank):
                        thresh_value = from_si(FlowUnits[self.db_units], threshold, HydParam.HydraulicHead)
                    elif isinstance(source_obj, Junction):
                        thresh_value = from_si(FlowUnits[self.db_units], threshold, HydParam.Pressure)
                    else:
                        msg = "Unknown control for EPANET INP files: {0}"
                        msg_params = (type(control),)
                        raise RuntimeError(tools_qt.tr(msg, list_params=msg_params))

                    text = f"{link_type} {link_id} {setting} IF {node_type} {node_id} {compare} {thresh_value}"
                else:
                    msg = "Unknown control for EPANET INP files: {0}"
                    msg_params = (type(control),)
                    raise RuntimeError(tools_qt.tr(msg, list_params=msg_params))

                if text in controls_db:
                    msg = "The control '{0}' is already on database. Skipping..."
                    msg_params = (control_name,)
                    self._log_message(tools_qt.tr(msg, list_params=msg_params))
                    continue

                sql = "INSERT INTO inp_controls (sector_id, text, active) VALUES (%s, %s, true)"
                params = (self.sector, text)
                execute_sql(sql, params, commit=self.force_commit, is_thread=True)

            elif type(control) is Rule:
                condition = str(control.condition)
                req = control.requires()
                then_actions = control_dict.get("then_actions")
                else_actions = control_dict.get("else_actions")

                text = f"RULE {control.name}" + "\n" + f"IF {condition}" + "\n" + f"THEN {' AND '.join(then_actions)}"
                if else_actions:
                    text += f"\nELSE {else_actions}"
                text += f"\nPRIORITY {priority}"
                text = self._replace_codes_with_ids(text, req)
                if text in rules_db:
                    msg = "The rule '{0}' is already on database. Skipping..."
                    msg_params = (control_name,)
                    self._log_message(tools_qt.tr(msg, list_params=msg_params))
                    continue

                sql = "INSERT INTO inp_rules (sector_id, text, active) VALUES (%s, %s, true)"
                params = (self.sector, text)
                execute_sql(sql, params, commit=self.force_commit, is_thread=True)

    def _save_junctions(self) -> None:
        node_sql = """ 
            INSERT INTO node (
                the_geom, code, nodecat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, top_elev
            ) VALUES %s
            RETURNING node_id, code
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = """
            INSERT INTO man_junction (
                node_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_junction (
                node_id, demand, emitter_coeff, init_quality
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s)"
        )

        demands_sql = """
            INSERT INTO inp_dscenario_demand (dscenario_id, feature_id, feature_type, demand, pattern_id, demand_type, source)
            VALUES %s
        """
        demands_template = (
            "(%s, %s, 'NODE', %s, %s, null, %s)"
        )
        demands_params = []

        node_params = []

        inp_dict = {}

        for j_name, j in self.network.junctions():
            x, y = j.coordinates
            srid = lib_vars.data_epsg
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
                    nodecat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                    j.elevation,
                )
            )
            inp_dict[j_name] = {
                "demand": j.base_demand * 1000,
                "pattern_id": None,
                "peak_factor": None,
                "emitter_coeff": j.emitter_coefficient,
                "init_quality": j.initial_quality,
                "source_type": None,
                "source_quality": None,
                "source_pattern_id": None
            }

            # If only one demand timeseries, set pattern_id in inp_dict; otherwise, populate demands_params
            if j.demand_timeseries_list:
                inp_dict[j_name]["pattern_id"] = j.demand_timeseries_list[0].pattern_name
                if len(j.demand_timeseries_list) > 1:
                    for d in j.demand_timeseries_list:
                        demands_params.append(
                            (
                                self.dscenario_id,
                                j_name,
                                d.base_value * 1000,
                                d.pattern_name,
                                d.category,
                            )
                        )

        # Insert into parent table
        junctions = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            msg = "DEBUG: {0}"
            msg_params = (str(junctions),)
            self._log_message(tools_qt.tr(msg, list_params=msg_params))
        if not junctions:
            msg = "Junctions couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
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
                (node_id, inp_data["demand"], inp_data["emitter_coeff"], inp_data["init_quality"])
            )

        # Update demands_params to replace j_name with node_id
        for i, demand_param in enumerate(demands_params):
            j_name = demand_param[1]  # Get the original j_name
            node_id = self.node_ids.get(j_name)  # Find the node_id associated with j_name
            if node_id is not None:
                demands_params[i] = (demand_param[0], node_id, *demand_param[2:])
            else:
                msg = "Node ID for {0} not found!"
                msg_params = (j_name,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )
        # Insert demands into dscenario table
        toolsdb_execute_values(
            demands_sql, demands_params, demands_template, fetch=False, commit=self.force_commit
        )

    def _save_reservoirs(self) -> None:
        man_table = self.man_tables['reservoirs']

        node_sql = """ 
            INSERT INTO node (
                the_geom, code, nodecat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id
            ) VALUES %s
            RETURNING node_id, code
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO {man_table} (
                node_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_reservoir (
                node_id, pattern_id, head, init_quality
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s)"
        )

        node_params = []

        inp_dict = {}

        for r_name, r in self.network.reservoirs():
            x, y = r.coordinates
            srid = lib_vars.data_epsg
            nodecat_id = self.catalogs["reservoirs"]
            epa_type = "RESERVOIR"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            node_params.append(
                (
                    x, y, srid,  # the_geom
                    r_name,  # code
                    nodecat_id,
                    epa_type,
                    expl_id,
                    sector_id,
                    muni_id,
                    state,
                    state_type,
                    workcat_id,
                )
            )
            inp_dict[r_name] = {
                "pattern_id": r.head_pattern_name,
                "head": r.base_head,
                "init_quality": r.initial_quality,
                "source_type": None,
                "source_quality": None,
                "source_pattern_id": None
            }

        # Insert into parent table
        reservoirs = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            msg = "DEBUG: {0}"
            msg_params = (str(reservoirs),)
            self._log_message(tools_qt.tr(msg, list_params=msg_params)) 
        if not reservoirs:
            msg = "Reservoirs couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []

        for r in reservoirs:
            node_id = r[0]
            code = r[1]

            self.node_ids[code] = node_id

            man_params.append(
                (node_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (node_id, inp_data["pattern_id"], inp_data["head"], inp_data["init_quality"])
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_tanks(self) -> None:
        man_table = self.man_tables['tanks']

        node_sql = """ 
            INSERT INTO node (
                the_geom, code, nodecat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id, top_elev
            ) VALUES %s
            RETURNING node_id, code
        """
        node_template = (
            "(ST_SetSRID(ST_Point(%s, %s),%s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO {man_table} (
                node_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_tank (
                node_id, initlevel, minlevel, maxlevel, diameter, minvol, curve_id, overflow, mixing_model, mixing_fraction, reaction_coeff, init_quality
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        node_params = []

        inp_dict = {}

        for t_name, t in self.network.tanks():
            x, y = t.coordinates
            srid = lib_vars.data_epsg
            nodecat_id = self.catalogs["tanks"]
            epa_type = "TANK"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            elevation = t.elevation
            node_params.append(
                (
                    x, y, srid,  # the_geom
                    t_name,  # code
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
            inp_dict[t_name] = {
                "initlevel": t.init_level,
                "minlevel": t.min_level,
                "maxlevel": t.max_level,
                "diameter": t.diameter,
                "minvol": t.min_vol,
                "curve_id": t.vol_curve_name,
                "overflow": "Yes" if t.overflow else "No",
                "mixing_model": t.mixing_model,
                "mixing_fraction": t.mixing_fraction,
                "reaction_coeff": t.bulk_coeff,
                "init_quality": t.initial_quality,
                "source_type": None,
                "source_quality": None,
                "source_pattern_id": None,
            }

        # Insert into parent table
        tanks = toolsdb_execute_values(
            node_sql, node_params, node_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            msg = "DEBUG: {0}"
            msg_params = (str(tanks),)
            self._log_message(tools_qt.tr(msg, list_params=msg_params))
        if not tanks:
            msg = "Tanks couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []

        for t in tanks:
            node_id = t[0]
            code = t[1]

            self.node_ids[code] = node_id

            man_params.append(
                (node_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (node_id, inp_data["initlevel"], inp_data["minlevel"], inp_data["maxlevel"], inp_data["diameter"],
                 inp_data["minvol"], inp_data["curve_id"], inp_data["overflow"], inp_data["mixing_model"],
                 inp_data["mixing_fraction"], inp_data["reaction_coeff"], inp_data["init_quality"])
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
        man_table = self.man_tables['pumps']
        arccat_id = self.catalogs["pumps"]
        # Set 'fake' catalogs if it will be converted to flwreg
        if self.manage_nodarcs["pumps"]:
            man_table = "man_varc"
            arccat_id = "VARC"

        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id
            ) VALUES %s
            RETURNING arc_id, code
        """
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO {man_table} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_virtualpump (
                arc_id, power, curve_id, speed, pattern_id, status, effic_curve_id, energy_price, energy_pattern_id, pump_type
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        arc_params = []

        inp_dict = {}

        for p_name, p in self.network.pumps():
            geometry = get_geometry_from_link(p)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[p.start_node_name]
                node_2 = self.node_ids[p.end_node_name]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            epa_type = "VIRTUALPUMP"
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
                "power": None,
                "curve_id": None,
                "speed": p.base_speed,
                "pattern_id": p.speed_pattern_name,
                "status": p.initial_status.name.upper(),
                "effic_curve_id": p.efficiency.name if p.efficiency else None,
                "energy_price": p.energy_price,
                "energy_pattern_id": p.energy_pattern,
                "pump_type": "POWERPUMP",
            }
            if p.pump_type == "POWER":
                inp_dict[p_name]["power"] = p.power / 1000
            elif p.pump_type == "HEAD":
                inp_dict[p_name]["curve_id"] = p.pump_curve_name

        # Insert into parent table
        pumps = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            msg = "DEBUG: {0}"
            msg_params = (str(pumps),)
            self._log_message(tools_qt.tr(msg, list_params=msg_params))
        if not pumps:
            msg = "Pumps couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []

        for p in pumps:
            arc_id = p[0]
            code = p[1]

            self.arc_ids[code] = arc_id

            man_params.append(
                (arc_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["power"], inp_data["curve_id"], inp_data["speed"], inp_data["pattern_id"],
                 inp_data["status"], inp_data["effic_curve_id"], inp_data["energy_price"],
                 inp_data["energy_pattern_id"], inp_data["pump_type"])
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_valves(self) -> None:
        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id
            ) VALUES %s
            RETURNING arc_id, code
        """
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql_template = """
            INSERT INTO man_{feature_class} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_virtualvalve (
                arc_id, valve_type, setting, diameter, curve_id, minorloss, status, init_quality
            ) VALUES %s
        """
        inp_template = "(%s, %s, %s, %s, %s, %s, %s, %s)"

        arc_params = []
        inp_dict = {}

        for v_name, v in self.network.valves():
            geometry = get_geometry_from_link(v)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[v.start_node_name]
                node_2 = self.node_ids[v.end_node_name]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue

            valve_type = v.valve_type.lower()
            # Get valve-specific feature class and arccat_id
            feature_class = self.catalogs["features"][valve_type]
            arccat_id = self.catalogs[valve_type]

            # Convert to node if required
            if self.manage_nodarcs.get(valve_type, False):
                feature_class = "VARC"
                arccat_id = "VARC"

            arc_params.append(
                (
                    geometry, srid,  # the_geom
                    v_name,  # code
                    node_1,
                    node_2,
                    arccat_id,
                    "VIRTUALVALVE",
                    self.exploitation,
                    self.sector,
                    self.municipality,
                    self.state,
                    self.state_type,
                    self.workcat,
                )
            )

            inp_dict[v_name] = {
                "valve_type": v.valve_type,
                "diameter": v.diameter * 1000,
                "setting": v.initial_setting,
                "curve_id": None,
                "minorloss": v.minor_loss,
                "status": v.initial_status.name.upper(),
                "init_quality": None,
                "feature_class": feature_class,  # Store feature_class for later use
            }

        # Insert into parent table
        valves = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if not valves:
            msg = "Valves couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = {}
        inp_params = []

        for v in valves:
            arc_id = v[0]
            code = v[1]

            self.arc_ids[code] = arc_id

            feature_class = inp_dict[code]["feature_class"]

            if feature_class not in man_params:
                man_params[feature_class] = []
            man_params[feature_class].append((arc_id,))

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["valve_type"], inp_data["setting"], inp_data["diameter"], inp_data["curve_id"],
                inp_data["minorloss"], inp_data["status"], inp_data["init_quality"])
            )

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )

        # Insert into each man table separately
        for feature_class, params in man_params.items():
            man_sql = man_sql_template.format(feature_class=feature_class)
            toolsdb_execute_values(
                man_sql, params, man_template, fetch=False, commit=self.force_commit
            )

    def _save_pipes(self) -> None:
        man_table = self.man_tables['pipes']

        arc_sql = """ 
            INSERT INTO arc (
                the_geom, code, node_1, node_2, arccat_id, epa_type, expl_id, sector_id, muni_id, state, state_type, workcat_id
            ) VALUES %s
            RETURNING arc_id, code
        """
        arc_template = (
            "(ST_GeomFromText(%s, %s), %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        man_sql = f"""
            INSERT INTO {man_table} (
                arc_id
            ) VALUES %s
        """
        man_template = "(%s)"

        inp_sql = """
            INSERT INTO inp_pipe (
                arc_id, minorloss, status, custom_roughness, custom_dint, reactionparam, reactionvalue, bulk_coeff, wall_coeff
            ) VALUES %s
        """
        inp_template = (
            "(%s, %s, %s, %s, %s, %s, %s, %s, %s)"
        )

        arc_params = []

        inp_dict = {}

        for p_name, p in self.network.pipes():
            geometry = get_geometry_from_link(p)

            srid = lib_vars.data_epsg
            try:
                node_1 = self.node_ids[p.start_node_name]
                node_2 = self.node_ids[p.end_node_name]
            except KeyError as e:
                msg = "Node not found: {0}"
                msg_params = (e,)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            arccat_id = self.catalogs["pipes"][(round(p.diameter * 1000, 0), p.roughness)]
            epa_type = "PIPE"
            expl_id = self.exploitation
            sector_id = self.sector
            muni_id = self.municipality
            state = self.state
            state_type = self.state_type
            workcat_id = self.workcat
            arc_params.append(
                (
                    geometry,
                    srid,
                    p_name,
                    node_1,
                    node_2,
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
                "minorloss": p.minor_loss,
                "status": "CV" if p.check_valve else p.initial_status.name.upper(),
                "custom_roughness": p.roughness,
                "custom_dint": p.diameter * 1000,
                "reactionparam": None,
                "reactionvalue": None,
                "bulk_coeff": p.bulk_coeff,
                "wall_coeff": p.wall_coeff,
            }

        # Insert into parent table
        pipes = toolsdb_execute_values(
            arc_sql, arc_params, arc_template, fetch=True, commit=self.force_commit
        )
        if self.debug_mode:
            msg = "DEBUG: {0}"
            msg_params = (str(pipes),)
            self._log_message(tools_qt.tr(msg, list_params=msg_params))
        if not pipes:
            msg = "Pipes couldn't be inserted!"
            self._log_message(tools_qt.tr(msg))
            return

        man_params = []
        inp_params = []

        for p in pipes:
            arc_id = p[0]
            code = p[1]

            self.arc_ids[code] = arc_id

            man_params.append(
                (arc_id,)
            )

            inp_data = inp_dict[code]
            inp_params.append(
                (arc_id, inp_data["minorloss"], inp_data["status"], inp_data["custom_roughness"], inp_data["custom_dint"],
                 inp_data["reactionparam"], inp_data["reactionvalue"], inp_data["bulk_coeff"], inp_data["wall_coeff"],
                 )
            )
            if self.debug_mode:
                msg = "DEBUG: {0}"
                msg_params = (str(inp_params),)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))

        # Insert into inp table
        toolsdb_execute_values(
            inp_sql, inp_params, inp_template, fetch=False, commit=self.force_commit
        )
        # Insert into man table
        toolsdb_execute_values(
            man_sql, man_params, man_template, fetch=False, commit=self.force_commit
        )

    def _save_sources(self):
        for s_name, s in self.network.sources():
            # Get source properties
            node_name = s.node_name
            source_type = s.source_type
            source_quality = s.strength_timeseries.base_value
            source_pattern_id = s.strength_timeseries.pattern_name

            # Get node_id & epa_type of related node
            sql = """
                SELECT node_id, epa_type FROM node WHERE code = %s
            """
            params = (node_name,)
            row = get_row(sql, params, commit=self.force_commit, is_thread=True)
            if not row:
                msg = "Couldn't find node '{0}' for source '{1}'."
                msg_params = (node_name, s_name)
                self._log_message(tools_qt.tr(msg, list_params=msg_params))
                continue
            node_id, epa_type = row

            # Update source columns
            sql = f"""
                UPDATE inp_{epa_type.lower()} 
                SET source_type = %s, source_quality = %s, source_pattern_id = %s 
                WHERE node_id = %s;
            """
            params = (source_type, source_quality, source_pattern_id, node_id)
            execute_sql(sql, params, commit=self.force_commit, is_thread=True)

    def _manage_nodarcs(self) -> str:
        """ Transform pumps and valves into nodes """

        extras = ""
        extras += f'"workcatId": "{self.workcat}",'
        for k, v in self.manage_nodarcs.items():
            if not v:
                continue
            extras += f'"{k}": {{"featureClass": "{self.catalogs["features"][k]}", "catalog": "{self.catalogs[k]}"}},'

        if extras:
            fct_name = "gw_fct_import_epanet_nodarcs"
            extras = extras[:-1]
            body = tools_gw.create_body(extras=extras)
            json_result = tools_gw.execute_procedure(fct_name, body, commit=self.force_commit, is_thread=True)
            if not json_result or json_result.get('status') != 'Accepted':
                message = "Error executing {0} - {1}"
                raise ValueError(message.format(fct_name, json_result.get('message')))
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
        return "No nodarcs to manage"

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
