"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

import configparser
import json
import traceback
from datetime import date
from math import log, log1p, exp
from pathlib import Path

from qgis.core import QgsTask
from qgis.PyQt.QtCore import pyqtSignal

from .task import GwTask
from ...libs import lib_vars, tools_db, tools_os, tools_qt


def get_min_greater_than(iterable, value):
    """ Return smallest iterable value greater than or equal to value """
    result = None
    for item in iterable:
        if item == value:
            return item
        if item < value:
            continue
        if result is None or item < result:
            result = item
    return result


# sh formula [directly from the paper Shamir and Howard Concept]
def optimal_replacement_time(
    present_year,
    number_of_breaks,
    break_growth_rate,
    repairing_cost,
    replacement_cost,
    discount_rate,
):
    """ Compute Shamir-Howard optimal pipe replacement year """
    BREAKS_YEAR_0 = 0.05   # represents how many breaks we have in the pipe right now.
    optimal_replacement_cycle = (1 / break_growth_rate) * log(
        log1p(discount_rate) * replacement_cost / BREAKS_YEAR_0 / repairing_cost
    )
    cycle_costs = 0
    for t in range(1, round(optimal_replacement_cycle) + 1):
        cycle_costs += (
            repairing_cost
            * BREAKS_YEAR_0
            * exp(break_growth_rate * t)
            / (1 + discount_rate) ** t
        )

    b_orc = 1 / ((1 + discount_rate) ** optimal_replacement_cycle - 1)

    return present_year + (1 / break_growth_rate) * log(
        log1p(discount_rate)
        # * replacement_cost
        * ((replacement_cost + cycle_costs) * b_orc + replacement_cost)
        / number_of_breaks
        / repairing_cost
    )


class GwCalculatePriority(GwTask):
    report = pyqtSignal(dict)
    step = pyqtSignal(str)

    def __init__(
        self,
        description,
        result_type,
        result_name,
        result_description,
        status,
        features,
        exploitation,
        presszone,
        diameter,
        material,
        budget,
        target_year,
        config_catalog,
        config_material,
        config_engine,
        asset_type="ARC",
        node_type=None,
        nodecat=None,
        linked_arc_result_id=None,
    ):
        super().__init__(description, QgsTask.Flag.CanCancel)
        self.result_type = result_type
        self.result_name = result_name
        self.result_description = result_description
        self.status = status
        self.features = features
        self.exploitation = exploitation
        self.presszone = presszone
        self.diameter = diameter
        self.material = material
        self.result_budget = budget
        self.target_year = target_year
        self.config_catalog = config_catalog
        self.config_material = config_material
        self.config_engine = config_engine
        self.asset_type = asset_type or "ARC"
        self.node_type = node_type
        self.nodecat = nodecat
        self.linked_arc_result_id = linked_arc_result_id

        if lib_vars.plugin_dir:
            config_path = Path(lib_vars.plugin_dir) / "config" / "giswater.config"
            config = configparser.ConfigParser()
            config.read(config_path)
            self.method = config.get("general", "engine_method")
            self.unknown_material = config.get("general", "unknown_material")

            self.msg_task_canceled = tools_qt.tr("Task canceled.")

    def run(self):
        """ Execute SH or WM priority calculation for selected asset type """
        try:
            tools_os.get_dep("pandas")
        except ImportError:
            self.exception = (
                "Python package 'pandas' is not installed. "
                "Please install it using pip or the 'qpip' QGIS plugin."
            )
            return False

        try:
            if self.method == "SH":
                if self.asset_type in ("NODE", "LINK"):
                    self._emit_report(
                        tools_qt.tr("Task canceled:"),
                        tools_qt.tr(
                            "The Shamir-Howard method is not available for NODE or LINK assets. "
                            "Please switch the calculation engine to Weighted Method."
                        ),
                    )
                    return False
                return self._run_sh()
            elif self.method == "WM":
                return self._run_wm()
            else:
                raise ValueError(
                    tools_qt.tr(
                        "Method of calculation not defined in configuration file. ",
                        "Please check config file.",
                    )
                )

        except Exception:
            self._emit_report(traceback.format_exc())
            return False

    def _calculate_ivi(self, arcs, year, replacements=False):
        """ Compute Infrastructure Value Index for assets at a year """
        current_value = self._current_value(arcs, year, replacements)
        replacement_cost = self._replacement_cost(arcs)
        if not replacement_cost:
            return 0.0
        return current_value / replacement_cost

    def _calculate_combined_ivi(self, arc_assets, node_assets, year, replacements=False):
        """IVI from summed current values and replacement costs (not average of IVIs)."""
        current_value = self._current_value(arc_assets, year, replacements) + self._current_value(
            node_assets, year, replacements
        )
        replacement_cost = self._replacement_cost(arc_assets) + self._replacement_cost(node_assets)
        if not replacement_cost:
            return 0.0
        return current_value / replacement_cost

    def _build_ivi_series(self, assets):
        """Year → (IVI without replacements, IVI with replacements) through target_year."""
        ivi = {}
        for year in range(date.today().year, self.target_year + 1):
            ivi[year] = (
                self._calculate_ivi(assets, year),
                self._calculate_ivi(assets, year, replacements=True),
            )
        return ivi

    def _build_combined_ivi_series(self, arc_assets, node_assets):
        """Year → combined ARC+NODE IVI pair through target_year."""
        ivi = {}
        for year in range(date.today().year, self.target_year + 1):
            ivi[year] = (
                self._calculate_combined_ivi(arc_assets, node_assets, year),
                self._calculate_combined_ivi(arc_assets, node_assets, year, replacements=True),
            )
        return ivi

    def _enrich_nodes_for_ivi(self, nodes):
        """Map NODE fields to ARC IVI shape: cost_constr + useful life (age_med, press=60)."""
        for node in nodes:
            node["cost_constr"] = float(node.get("estimated_cost") or 0)
            # No node pressure → age_med band (same as ARC get_age for 50 <= P < 75)
            node["total_expected_useful_life"] = self.config_material.get_age(
                node["matcat_id"], 60
            )

    def _copy_input_to_output(self):
        """ Copy ext_arc_asset attributes into arc_output rows """
        tools_db.execute_sql(
            f"""
            update am.arc_output o
            set (sector_id, macrosector_id, presszone_id, pavcat_id, function_type, the_geom, code, expl_id)
                = (select sector_id, macrosector_id, presszone_id, pavcat_id, function_type, st_multi(the_geom), code, expl_id
                    from am.ext_arc_asset a
                    where a.arc_id = o.arc_id)
            where o.result_id = {self.result_id}
            """,
            is_thread=True
        )

    def _copy_node_input_to_output(self):
        """ Copy ext_node_asset attributes into node_output rows """
        tools_db.execute_sql(
            f"""
            update am.node_output o
            set (sector_id, macrosector_id, presszone_id, builtdate, nodecat_id, node_type, the_geom, code, expl_id, dma_id)
                = (select sector_id, macrosector_id, presszone_id, builtdate, nodecat_id, node_type, the_geom, code, expl_id, dma_id
                    from am.ext_node_asset a
                    where a.node_id = o.node_id)
            where o.result_id = {self.result_id}
            """,
            is_thread=True
        )

    def _current_value(self, arcs, year, replacements=False):
        """ Sum depreciated replacement cost of arcs at a year """
        current_value = 0
        for arc in arcs:
            if (
                replacements
                and "replacement_year" in arc
                and arc["replacement_year"] <= year
            ):
                builtdate = arc["replacement_year"]
            else:
                builtdate = getattr(
                    arc["builtdate"], "year", None
                ) or self.config_material.get_default_builtdate(arc["matcat_id"])
            useful_life = arc.get("total_expected_useful_life") or 0
            if useful_life <= 0:
                continue
            residual_useful_life = builtdate + useful_life - year
            multiplier = residual_useful_life / useful_life
            result = (arc["cost_constr"] * multiplier) if multiplier > 0 else 0
            current_value += result

        return current_value

    def _emit_report(self, *args):
        """ Emit log report messages to the dialog """
        self.report.emit({"info": {"values": [{"message": arg} for arg in args]}})

    def _fit_to_scale(self, value, min, max):
        """Fit a value to a 0 to 10 scale, where min is the zero and max is ten."""
        if min == max:
            return 10
        return float((value - min) * 10 / (max - min))

    def _fit_mincut_criticity(self, value, min_customers, max_customers):
        """Fit affected customers to Stage-1 mincut criticity scale [1, 10]."""
        if value is None:
            return None
        if min_customers is None or max_customers is None:
            return None
        if min_customers == max_customers:
            return 5.5
        return round(1 + 9.0 * (value - min_customers) / (max_customers - min_customers), 2)

    def _normalize_min_max(self, value, lo, hi):
        """Fit a raw value onto a [1, 10] scale using dataset min/max (Stage-2 convention).
        A flat dataset (lo == hi) yields the mid value 5.5; a missing value or missing
        bounds yields None so the caller can decide how to treat absent data."""
        if value is None or lo is None or hi is None:
            return None
        # Numeric DB columns come back as Decimal; normalize to float upfront so the
        # arithmetic below never mixes Decimal and float operands.
        value, lo, hi = float(value), float(lo), float(hi)
        if lo == hi:
            return 5.5
        return round(1 + 9.0 * (value - lo) / (hi - lo), 2)

    def _normalize_binary(self, value):
        """Map a boolean/None raw value to the [0, 10] scale used by binary criteria."""
        if value is None:
            return None
        return 10 if value else 0

    def _scale_or_zero(self, normalized):
        """A NULL raw input must contribute 0 to a weighted sum, never a fake mid value."""
        return float(normalized) if normalized is not None else 0.0

    def _format_report(self, title, rows):
        """Render a two-column, left-padded 'label: value' report block from (header, value) pairs."""
        headers = [row[0] for row in rows]
        values = [row[1] for row in rows]
        columns = [headers, values]
        for column in columns:
            length = max(len(x) for x in column)
            for index, string in enumerate(column):
                column[index] = string.ljust(length)
        txt = f"{title}:\n"
        for line in zip(*columns):
            txt += "  ".join(line) + "\n"
        return txt.strip()

    def _update_mincut_criticity(self):
        """Refresh mincut_customers / mincut_criticity on am.arc_input."""
        try:
            row = tools_db.get_row(
                "SELECT am.gw_fct_am_update_mincut_criticity('{}'::json) AS result",
                is_thread=True,
            )
            if not row:
                return False
            result = row["result"]
            if isinstance(result, str):
                result = json.loads(result)
            status = (result or {}).get("status")
            return status == "Accepted"
        except Exception:
            return False

    def _get_arcs(self):
        """ Get arcs """

        columns = ""

        # Set columns variable depending of the method
        if self.method == "SH":
            columns = """
                a.arc_id,
                a.arccat_id,
                a.matcat_id,
                a.dnom,
                st_length(a.the_geom) length,
                coalesce(ai.rleak, 0) rleak,
                a.expl_id,
                a.presszone_id,
                ai.strategic
            """
        elif self.method == "WM":
            columns = """
                a.arc_id,
                a.arccat_id,
                a.matcat_id,
                a.dnom,
                st_length(a.the_geom) length,
                coalesce(ai.rleak, 0) rleak,
                a.builtdate,
                a.press1,
                a.press2,
                coalesce(a.flow_avg, 0) flow_avg,
                a.dma_id,
                ai.strategic,
                coalesce(ai.mandatory, false) mandatory,
                ai.mincut_customers,
                ai.mincut_criticity
            """

        filter_list = []
        if self.features:
            filter_list.append(f"""a.arc_id in ('{"','".join(self.features)}')""")
        if self.exploitation:
            filter_list.append(f"a.expl_id = {self.exploitation}")
        if self.presszone:
            filter_list.append(f"a.presszone_id = '{self.presszone}'")
        if self.diameter:
            filter_list.append(f"a.dnom = '{self.diameter}'")
        if self.material:
            filter_list.append(f"a.matcat_id = '{self.material}'")
        filters = f"where {' and '.join(filter_list)}" if filter_list else ""

        if columns != "":
            sql = f"""
                select {columns}
                from am.ext_arc_asset a
                left join am.arc_input ai using (arc_id)
                {filters}
            """
            return tools_db.get_rows(sql, is_thread=True)

    def _get_nodes(self):
        """Get nodes (Stage 2, NODE asset_type).

        Raw overlay fields live on node_input (*_raw); age/cost can also come from
        ext_node_asset when the overlay row is missing.
        """

        columns = """
            a.node_id,
            a.node_type,
            a.nodecat_id,
            a.matcat_id,
            a.builtdate,
            a.sector_id,
            a.macrosector_id,
            a.presszone_id,
            a.expl_id,
            a.dma_id,
            a.code,
            a.the_geom,
            coalesce(i.age, a.age) AS age,
            coalesce(i.mandatory, false) AS mandatory,
            i.strategic,
            i.incident_count,
            coalesce(i.structural_raw, a.structural_raw_src) AS structural_raw,
            coalesce(i.operational_raw, a.operational_raw_src) AS operational_raw,
            i.nrw_raw,
            i.affected_users_raw,
            i.compliance,
            coalesce(i.estimated_cost, a.estimated_cost, 0) AS estimated_cost
        """

        filter_list = []
        if self.features:
            filter_list.append(f"""a.node_id in ('{"','".join(self.features)}')""")
        if self.exploitation:
            filter_list.append(f"a.expl_id = {self.exploitation}")
        if self.presszone:
            filter_list.append(f"a.presszone_id = '{self.presszone}'")
        if self.node_type:
            if isinstance(self.node_type, (list, tuple)):
                types = "','".join(str(t).replace("'", "''") for t in self.node_type)
                filter_list.append(f"a.node_type in ('{types}')")
            else:
                filter_list.append(f"a.node_type = '{self.node_type}'")
        if self.nodecat:
            filter_list.append(f"a.nodecat_id = '{self.nodecat}'")
        filters = f"where {' and '.join(filter_list)}" if filter_list else ""

        sql = f"""
            select {columns}
            from am.ext_node_asset a
            left join am.node_input i using (node_id)
            {filters}
        """
        return tools_db.get_rows(sql, is_thread=True)

    def _get_links(self):
        """Get links (Stage 3, LINK asset_type). Overlay on link_input; inventory on ext_link_asset."""

        columns = """
            a.link_id,
            a.connec_id,
            a.arc_id,
            a.linkcat_id,
            a.matcat_id,
            a.dnom,
            a.builtdate,
            a.length,
            a.sector_id,
            a.macrosector_id,
            a.presszone_id,
            a.expl_id,
            a.dma_id,
            a.the_geom,
            coalesce(i.age, a.age) AS age,
            coalesce(i.mandatory, false) AS mandatory,
            i.strategic,
            coalesce(i.incident_count, a.incident_count_src) AS incident_count,
            coalesce(i.material_raw, a.material_raw_src) AS material_raw,
            coalesce(i.affected_users_raw, a.affected_users_raw_src) AS affected_users_raw,
            i.parent_arc_selected_raw,
            i.compliance,
            i.estimated_cost,
            coalesce(i.data_quality, a.data_quality_src) AS data_quality,
            coalesce(i.data_quality_obs, a.data_quality_obs_src) AS data_quality_obs,
            a.connecat_id
        """

        filter_list = []
        if self.features:
            filter_list.append(f"""a.link_id in ('{"','".join(str(x) for x in self.features)}')""")
        if self.exploitation:
            filter_list.append(f"a.expl_id = {self.exploitation}")
        if self.presszone:
            filter_list.append(f"a.presszone_id = '{self.presszone}'")
        if self.material:
            filter_list.append(f"a.matcat_id = '{self.material}'")
        if self.nodecat:
            filter_list.append(f"a.linkcat_id = '{self.nodecat}'")
        filters = f"where {' and '.join(filter_list)}" if filter_list else ""

        sql = f"""
            select {columns}
            from am.ext_link_asset a
            left join am.link_input i using (link_id)
            {filters}
        """
        return tools_db.get_rows(sql, is_thread=True)

    def _invalid_arccat_id_report(self, obj):
        """ Build report text for pipes with invalid arccat_id """
        if not obj["qtd"]:
            return
        msg = "\n".join(
            [
                tools_qt.tr("Pipes with invalid arccat_ids: {qtd}."),
                tools_qt.tr("Invalid arccat_ids: {list}."),
                tools_qt.tr("These pipes have NOT been assigned a priority value."),
            ]
        )
        return msg.format(qtd=obj["qtd"], list=", ".join(obj["set"]))

    def _invalid_nodecat_id_report(self, obj):
        """ Build report text for nodes with invalid nodecat_id """
        if not obj["qtd"]:
            return
        msg = "\n".join(
            [
                tools_qt.tr("Nodes with invalid nodecat_ids: {qtd}."),
                tools_qt.tr("Invalid nodecat_ids: {list}."),
                tools_qt.tr("These nodes have NOT been assigned a priority value."),
            ]
        )
        return msg.format(qtd=obj["qtd"], list=", ".join(str(x) for x in obj["set"]))

    def _invalid_diameter_report(self, obj):
        """ Build report text for pipes with invalid diameter """
        if not obj["qtd"]:
            return
        msg = "\n".join(
            [
                tools_qt.tr("Pipes with invalid diameters: {qtd}."),
                tools_qt.tr("Invalid diameters: {list}."),
                tools_qt.tr("These pipes have NOT been assigned a priority value."),
            ]
        )
        return msg.format(qtd=obj["qtd"], list=", ".join(map(str, sorted(obj["set"]))))

    def _invalid_material_report(self, obj):
        """ Build report text for assets with invalid material (ARC pipes / NODE nodes). """
        if not obj["qtd"]:
            return
        is_node = getattr(self, "asset_type", "ARC") == "NODE"
        if self.config_material.has_material(self.unknown_material):
            if is_node:
                info = tools_qt.tr(
                    "These nodes have been identified as the configured unknown material, "
                    "{unknown_material}."
                )
            else:
                info = tools_qt.tr(
                    "These pipes have been identified as the configured unknown material, "
                    "{unknown_material}."
                )
        else:
            if is_node:
                info = tools_qt.tr(
                    "These nodes have NOT been assigned a priority value "
                    "as the configured unknown material, {unknown_material}, "
                    "is not listed in the configuration tab for materials."
                )
            else:
                info = tools_qt.tr(
                    "These pipes have NOT been assigned a priority value "
                    "as the configured unknown material, {unknown_material}, "
                    "is not listed in the configuration tab for materials."
                )
        header = (
            tools_qt.tr("Nodes with invalid materials: {qtd}.")
            if is_node
            else tools_qt.tr("Pipes with invalid materials: {qtd}.")
        )
        msg = "\n".join(
            [
                header,
                tools_qt.tr("Invalid materials: {list}."),
                info,
            ]
        )
        return msg.format(
            qtd=obj["qtd"],
            list=", ".join(str(x) for x in obj["set"]),
            unknown_material=self.unknown_material,
        )

    def _invalid_pressures_report(self, null_pressures):
        """ Build report text for pipes missing pressure data """
        if not null_pressures:
            return
        msg = "\n".join(
            [
                tools_qt.tr("Pipes with invalid pressures: {qtd}."),
                tools_qt.tr(
                    "These pipes received the maximum longevity value for their material."
                ),
            ]
        )
        return msg.format(qtd=null_pressures)

    def _ivi_report(self, ivi, title=None):
        """ Format IVI values by year as report text """
        if not ivi:
            return ""
        title = title or tools_qt.tr("IVI")
        year_header = tools_qt.tr("Year")
        without_replacements_header = tools_qt.tr("Without replacements")
        with_replacements_header = tools_qt.tr("With replacements")
        columns = [
            [year_header],
            [without_replacements_header],
            [with_replacements_header],
        ]
        for year, (value_without, value_with) in ivi.items():
            columns[0].append(str(year))
            columns[1].append(f"{value_without:.3f}")
            columns[2].append(f"{value_with:.3f}")
        for column in columns:
            length = max(len(x) for x in column)
            for index, string in enumerate(column):
                column[index] = string.ljust(length)

        txt = f"{title}:\n"
        for line in zip(*columns):
            txt += "  ".join(line)
            txt += "\n"
        return txt.strip()

    def _arc_pressure(self, arc):
        """Average / fallback pressure used by ARC useful-life banding."""
        if arc.get("press1") is None and arc.get("press2") is None:
            return 0
        if arc.get("press2") is None:
            return arc["press1"]
        if arc.get("press1") is None:
            return arc["press2"]
        return (arc["press1"] + arc["press2"]) / 2

    def _material_age_from_row(self, mat_row, pressure):
        """Same banding as ConfigMaterial.get_age (max / med / min)."""
        if pressure < 50:
            return mat_row["age_max"]
        if pressure < 75:
            return mat_row["age_med"]
        return mat_row["age_min"]

    def _load_linked_arc_ivi_assets(self, arc_result_id):
        """Rebuild ARC IVI inputs for a saved ARC result (filters + that result's configs)."""
        cat = tools_db.get_row(
            f"""
            SELECT result_name, features, expl_id, presszone_id, dnom, material_id
            FROM am.cat_result
            WHERE result_id = {int(arc_result_id)}
              AND COALESCE(asset_type, 'ARC') = 'ARC'
            """,
            is_thread=True,
        )
        if not cat:
            return [], None

        mat_rows = tools_db.get_rows(
            f"""
            SELECT material, age_max, age_med, age_min, builtdate_vdef
            FROM am.config_material
            WHERE result_id = {int(arc_result_id)}
            """,
            is_thread=True,
        ) or []
        materials = {row["material"]: row for row in mat_rows}
        if not materials:
            return [], cat["result_name"]

        cost_rows = tools_db.get_rows(
            f"""
            SELECT arccat_id, cost_constr
            FROM am.config_catalog
            WHERE result_id = {int(arc_result_id)}
            """,
            is_thread=True,
        ) or []
        costs = {row["arccat_id"]: row["cost_constr"] for row in cost_rows}

        out_rows = tools_db.get_rows(
            f"""
            SELECT arc_id, replacement_year
            FROM am.arc_output
            WHERE result_id = {int(arc_result_id)}
            """,
            is_thread=True,
        ) or []
        replacement_by_arc = {
            row["arc_id"]: row["replacement_year"] for row in out_rows
        }

        filter_list = []
        features = cat["features"]
        if features:
            feature_ids = "','".join(str(f) for f in features)
            filter_list.append(f"a.arc_id in ('{feature_ids}')")
        if cat["expl_id"] is not None:
            filter_list.append(f"a.expl_id = {cat['expl_id']}")
        if cat["presszone_id"]:
            filter_list.append(f"a.presszone_id = '{cat['presszone_id']}'")
        if cat["dnom"] is not None:
            filter_list.append(f"a.dnom = '{cat['dnom']:g}'")
        if cat["material_id"]:
            filter_list.append(f"a.matcat_id = '{cat['material_id']}'")
        filters = f"where {' and '.join(filter_list)}" if filter_list else ""

        rows = tools_db.get_rows(
            f"""
            SELECT
                a.arc_id,
                a.arccat_id,
                a.matcat_id,
                st_length(a.the_geom) AS length,
                a.builtdate,
                a.press1,
                a.press2
            FROM am.ext_arc_asset a
            {filters}
            """,
            is_thread=True,
        ) or []

        assets = []
        for arc in rows:
            mat = arc.get("matcat_id")
            mat_row = materials.get(mat) or materials.get(self.unknown_material)
            if not mat_row:
                continue
            cost_by_m = costs.get(arc["arccat_id"])
            if cost_by_m is None:
                continue
            pressure = self._arc_pressure(arc)
            asset = {
                "arc_id": arc["arc_id"],
                "matcat_id": mat or self.unknown_material,
                "builtdate": arc["builtdate"],
                "cost_constr": float(cost_by_m) * float(arc["length"] or 0),
                "total_expected_useful_life": self._material_age_from_row(mat_row, pressure),
            }
            if arc["arc_id"] in replacement_by_arc:
                asset["replacement_year"] = replacement_by_arc[arc["arc_id"]]
            assets.append(asset)
        return assets, cat["result_name"]

    def _replacement_cost(self, arcs):
        """ Sum replacement construction cost for arcs """
        return sum(float(arc.get("cost_constr") or 0) for arc in arcs)

    def _yearly_replacement_report(self, output_arcs):
        """ Format yearly replacement counts and costs as report text """
        # output_arcs: [arc_id, cost_repmain, cost_constr, bratemain, year, ...]
        by_year = {}
        for arc in output_arcs:
            year = arc[4]
            cost = arc[2]
            if year is None:
                continue
            if year not in by_year:
                by_year[year] = {"n_arcs": 0, "cost": 0.0}
            by_year[year]["n_arcs"] += 1
            by_year[year]["cost"] += cost

        if not by_year:
            return ""

        title = tools_qt.tr("REPLACEMENTS PER YEAR")
        year_h = tools_qt.tr("Year")
        arcs_h = tools_qt.tr("Arcs")
        cost_h = tools_qt.tr("Cost (€)")

        columns = [[year_h], [arcs_h], [cost_h]]
        for year in sorted(by_year):
            columns[0].append(str(year))
            columns[1].append(str(by_year[year]["n_arcs"]))
            columns[2].append(f"{by_year[year]['cost']:.2f}")

        for column in columns:
            length = max(len(x) for x in column)
            for i, s in enumerate(column):
                column[i] = s.ljust(length)

        txt = f"{title}:\n"
        for line in zip(*columns):
            txt += "  ".join(line) + "\n"
        return txt.strip()

    def _run_sh(self):
        """ Run Shamir-Howard priority calculation for ARC assets """
        self._emit_report(tools_qt.tr("Getting auxiliary data from DB") + " (1/5)...")
        self.setProgress(0)

        discount_rate = float(self.config_engine["drate"])
        break_growth_rate = float(self.config_engine["bratemain0"])

        rows = tools_db.get_row(
            "select max(date_part('year', date)) from am.leaks", is_admin=True, is_thread=True
        )

        if not rows:
            return

        last_leak_year = rows[0]

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False
        self._emit_report(tools_qt.tr("Getting pipe data from DB") + " (2/5)...")
        self.setProgress(20)

        arcs = self._get_arcs()
        if not arcs:
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No pipes found matching your selected filters."),
            )
            return False

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False
        self._emit_report(tools_qt.tr("Calculating values") + " (3/5)...")
        self.setProgress(40)

        output_arcs = []
        invalid_material = {"qtd": 0, "set": set()}
        invalid_diameter = {"qtd": 0, "set": set()}
        for arc in arcs:
            (arc_id, arccat_id, arc_material, arc_diameter, arc_length, rleak, expl_id, presszone_id, strategic) = arc
            if not self.config_material.has_material(arc_material):
                invalid_material["qtd"] += 1
                invalid_material["set"].add(arc_material)
                if not self.config_material.has_material(self.unknown_material):
                    continue
                arc_material = self.unknown_material
            if (
                arc_diameter is None
                or int(arc_diameter) <= 0
                or int(arc_diameter) > self.config_catalog.max_diameter()
            ):
                invalid_diameter["qtd"] += 1
                invalid_diameter["set"].add(arc_diameter)
                continue
            if arc_length is None:
                continue
            if self.exploitation and self.exploitation != expl_id:
                continue
            if self.presszone and self.presszone != presszone_id:
                continue
            if self.diameter and self.diameter != arc_diameter:
                continue
            if self.material and self.material != arc_material:
                continue

            cost_repmain = self.config_catalog.get_cost_repmain(arccat_id)

            replacement_cost = self.config_catalog.get_cost_constr(arccat_id)
            cost_constr = replacement_cost * float(arc_length)

            compliance = 10 - min(
                self.config_catalog.get_compliance(arccat_id),
                self.config_material.get_compliance(arc_material),
            )

            strategic_val = 10 if strategic else 0

            if rleak == 0 or rleak is None:
                year = None
            else:
                year = int(
                    optimal_replacement_time(
                        last_leak_year,
                        float(rleak),
                        break_growth_rate,
                        cost_repmain,
                        replacement_cost * 1000,
                        discount_rate / 100,
                    )
                )

            if year is not None and year > self.target_year:
                continue

            output_arcs.append(
                [
                    arc_id,
                    cost_repmain,
                    cost_constr,
                    break_growth_rate,
                    year,
                    compliance,
                    strategic_val,
                ]
            )
        if not len(output_arcs):
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No pipes found matching your selected filters."),
            )
            return False

        self.setProgress(50)

        years = [x[4] for x in output_arcs if x[4]]
        min_year = min(years) if years else None
        max_year = max(years) if years else None

        for arc in output_arcs:
            _, _, _, _, year, compliance, strategic = arc
            year_order = 0
            if max_year and min_year:
                year_order = 10 * (
                    1 - ((year or max_year) - min_year) / (max_year - min_year)
                )
            val = (
                year_order * self.config_engine["expected_year"]
                + compliance * self.config_engine["compliance"]
                + strategic * self.config_engine["strategic"]
            )
            arc.extend([year_order, val])

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False
        self._emit_report(tools_qt.tr("Updating tables") + " (4/5)...")
        self.setProgress(60)

        self.statistics_report = "\n\n".join(
            filter(
                lambda x: x,
                [
                    self._yearly_replacement_report(output_arcs),
                    self._invalid_diameter_report(invalid_diameter),
                    self._invalid_material_report(invalid_material),
                ],
            )
        )

        self.result_id = self._save_result_info()

        if not self.result_id:
            return False

        self.config_catalog.save(self.result_id)

        self.setProgress(66)

        self.config_material.save(self.result_id)

        self.setProgress(69)

        self._save_config_engine()

        self.setProgress(72)

        tools_db.execute_sql(
            f"delete from am.arc_engine_sh where result_id = {self.result_id};",
            is_thread=True
        )
        index = 0
        loop = 0
        ended = False
        while not ended:
            save_arcs_sql = """
                insert into am.arc_engine_sh (
                    arc_id,
                    result_id,
                    cost_repmain,
                    cost_constr,
                    bratemain,
                    year,
                    compliance,
                    strategic,
                    year_order,
                    val
                ) values
            """
            for i in range(1000):
                try:
                    (
                        arc_id,
                        cost_repmain,
                        cost_constr,
                        break_growth_rate,
                        year,
                        compliance,
                        strategic,
                        year_order,
                        val,
                    ) = output_arcs[index]
                    save_arcs_sql += f"""
                        ({arc_id},
                        {self.result_id},
                        {cost_repmain},
                        {cost_constr},
                        {break_growth_rate},
                        {year or 'NULL'},
                        {compliance},
                        {strategic},
                        {year_order},
                        {val}),
                    """
                    index += 1
                except IndexError:
                    ended = True
                    break
            save_arcs_sql = save_arcs_sql.strip()[:-1]
            tools_db.execute_sql(save_arcs_sql, is_thread=True)
            loop += 1
            progress = (76 - 72) / len(output_arcs) * 1000 * loop + 72
            self.setProgress(progress)

        tools_db.execute_sql(
            f"""
            delete from am.arc_output
                where result_id = {self.result_id};
            insert into am.arc_output (arc_id,
                    result_id,
                    dnom,
                    matcat_id,
                    val,
                    orderby,
                    expected_year,
                    budget,
                    total,
                    length,
                    cum_length,
                    mandatory,
                    strategic,
                    rleak,
                    compliance)
                select arc_id,
                    sh.result_id,
                    a.dnom,
                    a.matcat_id,
                    val,
                    rank()
                        over (order by coalesce(i.mandatory, false) desc, val desc),
                    year,
                    cost_constr,
                    sum(cost_constr)
                        over (order by coalesce(i.mandatory, false) desc, val desc, arc_id)
                        as total,
                    st_length(a.the_geom),
                    sum(st_length(a.the_geom))
                        over (order by coalesce(i.mandatory, false) desc, val desc, arc_id),
                    mandatory,
                    i.strategic,
                    rleak,
                    10 - sh.compliance
                from am.arc_engine_sh sh
                left join am.arc_input i using (arc_id)
                left join am.ext_arc_asset a using (arc_id)
                where sh.result_id = {self.result_id}
                order by total;
            """,
            is_thread=True
        )

        self._copy_input_to_output()

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False
        self._emit_report(tools_qt.tr("Generating result stats") + " (5/5)...")
        self.setProgress(80)

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(self.statistics_report)
        self._emit_report(tools_qt.tr("Task finished!"))

        return True

    def _run_wm(self):
        """Dispatch the Weighted Method calculation to the ARC or NODE implementation."""
        if self.asset_type == "NODE":
            return self._run_node_wm()
        if self.asset_type == "LINK":
            return self._run_link_wm()
        return self._run_arc_wm()

    def _run_arc_wm(self):
        """ Run Weighted Method two-iteration calculation for ARC assets """
        pd = tools_os.get_dep("pandas")

        self._emit_report(tools_qt.tr("Getting auxiliary data from DB") + " (1/4)...")
        self.setProgress(10)

        self._update_mincut_criticity()

        rows = tools_db.get_rows(
            """
            with lengths AS (
                select a.dma_id, sum(st_length(a.the_geom)) as length
                from am.ext_arc_asset a
                group by dma_id
            )
            select d.dma_id, (d.nrw / d.days / l.length * 1000) as nrw_m3kmd
            from am.dma_nrw as d
            join lengths as l using (dma_id)
            """,
            is_thread=True
        )

        if not rows:
            return

        nrw = {row["dma_id"]: row["nrw_m3kmd"] for row in rows}

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Getting pipe data from DB") + " (2/4)...")
        self.setProgress(20)

        rows = self._get_arcs()
        if not rows:
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No pipes found matching your selected filters."),
            )
            return False

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Calculating values") + " (3/4)...")
        self.setProgress(30)

        arcs = []
        invalid_arccat_id = {"qtd": 0, "set": set()}
        invalid_material = {"qtd": 0, "set": set()}
        null_pressures = 0
        for row in rows:
            # Convert arc from psycopg2.extras.DictRow to OrderedDict
            arc = row.copy()
            if not self.config_catalog.has_key(arc["arccat_id"]):
                invalid_arccat_id["qtd"] += 1
                invalid_arccat_id["set"].add(arc["arccat_id"])
                continue
            if arc["length"] is None:
                continue

            arc_material = arc.get("matcat_id", None)
            if (
                not arc_material
                or arc_material == self.unknown_material
                or not self.config_material.has_material(arc_material)
            ):
                invalid_material["qtd"] += 1
                invalid_material["set"].add(arc_material or "NULL")
                if not self.config_material.has_material(self.unknown_material):
                    continue

            arc["mleak"] = self.config_material.get_pleak(arc_material)

            arc["cost_by_meter"] = self.config_catalog.get_cost_constr(arc["arccat_id"])
            arc["cost_constr"] = arc["cost_by_meter"] * float(arc["length"])

            arc["calculated_builtdate"] = arc["builtdate"] or date(
                self.config_material.get_default_builtdate(arc_material), 1, 1
            )
            if arc["press1"] is None and arc["press2"] is None:
                null_pressures += 1
            pressure = (
                0
                if arc["press1"] is None and arc["press2"] is None
                else arc["press1"]
                if arc["press2"] is None
                else arc["press2"]
                if arc["press1"] is None
                else (arc["press1"] + arc["press2"]) / 2
            )
            arc["total_expected_useful_life"] = self.config_material.get_age(
                arc_material, pressure
            )
            # one_year = timedelta(days=365)  # TODO: Remove this line if not needed
            duration = arc["total_expected_useful_life"]
            # TODO: Remove this line if not needed
            # remaining_years = arc["calculated_builtdate"].year + duration - date.today().year
            # Actual age of the arc
            real_years = date.today().year - arc["calculated_builtdate"].year
            # Calculate the longevity value [real life/ expected useful life]
            arc["longevity"] = real_years / duration

            # Calculate the current cost of construction
            current_cost_constr = arc["cost_constr"] * (1 - arc["longevity"])
            arc["current_cost_constr"] = current_cost_constr if current_cost_constr >= 0 else 0

            arc["nrw"] = nrw.get(arc["dma_id"], 0)

            arc["material_compliance"] = self.config_material.get_compliance(
                arc["matcat_id"]
            )
            arc["catalog_compliance"] = self.config_catalog.get_compliance(
                arc["arccat_id"]
            )

            arc["compliance"] = min(
                arc["material_compliance"],
                arc["catalog_compliance"],
            )

            # NULL means no mincut footprint; keep distinct from criticity = 1
            if "mincut_customers" not in arc:
                arc["mincut_customers"] = None
            if "mincut_criticity" not in arc:
                arc["mincut_criticity"] = None

            arcs.append(arc)

        min_rleak = min(arc["rleak"] for arc in arcs)
        max_rleak = max(arc["rleak"] for arc in arcs)

        min_mleak = min(arc["mleak"] for arc in arcs)
        max_mleak = max(arc["mleak"] for arc in arcs)

        min_longevity = min(arc["longevity"] for arc in arcs)
        max_longevity = max(arc["longevity"] for arc in arcs)

        min_flow = min(arc["flow_avg"] for arc in arcs)
        max_flow = max(arc["flow_avg"] for arc in arcs)

        mincut_values = [
            arc["mincut_customers"]
            for arc in arcs
            if arc["mincut_customers"] is not None
        ]
        min_mincut = min(mincut_values) if mincut_values else None
        max_mincut = max(mincut_values) if mincut_values else None

        for arc in arcs:
            arc["val_rleak"] = self._fit_to_scale(arc["rleak"], min_rleak, max_rleak)
            arc["val_mleak"] = self._fit_to_scale(arc["mleak"], min_mleak, max_mleak)
             # New Longevity formula
            denominator = max_longevity - min_longevity
            arc["val_longevity"] = ((arc["longevity"] - min_longevity) * 10) / denominator if denominator != 0 else 1
            #   - flow (how to take in account ficticious flows?)
            arc["val_flow"] = self._fit_to_scale(arc["flow_avg"], min_flow, max_flow)
            arc["val_nrw"] = (
                0
                if arc["nrw"] < 2
                else 10
                if arc["nrw"] > 20
                else self._fit_to_scale(arc["nrw"], 2, 20)
            )
            arc["val_strategic"] = 10 if arc["strategic"] else 0
            arc["val_compliance"] = 10 - arc["compliance"]

            # Prefer DB precomputed criticity; recompute for the current selection if missing
            if arc["mincut_criticity"] is None and arc["mincut_customers"] is not None:
                arc["mincut_criticity"] = self._fit_mincut_criticity(
                    arc["mincut_customers"], min_mincut, max_mincut
                )
            arc["val_mincut_criticity"] = (
                float(arc["mincut_criticity"])
                if arc["mincut_criticity"] is not None
                else 0.0
            )

            # First iteration weights
            arc["w1_rleak"] = self.config_engine["rleak_1"]
            arc["w1_mleak"] = self.config_engine["mleak_1"]
            arc["w1_longevity"] = self.config_engine["longevity_1"]
            arc["w1_flow"] = self.config_engine["flow_1"]
            arc["w1_nrw"] = self.config_engine["nrw_1"]
            arc["w1_strategic"] = self.config_engine["strategic_1"]
            arc["w1_compliance"] = self.config_engine["compliance_1"]
            arc["w1_mincut_criticity"] = float(
                self.config_engine.get("mincut_criticity_1", 0) or 0
            )

            # Second iteration weights
            arc["w2_rleak"] = self.config_engine["rleak_2"]
            arc["w2_mleak"] = self.config_engine["mleak_2"]
            arc["w2_longevity"] = self.config_engine["longevity_2"]
            arc["w2_flow"] = self.config_engine["flow_2"]
            arc["w2_nrw"] = self.config_engine["nrw_2"]
            arc["w2_strategic"] = self.config_engine["strategic_2"]
            arc["w2_compliance"] = self.config_engine["compliance_2"]
            arc["w2_mincut_criticity"] = float(
                self.config_engine.get("mincut_criticity_2", 0) or 0
            )

            arc["val_1"] = (
                arc["val_rleak"] * arc["w1_rleak"]
                + arc["val_mleak"] * arc["w1_mleak"]
                + arc["val_longevity"] * arc["w1_longevity"]
                + arc["val_flow"] * arc["w1_flow"]
                + arc["val_nrw"] * arc["w1_nrw"]
                + arc["val_strategic"] * arc["w1_strategic"]
                + arc["val_compliance"] * arc["w1_compliance"]
                + arc["val_mincut_criticity"] * arc["w1_mincut_criticity"]
            )
            arc["val_2"] = (
                arc["val_rleak"] * arc["w2_rleak"]
                + arc["val_mleak"] * arc["w2_mleak"]
                + arc["val_longevity"] * arc["w2_longevity"]
                + arc["val_flow"] * arc["w2_flow"]
                + arc["val_nrw"] * arc["w2_nrw"]
                + arc["val_strategic"] * arc["w2_strategic"]
                + arc["val_compliance"] * arc["w2_compliance"]
                + arc["val_mincut_criticity"] * arc["w2_mincut_criticity"]
            )

        # First iteration
        arcs.sort(key=lambda x: x["val_1"], reverse=True)
        arcs.sort(key=lambda x: x["mandatory"], reverse=True)
        cum_cost_constr = 0
        second_iteration = []
        for arc in arcs:
            second_iteration.append(arc)
            cum_cost_constr += arc["cost_constr"]
            if cum_cost_constr > self.result_budget * (
                self.target_year - date.today().year
            ):
                break

        if not len(second_iteration):
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No pipes found matching your budget. (Hint: increase the yearly budget or/and the horizon year)"),
            )
            return False

        # Second iteration
        second_iteration.sort(key=lambda x: x["val_2"], reverse=True)
        second_iteration.sort(key=lambda x: x["mandatory"], reverse=True)
        replacement_year = date.today().year + 1
        cum_cost_constr = 0
        cum_length = 0

        for arc in second_iteration:
            # Assign arc to current year before checking for overflow
            cum_cost_constr += arc["cost_constr"]
            cum_length += arc["length"]

            arc["replacement_year"] = replacement_year
            arc["cum_cost_constr"] = cum_cost_constr
            arc["cum_length"] = cum_length

            # If the budget is exceeded, increment the year for the *next* arc
            if cum_cost_constr > self.result_budget:
                replacement_year += 1
                cum_cost_constr = 0
                cum_length = 0

        for arc in arcs:
            # Check if the arc is in second_iteration, and update it
            matching_arc = next((arc_2 for arc_2 in second_iteration if arc_2['arc_id'] == arc['arc_id']), None)
            if matching_arc:
                # Update the arc in arcs with the modified data from second_iteration
                arc.update(matching_arc)

        # Save all arcs (both to be replaced and not replaced) to a DataFrame
        self.df = pd.DataFrame(arcs).reset_index(drop=True)
        self.df = self.df[
            [
                "arc_id",
                "matcat_id",
                "arccat_id",
                "dnom",
                "rleak",
                "val_rleak",
                "w1_rleak",
                "w2_rleak",
                "mleak",
                "val_mleak",
                "w1_mleak",
                "w2_mleak",
                "calculated_builtdate",
                "total_expected_useful_life",
                "longevity",
                "val_longevity",
                "w1_longevity",
                "w2_longevity",
                "flow_avg",
                "val_flow",
                "w1_flow",
                "w2_flow",
                "dma_id",
                "nrw",
                "val_nrw",
                "w1_nrw",
                "w2_nrw",
                "material_compliance",
                "catalog_compliance",
                "compliance",
                "val_compliance",
                "w1_compliance",
                "w2_compliance",
                "mincut_customers",
                "mincut_criticity",
                "val_mincut_criticity",
                "w1_mincut_criticity",
                "w2_mincut_criticity",
                "val_strategic",
                "w1_strategic",
                "w2_strategic",
                "mandatory",
                "cost_by_meter",
                "length",
                "cost_constr",
                "current_cost_constr",
                "val_1",
                "val_2",
                "cum_cost_constr",
                "cum_length",
                "replacement_year",
            ]
        ]

        # IVI calculation
        ivi = self._build_ivi_series(arcs)

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Updating tables") + " (4/4)...")
        self.setProgress(40)

        self.statistics_report = "\n\n".join(
            filter(
                lambda x: x,
                [
                    self._summary(arcs),
                    self._ivi_report(ivi),
                    self._invalid_arccat_id_report(invalid_arccat_id),
                    self._invalid_material_report(invalid_material),
                    self._invalid_pressures_report(null_pressures),
                ],
            )
        )

        self.result_id = self._save_result_info()
        if not self.result_id:
            return False

        self.config_catalog.save(self.result_id)
        self.config_material.save(self.result_id)
        self._save_config_engine()

        tools_db.execute_sql(
            f"""
            delete from am.arc_engine_wm where result_id = {self.result_id};
            delete from am.arc_output where result_id = {self.result_id};
            """,
            is_thread=True
        )

        # Saving to am.arc_engine_wm
        index = 0
        loop = 0
        ended = False
        while not ended:
            save_arcs_sql = """
                insert into am.arc_engine_wm (
                    arc_id,
                    result_id,
                    rleak,
                    longevity,
                    pressure,
                    flow,
                    nrw,
                    strategic,
                    compliance,
                    mincut_customers,
                    mincut_criticity,
                    val_first,
                    val
                ) values
            """
            for i in range(1000):
                try:
                    arc = second_iteration[index]
                    mincut_customers_sql = (
                        arc["mincut_customers"]
                        if arc["mincut_customers"] is not None
                        else "NULL"
                    )
                    mincut_criticity_sql = (
                        arc["mincut_criticity"]
                        if arc["mincut_criticity"] is not None
                        else "NULL"
                    )
                    save_arcs_sql += f"""
                        ({arc["arc_id"]},
                        {self.result_id},
                        {arc["val_rleak"]},
                        {arc["val_longevity"]},
                        NULL,
                        {arc["val_flow"]},
                        {arc["val_nrw"]},
                        {arc["val_strategic"]},
                        {arc["val_compliance"]},
                        {mincut_customers_sql},
                        {mincut_criticity_sql},
                        {arc["val_1"]},
                        {arc["val_2"]}
                        ),
                    """
                    index += 1
                except IndexError:
                    ended = True
                    break
            save_arcs_sql = save_arcs_sql.strip()[:-1]
            tools_db.execute_sql(save_arcs_sql, is_thread=True)
            loop += 1
            progress = (70 - 40) / len(second_iteration) * 1000 * loop + 40
            self.setProgress(progress)

        # Saving to am.arc_output
        index = 0
        loop = 0
        ended = False
        while not ended:
            save_arcs_sql = """
                insert into am.arc_output (
                    arc_id,
                    result_id,
                    arccat_id,
                    matcat_id,
                    dnom,
                    rleak,
                    builtdate,
                    press1,
                    press2,
                    flow_avg,
                    dma_id,
                    strategic,
                    nrw,
                    longevity,
                    mincut_customers,
                    mincut_criticity,
                    val,
                    mandatory,
                    compliance,
                    orderby,
                    expected_year,
                    replacement_year,
                    budget,
                    total,
                    length,
                    cum_length
                ) values
            """
            for i in range(1000):
                try:
                    arc = second_iteration[index]
                    if arc["replacement_year"] > self.target_year:
                        ended = True
                        break
                    builtdate_str = (
                        f"'{arc['builtdate'].isoformat()}'"
                        if arc["builtdate"]
                        else "NULL"
                    )
                    mincut_customers_sql = (
                        arc["mincut_customers"]
                        if arc["mincut_customers"] is not None
                        else "NULL"
                    )
                    mincut_criticity_sql = (
                        arc["mincut_criticity"]
                        if arc["mincut_criticity"] is not None
                        else "NULL"
                    )
                    save_arcs_sql += f"""
                        ({arc["arc_id"]},
                        {self.result_id},
                        '{arc["arccat_id"]}',
                        '{arc["matcat_id"]}',
                        '{arc["dnom"]}',
                        {arc["rleak"]},
                        {builtdate_str},
                        {arc["press1"] or 'NULL'},
                        {arc["press2"] or 'NULL'},
                        {arc["flow_avg"]},
                        {arc["dma_id"]},
                        {arc["strategic"] or 'false'},
                        {arc["nrw"]},
                        {arc["longevity"]},
                        {mincut_customers_sql},
                        {mincut_criticity_sql},
                        {arc["val_2"]},
                        {arc["mandatory"]},
                        {arc["compliance"]},
                        {index + 1},
                        {date.today().year + arc["longevity"]},
                        {arc["replacement_year"]},
                        {arc["cost_constr"]},
                        {arc["cum_cost_constr"]},
                        {arc["length"]},
                        {arc["cum_length"]}
                        ),
                    """
                    index += 1
                except IndexError:
                    ended = True
                    break
            save_arcs_sql = save_arcs_sql.strip()[:-1]
            if save_arcs_sql.endswith("value"):
                break
            tools_db.execute_sql(save_arcs_sql, is_thread=True)
            loop += 1
            progress = (90 - 70) / len(second_iteration) * 1000 * loop + 70
            self.setProgress(progress)

        self._copy_input_to_output()

        self._emit_report(self.statistics_report)

        self._emit_report(tools_qt.tr("Task finished!"))
        return True

    def _compute_affected_arcs_raw(self, nodes):
        """Set affected_arcs_raw = share of adjacent arcs in the linked ARC plan.

        Only nodes with ≥2 adjacent arcs in that plan get a ratio (0–1); others stay
        None so they score 0. No linked ARC → all None.
        """
        for node in nodes:
            node["affected_arcs_raw"] = None
        if not nodes or not self.linked_arc_result_id:
            return

        parent = lib_vars.schema_name
        if not parent:
            return

        replaced_rows = tools_db.get_rows(
            f"""
            SELECT arc_id
            FROM am.arc_output
            WHERE result_id = {int(self.linked_arc_result_id)}
            """,
            is_thread=True,
        ) or []
        replaced = {row["arc_id"] for row in replaced_rows}
        if not replaced:
            return

        adj_rows = tools_db.get_rows(
            f"""
            SELECT arc_id, node_1, node_2
            FROM {parent}.arc
            WHERE state = 1
              AND node_1 IS NOT NULL
              AND node_2 IS NOT NULL
            """,
            is_thread=True,
        ) or []
        adjacency = {}
        for row in adj_rows:
            for node_id in (row["node_1"], row["node_2"]):
                adjacency.setdefault(node_id, []).append(row["arc_id"])

        scored = 0
        for node in nodes:
            arcs = adjacency.get(node["node_id"]) or []
            if not arcs:
                continue
            n_replaced = sum(1 for arc_id in arcs if arc_id in replaced)
            # "Between two arcs that are going to be modified"
            if n_replaced < 2:
                continue
            node["affected_arcs_raw"] = n_replaced / len(arcs)
            scored += 1

        if scored:
            self._emit_report(
                tools_qt.tr(
                    "Affected Arcs: {0} nodes scored from linked ARC result.",
                    list_params=(scored,),
                )
            )

    def _prepare_nodes_for_wm(self, rows, nrw_by_dma, today_year):
        """ Build NODE WM working rows; skip invalid catalog/material. """
        nodes = []
        invalid_nodecat_id = {"qtd": 0, "set": set()}
        invalid_material = {"qtd": 0, "set": set()}
        for row in rows:
            node = row.copy()
            nodecat_id = node.get("nodecat_id")
            if not self.config_catalog or not self.config_catalog.has_key(nodecat_id):
                invalid_nodecat_id["qtd"] += 1
                invalid_nodecat_id["set"].add(nodecat_id or "NULL")
                continue

            node_material = node.get("matcat_id")
            if (
                not node_material
                or node_material == self.unknown_material
                or not self.config_material.has_material(node_material)
            ):
                invalid_material["qtd"] += 1
                invalid_material["set"].add(node_material or "NULL")
                if not self.config_material.has_material(self.unknown_material):
                    continue
                node_material = self.unknown_material
            node["matcat_id"] = node_material

            # Prefer overlay/ext age; fall back to builtdate / material default year
            if node.get("age") is None and node.get("builtdate"):
                node["age"] = today_year - node["builtdate"].year
            elif node.get("age") is None:
                default_year = self.config_material.get_default_builtdate(node_material)
                if default_year:
                    node["age"] = today_year - int(default_year)

            # DMA NRW wins when present; node_input.nrw_raw is the fallback
            node["nrw_raw"] = nrw_by_dma.get(node.get("dma_id"), node.get("nrw_raw"))

            # Cost from nodecatalog (unit), same role as ARC cost_constr * length
            catalog_cost = self.config_catalog.get_cost_constr(nodecat_id)
            if catalog_cost is not None:
                node["estimated_cost"] = max(float(catalog_cost), 0)
            else:
                node["estimated_cost"] = max(float(node.get("estimated_cost") or 0), 0)

            # Compliance grade from catalog + material (ARC pattern); keep input bool for output
            node["catalog_compliance"] = self.config_catalog.get_compliance(nodecat_id)
            node["material_compliance"] = self.config_material.get_compliance(node_material)
            node["compliance_grade"] = min(
                node["material_compliance"],
                node["catalog_compliance"],
            )
            nodes.append(node)
        return nodes, invalid_nodecat_id, invalid_material

    def _save_node_engine_wm(self, second_iteration):
        """ Batch-insert NODE WM engine scores. """
        index = 0
        loop = 0
        ended = False
        while not ended:
            save_nodes_sql = """
                insert into am.node_engine_wm (
                    node_id,
                    result_id,
                    longevity,
                    incident_history,
                    structural_condition,
                    operational_condition,
                    nrw,
                    affected_users,
                    strategic,
                    compliance,
                    val_first,
                    val,
                    orderby
                ) values
            """
            for i in range(1000):
                try:
                    node = second_iteration[index]
                    save_nodes_sql += f"""
                        ({node["node_id"]},
                        {self.result_id},
                        {node["val_longevity"]},
                        {node["val_incident_history"]},
                        {node["val_structural_condition"]},
                        {node["val_operational_condition"]},
                        {node["val_nrw"]},
                        {node["val_affected_users"]},
                        {node["val_strategic"]},
                        {node["val_compliance"]},
                        {node["val_1"]},
                        {node["val_2"]},
                        {index + 1}
                        ),
                    """
                    index += 1
                except IndexError:
                    ended = True
                    break
            save_nodes_sql = save_nodes_sql.strip()[:-1]
            tools_db.execute_sql(save_nodes_sql, is_thread=True)
            loop += 1
            progress = (70 - 40) / len(second_iteration) * 1000 * loop + 40
            self.setProgress(progress)


    def _save_node_output_wm(self, second_iteration):
        """ Batch-insert NODE WM output rows. """
        index = 0
        loop = 0
        ended = False
        while not ended:
            save_nodes_sql = """
                insert into am.node_output (
                    node_id,
                    result_id,
                    longevity,
                    incident_history,
                    structural_condition,
                    operational_condition,
                    nrw,
                    affected_users,
                    strategic,
                    mandatory,
                    compliance,
                    val,
                    orderby,
                    replacement_year,
                    budget,
                    total,
                    estimated_cost
                ) values
            """
            for i in range(1000):
                try:
                    node = second_iteration[index]
                    if node["replacement_year"] > self.target_year:
                        # Years are non-decreasing along second_iteration → rest are out of horizon
                        ended = True
                        break
                    strategic_sql = (
                        "TRUE" if node.get("strategic") else
                        "FALSE" if node.get("strategic") is not None else "NULL"
                    )
                    compliance_sql = (
                        "TRUE" if node.get("compliance") else
                        "FALSE" if node.get("compliance") is not None else "NULL"
                    )
                    save_nodes_sql += f"""
                        ({node["node_id"]},
                        {self.result_id},
                        {node["val_longevity"]},
                        {node["val_incident_history"]},
                        {node["val_structural_condition"]},
                        {node["val_operational_condition"]},
                        {node["val_nrw"]},
                        {node["val_affected_users"]},
                        {strategic_sql},
                        {node["mandatory"]},
                        {compliance_sql},
                        {node["val_2"]},
                        {index + 1},
                        {node["replacement_year"]},
                        {node["estimated_cost"]},
                        {node["cum_cost"]},
                        {node["estimated_cost"]}
                        ),
                    """
                    index += 1
                except IndexError:
                    ended = True
                    break
            save_nodes_sql = save_nodes_sql.strip()[:-1]
            # After strip()[:-1], empty INSERT ends with "value" (not "values") — same as ARC.
            if save_nodes_sql.endswith("value"):
                break
            tools_db.execute_sql(save_nodes_sql, is_thread=True)
            loop += 1
            progress = (90 - 70) / len(second_iteration) * 1000 * loop + 70
            self.setProgress(progress)

    def _run_node_wm(self):
        """ Run Weighted Method two-iteration calculation for NODE assets """
        pd = tools_os.get_dep("pandas")

        self._emit_report(tools_qt.tr("Getting auxiliary data from DB") + " (1/4)...")
        self.setProgress(10)

        dma_rows = tools_db.get_rows(
            "select dma_id, nrw from am.dma_nrw", is_thread=True
        ) or []
        nrw_by_dma = {row["dma_id"]: row["nrw"] for row in dma_rows}

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Getting node data from DB") + " (2/4)...")
        self.setProgress(20)

        rows = self._get_nodes()
        if not rows:
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No nodes found matching your selected filters."),
            )
            return False

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Calculating values") + " (3/4)...")
        self.setProgress(30)

        today_year = date.today().year
        nodes, invalid_nodecat_id, invalid_material = self._prepare_nodes_for_wm(
            rows, nrw_by_dma, today_year
        )
        self._compute_affected_arcs_raw(nodes)

        if not nodes:
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No nodes found matching your selected filters."),
            )
            reports = [
                self._invalid_nodecat_id_report(invalid_nodecat_id),
                self._invalid_material_report(invalid_material),
            ]
            for report in reports:
                if report:
                    self._emit_report(report)
            return False

        # Stage2: MIN_MAX raw → scaled score name. BINARY handled separately.
        min_max_fields = {
            "age": "longevity",
            "incident_count": "incident_history",
            "structural_raw": "structural_condition",
            "operational_raw": "operational_condition",
            "nrw_raw": "nrw",
            "affected_users_raw": "affected_users",
            "affected_arcs_raw": "affected_arcs",
        }
        bounds = {}
        for field in min_max_fields:
            values = [n[field] for n in nodes if n.get(field) is not None]
            bounds[field] = (min(values), max(values)) if values else (None, None)

        for node in nodes:
            for field, score_name in min_max_fields.items():
                lo, hi = bounds[field]
                node[f"val_{score_name}"] = self._scale_or_zero(
                    self._normalize_min_max(node.get(field), lo, hi)
                )
            node["val_strategic"] = self._scale_or_zero(
                self._normalize_binary(node.get("strategic"))
            )
            # Same as ARC WM: lower compliance grade → higher priority score
            node["val_compliance"] = float(10 - node["compliance_grade"])

            for suffix in ("1", "2"):
                node[f"w{suffix}_longevity"] = float(self.config_engine[f"longevity_{suffix}"])
                node[f"w{suffix}_incident_history"] = float(self.config_engine[f"incident_history_{suffix}"])
                node[f"w{suffix}_structural_condition"] = float(self.config_engine[f"structural_condition_{suffix}"])
                node[f"w{suffix}_operational_condition"] = float(self.config_engine[f"operational_condition_{suffix}"])
                node[f"w{suffix}_nrw"] = float(self.config_engine[f"nrw_{suffix}"])
                node[f"w{suffix}_affected_users"] = float(self.config_engine[f"affected_users_{suffix}"])
                node[f"w{suffix}_strategic"] = float(self.config_engine[f"strategic_{suffix}"])
                node[f"w{suffix}_compliance"] = float(self.config_engine[f"compliance_{suffix}"])
                node[f"w{suffix}_affected_arcs"] = float(self.config_engine[f"affected_arcs_{suffix}"])

            for suffix in ("1", "2"):
                node[f"val_{suffix}"] = sum(
                    node[f"val_{score_name}"] * node[f"w{suffix}_{score_name}"]
                    for score_name in (
                        "longevity", "incident_history", "structural_condition",
                        "operational_condition", "nrw",
                        "affected_users", "strategic", "compliance", "affected_arcs",
                    )
                )

        # First iteration: yearly-budget * horizon window, ordered by mandatory then val_1
        nodes.sort(key=lambda x: x["val_1"], reverse=True)
        nodes.sort(key=lambda x: x["mandatory"], reverse=True)
        cum_cost = 0
        second_iteration = []
        for node in nodes:
            second_iteration.append(node)
            cum_cost += node["estimated_cost"]
            if cum_cost > self.result_budget * (self.target_year - today_year):
                break

        if not len(second_iteration):
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No nodes found matching your budget. (Hint: increase the yearly budget or/and the horizon year)"),
            )
            return False

        # Second iteration: assign replacement_year by yearly budget, ordered by mandatory then val_2
        second_iteration.sort(key=lambda x: x["val_2"], reverse=True)
        second_iteration.sort(key=lambda x: x["mandatory"], reverse=True)
        replacement_year = today_year + 1
        cum_cost = 0
        for node in second_iteration:
            cum_cost += node["estimated_cost"]
            node["replacement_year"] = replacement_year
            node["cum_cost"] = cum_cost
            if cum_cost > self.result_budget:
                replacement_year += 1
                cum_cost = 0

        for node in nodes:
            matching_node = next(
                (n2 for n2 in second_iteration if n2["node_id"] == node["node_id"]), None
            )
            if matching_node:
                node.update(matching_node)

        self._enrich_nodes_for_ivi(nodes)
        ivi_node = self._build_ivi_series(nodes)
        ivi_reports = [self._ivi_report(ivi_node, tools_qt.tr("IVI (NODE)"))]

        arc_assets = []
        arc_result_name = None
        if self.linked_arc_result_id:
            arc_assets, arc_result_name = self._load_linked_arc_ivi_assets(
                self.linked_arc_result_id
            )
            if arc_assets:
                arc_title = tools_qt.tr("IVI (ARC) - {0}", list_params=(arc_result_name,))
                ivi_reports.append(self._ivi_report(self._build_ivi_series(arc_assets), arc_title))
                ivi_reports.append(
                    self._ivi_report(
                        self._build_combined_ivi_series(arc_assets, nodes),
                        tools_qt.tr("IVI (COMBINED ARC+NODE)"),
                    )
                )
            else:
                self._emit_report(
                    tools_qt.tr(
                        "Linked ARC result has no assets for IVI; NODE IVI only."
                    )
                )

        self.df = pd.DataFrame(nodes).reset_index(drop=True)

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False
        self._emit_report(tools_qt.tr("Updating tables") + " (4/4)...")
        self.setProgress(40)

        self.statistics_report = "\n\n".join(
            filter(
                lambda x: x,
                [
                    self._node_summary(nodes, arc_assets=arc_assets),
                    *ivi_reports,
                    self._invalid_nodecat_id_report(invalid_nodecat_id),
                    self._invalid_material_report(invalid_material),
                ],
            )
        )

        self.result_id = self._save_result_info()
        if not self.result_id:
            return False

        if self.config_catalog is not None:
            self.config_catalog.save(self.result_id)
        if self.config_material is not None:
            self.config_material.save(self.result_id)
        self._save_config_engine()

        tools_db.execute_sql(
            f"""
            delete from am.node_engine_wm where result_id = {self.result_id};
            delete from am.node_output where result_id = {self.result_id};
            """,
            is_thread=True
        )

        self._save_node_engine_wm(second_iteration)
        self._save_node_output_wm(second_iteration)

        self._copy_node_input_to_output()

        self._emit_report(self.statistics_report)

        self._emit_report(tools_qt.tr("Task finished!"))
        self.setProgress(100)
        return True

    def _copy_link_input_to_output(self):
        """ Copy ext_link_asset attributes into link_output rows """
        tools_db.execute_sql(
            f"""
            update am.link_output o
            set (connec_id, arc_id, sector_id, macrosector_id, presszone_id, builtdate,
                 linkcat_id, matcat_id, the_geom, expl_id, dma_id, length)
                = (select connec_id, arc_id, sector_id, macrosector_id, presszone_id, builtdate,
                          linkcat_id, matcat_id, the_geom, expl_id, dma_id, length
                    from am.ext_link_asset a
                    where a.link_id = o.link_id)
            where o.result_id = {self.result_id}
            """,
            is_thread=True
        )
        tools_db.execute_sql(
            f"""
            UPDATE am.link_output o
            SET length = c.default_length
            FROM am.config_linkcatalog c
            WHERE o.result_id = {self.result_id}
              AND c.result_id = o.result_id
              AND c.linkcat_id = o.linkcat_id
              AND (o.length IS NULL OR o.length = 0)
              AND c.default_length IS NOT NULL
            """,
            is_thread=True
        )

    def _compute_parent_arc_selected_raw(self, links):
        """ODT §6.8: parent_arc_selected_raw from linked ARC result selected flag."""
        if not links:
            return
        if not self.linked_arc_result_id:
            for link in links:
                link["parent_arc_selected_raw"] = None
            return
        rows = tools_db.get_rows(
            f"""
            SELECT arc_id
            FROM am.arc_output
            WHERE result_id = {int(self.linked_arc_result_id)}
            """,
            is_thread=True
        ) or []
        selected_arcs = {r["arc_id"] for r in rows}
        for link in links:
            arc_id = link.get("arc_id")
            if arc_id is None or arc_id not in selected_arcs:
                link["parent_arc_selected_raw"] = None
            else:
                link["parent_arc_selected_raw"] = True

    def _prepare_links_for_wm(self, rows, today_year):
        """Build LINK WM working rows. Cost = fixed + length × pipe €/m (ODT §3)."""
        links = []
        invalid_linkcat_id = {"qtd": 0, "set": set()}
        for row in rows:
            link = row.copy()
            linkcat_id = link.get("linkcat_id")
            length = float(link.get("length") or 0)
            if (
                not length
                and self.config_catalog
                and linkcat_id
                and self.config_catalog.has_key(linkcat_id)
            ):
                length = float(self.config_catalog.get_default_length(linkcat_id) or 0)
                link["length"] = length

            if link.get("age") is None and link.get("builtdate"):
                link["age"] = today_year - link["builtdate"].year

            if self.config_catalog and linkcat_id and self.config_catalog.has_key(linkcat_id):
                fixed = float(self.config_catalog.get_cost_constr(linkcat_id) or 0)
                pipe_unit = float(self.config_catalog.get_cost_repmain(linkcat_id) or 0)
                link["estimated_cost"] = max(fixed + length * pipe_unit, 0)
            else:
                if linkcat_id:
                    invalid_linkcat_id["qtd"] += 1
                    invalid_linkcat_id["set"].add(linkcat_id or "NULL")
                overlay_cost = link.get("estimated_cost")
                link["estimated_cost"] = max(float(overlay_cost or 0), 0)

            links.append(link)
        return links, invalid_linkcat_id

    def _save_link_engine_wm(self, second_iteration):
        """ Batch-insert LINK WM engine scores. """
        index = 0
        loop = 0
        ended = False
        while not ended:
            save_sql = """
                insert into am.link_engine_wm (
                    link_id, result_id,
                    longevity, incident_history, material_condition,
                    affected_users, parent_arc_selected, strategic, compliance,
                    val_first, val, orderby
                ) values
            """
            for _i in range(1000):
                try:
                    link = second_iteration[index]
                    save_sql += f"""
                        ({link["link_id"]},
                        {self.result_id},
                        {link["val_longevity"]},
                        {link["val_incident_history"]},
                        {link["val_material_condition"]},
                        {link["val_affected_users"]},
                        {link["val_parent_arc_selected"]},
                        {link["val_strategic"]},
                        {link["val_compliance"]},
                        {link["val_1"]},
                        {link["val_2"]},
                        {index + 1}
                        ),
                    """
                    index += 1
                except IndexError:
                    ended = True
                    break
            save_sql = save_sql.strip()[:-1]
            tools_db.execute_sql(save_sql, is_thread=True)
            loop += 1
            progress = (70 - 40) / len(second_iteration) * 1000 * loop + 40
            self.setProgress(progress)

    def _save_link_output_wm(self, second_iteration):
        """ Batch-insert LINK WM output rows. """
        index = 0
        loop = 0
        ended = False
        while not ended:
            save_sql = """
                insert into am.link_output (
                    link_id, result_id, connec_id, arc_id,
                    longevity, incident_history, material_condition,
                    affected_users, parent_arc_selected,
                    strategic, mandatory, compliance,
                    val_first, val, orderby,
                    selected, expected_year, replacement_year,
                    budget, total, estimated_cost
                ) values
            """
            for _i in range(1000):
                try:
                    link = second_iteration[index]
                    if link["replacement_year"] > self.target_year:
                        ended = True
                        break
                    strategic_sql = (
                        "TRUE" if link.get("strategic") else
                        "FALSE" if link.get("strategic") is not None else "NULL"
                    )
                    compliance_sql = (
                        "TRUE" if link.get("compliance") else
                        "FALSE" if link.get("compliance") is not None else "NULL"
                    )
                    selected = "TRUE"
                    save_sql += f"""
                        ({link["link_id"]},
                        {self.result_id},
                        {link["connec_id"] if link.get("connec_id") is not None else "NULL"},
                        {link["arc_id"] if link.get("arc_id") is not None else "NULL"},
                        {link["val_longevity"]},
                        {link["val_incident_history"]},
                        {link["val_material_condition"]},
                        {link["val_affected_users"]},
                        {link["val_parent_arc_selected"]},
                        {strategic_sql},
                        {link["mandatory"]},
                        {compliance_sql},
                        {link["val_1"]},
                        {link["val_2"]},
                        {index + 1},
                        {selected},
                        {link["replacement_year"]},
                        {link["replacement_year"]},
                        {link["estimated_cost"]},
                        {link["cum_cost"]},
                        {link["estimated_cost"]}
                        ),
                    """
                    index += 1
                except IndexError:
                    ended = True
                    break
            save_sql = save_sql.strip()[:-1]
            if save_sql.endswith("value"):
                break
            tools_db.execute_sql(save_sql, is_thread=True)
            loop += 1
            progress = (90 - 70) / len(second_iteration) * 1000 * loop + 70
            self.setProgress(progress)

    def _run_link_wm(self):
        """ Run Weighted Method two-iteration calculation for LINK assets (ODT Stage 3). """
        pd = tools_os.get_dep("pandas")

        self._emit_report(tools_qt.tr("Getting auxiliary data from DB") + " (1/4)...")
        self.setProgress(10)

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Getting link data from DB") + " (2/4)...")
        self.setProgress(20)

        rows = self._get_links()
        if not rows:
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No links found matching your selected filters."),
            )
            return False

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Calculating values") + " (3/4)...")
        self.setProgress(30)

        today_year = date.today().year
        links, invalid_linkcat_id = self._prepare_links_for_wm(rows, today_year)
        self._compute_parent_arc_selected_raw(links)

        if not links:
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No links found matching your selected filters."),
            )
            return False

        min_max_fields = {
            "age": "longevity",
            "incident_count": "incident_history",
            "material_raw": "material_condition",
            "affected_users_raw": "affected_users",
        }
        bounds = {}
        for field in min_max_fields:
            values = [lk[field] for lk in links if lk.get(field) is not None]
            bounds[field] = (min(values), max(values)) if values else (None, None)

        score_names = (
            "longevity", "incident_history", "material_condition",
            "affected_users", "parent_arc_selected", "strategic", "compliance",
        )

        for link in links:
            for field, score_name in min_max_fields.items():
                lo, hi = bounds[field]
                link[f"val_{score_name}"] = self._scale_or_zero(
                    self._normalize_min_max(link.get(field), lo, hi)
                )
            link["val_parent_arc_selected"] = self._scale_or_zero(
                self._normalize_binary(link.get("parent_arc_selected_raw"))
            )
            link["val_strategic"] = self._scale_or_zero(
                self._normalize_binary(link.get("strategic"))
            )
            link["val_compliance"] = self._scale_or_zero(
                self._normalize_binary(link.get("compliance"))
            )

            for suffix in ("1", "2"):
                for score_name in score_names:
                    key = f"{score_name}_{suffix}"
                    link[f"w{suffix}_{score_name}"] = float(self.config_engine.get(key, 0) or 0)
                link[f"val_{suffix}"] = sum(
                    link[f"val_{score_name}"] * link[f"w{suffix}_{score_name}"]
                    for score_name in score_names
                )

        links.sort(key=lambda x: x["val_1"], reverse=True)
        links.sort(key=lambda x: x["mandatory"], reverse=True)
        cum_cost = 0
        second_iteration = []
        for link in links:
            second_iteration.append(link)
            cum_cost += link["estimated_cost"]
            if cum_cost > self.result_budget * (self.target_year - today_year):
                break

        if not len(second_iteration):
            self._emit_report(
                tools_qt.tr("Task canceled:"),
                tools_qt.tr("No links found matching your budget. (Hint: increase the yearly budget or/and the horizon year)"),
            )
            return False

        second_iteration.sort(key=lambda x: x["val_2"], reverse=True)
        second_iteration.sort(key=lambda x: x["mandatory"], reverse=True)
        replacement_year = today_year + 1
        cum_cost = 0
        for link in second_iteration:
            cum_cost += link["estimated_cost"]
            link["replacement_year"] = replacement_year
            link["cum_cost"] = cum_cost
            if cum_cost > self.result_budget:
                replacement_year += 1
                cum_cost = 0

        for link in links:
            matching = next(
                (l2 for l2 in second_iteration if l2["link_id"] == link["link_id"]), None
            )
            if matching:
                link.update(matching)

        self.df = pd.DataFrame(links).reset_index(drop=True)

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False
        self._emit_report(tools_qt.tr("Updating tables") + " (4/4)...")
        self.setProgress(40)

        selected = [lk for lk in links if lk.get("replacement_year")]
        total_cost = sum(lk["estimated_cost"] for lk in selected)
        replacement_cost = sum(lk["estimated_cost"] for lk in links)
        replacement_rate = (
            self.result_budget / replacement_cost * 100 if replacement_cost > 0 else 0
        )
        report_rows = [
            (tools_qt.tr("Investment (€/year):"), f"{self.result_budget:.2f}"),
            (tools_qt.tr("Year:"), f"{self.target_year}"),
            (tools_qt.tr("Links evaluated:"), f"{len(links)}"),
            (tools_qt.tr("Links selected for replacement:"), f"{len(selected)}"),
            (tools_qt.tr("Total renewal cost (€):"), f"{replacement_cost:.2f}"),
            (tools_qt.tr("Selected renewal cost (€):"), f"{total_cost:.2f}"),
            (tools_qt.tr("Replacement rate (%/year):"), f"{replacement_rate:.2f}"),
        ]
        if self.linked_arc_result_id:
            report_rows.append(
                (tools_qt.tr("Linked ARC result_id:"), f"{self.linked_arc_result_id}")
            )
        else:
            report_rows.append(
                (
                    tools_qt.tr("No parent arc result selected."),
                    tools_qt.tr("Parent arc selected criterion will contain no value."),
                )
            )
        self.statistics_report = self._format_report(tools_qt.tr("SUMMARY"), report_rows)
        if invalid_linkcat_id["qtd"]:
            self.statistics_report += "\n\n" + tools_qt.tr(
                "Links with unknown linkcat_id (cost 0): {qtd}. {list}."
            ).format(qtd=invalid_linkcat_id["qtd"], list=", ".join(invalid_linkcat_id["set"]))

        self.result_id = self._save_result_info()
        if not self.result_id:
            return False

        if self.config_catalog is not None:
            self.config_catalog.save(self.result_id)
        if self.config_material is not None:
            self.config_material.save(self.result_id)
        self._save_config_engine()

        tools_db.execute_sql(
            f"""
            delete from am.link_engine_wm where result_id = {self.result_id};
            delete from am.link_output where result_id = {self.result_id};
            """,
            is_thread=True
        )

        self._save_link_engine_wm(second_iteration)
        self._save_link_output_wm(second_iteration)
        self._copy_link_input_to_output()

        self._emit_report(self.statistics_report)
        self._emit_report(tools_qt.tr("Task finished!"))
        self.setProgress(100)
        return True

    def _save_config_engine(self):
        """ Persist engine parameter values for the result """
        save_config_engine_sql = f"""
            delete from am.config_engine where result_id = {self.result_id};
            insert into am.config_engine
                (result_id, parameter, value, asset_type)
            values
        """
        for k, v in self.config_engine.items():
            save_config_engine_sql += f"({self.result_id}, '{k}', {v}, '{self.asset_type}'),"
        save_config_engine_sql = save_config_engine_sql.strip()[:-1]
        tools_db.execute_sql(save_config_engine_sql, is_thread=True)

    def _save_result_info(self):
        """ Insert or update cat_result and return result_id """
        str_features = (
            f"""ARRAY['{"','".join(self.features)}']""" if self.features else "NULL"
        )
        str_presszone_id = f"'{self.presszone}'" if self.presszone else "NULL"
        str_material_id = f"'{self.material}'" if self.material else "NULL"
        str_nodecat = f"'{self.nodecat}'" if self.nodecat else "NULL"
        if isinstance(self.node_type, (list, tuple)) and self.node_type:
            escaped = [str(t).replace("'", "''") for t in self.node_type]
            str_node_type = f"'{','.join(escaped)}'"
        elif self.node_type:
            str_node_type = f"'{self.node_type}'"
        else:
            str_node_type = "NULL"
        linked_arc = (
            int(self.linked_arc_result_id)
            if self.linked_arc_result_id and self.asset_type in ("NODE", "LINK")
            else None
        )
        str_linked_arc = str(linked_arc) if linked_arc else "NULL"
        tools_db.execute_sql(
            f"""
            insert into am.cat_result (result_name,
                result_type,
                descript,
                status,
                features,
                expl_id,
                presszone_id,
                dnom,
                material_id,
                nodecat_id,
                node_type,
                budget,
                target_year,
                report,
                cur_user,
                tstamp,
                asset_type,
                linked_arc_result_id)
            values ('{self.result_name}',
                '{self.result_type}',
                '{self.result_description}',
                '{self.status}',
                {str_features},
                {self.exploitation or 'NULL'},
                {str_presszone_id},
                {self.diameter or 'NULL'},
                {str_material_id},
                {str_nodecat},
                {str_node_type},
                {self.result_budget or 'NULL'},
                {self.target_year or 'NULL'},
                '{self.statistics_report}',
                current_user,
                now(),
                '{self.asset_type}',
                {str_linked_arc})
            on conflict (result_name) do update
            set result_type = EXCLUDED.result_type,
                descript = EXCLUDED.descript,
                status = EXCLUDED.status,
                features = EXCLUDED.features,
                expl_id = EXCLUDED.expl_id,
                presszone_id = EXCLUDED.presszone_id,
                dnom = EXCLUDED.dnom,
                material_id = EXCLUDED.material_id,
                nodecat_id = EXCLUDED.nodecat_id,
                node_type = EXCLUDED.node_type,
                budget = EXCLUDED.budget,
                target_year = EXCLUDED.target_year,
                report = EXCLUDED.report,
                cur_user = EXCLUDED.cur_user,
                tstamp = EXCLUDED.tstamp,
                asset_type = EXCLUDED.asset_type,
                linked_arc_result_id = EXCLUDED.linked_arc_result_id
            """,
            is_thread=True
        )

        sql = f"select result_id from am.cat_result where result_name = '{self.result_name}'"
        row = tools_db.get_row(sql, is_admin=True, is_thread=True)
        if not row:
            return
        return row[0]

    def _summary(self, arcs):
        """ Build ARC weighted-method summary report block """
        current_cost = sum(arc["current_cost_constr"] for arc in arcs)

        replacement_cost = self._replacement_cost(arcs)
        ivi_target_year = self._calculate_ivi(arcs, self.target_year, True)
        replacement_rate = self.result_budget / replacement_cost * 100 if replacement_cost > 0 else 0

        rows = [
            (tools_qt.tr("Investment (€/year):"), f"{self.result_budget:.2f}"),
            (tools_qt.tr("Year:"), f"{self.target_year}"),
            (tools_qt.tr("Current network cost (€):"), f"{current_cost:.2f}"),
            (tools_qt.tr("Total renewal cost (€):"), f"{replacement_cost:.2f}"),
            (tools_qt.tr("IVI (Horizon year):"), f"{ivi_target_year:.3f}"),
            (tools_qt.tr("Replacement rate (%/year):"), f"{replacement_rate:.2f}"),
        ]
        return self._format_report(tools_qt.tr("SUMMARY"), rows)

    def _node_summary(self, nodes, arc_assets=None):
        """ Build NODE weighted-method summary report block """
        selected = [n for n in nodes if n.get("replacement_year")]
        total_cost = sum(n["estimated_cost"] for n in selected)
        replacement_cost = sum(n["estimated_cost"] for n in nodes)
        replacement_rate = (
            self.result_budget / replacement_cost * 100 if replacement_cost > 0 else 0
        )
        ivi_target_year = self._calculate_ivi(nodes, self.target_year, True)

        rows = [
            (tools_qt.tr("Investment (€/year):"), f"{self.result_budget:.2f}"),
            (tools_qt.tr("Year:"), f"{self.target_year}"),
            (tools_qt.tr("Nodes evaluated:"), f"{len(nodes)}"),
            (tools_qt.tr("Nodes selected for replacement:"), f"{len(selected)}"),
            (tools_qt.tr("Total renewal cost (€):"), f"{replacement_cost:.2f}"),
            (tools_qt.tr("Selected renewal cost (€):"), f"{total_cost:.2f}"),
            (tools_qt.tr("IVI NODE (Horizon year):"), f"{ivi_target_year:.3f}"),
            (tools_qt.tr("Replacement rate (%/year):"), f"{replacement_rate:.2f}"),
        ]
        if arc_assets:
            ivi_combined = self._calculate_combined_ivi(
                arc_assets, nodes, self.target_year, True
            )
            rows.append(
                (
                    tools_qt.tr("IVI COMBINED ARC+NODE (Horizon year):"),
                    f"{ivi_combined:.3f}",
                )
            )
            if self.linked_arc_result_id:
                rows.append(
                    (
                        tools_qt.tr("Linked ARC result_id:"),
                        f"{self.linked_arc_result_id}",
                    )
                )
        return self._format_report(tools_qt.tr("SUMMARY"), rows)
