"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
import copy
import csv
import json
from pathlib import Path

from qgis.core import QgsTask

from .task import GwTask
from ...libs import lib_vars, tools_db, tools_os, tools_qt


class GwValveOperationCheck(GwTask):
    def __init__(
        self,
        description,
        network,
        config,
        output_folder,
        file_name,
    ):
        super().__init__(description, QgsTask.Flag.CanCancel)
        wntr_epanet_util = tools_os.get_dep("wntr.epanet.util")
        to_si = wntr_epanet_util.to_si
        FlowUnits = wntr_epanet_util.FlowUnits
        HydParam = wntr_epanet_util.HydParam

        self.input_network = network
        self.config = config
        self.output_folder = output_folder
        self.file_name = file_name
        self.results = {"scenarios": {}}
        self.log = ""
        self.total_scenarios = len(self.config.scenarios) + 1
        self.cur_scenario = 0

        units = self.input_network.options.hydraulic.inpfile_units
        self.reference_pressure = to_si(
            FlowUnits[units],
            self.config.options["reference_pressure"],
            HydParam.Pressure,
        )
        self.min_pressure = to_si(
            FlowUnits[units],
            self.config.options["min_pressure"],
            HydParam.Pressure,
        )

    def run(self):
        try:
            tools_os.get_dep("wntr")
        except ImportError as e:
            msg = "Python package '{0}' is not installed. Please install it using pip or the 'qpip' QGIS plugin."
            msg_params = (e.name,)
            self.exception = tools_qt.tr(msg, list_params=msg_params)
            return False

        self._prepare_network()

        if self.isCanceled():
            msg = "Task canceled!"
            self._add_log(tools_qt.tr(msg), add_line=True)
            return False

        self._run_base_scenario()

        if self.isCanceled():
            msg = "Task canceled!"
            self._add_log(tools_qt.tr(msg), add_line=True)
            return False

        if not self._run_scenarios_simulations():
            msg = "Task canceled!"
            self._add_log(tools_qt.tr(msg), add_line=True)
            return False

        return True

    def _add_log(self, message, add_line=False):
        if add_line:
            self.log += "\n"
        self.log += message + "\n"

    def _prepare_network(self):
        wntr_metrics_hydraulic = tools_os.get_dep("wntr.metrics.hydraulic")
        average_expected_demand = wntr_metrics_hydraulic.average_expected_demand

        msg = "Preparing network..."
        self._add_log(tools_qt.tr(msg))
        adjusted_demands = (
            average_expected_demand(self.input_network)
            * self.config.options["base_demand_multiplier"]
        )

        # Replace demands with the adjusted demands
        wn = copy.deepcopy(self.input_network)
        wn.add_pattern("constant_pattern", [1])
        pat = wn.get_pattern("constant_pattern")
        for junction_name, junction in wn.junctions():
            junction.demand_timeseries_list.clear()
            junction.demand_timeseries_list.append(
                (adjusted_demands[junction_name], pat)
            )

        # Reduce the simulation to just one timestep
        wn.options.time.duration = 0

        self.network = wn

    def _run_base_scenario(self):
        self.cur_scenario += 1
        self.results["base"] = self._run_simulation(self.network)

        sql = """
            delete from anl_node
            where fid = 494 and cur_user = current_user;
            delete from anl_arc
            where fid = 494 and cur_user = current_user;
            """
        tools_db.execute_sql(sql, is_thread=True)
        self._save_result_to_db("base")

        # Nodes file
        csvpath = Path(self.output_folder) / f"{self.file_name}-nodes.csv"
        with open(csvpath, "w", newline="") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(["node_id", "x", "y", "scenario", "pressure", "status"])
        self._save_to_nodes_file("base")

        # Arcs file
        csvpath = Path(self.output_folder) / f"{self.file_name}-arcs.csv"
        with open(csvpath, "w", newline="") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(["arc_id", "scenario", "valve_status", "wkt"])

        # Report file
        csvpath = Path(self.output_folder) / f"{self.file_name}-report.csv"
        with open(csvpath, "w", newline="") as csvfile:
            writer = csv.writer(csvfile)
            writer.writerow(["Scenario", "Failed", "Unserviced", "Partial", "Ok"])
        self._save_to_report_file("base")

        # .in file
        inpath = Path(self.output_folder) / f"{self.file_name}.in"
        o = self.config.options
        with open(inpath, "w") as infile:
            infile.write("[OPTIONS]\n")
            infile.write(f"base_demand_multiplier {o['base_demand_multiplier']}\n")
            infile.write(f"reference_pressure     {o['reference_pressure']}\n")
            infile.write(f"min_pressure           {o['min_pressure']}\n")
            infile.write(f"scenario_results       {o['scenario_results']}\n")
            infile.write("\n[SCENARIOS]\n")

    def _run_scenarios_simulations(self):
        wntr_network = tools_os.get_dep("wntr.network")
        LinkStatus = wntr_network.LinkStatus

        scenarios = self.config.scenarios.values()
        for index, scenario in enumerate(scenarios):
            self.cur_scenario += 1
            self._add_log(
                f"Testing scenario {scenario['name']} ({index + 1} of {len(scenarios)})...",
                add_line=True,
            )
            open_links = set(scenario["open"])
            closed_links = set(scenario["closed"])
            all_links = set(self.network.link_name_list)
            if open_links.isdisjoint(all_links) and closed_links.isdisjoint(all_links):
                message = "No link in common between network and scenario {0}."
                formatted = message.format(scenario['name'])
                self._add_log(formatted)
                results = {"error": formatted}
            else:
                scenario_network = copy.deepcopy(self.network)

                not_found = []
                for link_name in scenario["open"]:
                    if link_name not in scenario_network.link_name_list:
                        not_found.append(link_name)
                        continue
                    link = scenario_network.get_link(link_name)
                    if link.initial_status == LinkStatus.Closed:
                        link.initial_status = LinkStatus.Opened

                for link_name in scenario["closed"]:
                    if link_name not in scenario_network.link_name_list:
                        not_found.append(link_name)
                        continue
                    link = scenario_network.get_link(link_name)
                    link.initial_status = LinkStatus.Closed

                if len(not_found):
                    msg = "These links could not be located within the network: "
                    message = tools_qt.tr(msg)
                    message += ", ".join(not_found)
                    message += "."
                    self._add_log(message)

                if self.isCanceled():
                    return False

                results = self._run_simulation(scenario_network)
            self.results["scenarios"][scenario["name"]] = results

            self._save_to_report_file(scenario["name"])

            if "error" in results:
                continue

            scenario_results = self.config.options["scenario_results"]
            if scenario_results == "all" or (
                scenario_results == "failed" and results["failed"]
            ):
                self._save_result_to_db(scenario["name"])
                self._save_to_nodes_file(scenario["name"])
                self._save_to_arcs_file(scenario["name"])

            self._save_scenario_to_infile(scenario["name"])
        return True

    def _run_simulation(self, network):
        wntr = tools_os.get_dep("wntr")
        wntr_sim = tools_os.get_dep("wntr.sim")
        EpanetSimulator = wntr_sim.EpanetSimulator

        nodes = {}
        unserviced = 0
        partial = 0
        ok = 0

        for node_name in network.nodes.unused():
            network.remove_node(node_name, with_control=True)
            nodes[node_name] = {"pressure": 0, "status": "unserviced"}
            unserviced += 1

        prefix = str(Path.home() / "temp")
        try:
            pressures = (
                EpanetSimulator(network)
                .run_sim(file_prefix=prefix)
                .node["pressure"]
                .loc[0]
                .to_dict()
            )
        except wntr.epanet.toolkit.EpanetException as e:
            self._add_log(f"{e}")
            return {"error": f"{e}"}

        for node_name, pressure in pressures.items():
            if (
                "base" in self.results
                and self.results["base"]["nodes"][node_name]["status"] != "ok"
            ):
                # Consider the node "ok" if it's not ok in the base scenario
                status = "ok"
                ok += 1
            elif pressure <= self.min_pressure:
                status = "unserviced"
                unserviced += 1
            elif pressure < self.reference_pressure:
                status = "partial"
                partial += 1
            else:
                status = "ok"
                ok += 1

            nodes[node_name] = {"pressure": pressure, "status": status}

        self._add_log(f"Nodes with partial service: {partial}.")
        self._add_log(f"Nodes with no service: {unserviced}.")
        self._add_log(f"Nodes with normal service: {ok}.")

        return {
            "failed": partial > 0,
            "report": {"unserviced": unserviced, "partial": partial, "ok": ok},
            "nodes": nodes,
        }

    def _save_result_to_db(self, scenario_name):
        if scenario_name == "base":
            scenario = self.results["base"]
        else:
            scenario = self.results["scenarios"][scenario_name]

        # Nodes
        sql = """
            insert into anl_node (node_id, fid, cur_user, the_geom, addparam)
                values
            """

        template = (
            "('{node_id}', 494, current_user, st_setsrid('POINT({x} {y})'::geometry, "
            + str(lib_vars.data_epsg)
            + "), '{json}'),"
        )

        for node_name, node_properties in scenario["nodes"].items():
            x, y = self.network.get_node(node_name).coordinates
            addparam = json.dumps(
                {
                    "scenario": scenario_name,
                    "pressure": node_properties["pressure"],
                    "status": node_properties["status"],
                }
            )
            sql += template.format(node_id=node_name, x=x, y=y, json=addparam)

        sql = sql[:-1]
        tools_db.execute_sql(sql, is_thread=True)

        # Arcs
        if scenario_name != "base":
            sql = """
                insert into anl_arc (arc_id, fid, cur_user, the_geom, addparam)
                    values
                """
            template = (
                "('{arc_id}', 494, current_user, st_setsrid('{the_geom}'::geometry,"
                + str(lib_vars.data_epsg)
                + "), '{json}'),"
            )
            for link_name in self.config.scenarios[scenario_name]["open"]:
                if link_name not in self.network.link_name_list:
                    continue
                geom = self._wkt_from_link(self.network.get_link(link_name))
                addparam = json.dumps(
                    {"scenario": scenario_name, "valve_status": "open"}
                )
                sql += template.format(arc_id=link_name, the_geom=geom, json=addparam)
            for link_name in self.config.scenarios[scenario_name]["closed"]:
                if link_name not in self.network.link_name_list:
                    continue
                geom = self._wkt_from_link(self.network.get_link(link_name))
                addparam = json.dumps(
                    {"scenario": scenario_name, "valve_status": "closed"}
                )
                sql += template.format(arc_id=link_name, the_geom=geom, json=addparam)
            sql = sql[:-1]
            tools_db.execute_sql(sql, is_thread=True)

    def _save_scenario_to_infile(self, scenario_name):
        inpath = Path(self.output_folder) / f"{self.file_name}.in"
        with open(inpath, "a") as infile:
            if self.config.scenarios[scenario_name]["open"]:
                line = f"{scenario_name} OPEN"
                for link_name in self.config.scenarios[scenario_name]["open"]:
                    if link_name not in self.network.link_name_list:
                        continue
                    if len(line + f" {link_name}") > 80:
                        infile.write(line + "\n")
                        line = f"{scenario_name} OPEN {link_name}"
                    else:
                        line += f" {link_name}"
                infile.write(line + "\n")
            if self.config.scenarios[scenario_name]["closed"]:
                line = f"{scenario_name} CLOSED"
                for link_name in self.config.scenarios[scenario_name]["closed"]:
                    if link_name not in self.network.link_name_list:
                        continue
                    if len(line + f" {link_name}") > 80:
                        infile.write(line + "\n")
                        line = f"{scenario_name} CLOSED {link_name}"
                    else:
                        line += f" {link_name}"
                infile.write(line + "\n")
            infile.write("\n")

    def _save_to_nodes_file(self, scenario_name):
        if scenario_name == "base":
            scenario = self.results["base"]
        else:
            scenario = self.results["scenarios"][scenario_name]

        csvpath = Path(self.output_folder) / f"{self.file_name}-nodes.csv"
        with open(csvpath, "a", newline="") as csvfile:
            writer = csv.writer(csvfile)
            for node_name, node_properties in scenario["nodes"].items():
                x, y = self.network.get_node(node_name).coordinates
                pressure = node_properties["pressure"]
                status = node_properties["status"]
                writer.writerow([node_name, x, y, scenario_name, pressure, status])

    def _save_to_arcs_file(self, scenario_name):
        csvpath = Path(self.output_folder) / f"{self.file_name}-arcs.csv"
        with open(csvpath, "a", newline="") as csvfile:
            writer = csv.writer(csvfile)
            for link_name in self.config.scenarios[scenario_name]["open"]:
                if link_name not in self.network.link_name_list:
                    continue
                geom = self._wkt_from_link(self.network.get_link(link_name))
                writer.writerow([link_name, scenario_name, "open", geom])
            for link_name in self.config.scenarios[scenario_name]["closed"]:
                if link_name not in self.network.link_name_list:
                    continue
                geom = self._wkt_from_link(self.network.get_link(link_name))
                writer.writerow([link_name, scenario_name, "closed", geom])

    def _save_to_report_file(self, scenario_name):
        if scenario_name == "base":
            scenario = self.results["base"]
        else:
            scenario = self.results["scenarios"][scenario_name]

        csvpath = Path(self.output_folder) / f"{self.file_name}-report.csv"
        with open(csvpath, "a", newline="") as csvfile:
            writer = csv.writer(csvfile)
            if "error" in scenario:
                writer.writerow([scenario_name, scenario["error"]])
            else:
                report = scenario["report"]
                line = [
                    scenario_name,
                    scenario["failed"],
                    report["unserviced"],
                    report["partial"],
                    report["ok"],
                ]
                writer.writerow(line)

    def _wkt_from_link(self, link):
        linestring = "LINESTRING ("
        x1, y1 = link.start_node.coordinates
        linestring += f"{x1} {y1},"
        for x, y in link.vertices:
            linestring += f"{x} {y},"
        x2, y2 = link.end_node.coordinates
        linestring += f"{x2} {y2})"
        return linestring
