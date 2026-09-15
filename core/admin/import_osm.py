"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""

# -*- coding: utf-8 -*-
import sys
from datetime import timedelta
from functools import partial
from time import time

from qgis.core import QgsApplication
from qgis.PyQt.QtCore import Qt, QTimer, pyqtSignal
from qgis.PyQt.QtWidgets import QApplication, QCheckBox, QLabel, QTabWidget, QTextEdit, QVBoxLayout
from qgis.PyQt.sip import isdeleted

from ..threads.task import GwTask
from ..ui.ui_manager import GwAdminImportOsmUi
from ..utils import tools_gw
from ...libs import lib_vars, tools_db, tools_os, tools_qgis, tools_qt


class GwImportOsmTask(GwTask):
    """Download OSM streets and insert them into om_streetaxis (worker thread)."""

    log_line = pyqtSignal(str)

    def __init__(self, description, schema_name, muni_ids, logs_list):
        super().__init__(description)
        self.schema_name = schema_name
        self.muni_ids = muni_ids
        self.logs_list = list(logs_list) if logs_list else []
        self.success = 0
        self.errors = 0
        self.exception = None

    def _log(self, message):
        self.logs_list.append(message)
        self.log_line.emit(message)

    def run(self):
        super().run()
        try:
            return self._import()
        except Exception as e:
            self.exception = e
            self._log(f"ERROR: {e}")
            return False

    def _import(self):
        shapely_wkt = tools_os.get_dep("shapely.wkt")
        shapely_ops = tools_os.get_dep("shapely.ops")
        pyproj = tools_os.get_dep("pyproj")
        pd = tools_os.get_dep("pandas")
        np = tools_os.get_dep("numpy")
        ox = tools_os.get_dep("osmnx")
        loads = shapely_wkt.loads
        transform = shapely_ops.transform
        transformer_cls = pyproj.Transformer
        if "surface" not in ox.settings.useful_tags_way:
            ox.settings.useful_tags_way = ox.settings.useful_tags_way + ["surface"]

        table_name = "om_streetaxis"
        ids_sql = ", ".join(str(int(muni_id)) for muni_id in self.muni_ids)
        sql = (
            f"SELECT m.muni_id, ST_AsText(m.the_geom) "
            f"FROM {self.schema_name}.v_municipality m "
            f"WHERE m.muni_id IN ({ids_sql});"
        )
        municipalities = tools_db.get_rows(sql, is_thread=True, aux_conn=self.aux_conn)
        if not municipalities:
            self._log("No municipalities found")
            return False

        all_edges = self._download_edges(
            municipalities, pd, np, ox, loads, transform, transformer_cls)
        if all_edges is None:
            return False

        if len(all_edges) > 0:
            self._log(f"Total municipalities processed: {len(all_edges['muni_id'].unique())}")

        return self._insert_edges(all_edges, table_name)

    def _download_edges(self, municipalities, pd, np, ox, loads, transform, transformer_cls):
        all_edges = pd.DataFrame()
        total_munis = len(municipalities)
        self.setProgress(5)
        for idx, (muni_id, boundary_geom_wkt) in enumerate(municipalities):
            if self.isCanceled():
                return None
            if not boundary_geom_wkt or muni_id == 0:
                self._log(f"Skipping muni_id {muni_id}: Invalid geometry")
                continue

            try:
                boundary_geom = loads(boundary_geom_wkt)
                transformer = transformer_cls.from_crs("EPSG:25831", "EPSG:4326", always_xy=True)
                boundary_geom = transform(transformer.transform, boundary_geom)

                if not boundary_geom.is_valid:
                    self._log(f"Skipping muni_id {muni_id}: Invalid geometry")
                    continue

                self._log(f"Processing muni_id {muni_id}")
                graph = ox.graph_from_polygon(boundary_geom, custom_filter=None)
                edges = ox.graph_to_gdfs(graph, nodes=False)

                edges['muni_id'] = muni_id
                edges['code'] = edges['osmid'].apply(lambda x: x[0] if isinstance(x, list) else x)
                edges['name'] = edges['name'].fillna('Unnamed Road')

                edges['maxspeed'] = edges['maxspeed'].apply(
                    lambda x: int(x[0]) if isinstance(x, list) and x and str(x[0]).isdigit() else (
                        int(x) if pd.notna(x) and str(x).isdigit() else None))
                edges['maxspeed'] = np.where(edges['maxspeed'].isnull(), None, edges['maxspeed'])

                edges['lanes'] = edges['lanes'].apply(
                    lambda x: int(x[0]) if isinstance(x, list) and x and str(x[0]).isdigit() else (
                        int(x) if pd.notna(x) and str(x).isdigit() else 1))
                edges['oneway'] = edges['oneway'].fillna(False).astype(bool)

                if 'access' not in edges:
                    edges['access'] = None
                else:
                    edges['access'] = edges['access'].replace(np.nan, None)

                edges['pedestrian'] = edges['highway'].apply(lambda h: h in ['footway', 'path', 'pedestrian'])
                edges['road_type'] = edges['highway']
                edges['surface'] = edges['surface'].fillna('unknown') if 'surface' in edges.columns else 'unknown'

                transformer = transformer_cls.from_crs("EPSG:4326", "EPSG:25831", always_xy=True)
                edges['the_geom'] = edges['geometry'].apply(lambda geom: transform(transformer.transform, geom).wkt)
                edges = edges[['code', 'name', 'the_geom', 'maxspeed', 'lanes', 'oneway',
                               'pedestrian', 'road_type', 'surface', 'muni_id', 'access']]
                all_edges = pd.concat([all_edges, edges], ignore_index=True)
            except Exception as e:
                self._log(f"ERROR: Processing muni_id {muni_id}: {e}")
                continue

            progress = 5 + int(((idx + 1) / float(total_munis)) * 65)
            self.setProgress(min(progress, 70))

        return all_edges

    def _insert_edges(self, all_edges, table_name):
        cur = tools_db.dao.get_cursor(self.aux_conn)
        total_rows = len(all_edges)
        for row_idx, row in all_edges.iterrows():
            if self.isCanceled():
                tools_db.dao.rollback(self.aux_conn)
                return False
            try:
                cur.execute(f"""
                    INSERT INTO {self.schema_name}.{table_name}
                    (code, name, the_geom, maxspeed, lanes, oneway, pedestrian,
                     road_type, surface, muni_id, access_info, expl_id)
                    VALUES (%s, %s, ST_GeomFromText(%s, 25831), %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (row['code'], row['name'], row['the_geom'], row['maxspeed'], row['lanes'], row['oneway'],
                      row['pedestrian'], row['road_type'], row['surface'], row['muni_id'], row['access'], 0))
                tools_db.dao.commit(self.aux_conn)
                self.success += 1
            except Exception as e:
                tools_db.dao.rollback(self.aux_conn)
                self._log(f"ERROR: Inserting row: {e}")
                self._log(f"ERROR: Failing data: {row.to_dict()}")
                self.errors += 1

            if total_rows:
                progress = 70 + int(((row_idx + 1) / float(total_rows)) * 25)
                self.setProgress(min(progress, 95))

        try:
            cur.execute(f"""
                UPDATE {self.schema_name}.{table_name} as osms
                SET expl_id = COALESCE(
                    (SELECT
                        CASE
                            WHEN COUNT(*) > 1 THEN NULL
                            ELSE (SELECT exp.expl_id
                                FROM {self.schema_name}.exploitation as exp
                                WHERE ST_Contains(exp.the_geom, osms.the_geom) IS TRUE
                                    OR ST_Touches(exp.the_geom, osms.the_geom) IS TRUE)
                        END
                    ), 0)
            """)
            tools_db.dao.commit(self.aux_conn)
            self.success += 1
        except Exception as e:
            tools_db.dao.rollback(self.aux_conn)
            self._log(f"ERROR: Updating expl_id: {e}")
            self.errors += 1

        self._log(f"Data insertion completed: {self.success} successful, {self.errors} errors.")
        self.setProgress(100)
        return True


class GwImportOsm:

    def __init__(self):
        self.plugin_dir = lib_vars.plugin_dir
        self.schema_name = lib_vars.schema_name
        self.projetc_type = None
        self.import_task = None
        self.logs_list = list()
        self._task_finished = False
        self.timer = None
        self.t0 = None

    def init_dialog(self, schema_name):
        """ Constructor """

        self.schema_name = schema_name

        # Check project type
        sql = f"SELECT project_type FROM {self.schema_name}.sys_version"
        self.projetc_type = tools_db.get_row(sql)
        if self.projetc_type[0] != 'WS':
            msg = "Import OSM Streetaxis its only for WS projects"
            tools_qgis.show_warning(msg)
            return

        # Initialize the UI
        self.dlg_import_osm = GwAdminImportOsmUi(self)
        tools_gw.load_settings(self.dlg_import_osm)

        title = "Import OSM Streetaxis - {0}"
        title_params = (self.schema_name,)
        self.dlg_import_osm.setWindowTitle(tools_qt.tr(title, list_params=title_params))

        if sys.version_info < (3, 10):
            msg = "Import OSM Streetaxis is only available on Python 3.10 or higher. " \
                  "Please update your QGIS's Python version."
            tools_qgis.show_warning(msg, dialog=self.dlg_import_osm)
            tools_qt.set_widget_enabled(self.dlg_import_osm.btn_accept, False)

        self._setup_progress_bar()
        tools_gw.disable_tab_log(self.dlg_import_osm)

        self.load_municipalities()

        self.dlg_import_osm.btn_accept.clicked.connect(partial(self.run))
        self.dlg_import_osm.btn_close.clicked.connect(partial(self.close_dialog))

        tools_gw.open_dialog(self.dlg_import_osm, dlg_name='admin_import_osm')

    def _setup_progress_bar(self):
        progress_bar = self.dlg_import_osm.progressBar
        progress_bar.setVisible(False)
        progress_bar.setRange(0, 0)
        progress_bar.setTextVisible(False)
        progress_bar.setStyleSheet(
            "QProgressBar {border: 0px solid #000000; border-radius: 5px; background-color: #E0E0E0;}"
            "QProgressBar::chunk {background-color:#0bd82c; width: 10 px; margin: 0.5px;}"
        )
        lbl_time = self.dlg_import_osm.findChild(QLabel, 'lbl_time')
        if lbl_time:
            lbl_time.setVisible(False)
            lbl_time.setText("")

    def _set_busy(self, busy):
        if isdeleted(self.dlg_import_osm):
            return
        self.dlg_import_osm.progressBar.setVisible(busy)
        lbl_time = self.dlg_import_osm.findChild(QLabel, 'lbl_time')
        tools_qt.set_widget_enabled(self.dlg_import_osm, 'btn_accept', not busy)
        if busy:
            self.dlg_import_osm.progressBar.setRange(0, 0)
            self.dlg_import_osm.setCursor(Qt.CursorShape.WaitCursor)
            if lbl_time:
                lbl_time.setVisible(True)
            self._start_timer()
        else:
            self.dlg_import_osm.unsetCursor()
            self._stop_timer()
        QApplication.processEvents()

    def _start_timer(self):
        self.t0 = time()
        if self.timer is None:
            self.timer = QTimer()
            self.timer.timeout.connect(partial(self._calculate_elapsed_time, self.dlg_import_osm))
        self._calculate_elapsed_time(self.dlg_import_osm)
        self.timer.start(1000)

    def _stop_timer(self):
        if self.timer is None:
            return
        self.timer.stop()
        if not isdeleted(self.dlg_import_osm):
            self._calculate_elapsed_time(self.dlg_import_osm)

    def _calculate_elapsed_time(self, dialog):
        if self.t0 is None:
            return
        tf = time()
        td = tf - self.t0
        msg = "Exec. time: {0}"
        msg_params = (timedelta(seconds=round(td)),)
        self._update_time_elapsed(tools_qt.tr(msg, list_params=msg_params), dialog)

    def _update_time_elapsed(self, text, dialog):
        if isdeleted(dialog):
            if self.timer is not None:
                self.timer.stop()
            return
        lbl_time = dialog.findChild(QLabel, 'lbl_time')
        if lbl_time is None:
            return
        lbl_time.setText(text)

    def load_municipalities(self):
        """ Get municipalities and add a checkbox widget for each of them """
        sql = (f"""
            SELECT muni_id, name
            FROM {self.schema_name}.v_municipality;
        """)
        chk_municipalities = tools_db.get_rows(sql)
        layout = self.dlg_import_osm.mainTab.findChild(QVBoxLayout, "lyt_data_1")

        if not chk_municipalities:
            return

        for chk_muni in chk_municipalities:
            widget = QCheckBox()
            widget.setObjectName(f'chk_{chk_muni[0]}')
            widget.setLayoutDirection(Qt.LayoutDirection.LeftToRight)
            widget.setText(chk_muni[1])
            layout.addWidget(widget)

    def run(self):
        """ Start import process """

        if self.import_task is not None:
            try:
                if self.import_task.isActive():
                    msg = "OSM import is already running"
                    tools_qgis.show_warning(msg, dialog=self.dlg_import_osm)
                    return
            except RuntimeError:
                pass

        try:
            tools_os.get_dep("shapely.wkt")
            tools_os.get_dep("shapely.ops")
            tools_os.get_dep("pyproj")
            tools_os.get_dep("pandas")
            tools_os.get_dep("numpy")
            tools_os.get_dep("osmnx")
        except ImportError as e:
            msg = (
                "Python package required for OSM import is not installed: {0}. "
                "Please install it using pip or the 'qpip' QGIS plugin."
            )
            msg_params = (getattr(e, "name", str(e)),)
            tools_qgis.show_critical(msg, msg_params=msg_params)
            return

        self.logs_list = list()
        checked_municipalities = self.get_checked_municipalities()

        if not checked_municipalities:
            msg = "No municipalities selected"
            tools_qgis.show_warning(msg, dialog=self.dlg_import_osm)
            self.logs_list.append("No municipalities selected")
            return

        qtabwidget = self.dlg_import_osm.findChild(QTabWidget, 'mainTab')
        if qtabwidget:
            tools_qt.enable_tab_by_tab_name(qtabwidget, "tab_log", True)
            qtabwidget.setCurrentIndex(qtabwidget.count() - 1)

        self._set_busy(True)
        self._task_finished = False
        msg = "Downloading OSM streetaxis. This can take a while..."
        tools_qgis.show_info(msg, dialog=self.dlg_import_osm)
        self.logs_list.append(msg)
        self._append_log_line(tools_qt.tr(msg))

        title = "Import OSM Streetaxis"
        self.import_task = GwImportOsmTask(
            tools_qt.tr(title), self.schema_name, checked_municipalities, self.logs_list)
        self.import_task.log_line.connect(self._append_log_line)
        self.import_task.taskCompleted.connect(partial(self._on_task_finished, True))
        self.import_task.taskTerminated.connect(partial(self._on_task_finished, False))
        QgsApplication.taskManager().addTask(self.import_task)
        QgsApplication.taskManager().triggerTask(self.import_task)

    def _append_log_line(self, message):
        if isdeleted(self.dlg_import_osm):
            return
        widget = self.dlg_import_osm.findChild(QTextEdit, 'tab_log_txt_infolog')
        if widget is None:
            return
        widget.append(str(message))

    def _on_task_finished(self, completed):
        if self._task_finished or isdeleted(self.dlg_import_osm):
            return
        self._task_finished = True

        self._set_busy(False)

        task = self.import_task
        if task is None:
            return

        if task.exception is not None:
            msg = "Error processing OSM import: {0}"
            msg_params = (str(task.exception),)
            tools_qgis.show_warning(msg, dialog=self.dlg_import_osm, msg_params=msg_params)

        if task.isCanceled():
            msg = "OSM import was cancelled"
            tools_qgis.show_warning(msg, dialog=self.dlg_import_osm)
            return

        values = []
        for idx, message in enumerate(task.logs_list, 1):
            values.append({"id": idx, "message": message})
        tools_gw.fill_tab_log(
            self.dlg_import_osm, {"info": {"values": values}}, reset_text=True, close=completed)

        if completed:
            msg = "Data insertion completed: {0} successful, {1} errors."
            msg_params = (task.success, task.errors,)
            tools_qgis.show_info(msg, msg_params=msg_params, dialog=self.dlg_import_osm)

    def get_checked_municipalities(self):
        """ Get selected municipalities and checks if there are already imported """

        all_munis = self.dlg_import_osm.mainTab.findChildren(QCheckBox)
        selected_munis = list()

        # Get selected municipalities
        for muni in all_munis:
            if muni.isChecked():
                muni_id = muni.objectName().replace('chk_', '')
                selected_munis.append(int(muni_id))

        # Check if selected municipalities are already on om_streetaxis
        sql = f"""
            SELECT DISTINCT muni_id
            FROM {self.schema_name}.om_streetaxis;
        """
        imported_munis = tools_db.get_rows(sql)

        if imported_munis is not None:
            for imported_muni in imported_munis:
                # Check if imported_muni is selected
                if imported_muni[0] in selected_munis:
                    # Ask if user wants to overwrite the municipaly imports
                    msg = (
                        "Municipality with id[{0}] is already imported on om_streetaxis.\n\r"
                        "Do you want to overwrite it?"
                        "\n\r(This decision will not cancel the other selections, the process will keep running)"
                    )
                    msg_params = (imported_muni[0],)
                    result = tools_qt.show_question(msg, "Info", force_action=True, msg_params=msg_params)
                    if not result:
                        selected_munis.remove(imported_muni[0])
                        self.dlg_import_osm.findChild(QCheckBox, f"chk_{imported_muni[0]}").setChecked(False)
                        msg = "Municipality with ID: {0} deleted from selection"
                        msg_params = (imported_muni[0],)
                        tools_qgis.show_info(msg, msg_params=msg_params)
                        self.logs_list.append(
                            "Municipality with ID: {0} deleted from selection".format(imported_muni[0]))
                    else:
                        # Delete municipality imports
                        status = tools_db.execute_sql(
                            f"DELETE FROM {self.schema_name}.om_streetaxis WHERE muni_id = {imported_muni[0]};",
                            commit=False)
                        if status:
                            tools_db.dao.commit()
                        else:
                            tools_db.dao.rollback()
                            return None

        if not selected_munis:
            return None

        return selected_munis

    def close_dialog(self):
        """ Close dialog """
        if self.timer is not None:
            self.timer.stop()
        if self.import_task is not None:
            try:
                if self.import_task.isActive():
                    self.import_task.cancel()
            except RuntimeError:
                pass
        tools_gw.close_dialog(self.dlg_import_osm, delete_dlg=True)
