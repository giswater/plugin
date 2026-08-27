"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-

import configparser
import traceback
from pathlib import Path

from qgis.core import QgsTask
from qgis.PyQt.QtCore import pyqtSignal

from .task import GwTask
from ...libs import tools_db, tools_qt, lib_vars


class GwAssignation(GwTask):
    report = pyqtSignal(dict)
    step = pyqtSignal(str)

    def __init__(
        self,
        description,
        buffer,
        years,
        max_distance,
        cluster_length,
        filter_material=False,
        diameter_range=None,
        builtdate_range=None,
    ):
        super().__init__(description, QgsTask.Flag.CanCancel)
        self.buffer = buffer
        self.years = years
        self.max_distance = max_distance
        self.cluster_length = cluster_length
        self.filter_material = filter_material
        self.diameter_range = diameter_range
        self.builtdate_range = builtdate_range

        config_path = Path(lib_vars.plugin_dir) / "config" / "giswater.config"
        config = configparser.ConfigParser()
        config.read(config_path)
        self.unknown_material = config.get("general", "unknown_material")

        self.msg_task_canceled = tools_qt.tr("Task canceled.")

    def run(self):
        try:
            self._emit_report(tools_qt.tr("Getting leak data from DB") + " (1/5)...")
            self.setProgress(0)

            arcs = self._assign_leaks()

            if not arcs:
                return False

            if self.isCanceled():
                self._emit_report(self.msg_task_canceled)
                return False

            arcs = self._calculate_rleak(arcs)
            if not arcs:
                return False

            if self.isCanceled():
                self._emit_report(self.msg_task_canceled)
                return False

            self._emit_report(tools_qt.tr("Saving results to DB") + " (5/5)...")
            self.setProgress(90)
            sql = (
                "UPDATE am.ws_arc_input SET rleak = NULL; "
                + "INSERT INTO am.ws_arc_input (arc_id, rleak) VALUES "
            )
            for arc in arcs.values():
                # Convert rleak to leaks/km.year
                rleak = arc.get("rleak", 0) * 1000 / self.years
                sql += f"('{arc['id']}', {rleak}),"
            sql = sql[:-1] + " ON CONFLICT(arc_id) DO UPDATE SET rleak=excluded.rleak;"
            tools_db.execute_sql(sql, is_thread=True)

            self.setProgress(100)

            self._emit_report(*self._final_report())
            return True

        except Exception:
            self._emit_report(traceback.format_exc())
            return False

    def _assign_leaks(self):
        interval = tools_db.get_row(
            "select max(date) - min(date) from am.leaks", is_admin=True, is_thread=True
        )[0]
        if self.years:
            self.years = min(self.years, interval / 365)
        else:
            self.years = interval / 365

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Getting pipe data from DB") + " (2/5)...")
        self.setProgress(10)

        # Pin: feature_type + feature_id set (ARC) → skip spatial buffer
        pinned_rows = tools_db.get_rows(
            f"""
            WITH max_date AS (
                SELECT max(date)
                FROM am.leaks)
            SELECT l.id AS leak_id,
                a.arc_id AS arc_id,
                a.dnom::integer AS arc_diameter,
                a.matcat_id AS arc_material,
                ST_LENGTH(a.the_geom) AS arc_length
            FROM am.leaks AS l
            JOIN am.ext_ws_arc_asset AS a ON
                a.arc_id::text = l.feature_id::text
                AND (l.date > a.builtdate OR a.builtdate IS NULL)
            WHERE l.feature_id IS NOT NULL
                AND l.feature_type IS NOT NULL
                AND upper(trim(l.feature_type)) = 'ARC'
                AND l.date > (
                    (SELECT * FROM max_date) - INTERVAL '{self.years} year')::date
            """,
            is_thread=True
        )

        # Spatial: no ARC feature pin → buffer matching (current behaviour)
        rows = tools_db.get_rows(
            f"""
            WITH max_date AS (
                SELECT max(date)
                FROM am.leaks)
            SELECT l.id AS leak_id,
                l.diameter::integer AS leak_diameter,
                l.material AS leak_material,
                a.arc_id AS arc_id,
                a.dnom::integer AS arc_diameter,
                a.matcat_id AS arc_material,
                ST_LENGTH(a.the_geom) AS arc_length,
                ST_DISTANCE(l.the_geom, a.the_geom) AS distance,
                ST_LENGTH(
                    ST_INTERSECTION(ST_BUFFER(l.the_geom, {self.buffer}), a.the_geom)
                ) AS length
            FROM am.leaks AS l
            JOIN am.ext_ws_arc_asset AS a ON
                (l.date > a.builtdate OR a.builtdate IS NULL)
                AND ST_DWITHIN(l.the_geom, a.the_geom, {self.buffer})
            WHERE l.date > (
                (SELECT * FROM max_date) - INTERVAL '{self.years} year')::date
                AND NOT (
                    l.feature_id IS NOT NULL
                    AND l.feature_type IS NOT NULL
                    AND upper(trim(l.feature_type)) = 'ARC'
                )
                AND ST_LENGTH(
                    ST_INTERSECTION(ST_BUFFER(l.the_geom, {self.buffer}), a.the_geom)
                ) > 0
            """,
            is_thread=True
        )

        if self.isCanceled():
            self._emit_report(self.msg_task_canceled)
            return False

        self._emit_report(tools_qt.tr("Assigning leaks to pipes") + " (3/5)...")
        self.setProgress(40)

        if not pinned_rows and not rows:
            self._emit_report(tools_qt.tr("No pipes were found near any leak within the specified time period."))
            return False

        arcs = {}
        assigned_leak_ids = set()
        self.by_feature = 0
        self.by_material_diameter = 0
        self.by_material = 0
        self.by_diameter = 0
        self.any_pipe = 0

        for row in pinned_rows or []:
            leak_id, arc_id, arc_diameter, arc_material, arc_length = row
            if arc_id not in arcs:
                arcs[arc_id] = {
                    "id": arc_id,
                    "material": arc_material,
                    "diameter": arc_diameter,
                    "length": arc_length,
                    "leaks": 0,
                }
            arcs[arc_id]["leaks"] += 1
            assigned_leak_ids.add(leak_id)
            self.by_feature += 1

        leaks = {}
        for row in rows or []:
            (
                leak_id,
                leak_diameter,
                leak_material,
                arc_id,
                arc_diameter,
                arc_material,
                arc_length,
                distance,
                length,
            ) = row

            index = ((self.buffer - distance) / self.buffer) ** 2 * length

            if leak_id not in leaks:
                leaks[leak_id] = []

            leaks[leak_id].append(
                {
                    "arc_id": arc_id,
                    "arc_material": arc_material,
                    "arc_diameter": arc_diameter,
                    "arc_length": arc_length,
                    "index": index,
                    "same_diameter": (
                        # Diameters within 4mm are the same
                        leak_diameter is not None
                        and arc_diameter is not None
                        and leak_diameter - 4 <= arc_diameter <= leak_diameter + 4
                    ),
                    "same_material": (
                        leak_material is not None
                        and leak_material != self.unknown_material
                        and leak_material == arc_material
                    ),
                }
            )

        for leak_id, leak_arcs in leaks.items():
            def is_arc_valid(x, validation_type):
                if validation_type == "material_diameter":
                    return x["same_material"] and x["same_diameter"]
                elif validation_type == "diameter":
                    return x["same_diameter"]
                elif validation_type == "material":
                    return x["same_material"]
                return True

            if any(a["same_material"] and a["same_diameter"] for a in leak_arcs):
                validation_type = "material_diameter"
                self.by_material_diameter += 1
            elif any(a["same_diameter"] for a in leak_arcs):
                validation_type = "diameter"
                self.by_diameter += 1
            elif any(a["same_material"] for a in leak_arcs):
                validation_type = "material"
                self.by_material += 1
            else:
                validation_type = "any"
                self.any_pipe += 1

            valid_arcs = list(
                filter(
                    lambda x: is_arc_valid(x, validation_type),
                    leak_arcs,
                )
            )
            sum_indexes = sum([a["index"] for a in valid_arcs])
            if sum_indexes == 0:
                continue
            for arc in valid_arcs:
                arc_id = arc["arc_id"]
                if arc_id not in arcs:
                    arcs[arc_id] = {
                        "id": arc_id,
                        "material": arc["arc_material"],
                        "diameter": arc["arc_diameter"],
                        "length": arc["arc_length"],
                        "leaks": 0,
                    }
                arcs[arc_id]["leaks"] += arc["index"] / sum_indexes
            assigned_leak_ids.add(leak_id)

        self.assigned_leaks = len(assigned_leak_ids)
        return arcs

    def _calculate_rleak(self, arcs):
        self._emit_report(tools_qt.tr("Calculating rleak values") + " (4/5)...")
        self.setProgress(50)

        arc_list = sorted(arcs.values(), key=lambda a: a["length"], reverse=True)
        where_clause = self._where_clause()
        for index, arc in enumerate(arc_list):
            if arc.get("done", False):
                continue
            if arc.get("leaks", 0) == 0:
                continue
            if arc.get("length", 0) > self.cluster_length:
                if "rleak" not in arc:
                    arc["rleak"] = arc["leaks"] / arc["length"]
                continue
            cluster = tools_db.get_rows(
                f"""
                WITH start_pipe AS (
                        SELECT arc_id, matcat_id, dnom, builtdate, the_geom
                        FROM am.ext_ws_arc_asset
                        WHERE arc_id = '{arc["id"]}'),
                    ordered_list AS (
                        SELECT a.arc_id, 
                            a.arc_id = (select arc_id from start_pipe LIMIT 1) AS start, 
                            a.matcat_id,
                            a.dnom,
                            a.the_geom <-> (select the_geom from start_pipe LIMIT 1) AS dist,
                            ST_LENGTH(a.the_geom) AS length
                        FROM am.ext_ws_arc_asset AS a
                        {where_clause}
                        ORDER BY start DESC, dist ASC),
                    cum_list AS (
                        SELECT arc_id, matcat_id, dnom, dist, length,
                            SUM(length) OVER (ORDER BY start DESC, dist ASC) AS cum_length
                        FROM ordered_list
                        WHERE dist < {self.max_distance})
                SELECT arc_id, length
                FROM cum_list
                WHERE cum_length <= COALESCE(
                    (SELECT MIN(cum_length) FROM cum_list WHERE cum_length > {self.cluster_length}),
                    {self.cluster_length})
                """,
                is_thread=True
            )
            if not cluster:
                continue

            sum_leaks = 0
            sum_length = 0

            for row in cluster:
                id, length = row
                if id not in arcs:
                    arcs[id] = {"id": id, "length": length}
                sum_leaks += arcs[id].get("leaks", 0)
                sum_length += length

            rleak = sum_leaks / sum_length
            for row in cluster:
                id, _ = row
                arcs[id]["rleak"] = rleak
                arcs[id]["leaks"] = rleak * arcs[id]["length"]
                arcs[id]["done"] = True

            self.setProgress((90 - 50) / len(arc_list) * index + 50)

            if self.isCanceled():
                self._emit_report(self.msg_task_canceled)
                return False
        return arcs

    def _emit_report(self, *args):
        self.report.emit({"info": {"values": [{"message": arg} for arg in args]}})

    def _final_report(self):
        values = tools_db.get_row(
            f"""
            with total_leaks as (
                select count(*) as total_leaks
                from am.leaks
                where "date" > (
                    (select max("date") from am.leaks) - interval '{self.years} year'
                )::date),
            total_pipes as (
                select count(*) as total_pipes
                from am.ext_ws_arc_asset),
            orphan_pipes as (
                select count(*) as orphan_pipes
                from am.v_asset_ws_arc_input
                where rleak is null or rleak = 0),
            max_rleak as (
                select max(rleak) as max_rleak
                from am.ws_arc_input),
            min_rleak as (
                select min(rleak) as min_rleak
                from am.ws_arc_input
                where rleak is not null and rleak <> 0)
            select *
            from total_leaks
            cross join total_pipes
            cross join orphan_pipes
            cross join max_rleak
            cross join min_rleak
            """,
            is_admin=True,
            is_thread=True,
        )

        final_report = []

        # Set final reports
        final_report_values = [
            (tools_qt.tr('Period of leaks (years): '), f'{self.years:.4g}'),
            (tools_qt.tr('Leaks within the indicated period: '), f'{values["total_leaks"]}'),
            (tools_qt.tr('Leaks without pipes intersecting its buffer: '), f'{values["total_leaks"] - self.assigned_leaks}')
        ]

        if self.by_feature:
            final_report_values.append((tools_qt.tr('Leaks assigned by feature id: '), f'{self.by_feature}'))
        if self.by_material_diameter:
            final_report_values.append((tools_qt.tr('Leaks assigned by material and diameter: '), f'{self.by_material_diameter}'))
        if self.by_material:
            final_report_values.append((tools_qt.tr('Leaks assigned by material only: '), f'{self.by_material}'))
        if self.by_diameter:
            final_report_values.append((tools_qt.tr('Leaks assigned by diameter only: '), f'{self.by_diameter}'))
        if self.any_pipe:
            final_report_values.append((tools_qt.tr('Leaks assigned to any nearby pipes: '), f'{self.any_pipe}'))

        final_report_values.extend([
            (tools_qt.tr('Total of pipes: '), f'{values["total_pipes"]}'),
            (tools_qt.tr('Pipes with zero leaks per km per year: '), f'{values["orphan_pipes"]}'),
            (tools_qt.tr('Max rleak (leaks/km/year): '), f'{values["max_rleak"]}'),
            (tools_qt.tr('Min non-zero rleak (leaks/km/year): '), f'{values["min_rleak"]}')
        ])

        label_width = max(len(label) for label, _ in final_report_values)
        value_width = max(len(value) for _, value in final_report_values)

        # Build final report
        for label, value in final_report_values:
            sentence = f'{label:<{label_width}}{str(value):>{value_width}}'
            final_report.append(sentence)

        final_report.append("")
        final_report.append(tools_qt.tr('Task finished!'))

        return final_report

    def _where_clause(self):
        conditions = []
        if self.filter_material:
            conditions.append("coalesce(a.matcat_id = (select matcat_id from start_pipe LIMIT 1), true)")
        if self.diameter_range:
            conditions.append(
                f"""
                coalesce(a.dnom::numeric >= (select dnom::numeric from start_pipe LIMIT 1) * {self.diameter_range[0]}
                AND a.dnom::numeric <= (select dnom::numeric from start_pipe LIMIT 1) * {self.diameter_range[1]},
                true)
                """
            )
        if self.builtdate_range:
            conditions.append(
                f"""
                coalesce(a.builtdate >= (select builtdate from start_pipe LIMIT 1) - interval '{self.builtdate_range} year'
                and a.builtdate <= (select builtdate from start_pipe LIMIT 1) + interval '{self.builtdate_range} year',
                true)
                """
            )
        if conditions:
            return "WHERE " + " AND ".join(conditions)
        return ""
