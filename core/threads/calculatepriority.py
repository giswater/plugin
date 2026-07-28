"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

import configparser
import traceback
from datetime import date
from math import log, log1p, exp
from pathlib import Path

from qgis.core import QgsTask
from qgis.PyQt.QtCore import pyqtSignal

from .task import GwTask
from ...libs import lib_vars, tools_db, tools_os, tools_qt


def get_min_greater_than(iterable, value):
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

        if lib_vars.plugin_dir:
            config_path = Path(lib_vars.plugin_dir) / "config" / "giswater.config"
            config = configparser.ConfigParser()
            config.read(config_path)
            self.method = config.get("general", "engine_method")
            self.unknown_material = config.get("general", "unknown_material")

            self.msg_task_canceled = tools_qt.tr("Task canceled.")

    def run(self):
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
        current_value = self._current_value(arcs, year, replacements)
        replacement_cost = self._replacement_cost(arcs)
        return current_value / replacement_cost

    def _copy_input_to_output(self):
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

    def _current_value(self, arcs, year, replacements=False):
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
            residual_useful_life = builtdate + arc["total_expected_useful_life"] - year
            multiplier = residual_useful_life / arc["total_expected_useful_life"]
            result = (arc["cost_constr"] * multiplier) if multiplier > 0 else 0
            current_value += result

        return current_value

    def _emit_report(self, *args):
        self.report.emit({"info": {"values": [{"message": arg} for arg in args]}})

    def _fit_to_scale(self, value, min, max):
        """Fit a value to a 0 to 10 scale, where min is the zero and max is ten."""
        if min == max:
            return 10
        return float((value - min) * 10 / (max - min))

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
                coalesce(ai.mandatory, false) mandatory
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

    def _invalid_arccat_id_report(self, obj):
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

    def _invalid_diameter_report(self, obj):
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
        if not obj["qtd"]:
            return
        if self.config_material.has_material(self.unknown_material):
            info = tools_qt.tr(
                "These pipes have been identified as the configured unknown material, "
                "{unknown_material}."
            )
        else:
            info = tools_qt.tr(
                "These pipes have NOT been assigned a priority value "
                "as the configured unknown material, {unknown_material}, "
                "is not listed in the configuration tab for materials."
            )
        msg = "\n".join(
            [
                tools_qt.tr("Pipes with invalid materials: {qtd}."),
                tools_qt.tr("Invalid materials: {list}."),
                info,
            ]
        )
        return msg.format(
            qtd=obj["qtd"],
            list=", ".join(obj["set"]),
            unknown_material=self.unknown_material,
        )

    def _invalid_pressures_report(self, null_pressures):
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

    def _ivi_report(self, ivi):
        title = tools_qt.tr("IVI")
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

    def _replacement_cost(self, arcs):
        return sum(arc["cost_constr"] for arc in arcs)

    def _yearly_replacement_report(self, output_arcs):
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
        pd = tools_os.get_dep("pandas")

        self._emit_report(tools_qt.tr("Getting auxiliary data from DB") + " (1/4)...")
        self.setProgress(10)

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

            arcs.append(arc)

        min_rleak = min(arc["rleak"] for arc in arcs)
        max_rleak = max(arc["rleak"] for arc in arcs)

        min_mleak = min(arc["mleak"] for arc in arcs)
        max_mleak = max(arc["mleak"] for arc in arcs)

        min_longevity = min(arc["longevity"] for arc in arcs)
        max_longevity = max(arc["longevity"] for arc in arcs)

        min_flow = min(arc["flow_avg"] for arc in arcs)
        max_flow = max(arc["flow_avg"] for arc in arcs)

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

            # First iteration weights
            arc["w1_rleak"] = self.config_engine["rleak_1"]
            arc["w1_mleak"] = self.config_engine["mleak_1"]
            arc["w1_longevity"] = self.config_engine["longevity_1"]
            arc["w1_flow"] = self.config_engine["flow_1"]
            arc["w1_nrw"] = self.config_engine["nrw_1"]
            arc["w1_strategic"] = self.config_engine["strategic_1"]
            arc["w1_compliance"] = self.config_engine["compliance_1"]

            # Second iteration weights
            arc["w2_rleak"] = self.config_engine["rleak_2"]
            arc["w2_mleak"] = self.config_engine["mleak_2"]
            arc["w2_longevity"] = self.config_engine["longevity_2"]
            arc["w2_flow"] = self.config_engine["flow_2"]
            arc["w2_nrw"] = self.config_engine["nrw_2"]
            arc["w2_strategic"] = self.config_engine["strategic_2"]
            arc["w2_compliance"] = self.config_engine["compliance_2"]

            arc["val_1"] = (
                arc["val_rleak"] * arc["w1_rleak"]
                + arc["val_mleak"] * arc["w1_mleak"]
                + arc["val_longevity"] * arc["w1_longevity"]
                + arc["val_flow"] * arc["w1_flow"]
                + arc["val_nrw"] * arc["w1_nrw"]
                + arc["val_strategic"] * arc["w1_strategic"]
                + arc["val_compliance"] * arc["w1_compliance"]
            )
            arc["val_2"] = (
                arc["val_rleak"] * arc["w2_rleak"]
                + arc["val_mleak"] * arc["w2_mleak"]
                + arc["val_longevity"] * arc["w2_longevity"]
                + arc["val_flow"] * arc["w2_flow"]
                + arc["val_nrw"] * arc["w2_nrw"]
                + arc["val_strategic"] * arc["w2_strategic"]
                + arc["val_compliance"] * arc["w2_compliance"]
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
        ivi = {}
        for year in range(date.today().year, self.target_year + 1):
            ivi_without_replacements = self._calculate_ivi(arcs, year)
            ivi_with_replacements = self._calculate_ivi(arcs, year, replacements=True)
            ivi[year] = (ivi_without_replacements, ivi_with_replacements)

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
                    val_first,
                    val
                ) values
            """
            for i in range(1000):
                try:
                    arc = second_iteration[index]
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
                        break
                    builtdate_str = (
                        f"'{arc['builtdate'].isoformat()}'"
                        if arc["builtdate"]
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

    def _save_config_engine(self):
        save_config_engine_sql = f"""
            delete from am.config_engine where result_id = {self.result_id};
            insert into am.config_engine
                (result_id, parameter, value)
            values
        """
        for k, v in self.config_engine.items():
            save_config_engine_sql += f"({self.result_id}, '{k}', {v}),"
        save_config_engine_sql = save_config_engine_sql.strip()[:-1]
        tools_db.execute_sql(save_config_engine_sql, is_thread=True)

    def _save_result_info(self):
        str_features = (
            f"""ARRAY['{"','".join(self.features)}']""" if self.features else "NULL"
        )
        str_presszone_id = f"'{self.presszone}'" if self.presszone else "NULL"
        str_material_id = f"'{self.material}'" if self.material else "NULL"
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
                budget,
                target_year,
                report,
                cur_user,
                tstamp)
            values ('{self.result_name}',
                '{self.result_type}',
                '{self.result_description}',
                '{self.status}',
                {str_features},
                {self.exploitation or 'NULL'},
                {str_presszone_id},
                {self.diameter or 'NULL'},
                {str_material_id},
                {self.result_budget or 'NULL'},
                {self.target_year or 'NULL'},
                '{self.statistics_report}',
                current_user,
                now())
            on conflict (result_name) do update
            set result_type = EXCLUDED.result_type,
                descript = EXCLUDED.descript,
                status = EXCLUDED.status,
                features = EXCLUDED.features,
                expl_id = EXCLUDED.expl_id,
                presszone_id = EXCLUDED.presszone_id,
                dnom = EXCLUDED.dnom,
                material_id = EXCLUDED.material_id,
                budget = EXCLUDED.budget,
                target_year = EXCLUDED.target_year,
                report = EXCLUDED.report,
                cur_user = EXCLUDED.cur_user,
                tstamp = EXCLUDED.tstamp
            """,
            is_thread=True
        )

        sql = f"select result_id from am.cat_result where result_name = '{self.result_name}'"
        row = tools_db.get_row(sql, is_admin=True, is_thread=True)
        if not row:
            return
        return row[0]

    def _summary(self, arcs):
        title = tools_qt.tr("SUMMARY")
        investment_header = tools_qt.tr("Investment (€/year):")
        year_header = tools_qt.tr("Year:")
        current_network_cost_header = tools_qt.tr("Current network cost (€):")
        total_replacement_cost_header = tools_qt.tr("Total replacement cost (€):")
        ivi_header = tools_qt.tr("IVI (Horizon year):")
        replacement_rate_header = tools_qt.tr("Replacement rate (%/year):")
        current_cost = sum(arc["current_cost_constr"] for arc in arcs)

        replacement_cost = self._replacement_cost(arcs)
        ivi_target_year = self._calculate_ivi(arcs, self.target_year, True)
        replacement_rate = self.result_budget / replacement_cost * 100 if replacement_cost > 0 else 0

        columns = [
            [
                investment_header,
                year_header,
                current_network_cost_header,
                total_replacement_cost_header,
                ivi_header,
                replacement_rate_header,
            ],
            [
                f"{self.result_budget:.2f}",
                f"{self.target_year}",
                f"{current_cost:.2f}",
                f"{replacement_cost:.2f}",
                f"{ivi_target_year:.3f}",
                f"{replacement_rate:.2f}",
            ],
        ]
        for column in columns:
            length = max(len(x) for x in column)
            for index, string in enumerate(column):
                column[index] = string.ljust(length)

        txt = f"{title}:\n"
        for line in zip(*columns):
            txt += "  ".join(line)
            txt += "\n"
        return txt.strip()
