"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import os
from datetime import timedelta
from time import sleep, time

from qgis.PyQt.QtCore import pyqtSignal
from qgis.PyQt.QtWidgets import QAction
from qgis.core import QgsLayoutExporter, QgsTask, QgsLayoutItemMap
from qgis.core import Qgis

from .task import GwTask
from ..utils import tools_gw
from ...libs import tools_log, tools_os, tools_qgis


class GwComposerPages(GwTask):
    time_changed = pyqtSignal(str)
    task_finished = pyqtSignal()
    change_btn_accept = pyqtSignal(bool)

    def __init__(self, description, result, layout, designer, prefix, path, is_single, sleep_time, skip_psectors=0):

        super().__init__(description, QgsTask.Flag.CanCancel)
        self.result = result
        self.layout = layout
        self.atlas = layout.atlas()
        self.designer = designer
        self.designer_window = designer.view().window()
        self.prefix = prefix
        self.path = path
        self.is_single = is_single
        self.map_refreshed = 0
        self.refreshed = False
        self.stop = False
        self.sleep_time = sleep_time
        self.skip_psectors = skip_psectors

        if Qgis.QGIS_VERSION_INT >= 32000:
            self.designer.mapPreviewRefreshed.connect(self._increase_map_refreshed)
            self.layout.refreshed.connect(self._set_refreshed)

    def sort_list(self, json_):

        try:
            return json_['atlas_id']
        except KeyError:
            return 0

    def run(self):
        try:
            _index = 0
            psectors_list = []
            self.time_changed.emit("")
            self.change_btn_accept.emit(True)
            for formtabs in self.result['body']['form']['formTabs']:
                if formtabs['tableName'] != 'selector_psector':
                    continue
                if self.atlas.count() != len(formtabs['fields']):
                    msg = "The number of pages in your composition does not match the number of psectors. ({0} != {1})"
                    msg_params = (self.atlas.count(), len(formtabs['fields']))
                    tools_qgis.show_warning(msg, msg_params=msg_params)
                    return False
                psectors_list = formtabs['fields']

            # psectors_list.sort(key=self.sort_list)
            for i, psector in enumerate(psectors_list):
                t0 = time()  # Initial time
                if i < self.skip_psectors:
                    _index += 1
                    self._calculate_remaining_time(t0)
                    action = self.designer_window.findChild(QAction, 'mActionAtlasNext')
                    action.trigger()
                    continue
                # Get the number of maps in the page
                items = self.designer.layout().pageCollection().itemsOnPage(0)
                maps = [i for i in items if isinstance(i, QgsLayoutItemMap)]

                if self.stop:
                    return False
                # Wait for the maps to be updated
                while self.map_refreshed < len(maps):
                    sleep(0.1)
                    if Qgis.QGIS_VERSION_INT <= 32000:
                        self.map_refreshed = self.map_refreshed + 1
                    if self.stop:
                        return False

                name = f"\\tomerge {self.prefix}{_index}" if self.is_single else f"\\{self.prefix}{psector['name']}"
                _id = psector['psector_id']
                extras = f'"selectorType":"selector_basic", "tabName":"tab_psector", "id":{_id}, "value":true, '
                extras += '"isAlone":true, "addSchema":"NULL"'
                body = tools_gw.create_body(extras=extras)
                tools_gw.execute_procedure("gw_fct_setselectors", body, is_thread=True)

                self.map_refreshed = 0
                self.layout.refresh()

                while not self.refreshed:
                    sleep(0.5)
                    if self.stop:
                        return False

                while self.map_refreshed < len(maps):
                    sleep(0.5)
                    if self.stop:
                        return False

                self.export_to_pdf(self.layout, self.path + f"{name}.pdf")
                self._calculate_remaining_time(t0)
                action = self.designer_window.findChild(QAction, 'mActionAtlasNext')
                action.trigger()
                self.map_refreshed = 0
                self.refreshed = False
                _index += 1
        except Exception as e:
            self.exception = e
            return False

        if self.is_single:
            try:
                self._merge_files()
            except Exception as e:
                self.exception = e
                return False
        return True

    def finished(self, result):
        # Restore user selectors
        self.designer.close()
        if self.stop:
            cur_page = self.layout.atlas().currentFeatureNumber()
            total_pages = self.layout.atlas().count()
            self.time_changed.emit(f"Cancelled ({cur_page}/{total_pages})")
        else:
            self.time_changed.emit("Finished!")
        self.change_btn_accept.emit(False)
        self.task_finished.emit()

    def cancel(self):
        self.stop_task()
        super().cancel()

    def export_to_pdf(self, layout, path):
        """ Export to PDF file """

        if layout:
            try:
                exporter = QgsLayoutExporter(layout)
                try:
                    sleep(float(self.sleep_time))
                except Exception:
                    sleep(0.5)
                exporter_settings = QgsLayoutExporter.PdfExportSettings()
                exporter_settings.dpi = 150
                exporter_settings.rasterizeWholeImage = True
                exporter.exportToPdf(path, exporter_settings)
                if not os.path.exists(path):
                    msg = "Cannot create file, check if its open"
                    tools_qgis.show_warning(msg, parameter=path)
            except Exception as e:
                tools_log.log_warning(str(e))
                msg = "Cannot create file, check if selected giswater_advancedtools is the correct giswater_advancedtools"
                tools_qgis.show_warning(msg, parameter=path)

    def _merge_files(self):
        py_pdf2 = tools_os.get_dep("PyPDF2")
        PdfFileMerger = py_pdf2.PdfFileMerger
        merger = PdfFileMerger()

        # Get all the files that have to be merged
        files = []
        for (dirpath, dirnames, filenames) in os.walk(self.path):
            files.extend(filenames)
            break
        files = [f for f in files if f'tomerge {self.prefix}' in f]

        # Merge the file to one pdf
        for file in files:
            f = open(f"{self.path}\\{file}", "rb")
            merger.append(f)
            f.close()
        output = open(f"{self.path}\\{self.prefix}atlas merged.pdf", "wb")
        merger.write(output)
        output.close()
        merger.close()

        # Remove the individual pages
        for file in files:
            try:
                os.remove(f"{self.path}\\{file}")
            except Exception as e:
                print(f"{e}")

    def _calculate_remaining_time(self, t0):
        tf = time()  # Final time
        td = tf - t0  # Delta time
        cur_page = self.layout.atlas().currentFeatureNumber() + 1
        total_pages = self.layout.atlas().count()
        time_remaining = td * (total_pages - cur_page)  # Delta time * remaining pages
        self.time_changed.emit(f"{timedelta(seconds=round(time_remaining))} ({cur_page}/{total_pages})")

    def _increase_map_refreshed(self, map):
        self.map_refreshed += 1

    def stop_task(self):
        self.stop = True
        self.time_changed.emit("Cancelling...")

    def _set_refreshed(self):
        self.refreshed = True
