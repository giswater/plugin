"""
Manage satellite / auxiliary schemas from a single dialog.
"""

from __future__ import annotations

from functools import partial

from qgis.PyQt.QtCore import QEvent, Qt
from qgis.PyQt.QtGui import QStandardItem, QStandardItemModel
from qgis.core import QgsApplication
from qgis.PyQt.sip import isdeleted
from qgis.PyQt.QtWidgets import (
    QHeaderView, QSizePolicy, QScrollArea, QWidget, QVBoxLayout,
)

from ..ui.ui_manager import GwAdminManageSchemasUi
from .i18n_multilang_languages import GwI18NMultilangLanguagesDialog
from ...libs import tools_qt
from ..utils import tools_gw
from . import _admin_catalog as admin_catalog

_NETWORK_COLUMNS = (
    "Schema", "Kind", "Version", "Profile", "Linked", "Created", "Last update",
)
_COL_SCHEMA = 0
_COL_LINKED = 4
_COL_CREATED = 5
_COL_UPDATED = 6
_MAX_VISIBLE_NETWORK_ROWS = 4
_FIXED_WIDTH = 1120
_SATELLITE_GROUPS = (
    "grb_utils", "grb_cibs", "grb_am", "grb_cm", "grb_i18n", "grb_audit",
)
_SATELLITE_INFO_LABELS = (
    "lbl_utils_info",
    "lbl_cibs_info",
    "lbl_am_info",
    "lbl_cm_info",
    "lbl_audit_info",
    "lbl_i18n_info",
)


class GwManageSchemasDialog(GwAdminManageSchemasUi):

    def __init__(self, admin_btn, parent=None):
        super().__init__(admin_btn, parent=parent)
        self.admin = admin_btn
        self._inventory_rows: list[dict] = []
        self._selected_network_parent = ""
        self._network_model = QStandardItemModel(0, len(_NETWORK_COLUMNS), self)
        self._network_model.setHorizontalHeaderLabels(list(_NETWORK_COLUMNS))
        self._scroll_area = None
        self._scroll_content = None

        self.messageBar().hide()
        self._setup_layout()
        self._setup_connection()
        self._setup_network_table()
        self._setup_satellite_labels()
        self._setup_cm_actions()
        self._refresh_inventory()
        self._connect_signals()

    def _setup_satellite_labels(self) -> None:
        for attr in _SATELLITE_INFO_LABELS:
            label = getattr(self, attr, None)
            if label is not None:
                label.setWordWrap(True)
                label.setMinimumWidth(0)
                # Reserve two text lines so panels match AM/CM when dates wrap.
                label.setMinimumHeight(label.fontMetrics().lineSpacing() * 2)
                label.setSizePolicy(
                    QSizePolicy.Policy.Preferred,
                    QSizePolicy.Policy.Minimum,
                )
        for grb_attr in _SATELLITE_GROUPS:
            group = getattr(self, grb_attr, None)
            if group is None:
                continue
            group.setSizePolicy(
                QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Preferred,
            )
            layout = group.layout()
            if layout is not None:
                layout.setContentsMargins(8, 10, 8, 6)
                if layout.count() >= 3:
                    # Spacer expands so equal-height boxes keep actions bottom-aligned.
                    layout.setStretch(0, 0)
                    layout.setStretch(1, 1)
                    layout.setStretch(2, 0)

    def _setup_cm_actions(self) -> None:
        self.btn_cm_qgis.setIcon(QgsApplication.getThemeIcon("mActionAddProject"))
        self.btn_cm_qgis.setToolButtonStyle(Qt.ToolButtonStyle.ToolButtonIconOnly)

    def _setup_layout(self) -> None:
        self.verticalLayout.setStretch(0, 0)
        self.verticalLayout.setStretch(1, 0)
        self.verticalLayout.setStretch(2, 0)
        self.verticalLayout.setStretch(3, 0)
        self.layout_network_root.setStretch(1, 0)
        self.layout_satellites.setColumnStretch(0, 1)
        self.layout_satellites.setColumnStretch(1, 1)
        self.layout_satellites.setRowStretch(0, 1)
        self.layout_satellites.setRowStretch(1, 1)
        self.layout_satellites.setRowStretch(2, 1)
        self.grb_connection.setSizePolicy(
            QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Fixed,
        )
        self.grb_network.setSizePolicy(
            QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Fixed,
        )

    def _equalize_satellite_panel_sizes(self) -> None:
        """Force all satellite group boxes to the tallest panel height (AM/CM)."""
        groups = [
            group for attr in _SATELLITE_GROUPS
            if (group := getattr(self, attr, None)) is not None
        ]
        if not groups:
            return
        for group in groups:
            group.setMinimumHeight(0)
        self.layout_satellites.activate()
        target_height = max(group.sizeHint().height() for group in groups)
        for group in groups:
            group.setMinimumHeight(target_height)

    def apply_scroll_geometry(self) -> None:
        """Cap table rows and size the dialog to content (no extra empty space)."""
        self._apply_network_table_height()
        self._equalize_satellite_panel_sizes()
        self._ensure_dialog_scroll()
        self._fit_dialog_geometry()

    def _ensure_dialog_scroll(self) -> None:
        if self._scroll_area is not None:
            return

        main_layout = self.verticalLayout
        scroll_area = QScrollArea(self)
        scroll_area.setWidgetResizable(True)
        scroll_area.setFrameShape(QScrollArea.Shape.NoFrame)
        scroll_area.setHorizontalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
        scroll_area.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
        scroll_area.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Expanding)

        content = QWidget()
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(0, 0, 0, 0)
        content_layout.setSpacing(main_layout.spacing())

        # Keep footer buttons outside the scroll area.
        while main_layout.count() > 1:
            item = main_layout.takeAt(0)
            if item.widget():
                content_layout.addWidget(item.widget())
            elif item.layout():
                content_layout.addLayout(item.layout())
            elif item.spacerItem():
                content_layout.addItem(item.spacerItem())

        scroll_area.setWidget(content)
        main_layout.insertWidget(0, scroll_area, 1)

        self._scroll_area = scroll_area
        self._scroll_content = content

    def _content_preferred_height(self) -> int:
        """Preferred height to show all content without empty stretch space."""
        spacing = self.verticalLayout.spacing()
        return (
            self.grb_connection.sizeHint().height()
            + spacing
            + self.grb_network.sizeHint().height()
            + spacing
            + self.layout_satellites.sizeHint().height()
        )

    def _fit_dialog_geometry(self) -> None:
        """Fix width; set height/max height to the tight content size."""
        margins = self.verticalLayout.contentsMargins()
        footer_h = self.lyt_buttons.sizeHint().height()
        height = (
            self._content_preferred_height()
            + footer_h
            + margins.top()
            + margins.bottom()
            + self.verticalLayout.spacing()
        )
        height = max(height, self.minimumHeight())
        width = _FIXED_WIDTH

        # Allow temporary growth while applying the fitted size.
        self.setMaximumSize(16777215, 16777215)
        self.setMinimumWidth(width)
        self.resize(width, height)
        self.setFixedWidth(width)
        self.setMaximumHeight(height)

    def _apply_network_table_height(self) -> None:
        """Cap the network table to four visible rows; scroll when there are more."""
        table = self.tbl_network
        row_h = table.verticalHeader().defaultSectionSize()
        visible_rows = _MAX_VISIBLE_NETWORK_ROWS
        if self._network_model.rowCount() > 0:
            visible_rows = min(self._network_model.rowCount(), _MAX_VISIBLE_NETWORK_ROWS)
            row_h = max(row_h, table.rowHeight(0))
        header_h = table.horizontalHeader().height()
        if header_h <= 0:
            header_h = table.fontMetrics().height() + 10
        frame = table.frameWidth() * 2
        height = header_h + row_h * visible_rows + frame
        table.setFixedHeight(height)
        table.setSizePolicy(QSizePolicy.Policy.Expanding, QSizePolicy.Policy.Fixed)
        self.grb_network.setSizePolicy(
            QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Fixed,
        )

    def _setup_connection(self) -> None:
        self.admin._populate_combo_connections()
        if self.admin.list_connections:
            tools_qt.fill_combo_values(self.cmb_connection, self.admin.list_connections)
        current = ""
        if getattr(self.admin, "cmb_connection", None) is not None:
            current = tools_qt.get_text(
                self.admin.dlg_readsql,
                self.admin.cmb_connection,
                return_string_null=False,
            )
        if not current:
            current = self.admin._get_last_connection() or ""
        if current:
            tools_qt.set_combo_value(self.cmb_connection, current, 1)
        self._active_connection = current
        self._update_system_info()

    def _format_system_info(self) -> str:
        result = getattr(self.admin, "_admin_catalog_cache", None)
        pg = self.admin.postgresql_version or "?"
        postgis = self.admin.postgis_version or "?"
        pgrouting = self.admin.pgrouting_version or "?"
        lines = [
            f"{tools_qt.tr('PostgreSQL version')}: {pg}",
            f"{tools_qt.tr('PostGis version')}: {postgis}",
            f"{tools_qt.tr('PgRouting version')}: {pgrouting}",
        ]
        if result and getattr(result, "extensions_present", None):
            missing = sorted(
                name for name, present in result.extensions_present.items() if not present
            )
            if missing:
                lines.append(
                    f"{tools_qt.tr('Missing extensions')}: {', '.join(missing)}"
                )
        return "\n".join(lines)

    def _update_system_info(self) -> None:
        self.txt_system_info.setPlainText(self._format_system_info())

    def _sync_connection_combo(self, connection_name: str) -> None:
        if not connection_name:
            return
        self.cmb_connection.blockSignals(True)
        tools_qt.set_combo_value(self.cmb_connection, connection_name, 1)
        self._active_connection = connection_name
        self.cmb_connection.blockSignals(False)

    def _on_connection_changed(self) -> None:
        connection_name = tools_qt.get_text(
            self, self.cmb_connection, return_string_null=False
        )
        if not connection_name or connection_name == self._active_connection:
            return
        previous = self._active_connection
        self.setEnabled(False)
        try:
            if not self.admin.reload_connection_for_manage_schemas(connection_name):
                if previous:
                    self.cmb_connection.blockSignals(True)
                    tools_qt.set_combo_value(self.cmb_connection, previous, 1)
                    self.cmb_connection.blockSignals(False)
                return
            self._active_connection = connection_name
            self._selected_network_parent = ""
            self.tbl_network.clearSelection()
            self._update_system_info()
            self._refresh_inventory()
        finally:
            self.setEnabled(True)

    def _connect_signals(self) -> None:
        self.cmb_connection.currentIndexChanged.connect(partial(self._on_connection_changed))
        self.btn_refresh.clicked.connect(partial(self._refresh_inventory))
        self.btn_network_rename.clicked.connect(partial(self._rename_network_schema))
        self.btn_network_delete.clicked.connect(partial(self._delete_network_schema))
        self.btn_update_network.clicked.connect(partial(self._update_network))
        self.btn_utils_create.clicked.connect(partial(self.admin._create_utils))
        self.btn_utils_integrate.clicked.connect(partial(self._integrate_utils))
        self.btn_utils_update.clicked.connect(partial(self.admin._update_utils))
        self.btn_cibs_create.clicked.connect(partial(self.admin._create_cibs))
        self.btn_cibs_integrate.clicked.connect(partial(self._integrate_cibs))
        self.btn_cibs_copy.clicked.connect(partial(self._adapt_cibs_copy))
        self.btn_cibs_update.clicked.connect(partial(self.admin._update_cibs))
        self.btn_create_am.clicked.connect(partial(self._create_am))
        self.btn_create_am_sample.clicked.connect(partial(self._create_am_sample))
        self.btn_integrate_am.clicked.connect(partial(self._integrate_am))
        self.btn_integrate_am_sample.clicked.connect(partial(self._integrate_am_sample))
        self.btn_update_am.clicked.connect(partial(self._update_am))
        self.btn_delete_am.clicked.connect(partial(self._delete_other_schema, 'am'))
        self.btn_create_cm.clicked.connect(partial(self._create_cm))
        self.btn_update_cm.clicked.connect(partial(self._update_cm))
        self.btn_cm_integrate.clicked.connect(partial(self._integrate_cm))
        self.btn_cm_sample.clicked.connect(partial(self._load_cm_sample))
        self.btn_cm_qgis.clicked.connect(partial(self._create_cm_qgis))
        self.btn_delete_cm.clicked.connect(partial(self._delete_cm))
        self.btn_i18n_create.clicked.connect(partial(self.admin._create_i18n))
        self.btn_i18n_update.clicked.connect(partial(self.admin._update_i18n))
        self.btn_languages.clicked.connect(partial(self.load_languages_multilang))
        self.btn_i18n_delete.clicked.connect(partial(self._delete_other_schema, 'multilang'))
        self.btn_create_audit.clicked.connect(partial(self._create_audit))
        self.btn_update_audit.clicked.connect(partial(self.admin._update_audit))
        self.btn_activate_audit.clicked.connect(partial(self._activate_audit))
        self.btn_reload_audit_triggers.clicked.connect(partial(self._reload_audit_triggers))
        self.btn_delete_audit.clicked.connect(partial(self._delete_other_schema, 'audit'))
        self.btn_close.clicked.connect(self.close)
        selection = self.tbl_network.selectionModel()
        if selection is not None:
            selection.selectionChanged.connect(partial(self._on_network_selection_changed))

    def _setup_network_table(self) -> None:
        self.tbl_network.setModel(self._network_model)
        self.tbl_network.setAlternatingRowColors(True)
        self.tbl_network.setSortingEnabled(True)
        self.tbl_network.verticalHeader().setVisible(False)
        self.tbl_network.setVerticalScrollBarPolicy(
            Qt.ScrollBarPolicy.ScrollBarAsNeeded,
        )

        header = self.tbl_network.horizontalHeader()
        header.setStretchLastSection(False)
        header.setSectionResizeMode(_COL_SCHEMA, QHeaderView.ResizeMode.Stretch)
        for col in (1, 2, 3, _COL_CREATED, _COL_UPDATED):
            header.setSectionResizeMode(col, QHeaderView.ResizeMode.ResizeToContents)
        header.setSectionResizeMode(_COL_LINKED, QHeaderView.ResizeMode.ResizeToContents)
        header.setMinimumSectionSize(48)
        self.tbl_network.viewport().installEventFilter(self)
        self._apply_network_table_height()
    
    def load_languages_multilang(self) -> None:
        dlg = getattr(self, 'dlg_multilang_languages', None)
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        dlg = GwI18NMultilangLanguagesDialog(self)
        dlg.init_dialog()
        self.dlg_multilang_languages = dlg

    def eventFilter(self, watched, event):
        if watched is self.tbl_network.viewport():
            if (
                event.type() == QEvent.Type.MouseButtonPress
                and event.button() == Qt.MouseButton.LeftButton
            ):
                index = self.tbl_network.indexAt(event.pos())
                if index.isValid():
                    selection = self.tbl_network.selectionModel()
                    if selection is not None and selection.isSelected(index):
                        selection.clearSelection()
                        return True
        return super().eventFilter(watched, event)

    def _network_rows(self) -> list[dict]:
        return [
            row for row in self._inventory_rows
            if str(row.get("kind") or "").upper() in ("WS", "UD")
        ]

    def _refresh_inventory(self) -> None:
        previous_parent = self._selected_network_parent
        self.btn_refresh.setEnabled(False)
        try:
            # Re-read baseline fingerprint so Update reflects file changes on disk.
            from .i18n_baseline_seed import invalidate_baseline_fingerprint_cache
            invalidate_baseline_fingerprint_cache(getattr(self.admin, "sql_dir", None))

            update_info = getattr(self.admin, "_manage_schemas_update_system_info", None)
            if update_info:
                update_info()
            self._inventory_rows = admin_catalog.fetch_schema_inventory()
            self._populate_network_table()
            if previous_parent:
                self._select_network_row(previous_parent)
            self._update_schema_labels()
            self._update_action_state()
        finally:
            self.btn_refresh.setEnabled(True)
        # Re-equalize after labels/actions change; refit once the dialog is scrolled.
        self._equalize_satellite_panel_sizes()
        if self._scroll_area is not None:
            self._fit_dialog_geometry()

    def _populate_network_table(self) -> None:
        self.tbl_network.setSortingEnabled(False)
        selection = self.tbl_network.selectionModel()
        if selection is not None:
            selection.blockSignals(True)
        try:
            self._network_model.removeRows(0, self._network_model.rowCount())
            for row in self._network_rows():
                values = (
                    row.get("schema", ""),
                    row.get("kind", ""),
                    row.get("version", ""),
                    row.get("profile", ""),
                    row.get("linked", ""),
                    row.get("date_created", ""),
                    row.get("date_updated", ""),
                )
                items = []
                for value in values:
                    item = QStandardItem(str(value or ""))
                    item.setEditable(False)
                    items.append(item)
                self._network_model.appendRow(items)
        finally:
            if selection is not None:
                selection.blockSignals(False)
        self.tbl_network.setSortingEnabled(True)
        if self._network_model.rowCount() > 0:
            self.tbl_network.resizeColumnToContents(_COL_LINKED)
        self._apply_network_table_height()

    def _on_network_selection_changed(self, *_args) -> None:
        self._selected_network_parent = self._selected_parent()
        self._update_network_label()
        self._update_action_state()

    def _selected_parent(self) -> str:
        selection = self.tbl_network.selectionModel()
        if selection is None:
            return ""
        indexes = selection.selectedRows()
        if not indexes:
            return ""
        row_idx = indexes[0].row()
        item = self._network_model.item(row_idx, _COL_SCHEMA)
        return item.text() if item else ""

    def _select_network_row(self, schema_name: str) -> None:
        for row_idx in range(self._network_model.rowCount()):
            item = self._network_model.item(row_idx, _COL_SCHEMA)
            if item and item.text() == schema_name:
                self.tbl_network.selectRow(row_idx)
                self._selected_network_parent = schema_name
                self._update_network_label()
                return

    def _parent_context(self) -> tuple[str, str]:
        parent = self._selected_parent()
        return parent, self._parent_kind(parent)

    def _parent_kind(self, schema_name: str) -> str:
        row = admin_catalog.find_inventory_row(self._inventory_rows, schema=schema_name)
        if row:
            return str(row.get("kind") or "").upper()
        for schema, project_type in admin_catalog.fetch_sys_version_schemas():
            if schema == schema_name:
                return str(project_type).upper()
        return ""

    def _satellite_group_title(
        self, group_name: str, row: dict | None, default_schema: str = "",
    ) -> str:
        if not row or not str(row.get("version") or ""):
            return group_name
        schema = str(row.get("schema") or default_schema or "?")
        version = str(row.get("version") or "?")
        return f"{group_name} · {schema} · {version}"

    def _format_satellite_dates(self, row: dict | None) -> str:
        if not row or not str(row.get("version") or ""):
            return tools_qt.tr("Not installed")
        parts: list[str] = []
        created = str(row.get("date_created") or "")
        updated = str(row.get("date_updated") or "")
        if created:
            parts.append(f"{tools_qt.tr('Created')}: {created}")
        if updated:
            parts.append(f"{tools_qt.tr('Last update')}: {updated}")
        return " · ".join(parts) if parts else tools_qt.tr("Not installed")

    def _format_audit_info(self, row: dict | None) -> str:
        if not row:
            return tools_qt.tr("Not installed")
        if admin_catalog.is_audit_stub():
            return tools_qt.tr("Partial (required by CM)")
        return self._format_satellite_dates(row)

    def _update_satellite_panel(
        self,
        group_attr: str,
        label_attr: str,
        group_name: str,
        row: dict | None,
        default_schema: str = "",
    ) -> None:
        group = getattr(self, group_attr, None)
        if group is not None:
            group.setTitle(self._satellite_group_title(group_name, row, default_schema))
        if group_attr == "grb_audit":
            self._set_info_label(label_attr, self._format_audit_info(row))
        else:
            self._set_info_label(label_attr, self._format_satellite_dates(row))

    def _satellite_row(self, *, kind: str | None = None, schema: str | None = None) -> dict | None:
        return admin_catalog.find_inventory_row(
            self._inventory_rows,
            kind=kind,
            schema=schema,
        )

    def _set_info_label(self, attr: str, text: str) -> None:
        label = getattr(self, attr, None)
        if label is not None:
            label.setText(text)

    def _update_schema_labels(self) -> None:
        utils_row = self._satellite_row(schema="utils")
        cibs_row = self._satellite_row(schema="cibs")
        am_row = self._satellite_row(kind="AM") or self._satellite_row(schema="am")
        cm_row = self._satellite_row(kind="CM")
        audit_row = self._satellite_row(kind="AUDIT") or self._satellite_row(schema="audit")
        i18n_row = self._satellite_row(kind="MULTILANG") or self._satellite_row(schema="multilang")

        self._update_satellite_panel("grb_utils", "lbl_utils_info", "Utils", utils_row, "utils")
        self._update_satellite_panel("grb_cibs", "lbl_cibs_info", "Cibs", cibs_row, "cibs")
        self._update_satellite_panel("grb_am", "lbl_am_info", "AM", am_row, "am")
        self._update_satellite_panel("grb_cm", "lbl_cm_info", "CM", cm_row, "cm")
        self._update_satellite_panel("grb_i18n", "lbl_i18n_info", "Multilang", i18n_row, "multilang")
        self._update_satellite_panel("grb_audit", "lbl_audit_info", "Audit", audit_row, "audit")
        self._update_network_label()

    def _update_network_label(self) -> None:
        parent = self._selected_parent()
        if not parent:
            if self._satellite_row(kind="CM"):
                self.lbl_network_selection.setText(
                    tools_qt.tr("Anchor: select a WS/UD row to integrate CM"),
                )
            else:
                self.lbl_network_selection.setText(
                    tools_qt.tr("Anchor: select a row below"),
                )
            return
        self.lbl_network_selection.setText(
            f"{tools_qt.tr('Anchor')}: {parent}",
        )

    def _needs_update(self, version: str) -> bool:
        return admin_catalog.schema_needs_plugin_update(
            version,
            str(self.admin.plugin_version),
        )

    def _i18n_needs_update(self) -> bool:
        """True when baseline files changed or seedable schemas are out of sync."""
        try:
            if self.admin._multilang_baseline_changed():
                return True
            if self.admin._multilang_schemas_out_of_sync(self._inventory_rows):
                return True
        except Exception:
            # Prefer enabling Update so the user can recover from a broken check.
            return True
        return False

    def _network_has_pending_updates(self, anchor: str) -> bool:
        if not anchor or self._parent_kind(anchor) not in ("WS", "UD"):
            return False
        plan = admin_catalog.build_network_update_plan(anchor, str(self.admin.plugin_version))
        return any(step.get("needs_update") for step in plan)

    def _update_action_state(self, *_args) -> None:
        parent, parent_kind = self._parent_context()
        has_network_parent = bool(parent) and parent_kind in ("WS", "UD")

        utils_row = self._satellite_row(schema="utils")
        cibs_row = self._satellite_row(schema="cibs")
        am_row = self._satellite_row(kind="AM") or self._satellite_row(schema="am")
        cm_row = self._satellite_row(kind="CM")
        audit_row = self._satellite_row(kind="AUDIT") or self._satellite_row(schema="audit")
        i18n_row = self._satellite_row(kind="MULTILANG") or self._satellite_row(schema="multilang")

        utils_exists = utils_row is not None
        cibs_exists = cibs_row is not None
        am_exists = am_row is not None
        cm_exists = cm_row is not None
        audit_namespace = audit_row is not None
        audit_full = admin_catalog.is_audit_fully_installed()
        i18n_exists = i18n_row is not None

        self.btn_utils_create.setEnabled(not utils_exists)
        self.btn_utils_update.setEnabled(
            utils_exists and self._needs_update(str((utils_row or {}).get("version") or ""))
        )
        self.btn_utils_integrate.setEnabled(
            has_network_parent
            and utils_exists
            and not admin_catalog.parent_satellite_linked(
                self._inventory_rows, parent, "utils"
            )
        )

        self.btn_cibs_create.setEnabled(not cibs_exists)
        self.btn_cibs_update.setEnabled(
            cibs_exists and self._needs_update(str((cibs_row or {}).get("version") or ""))
        )
        self.btn_cibs_integrate.setEnabled(
            has_network_parent
            and cibs_exists
            and not admin_catalog.parent_satellite_linked(
                self._inventory_rows, parent, "cibs"
            )
        )
        self.btn_cibs_copy.setEnabled(has_network_parent and cibs_exists)

        am_integrated = admin_catalog.am_is_integrated(am_row, self._inventory_rows)

        self.btn_create_am.setEnabled(not am_exists)
        self.btn_create_am_sample.setEnabled(not am_exists)
        self.btn_integrate_am.setEnabled(
            am_exists
            and parent_kind == "WS"
            and not am_integrated
        )
        self.btn_integrate_am_sample.setEnabled(
            am_exists
            and parent_kind == "WS"
            and not am_integrated
        )
        self.btn_update_am.setEnabled(
            am_exists and self._needs_update(str((am_row or {}).get("version") or ""))
        )
        self.btn_delete_am.setEnabled(am_exists)

        self.btn_create_cm.setEnabled(not cm_exists)
        self.btn_update_cm.setEnabled(
            cm_exists and self._needs_update(str((cm_row or {}).get("version") or ""))
        )
        self.btn_cm_integrate.setEnabled(
            has_network_parent
            and cm_exists
            and not admin_catalog.parent_satellite_linked(
                self._inventory_rows, parent, "cm"
            )
        )
        self.btn_cm_sample.setEnabled(
            has_network_parent
            and cm_exists
            and not self.admin._cm_has_sample_data()
        )
        self.btn_cm_qgis.setEnabled(cm_exists)
        self.btn_delete_cm.setEnabled(cm_exists)

        self.btn_i18n_create.setEnabled(not i18n_exists)
        self.btn_i18n_delete.setEnabled(i18n_exists)
        self.btn_languages.setEnabled(i18n_exists)
        self.btn_i18n_update.setEnabled(i18n_exists and self._i18n_needs_update())

        self.btn_create_audit.setEnabled(not audit_full)
        self.btn_update_audit.setEnabled(
            audit_full and self._needs_update(str((audit_row or {}).get("version") or ""))
        )
        self.btn_activate_audit.setEnabled(audit_full and has_network_parent)
        self.btn_reload_audit_triggers.setEnabled(audit_full and has_network_parent)
        self.btn_delete_audit.setEnabled(audit_namespace)

        self.btn_update_network.setEnabled(self._network_has_pending_updates(parent))
        has_selection = bool(parent) and parent_kind in ("WS", "UD")
        self.btn_network_delete.setEnabled(has_selection)
        self.btn_network_rename.setEnabled(
            has_selection
            and not self._needs_update(str((self._satellite_row(schema=parent) or {}).get("version") or ""))
        )

    def _delete_network_schema(self) -> None:
        parent = self._selected_parent()
        if not parent:
            msg = "Select a WS or UD schema in the table."
            tools_qt.show_info_box(msg)
            return
        self.admin._delete_schema(schema_name=parent)

    def _rename_network_schema(self) -> None:
        parent = self._selected_parent()
        if not parent:
            msg = "Select a WS or UD schema in the table."
            tools_qt.show_info_box(msg)
            return
        row = self._satellite_row(schema=parent)
        version = str((row or {}).get("version") or "")
        self.admin._open_rename(schema_name=parent, schema_version=version)

    def _update_network(self) -> None:
        parent = self._selected_parent()
        if not parent:
            msg = "Select a WS or UD schema in the table."
            tools_qt.show_info_box(msg)
            return
        if self._parent_kind(parent) not in ("WS", "UD"):
            msg = "Update network requires a WS or UD anchor."
            tools_qt.show_info_box(msg)
            return
        self.admin._update_network(anchor_schema=parent)

    def _create_am(self) -> None:
        self.admin._create_am_schema(profile="empty")

    def _create_am_sample(self) -> None:
        self.admin._create_am_schema(profile="sample")

    def _integrate_am(self) -> None:
        parent, parent_type = self._parent_context()
        if not parent or parent_type != "WS":
            msg = "Select a WS anchor in the network table."
            tools_qt.show_info_box(msg)
            return
        self.admin._integrate_am_schema(
            profile="integrate",
            parent_schema=parent,
            parent_type=parent_type.lower(),
        )

    def _integrate_am_sample(self) -> None:
        parent, parent_type = self._parent_context()
        if not parent or parent_type != "WS":
            msg = "Select a WS anchor in the network table."
            tools_qt.show_info_box(msg)
            return
        self.admin._integrate_am_schema(
            profile="integrate_sample",
            parent_schema=parent,
            parent_type=parent_type.lower(),
        )

    def _create_audit(self) -> None:
        self.admin.create_project_data_other_schema('audit')

    def _update_am(self) -> None:
        parent, parent_type = self._parent_context()
        self.admin._update_asset(
            parent_schema=parent,
            parent_type=parent_type.lower(),
        )

    def _create_cm(self) -> None:
        self.admin._create_cm_schema()

    def _integrate_cm(self) -> None:
        parent, parent_type = self._parent_context()
        if not parent:
            msg = "Select a WS or UD anchor in the network table."
            tools_qt.show_info_box(msg)
            return
        self.admin._integrate_cm(
            parent_schema=parent,
            parent_type=parent_type.lower(),
        )

    def _load_cm_sample(self) -> None:
        parent, parent_type = self._parent_context()
        if not parent:
            msg = "Select a WS or UD anchor in the network table."
            tools_qt.show_info_box(msg)
            return
        self.admin._load_cm_sample(
            parent_schema=parent,
            parent_type=parent_type.lower(),
        )

    def _create_cm_qgis(self) -> None:
        self.admin._set_cm_pschema_qgis()

    def _update_cm(self) -> None:
        parent, parent_type = self._parent_context()
        cm_row = self._satellite_row(kind="CM")
        cm_schema = str((cm_row or {}).get("schema") or admin_catalog.find_cm_schema() or "cm")
        self.admin._update_cm(
            parent_schema=parent,
            parent_type=parent_type.lower(),
            cm_schema=cm_schema,
        )

    def _delete_cm(self) -> None:
        cm_row = self._satellite_row(kind="CM")
        schema_name = str((cm_row or {}).get("schema") or admin_catalog.find_cm_schema() or "cm")
        self._delete_other_schema(schema_name)

    def _activate_audit(self) -> None:
        parent, parent_type = self._parent_context()
        if not parent:
            msg = "Select a WS/UD anchor in the network table."
            tools_qt.show_info_box(msg)
            return
        self.admin._activate_audit(
            'audit',
            parent_schema=parent,
            parent_type=parent_type.lower(),
        )

    def _reload_audit_triggers(self) -> None:
        parent = self._selected_parent()
        if not parent:
            msg = "Select a WS/UD anchor in the network table."
            tools_qt.show_info_box(msg)
            return
        self.admin._reload_audit_triggers(schema_name=parent)

    def _integrate_utils(self):
        parent, parent_kind = self._parent_context()
        if not parent:
            msg = "Select a WS or UD anchor in the network table."
            tools_qt.show_info_box(msg)
            return
        if parent_kind == "WS":
            self.admin._adapt_utils_ws(ws_schema=parent)
        elif parent_kind == "UD":
            self.admin._adapt_utils_ud(ud_schema=parent)
        else:
            msg = "Integrate utils requires a WS or UD anchor."
            tools_qt.show_info_box(msg)

    def _integrate_cibs(self):
        parent = self._selected_parent()
        if not parent:
            msg = "Select a network anchor to integrate cibs."
            tools_qt.show_info_box(msg)
            return
        self.admin._adapt_cibs(parent_schema=parent)

    def _adapt_cibs_copy(self):
        parent = self._selected_parent()
        if not parent:
            msg = "Select a network anchor to copy cibs data."
            tools_qt.show_info_box(msg)
            return
        self.admin._copy_cibs_data(parent_schema=parent)

    def _delete_other_schema(self, schema_name: str):
        self.admin._delete_other_schema(schema_name)
        self._refresh_inventory()
