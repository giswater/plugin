"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
from copy import deepcopy
from functools import cache, cached_property
from importlib.resources import open_text
from pathlib import Path
from random import choice, choices
from statistics import mean

from qgis.core import QgsTask
from qgis.PyQt.QtCore import pyqtSignal

from .task import GwTask
from ...libs import tools_os, tools_qt
from ...resources.epatools.utils import anl_quantized_demands


class GwQuantizedDemands(GwTask):
    status = pyqtSignal(str)
    ended = pyqtSignal(str)

    def __init__(
        self,
        description,
        input_file,
        config,
        output_folder,
        file_name,
    ):
        super().__init__(description, QgsTask.Flag.CanCancel)
        self.input_file = input_file
        self.flow_list = config.input_flows["values"]
        self.flow_period = config.input_flows["timestep"]
        self.timestep = config.options["model_timestep"]
        self.leak_flow = config.options.get("leak_flow")
        self.hourly_consumption = config.options["volume_distribution"] == "hourly"
        self.output_folder = output_folder
        self.file_name = file_name

    def run(self):
        try:
            tools_os.get_dep("pandas")
            wntr_network = tools_os.get_dep("wntr.network")
            write_inpfile = wntr_network.write_inpfile
        except ImportError as e:
            self.exception = (
                f"Python package '{e.name}' is not installed. "
                "Please install it using pip or the 'qpip' QGIS plugin."
            )
            return False

        try:
            message = "Creating quantized model..."
            self.status.emit(tools_qt.tr(message))
            model = QuantizedModel(
                self.input_file,
                self.flow_list,
                self.flow_period,
                self.timestep,
                self.leak_flow,
                self.hourly_consumption,
            )

            inppath = Path(self.output_folder) / f"{self.file_name}.inp"
            if self.isCanceled():
                self.status.emit("")
                message = "Task canceled."
                self.ended.emit(tools_qt.tr(message))
                return False
            message = "Saving INP file..."
            self.status.emit(tools_qt.tr(message))
            write_inpfile(model.quantized_network, inppath)

            csvpath = Path(self.output_folder) / f"{self.file_name}.csv"
            if self.isCanceled():
                self.status.emit("")
                message = "Task canceled."
                self.ended.emit(tools_qt.tr(message))
                return False
            self.write_statistics(model, csvpath)

            if self.isCanceled():
                self.status.emit("")
                message = "Task canceled."
                self.ended.emit(tools_qt.tr(message))
                return False

            self.status.emit("")
            msg = "Process finished.\n\nINP file created on:\n{0}\n\nStatistics file created on:\n{1}"
            msg_params = (inppath, csvpath)
            self.ended.emit(tools_qt.tr(msg, list_params=msg_params))
            return True

        except Exception as e:
            self.ended.emit(str(e))
            return False

    def write_statistics(self, model, file):
        pd = tools_os.get_dep("pandas")
        wntr_sim = tools_os.get_dep("wntr.sim")
        EpanetSimulator = wntr_sim.EpanetSimulator

        msg = "Running simulation..."
        self.status.emit(tools_qt.tr(msg))
        sim = EpanetSimulator(model.quantized_network)
        results = {}
        results["input"] = model.input_model.results
        results["output"] = sim.run_sim()

        if self.isCanceled():
            self.status.emit("")
            return

        msg = "Saving statistics file..."
        self.status.emit(tools_qt.tr(msg))
        statistics = {}
        for origin in ["input", "output"]:
            links = results[origin].link["velocity"]
            links = pd.DataFrame(
                [links.max(), links.mean(), links.min()]
            ).T.sort_index()
            links.columns = [f"{origin}_max", f"{origin}_mean", f"{origin}_min"]
            if origin == "input":
                links["type"] = "link"

            nodes = results[origin].node["pressure"]
            nodes = pd.DataFrame(
                [nodes.max(), nodes.mean(), nodes.min()]
            ).T.sort_index()
            nodes.columns = [f"{origin}_max", f"{origin}_mean", f"{origin}_min"]
            if origin == "input":
                nodes["type"] = "node"

            statistics[origin] = pd.concat([links, nodes])

        sheet = pd.concat(statistics.values(), axis="columns")
        sheet = sheet[
            [
                "type",
                "input_max",
                "input_mean",
                "input_min",
                "output_max",
                "output_mean",
                "output_min",
            ]
        ]
        sheet.to_csv(file)


class QuantizedModel:
    def __init__(
        self,
        input_file,
        flow_list,
        flow_list_timestep,
        model_timestep=10,
        leak_flow=None,
        hourly_consumption_table=False,
    ):
        self.input_model = InputModel(input_file)
        # Input model flow unit is m³/s
        self.leak_flow = leak_flow or (self.input_model.leak_flow * 1000)
        self.input_flows = InputFlow(flow_list, flow_list_timestep)
        self.timestep = model_timestep
        self.consumption_creator = ConsumptionCreator(hourly_consumption_table)

    @cached_property
    def consumptions_per_timestep(self):
        volumes = self.input_flows.get_volume_per_timestep(
            self.leak_flow, self.timestep
        )

        consumptions_per_timestep = []
        remainder = 0
        for volume in volumes:
            volume += remainder
            consumptions, remainder = divmod(volume, self._volume_coef)
            consumptions_per_timestep.append(int(consumptions))

        return consumptions_per_timestep

    @cached_property
    def quantized_network(self):
        wn = deepcopy(self.input_model.network)

        # Adjust existing patterns to the new timestep
        old_timestep = wn.options.time.pattern_timestep
        for _, pattern in wn.patterns():
            time = 0
            new_multipliers = []
            for index, multiplier in enumerate(pattern.multipliers, 1):
                while time < index * old_timestep:
                    new_multipliers.append(multiplier)
                    time += self.timestep
            pattern.multipliers = new_multipliers

        # Sets the new time options
        wn.options.time.hydraulic_timestep = self.timestep
        wn.options.time.report_timestep = self.timestep
        wn.options.time.pattern_timestep = self.timestep
        wn.options.time.duration = len(self.consumptions_per_timestep) * self.timestep

        # Apply new basedemands and patterns to junctions
        demand_matrix = self._get_demand_matrix()
        for junction_name, junction in wn.junctions():
            junction.demand_timeseries_list.clear()
            if junction_name in demand_matrix.columns:
                pattern = demand_matrix[junction_name].to_list()
                # Create a pattern that shares the junction name
                wn.add_pattern(junction_name, pattern)
                # Base demand is 1 liter, or 0.001 m³
                junction.add_demand(0.001, junction_name)
        return wn

    def _add_consumption_to_obj(
        self, obj, consumption, junction_name, start_time, timestep
    ):
        if junction_name not in obj:
            obj[junction_name] = {}

        junc_obj = obj[junction_name]

        timesteps = round(consumption.seconds / timestep)
        for i in range(timesteps):
            time = start_time + timestep * i
            if time not in junc_obj:
                junc_obj[time] = consumption.flow
            else:
                junc_obj[time] += consumption.flow

    def _get_demand_matrix(self):
        pd = tools_os.get_dep("pandas")

        obj = {}

        for index, consumptions in enumerate(self.consumptions_per_timestep):
            time = index * self.timestep
            hour = time // (60 * 60)
            hour = hour % 24

            junctions = self.input_model.node_table.get_random_nodes(consumptions)
            for junction in junctions:
                consumption = self.consumption_creator.new_consumption(hour)
                self._add_consumption_to_obj(
                    obj, consumption, junction, time, self.timestep
                )
        df = pd.DataFrame(obj).fillna(0)
        blank_df = pd.DataFrame(
            columns=df.columns,
            index=range(
                0, len(self.consumptions_per_timestep) * self.timestep, self.timestep
            ),
        ).fillna(0)
        return df.add(blank_df, fill_value=0).head(len(self.consumptions_per_timestep))

    @property
    def _volume_coef(self, magic_number=1.15):
        mean = self.consumption_creator.flows.mean
        return magic_number * mean * self.timestep


class Consumption:
    """An occasional water consumption

    Attributes
    ----------
    liters : float
        Consumption volume in liters
    flow : float
        Consumption flow in liters per second
    seconds : float
        Consumption time in seconds
    """

    def __init__(self, liters, flow):
        self._liters = liters
        self._flow = flow

    def __repr__(self):
        return f"Consumption(liters={self.liters}, flow={self.flow})"

    @property
    def liters(self):
        return self._liters

    @property
    def flow(self):
        return self._flow

    @property
    def seconds(self):
        return self._liters / self._flow


class ConsumptionCreator:
    """Create Consumptions randomly

    Methods
    -------
    new_consumption(hour)
        Returns a new random Consumption
    """

    def __init__(self, hourly_distribution=False):
        """
        Parameters
        ----------
        hourly_distribution : bool
            Defines whether the volume table should contain a different
            probability distribution for each hour of the day.
        """

        self._volumes = VolumeTable(hourly_distribution)
        self.flows = FlowTable()

    def new_consumption(self, hour):
        liters = self._volumes.get_random(hour)
        flow = self.flows.get_random()
        return Consumption(liters, flow)


class FlowTable:
    def __init__(self):
        file_name = "flow-distribution.csv"
        with open_text(anl_quantized_demands, file_name) as f:
            lines = f.readlines()

        if len(lines) != 1:
            msg = "{0} must contain just one line."
            msg_params = (file_name,)
            raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        self._flow_values = [float(x) for x in lines[0].split(" ")]

    @property
    def mean(self):
        return mean(self._flow_values)

    def get_random(self):
        return choice(self._flow_values)


class InputFlow:
    def __init__(self, flow_list, flow_list_timestep):
        self.flow_list = flow_list
        self.flow_list_timestep = flow_list_timestep

    def get_volume_per_timestep(self, leak_flow, model_timestep=10):
        steps, remainder = divmod(self.flow_list_timestep, model_timestep)
        if remainder:
            msg = "The flow data timestep must be a multiple of the desired timestep."
            raise ValueError(tools_qt.tr(msg))

        volume_list = []

        for flow in self.flow_list:
            flow = flow - leak_flow
            volume = flow * model_timestep
            for _ in range(steps):
                volume_list.append(volume)

        return volume_list


class InputModel:
    def __init__(self, input_file):
        wntr_network = tools_os.get_dep("wntr.network")
        WaterNetworkModel = wntr_network.WaterNetworkModel

        self._wn = WaterNetworkModel(input_file)

    @property
    @cache
    def leak_flow(self):
        simulation_demands = self.results.node["demand"][
            self.network.junction_name_list
        ]
        leak_demand = simulation_demands - self._expected_demands
        return leak_demand.sum(axis="columns").mean()

    @property
    def network(self):
        return self._wn

    @property
    @cache
    def node_table(self):
        return NodeTable(self._expected_demands)

    def has_negative_pressures(self):
        pressures = self.results.node["pressure"][self.network.junction_name_list]
        return (pressures < 0).any(axis=None)

    @property
    @cache
    def _expected_demands(self):
        wntr_metrics = tools_os.get_dep("wntr.metrics")
        expected_demand = wntr_metrics.expected_demand

        return expected_demand(self.network)

    @property
    @cache
    def results(self):
        wntr_sim = tools_os.get_dep("wntr.sim")
        EpanetSimulator = wntr_sim.EpanetSimulator

        sim = EpanetSimulator(self.network)
        return sim.run_sim()


class NodeTable:
    def __init__(self, demands_dataframe):
        series = demands_dataframe.sum().cumsum()
        self._junction_list = series.index.to_list()
        self._cum_demands = series.to_list()

    def get_random_nodes(self, k):
        return choices(self._junction_list, cum_weights=self._cum_demands, k=k)


class VolumeTable:
    def __init__(self, hourly_distribution=True):
        self._hourly_distribution = hourly_distribution

        file_name = "volume-distribution-hourly.csv"
        number_of_lines = 24
        if not self._hourly_distribution:
            file_name = "volume-distribution-simple.csv"
            number_of_lines = 1

        with open_text(anl_quantized_demands, file_name) as f:
            lines = f.readlines()

        if len(lines) != number_of_lines:
            msg = "{0} must contain {1} line{2}."
            msg_params = (file_name, number_of_lines, '' if number_of_lines == 1 else 's')
            raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        self._volume_values = [[float(i) for i in line.split(" ")] for line in lines]

    def get_random(self, hour: int) -> float:
        if not (0 <= hour <= 23):
            msg = "The hour value must be between 0 and 23, inclusive. Value supplied: {0}"
            msg_params = (hour,)
            raise ValueError(tools_qt.tr(msg, list_params=msg_params))

        if not self._hourly_distribution:
            return choice(self._volume_values[0])

        return choice(self._volume_values[hour])
