from functools import partial

from qgis.PyQt.QtCore import QDate
from qgis.PyQt.QtWidgets import QTableView, QLabel, QLineEdit, QComboBox, QDateEdit, \
                                QWidget, QTextEdit, QCheckBox
from qgis.PyQt.QtGui import QStandardItemModel, QStandardItem

from ....libs import tools_qt, tools_db, tools_qgis
from ...utils import tools_gw
from ...ui.ui_manager import WorkorderManagementUi, WorkorderAddUi


class Workorder:
    """Handles workorder management and dynamic CRUD via JSON-driven forms"""

    def __init__(self, icon_path, action_name, text, toolbar, action_group):
        self.date_format = 'yyyy-MM-dd'
        self.manager_dialog = None
        self.fields_form = []
        self.workorder_id = None

    def workorder_manager(self):
        """Open the workorder management dialog and set up table, filters, buttons"""
        self.manager_dialog = WorkorderManagementUi(self)
        tools_gw.load_settings(self.manager_dialog)
        self.load_workorders_into_manager()

        tbl = self.manager_dialog.tbl_workorder
        tbl.setEditTriggers(QTableView.EditTrigger.NoEditTriggers)
        tbl.setSelectionBehavior(QTableView.SelectionBehavior.SelectRows)

        # fill filter combos
        sql = "SELECT id, idval FROM cm.workorder_class ORDER BY id"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.manager_dialog.cmb_wclass, rows, index_to_show=1, add_empty=True)
        sql = "SELECT id, idval FROM cm.workorder_type ORDER BY id"
        rows = tools_db.get_rows(sql)
        tools_qt.fill_combo_values(self.manager_dialog.cmb_wtype, rows, index_to_show=1, add_empty=True)

        self.manager_dialog.cmb_wclass.currentIndexChanged.connect(self.filter_workorder)
        self.manager_dialog.cmb_wtype.currentIndexChanged.connect(self.filter_workorder)
        self.manager_dialog.txt_filter_name.textChanged.connect(self.filter_workorder)

        self.manager_dialog.tbl_workorder.doubleClicked.connect(partial(self.open_workorder_dialog, is_update=True))
        self.manager_dialog.btn_create.clicked.connect(partial(self.open_workorder_dialog, is_update=False))
        self.manager_dialog.btn_delete.clicked.connect(self.delete_selected_workorder)

        tools_gw.open_dialog(self.manager_dialog, dlg_name="workorder_management")

    def load_workorders_into_manager(self):
        """Populate management table with all workorders"""
        if not self.manager_dialog:
            return
        query = "SELECT * FROM cm.workorder ORDER BY workorder_id DESC"
        self.populate_tableview(self.manager_dialog.tbl_workorder, query)

    def filter_workorder(self):
        """Filter cm.workorder based on optional name, class, and type"""

        filters = []

        # Name filter
        name = self.manager_dialog.txt_filter_name.text().strip()
        if name:
            safe_name = name.replace("'", "''")
            filters.append(f"workorder_name ILIKE '%{safe_name}%'")

        # Class filter
        cls = tools_qt.get_combo_value(
            self.manager_dialog,
            self.manager_dialog.cmb_wclass,
        )
        if cls:
            filters.append(f"workorder_class = '{cls}'")

        # Type filter
        typ = tools_qt.get_combo_value(
            self.manager_dialog,
            self.manager_dialog.cmb_wtype
        )
        if typ:
            filters.append(f"workorder_type = '{typ}'")

        # Build WHERE clause only if filters
        where = ("WHERE " + " AND ".join(filters)) if filters else ""

        sql = f"""
            SELECT *
              FROM cm.workorder
            {where}
            ORDER BY workorder_id DESC
        """

        self.populate_tableview(self.manager_dialog.tbl_workorder, sql)

    def populate_tableview(self, qtable: QTableView, query: str, columns: list[str] = None):
        """Populate a QTableView with the results of a SQL query."""

        data = tools_db.get_rows(query)
        if not data:
            qtable.setModel(QStandardItemModel())  # Clear view
            return

        # Auto-detect column names if not provided
        if not columns:
            columns = list(data[0].keys())

        model = QStandardItemModel(len(data), len(columns))
        model.setHorizontalHeaderLabels(columns)

        for row_idx, row in enumerate(data):
            for col_idx, col_name in enumerate(columns):
                value = str(row.get(col_name, ''))
                model.setItem(row_idx, col_idx, QStandardItem(value))

        qtable.setModel(model)
        tools_gw.set_tablemodel_config(self.manager_dialog, qtable, "workorder", schema_name="cm")

    def open_workorder_dialog(self, is_update=False):
        """Open dynamic form dialog for new or existing workorder"""
        workorder_id = None
        if is_update:
            # On update, take the first selected row
            selected = self.manager_dialog.tbl_workorder.selectionModel().selectedRows()
            if not selected:
                msg = "Please select a workorder to open"
                tools_qgis.show_warning(msg, dialog=self.manager_dialog)
                return
            workorder_id = selected[0].data()
            self.is_new_workorder = False
        else:
            self.is_new_workorder = True

        # Build RPC body
        body = {
            "feature": {
                "tableName": "workorder",
                "idName": "workorder_id",
            }
        }
        if workorder_id:
            try:
                body["feature"]["id"] = int(workorder_id)
            except (TypeError, ValueError):
                msg = "Invalid workorder ID"
                tools_qgis.show_warning(msg, dialog=self.manager_dialog)
                return

        p_data = tools_gw.create_body(body=body)
        res = tools_gw.execute_procedure('gw_fct_cm_getworkorder', p_data, schema_name='cm')
        if not res or res.get('status') != 'Accepted':
            msg = "Failed to load workorder form"
            tools_qgis.show_warning(msg)
            return

        # Populate and show dialog as before...
        self.fields_form = res["body"]["data"].get("fields", [])
        self.dialog = WorkorderAddUi(self)
        # If editing, set the ID field
        if workorder_id:
            widget = self.get_widget_by_columnname(self.dialog, "workorder_id")
            if widget:
                widget.setText(str(workorder_id))
                widget.setProperty("columnname", "workorder_id")
        # Load settings and build form widgets
        tools_gw.load_settings(self.dialog)
        for field in self.fields_form:
            widget = self.create_widget_from_field(field)
            if not widget:
                continue
            if "value" in field:
                self.set_widget_value(widget, field["value"])
            widget.setProperty("columnname", field.get("columnname"))
            widget.setObjectName(field.get("widgetname"))
            label = QLabel(field.get("label")) if field.get("label") else None
            tools_gw.add_widget(self.dialog, field, label, widget)

        # Connect save/cancel
        self.dialog.btn_accept.clicked.connect(lambda: self.save_workorder(from_manager=False))
        self.dialog.btn_cancel.clicked.connect(self.dialog.reject)

        tools_gw.open_dialog(self.dialog, dlg_name='workorder_edit')

    def save_workorder(self, from_manager=True):
        """
        Read back all widgets, convert empty strings to None,
        then call cm.gw_fct_cm_setworkorder.
        """
        fields = {}
        missing = []

        # 1) Collect values from every defined field
        for fld in self.fields_form:
            col = fld["columnname"]
            wname = fld["widgetname"]
            widget = self.dialog.findChild(QWidget, wname)
            if not widget:
                continue

            # reset any red border from prior validation
            widget.setStyleSheet("")

            # extract based on widget type
            if isinstance(widget, QComboBox):
                val = widget.currentData()
            elif isinstance(widget, QDateEdit):
                d = widget.date()
                val = d.toString(self.date_format) if d.isValid() else None
            else:
                val = tools_qt.get_widget_value(self.dialog, widget)

            fields[col] = val

            # mark missing mandatory
            if fld.get("ismandatory") and not val:
                widget.setStyleSheet("border:1px solid red;")
                missing.append(wname)

        # 2) If any mandatory fields are missing, abort
        if missing:
            title = "Missing Data"
            msg = "Please fill all mandatory fields (highlighted in red)."
            tools_qt.show_warning_box(msg, title=title, parent=self.dialog)
            return False

        # 3) Convert empty strings to None so JSON nulls land in numeric/date cols
        for k, v in list(fields.items()):
            if isinstance(v, str) and v.strip() == "":
                fields[k] = None

        # 4) Build the RPC payload
        payload = {
            "feature": {
                "tableName": "workorder",
                "idName": "workorder_id",
                "id": fields.get("workorder_id")
            },
            "data": {
                "fields": fields,
                "message": None
            }
        }

        # 5) Execute the set-function
        result = tools_gw.execute_procedure(
            "gw_fct_cm_setworkorder",
            payload,
            schema_name="cm"
        )

        # 6) Handle the response
        if result and result.get("status") == "Accepted":
            # store the new/updated ID
            self.workorder_id = result["body"]["feature"]["id"]
            if not from_manager:
                tools_gw.close_dialog(self.dialog)
            self.load_workorders_into_manager()
            return True
        else:
            title = "Error"
            msg = "An error occurred saving the workorder."
            tools_qt.show_warning_box(msg, title=title, parent=self.dialog)
            return False

    def delete_selected_workorder(self):
        """Delete selected workorder with confirmation"""
        sel = self.manager_dialog.tbl_workorder.selectionModel().selectedRows()
        if not sel:
            msg = "Select a workorder to delete"
            tools_qgis.show_warning(msg, dialog=self.manager_dialog)
            return
        msg = "Are you sure you want to delete {0} workorder(s)?"
        msg_params = (len(sel),)
        title = "Delete Workorder(s)"
        if not tools_qt.show_question(msg, msg_params=msg_params, title=title):
            return

        deleted = 0
        for index in sel:
            wid = index.data()
            if not str(wid).isdigit():
                continue

            sql = f"DELETE FROM cm.workorder WHERE workorder_id = {wid}"
            if tools_db.execute_sql(sql):
                deleted += 1
        msg = "{0} workorder(s) deleted."
        msg_params = (deleted,)
        tools_qgis.show_info(msg, msg_params=msg_params, dialog=self.manager_dialog)
        self.load_workorders_into_manager()

    def create_widget_from_field(self, field):
        """Create a Qt widget based on field metadata"""

        wtype = field.get("widgettype", "text")
        iseditable = field.get("iseditable", True)
        widget = None

        if wtype == "text":
            widget = QLineEdit()
            if not iseditable:
                widget.setEnabled(False)

        elif wtype == "textarea":
            widget = QTextEdit()
            if not iseditable:
                widget.setReadOnly(True)

        elif wtype == "datetime":
            widget = QDateEdit()
            widget.setCalendarPopup(True)
            widget.setDisplayFormat("MM/dd/yyyy")
            value = field.get("value")
            date = QDate.fromString(value, "yyyy-MM-dd") if value else QDate.currentDate()
            widget.setDate(date if date.isValid() else QDate.currentDate())
            if not iseditable:
                widget.setEnabled(False)

        elif wtype == "check":
            widget = QCheckBox()
            if not iseditable:
                widget.setEnabled(False)

        elif wtype == "combo":
            widget = QComboBox()
            ids = field.get("comboIds", [])
            names = field.get("comboNames", [])
            for i, name in enumerate(names):
                widget.addItem(name, ids[i] if i < len(ids) else name)
            if not iseditable:
                widget.setEnabled(False)

        return widget

    def set_widget_value(self, widget, value):
        """Sets the widget value from JSON"""

        if isinstance(widget, QLineEdit):
            widget.setText(str(value))
        elif isinstance(widget, QTextEdit):
            widget.setPlainText(str(value))
        elif isinstance(widget, QDateEdit):
            if value:
                date = QDate.fromString(value, "yyyy-MM-dd")
                if date.isValid():
                    widget.setDate(date)
        elif isinstance(widget, QCheckBox):
            widget.setChecked(str(value).lower() in ["true", "1"])
        elif isinstance(widget, QComboBox):
            index = widget.findData(value)
            if index >= 0:
                widget.setCurrentIndex(index)

    def get_widget_by_columnname(self, dialog, columnname):
        for widget in dialog.findChildren(QWidget):
            if widget.property("columnname") == columnname:
                return widget
        return None
