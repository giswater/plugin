"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import sys
from functools import partial
from typing import Callable, List, Optional, Sequence, Tuple

from qgis.PyQt.QtCore import QAbstractListModel, QEvent, QModelIndex, QObject, QSize, Qt, QTimer
from qgis.PyQt.QtGui import QColor, QKeyEvent
from qgis.PyQt.QtWidgets import (
    QApplication,
    QBoxLayout,
    QComboBox,
    QFrame,
    QHBoxLayout,
    QLineEdit,
    QListView,
    QProxyStyle,
    QSizePolicy,
    QStyle,
    QStyleFactory,
    QStyledItemDelegate,
    QStyleOptionViewItem,
    QToolTip,
    QWidget,
)
from qgis.core import QgsApplication

from ..threads.combo_loader import GwComboLoaderTask, get_combo_rows_cached


# Pair of (id, idval) strings stored per row. Tuples are cheap and immutable.
_ComboRow = Tuple[str, str]


class _ComboListModel(QAbstractListModel):
    """Lightweight list model backed by a Python list of `(id, idval)` tuples.

    Built specifically to avoid the per-item cost of `QStandardItem` when a
    combo has many rows: replacing 15k items via `QComboBox.addItem` takes
    several seconds because each call constructs a `QStandardItem`, allocates
    indices and emits dataChanged/rowsInserted. With this model, refreshing
    the contents is a `beginResetModel`/`endResetModel` pair plus a Python
    list assignment — typically a few milliseconds even for 100k rows.
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        self._rows: List[_ComboRow] = []

    # region Model API used internally
    def set_rows(self, rows: Sequence[_ComboRow]) -> None:
        self.beginResetModel()
        self._rows = list(rows)
        self.endResetModel()

    def get_rows(self) -> List[_ComboRow]:
        return self._rows
    # endregion

    # region QAbstractListModel
    def rowCount(self, parent: QModelIndex = QModelIndex()) -> int:  # noqa: N802 - Qt API
        if parent.isValid():
            return 0
        return len(self._rows)

    def data(self, index: QModelIndex, role: int = Qt.ItemDataRole.DisplayRole):
        if not index.isValid():
            return None
        row = index.row()
        if row < 0 or row >= len(self._rows):
            return None
        item = self._rows[row]
        if role in (Qt.ItemDataRole.DisplayRole, Qt.ItemDataRole.EditRole):
            return item[1]
        if role == Qt.ItemDataRole.UserRole:
            # Keep `[id, idval]` as a list so existing code that does
            # `combo.itemData(i)[0]` (tools_qt.get_combo_value) keeps working.
            return [item[0], item[1]]
        return None

    def flags(self, index: QModelIndex):
        if not index.isValid():
            return Qt.ItemFlag.NoItemFlags
        return Qt.ItemFlag.ItemIsEnabled | Qt.ItemFlag.ItemIsSelectable

    def removeRows(self, row: int, count: int, parent: QModelIndex = QModelIndex()) -> bool:  # noqa: N802 - Qt API
        if parent.isValid() or row < 0 or count <= 0:
            return False
        if row + count > len(self._rows):
            return False
        self.beginRemoveRows(parent, row, row + count - 1)
        del self._rows[row:row + count]
        self.endRemoveRows()
        return True

    def append_row(self, row: _ComboRow) -> None:
        position = len(self._rows)
        self.beginInsertRows(QModelIndex(), position, position)
        self._rows.append(row)
        self.endInsertRows()
    # endregion


# Hard cap on how many rows are made visible in the popup at any one time.
# Even with the custom list model and uniform item sizes, painting and scroll
# math get noticeably slower past a few thousand rows; the user is expected
# to narrow with the search box past this point. The model itself still
# stores the full set so filtering uses every row.
MAX_POPUP_VISIBLE_ROWS = 200

# Cap on how many items the popup shows on screen at once (height limit).
# The popup scrolls past this; anything within the visible-rows cap can still
# be reached by scrolling, anything past it by typing in the search box.
MAX_POPUP_VISIBLE_HEIGHT_ITEMS = 15

# Popup layout: Qt may not have painted rows on the first pass.
_POPUP_LAYOUT_RETRY_MS = 10
_POPUP_LAYOUT_MAX_ATTEMPTS = 3
_POPUP_FRAME_PAD = 4
_SEARCH_H_PAD = 6
_SEARCH_V_PAD = 4
_ITEM_H_PAD = 8
_ITEM_V_PAD = 3
_QWIDGETSIZE_MAX = 16777215

try:
    _STATE_SELECTED = QStyle.StateFlag.State_Selected
    _STATE_MOUSEOVER = QStyle.StateFlag.State_MouseOver
except AttributeError:
    _STATE_SELECTED = QStyle.State_Selected
    _STATE_MOUSEOVER = QStyle.State_MouseOver

try:
    _ENSURE_VISIBLE = QListView.ScrollHint.EnsureVisible
except AttributeError:
    _ENSURE_VISIBLE = QListView.EnsureVisible


def _is_macos() -> bool:
    return sys.platform == "darwin"


# macOS Cocoa QComboBox ignores most stylesheets and paints the old aqua
# beveled button. Fusion + this QSS makes the closed combo look like a
# typeahead field (line-edit + chevron) without touching the app style.
_ASYNC_COMBO_MAC_QSS = """
QComboBox {
    background-color: palette(base);
    color: palette(text);
    border: 1px solid palette(mid);
    border-radius: 7px;
    padding: 4px 8px 4px 10px;
    min-height: 24px;
}
QComboBox:hover {
    border-color: palette(dark);
}
QComboBox:focus, QComboBox:on {
    border: 1px solid palette(highlight);
}
QComboBox::drop-down {
    subcontrol-origin: padding;
    subcontrol-position: top right;
    width: 22px;
    border: none;
    background: transparent;
}
QComboBox QAbstractItemView {
    background-color: palette(base);
    color: palette(text);
    border: none;
    outline: 0;
    selection-background-color: palette(highlight);
    selection-color: palette(highlighted-text);
}
"""


def _popup_search_qss() -> str:
    radius = 6 if _is_macos() else 3
    return f"""
QLineEdit {{
    background-color: palette(base);
    color: palette(text);
    border: 1px solid palette(mid);
    border-radius: {radius}px;
    padding: 2px 6px;
    selection-background-color: palette(highlight);
    selection-color: palette(highlighted-text);
}}
"""


def _popup_view_qss() -> str:
    # View chrome only. Item padding/selection is painted by
    # `_ComboItemDelegate` — QSS `::item { padding }` is not part of
    # `sizeHintForRow` on Windows Vista style, which clips the last row.
    return """
QListView {
    background-color: palette(base);
    color: palette(text);
    border: none;
    outline: 0;
    padding: 0px;
}
"""


def _style_closed_combo(combo: QComboBox) -> None:
    """Platform chrome for the closed combo (not the popup).

    On macOS the native style paints an aqua beveled button and ignores QSS,
    so we swap in Fusion + a line-edit-like sheet. On GTK+/KDE we only need
    the non-native popup hint. Windows already paints a non-native popup.

    `QWidget.setStyle` does **not** take ownership of the QStyle. Keep a
    Python reference on the combo so sip/GC cannot free it while Qt still
    paints (that double-free is a hard QGIS crash).
    """
    if combo is None:
        return
    if not sys.platform.startswith("win"):
        try:
            proxy = _build_non_native_combo_style()
            if proxy is not None:
                combo._gw_combo_style = proxy
                combo.setStyle(proxy)
        except Exception:
            pass
    if _is_macos():
        combo.setAttribute(Qt.WidgetAttribute.WA_MacShowFocusRect, False)
        combo.setStyleSheet(_ASYNC_COMBO_MAC_QSS)


class _NonNativeComboPopupStyle(QProxyStyle):
    """Style proxy that forces a non-native combo popup.

    Some styles (GTK+, macOS, sometimes Breeze) return `true` for
    `SH_ComboBox_Popup`, which makes Qt show a native popup that ignores
    `setMaxVisibleItems` on non-editable combos. By proxying the platform
    style and overriding only that hint we keep every other style detail
    (paint, metrics, sub-controls) untouched.

    Important: the base style passed to `QProxyStyle` is **reparented** by
    the proxy (Qt takes ownership). Never pass `QApplication.style()`
    directly — that steals the app's style and causes a crash later when
    the proxy (and with it, the app style) is destroyed. Always feed a
    fresh `QStyleFactory.create(...)` instance (or `None` to let Qt build
    its default).
    """

    def styleHint(self, hint, option=None, widget=None, returnData=None):  # noqa: N802 - Qt API
        if hint == QStyle.StyleHint.SH_ComboBox_Popup:
            return 0
        return super().styleHint(hint, option, widget, returnData)


def _build_non_native_combo_style() -> Optional[QProxyStyle]:
    """Build a `_NonNativeComboPopupStyle` over a fresh copy of the current
    application style. Returns `None` if no suitable style key is found
    (caller should then skip applying the proxy).

    On macOS the native style is skipped on purpose: Cocoa paints the
    closed combo as an aqua button and ignores QSS. Fusion is used instead.
    """
    app_style = QApplication.style()
    if app_style is None:
        return None
    if _is_macos():
        base = QStyleFactory.create("Fusion")
        if base is not None:
            return _NonNativeComboPopupStyle(base)

    style_key = app_style.objectName()
    if not style_key:
        # Fall back: derive from class name (QFusionStyle -> Fusion).
        cls_name = type(app_style).__name__
        if cls_name.startswith("Q") and cls_name.endswith("Style"):
            style_key = cls_name[1:-len("Style")]
    base = None
    # Try the QObject name first. QStyleFactory sets it to the key it was
    # created with (e.g. "Fusion"); native platform styles often have it
    # too (e.g. "Breeze" on KDE).
    if style_key:
        base = QStyleFactory.create(style_key)
    if base is None:
        # Anything is fine here — only used to delegate non-overridden
        # hints. Fusion is available on every Qt build.
        base = QStyleFactory.create("Fusion")
    if base is None:
        return None
    return _NonNativeComboPopupStyle(base)


class _ComboItemDelegate(QStyledItemDelegate):
    """Popup row painter with padding baked into ``sizeHint``.

    Windows Vista style applies QSS ``QListView::item { padding }`` at paint
    time but not in ``sizeHintForRow``, so content-height < painted height:
    the last row clips and the scrollbar max stops short. QSS
    ``margin`` / ``min-height`` also stretch the selected row to the viewport.
    """

    def sizeHint(self, option, index):  # noqa: N802 - Qt API
        metrics = option.fontMetrics
        text = '' if index.data() is None else str(index.data())
        try:
            text_w = metrics.horizontalAdvance(text)
        except AttributeError:
            text_w = metrics.width(text)
        height = max(20, metrics.height() + 2 * _ITEM_V_PAD)
        return QSize(text_w + 2 * _ITEM_H_PAD, height)

    def paint(self, painter, option, index):  # noqa: N802 - Qt API
        opt = QStyleOptionViewItem(option)
        self.initStyleOption(opt, index)
        text = '' if index.data() is None else str(index.data())
        selected = bool(opt.state & _STATE_SELECTED)
        hovered = bool(opt.state & _STATE_MOUSEOVER)

        painter.save()
        painter.setFont(opt.font)
        if selected:
            painter.fillRect(opt.rect, opt.palette.highlight())
            painter.setPen(opt.palette.highlightedText().color())
        else:
            painter.fillRect(opt.rect, opt.palette.base())
            if hovered:
                hover = QColor(opt.palette.highlight().color())
                hover.setAlpha(38)
                painter.fillRect(opt.rect, hover)
            painter.setPen(opt.palette.text().color())
        text_rect = opt.rect.adjusted(_ITEM_H_PAD, 0, -_ITEM_H_PAD, 0)
        elided = opt.fontMetrics.elidedText(
            text, Qt.TextElideMode.ElideRight, max(0, text_rect.width())
        )
        painter.drawText(
            text_rect,
            int(Qt.AlignmentFlag.AlignVCenter | Qt.AlignmentFlag.AlignLeft),
            elided,
        )
        painter.restore()


def _popup_search_bar_qss() -> str:
    return """
QFrame#gw_combo_search_bar {
    background-color: palette(base);
    border: none;
    border-bottom: 1px solid palette(mid);
}
"""


class _ComboSearchBar(QFrame):
    """Filter field that sits above the popup list (sibling of the view).

    Must not be parented into the ``QListView``: viewport-margin overlays
    steal height from the last row and the scrollbar max stops short.
    """

    def __init__(self, combo: QComboBox, parent=None):
        super().__init__(parent)
        self.setObjectName("gw_combo_search_bar")
        self.setFrameShape(QFrame.Shape.NoFrame)
        self.setStyleSheet(_popup_search_bar_qss())
        layout = QHBoxLayout(self)
        layout.setContentsMargins(_SEARCH_H_PAD, _SEARCH_V_PAD, _SEARCH_H_PAD, _SEARCH_V_PAD)
        layout.setSpacing(0)
        self.edit = QLineEdit(self)
        self.edit.setObjectName(f"{combo.objectName() or 'gw_combo'}_search")
        self.edit.setPlaceholderText(combo.tr("Type to filter..."))
        self.edit.setClearButtonEnabled(True)
        self.edit.setFrame(False)
        self.edit.setStyleSheet(_popup_search_qss())
        layout.addWidget(self.edit)
        # Must not expand: QVBoxLayout would grow this into a huge empty
        # band between the filter and the first row.
        self.setSizePolicy(QSizePolicy.Policy.Preferred, QSizePolicy.Policy.Fixed)
        self.setFixedHeight(self.sizeHint().height())


class _ComboPopupView(QListView):
    """`QListView` subclass that reserves a top viewport margin so a search
    `QLineEdit` can sit above the items without overlapping them.

    `setViewportMargins` is `protected` in `QAbstractScrollArea`, so we expose
    a public method here. Setting the margin reserves space inside the view's
    frame: the viewport (where items render) is shifted down by `margin`, but
    the view itself keeps the same outer geometry.
    """

    def __init__(self, parent=None):
        super().__init__(parent)
        # Drop the default frame; the QComboBox popup container already draws
        # its own frame around us.
        self.setFrameShape(QFrame.Shape.NoFrame)
        try:
            self.setUniformItemSizes(True)
        except AttributeError:
            pass
        self.setMouseTracking(True)
        self.setAttribute(Qt.WidgetAttribute.WA_Hover, True)
        self.setStyleSheet(_popup_view_qss())
        self.setItemDelegate(_ComboItemDelegate(self))
        self._top_margin = 0
        self._top_widget: Optional[QLineEdit] = None

    def set_top_margin(self, margin: int) -> None:
        self._top_margin = max(0, int(margin))
        self.setViewportMargins(0, self._top_margin, 0, 0)

    def set_top_widget(self, widget: Optional[QLineEdit]) -> None:
        self._top_widget = widget

    def top_margin(self) -> int:
        return self._top_margin

    def resizeEvent(self, event):  # noqa: N802 - Qt API
        super().resizeEvent(event)
        # Keep the registered search overlay anchored at the top, full-width.
        if self._top_margin <= 0 or self._top_widget is None:
            return
        try:
            width = max(0, self.width() - 2 * _SEARCH_H_PAD)
            height = max(0, self._top_margin - 2 * _SEARCH_V_PAD)
            self._top_widget.setGeometry(_SEARCH_H_PAD, _SEARCH_V_PAD, width, height)
        except RuntimeError:
            self._top_widget = None

    def viewportEvent(self, event):  # noqa: N802 - Qt API
        # Only tooltip when the label is actually elided. Repeating the
        # visible item text (Windows yellow balloon) is just noise.
        if event.type() == QEvent.Type.ToolTip:
            try:
                index = self.indexAt(event.pos())
                if not index.isValid():
                    QToolTip.hideText()
                    return True
                text = index.data(Qt.ItemDataRole.DisplayRole)
                if not text:
                    QToolTip.hideText()
                    return True
                label = str(text)
                rect = self.visualRect(index)
                metrics = self.fontMetrics()
                try:
                    text_w = metrics.horizontalAdvance(label)
                except AttributeError:
                    text_w = metrics.width(label)
                if text_w > max(0, rect.width() - 8):
                    if hasattr(event, "globalPosition"):
                        pos = event.globalPosition().toPoint()
                    else:
                        pos = event.globalPos()
                    QToolTip.showText(pos, label, self.viewport())
                else:
                    QToolTip.hideText()
                return True
            except RuntimeError:
                return True
        return super().viewportEvent(event)


class _ComboPopupSearchController(QObject):
    """Shared type-to-filter popup for ``QComboBox`` and ``GwAsyncComboBox``."""

    def __init__(
        self,
        combo: QComboBox,
        *,
        label_at: Callable[[int], str],
        row_count: Callable[[], int],
        index_at: Optional[Callable[[int], QModelIndex]] = None,
    ):
        super().__init__(combo)
        self._combo = combo
        self._label_at = label_at
        self._row_count = row_count
        self._index_at = index_at or (lambda i: combo.model().index(i, 0))
        self._search_edit: Optional[QLineEdit] = None
        self._search_bar: Optional[_ComboSearchBar] = None
        self._search_active: bool = False
        self._qt_list_height: int = 0
        self._hidden_rows: set = set()
        self._orig_show_popup = None
        self._orig_hide_popup = None

    def clear_filter_state(self) -> None:
        self._hidden_rows = set()

    def attach_to_plain_combo(self) -> None:
        """Hook ``showPopup`` / ``hidePopup`` on an existing ``QComboBox``."""
        self._ensure_popup_view()
        self._orig_show_popup = self._combo.showPopup
        self._orig_hide_popup = self._combo.hidePopup
        self._combo.showPopup = self._hook_show_popup  # noqa: N802 - Qt API
        self._combo.hidePopup = self._hook_hide_popup  # noqa: N802 - Qt API

    def _hook_show_popup(self) -> None:
        self._restore_hidden_rows()
        try:
            self._combo.setMaxVisibleItems(MAX_POPUP_VISIBLE_HEIGHT_ITEMS)
        except Exception:
            pass
        self._orig_show_popup()
        self.install_overlay()

    def _hook_hide_popup(self) -> None:
        self.teardown_overlay()
        self._orig_hide_popup()

    def _restore_hidden_rows(self) -> None:
        """Unhide every row so the next showPopup sizes a full list."""
        view = self._combo.view()
        total = self._row_count()
        if view is not None and total > 0:
            view.setUpdatesEnabled(False)
            try:
                for i in range(total):
                    try:
                        if view.isRowHidden(i):
                            view.setRowHidden(i, False)
                    except RuntimeError:
                        break
            finally:
                view.setUpdatesEnabled(True)
        self._hidden_rows = set()

    def install_overlay(self) -> None:
        view = self._combo.view()
        container = self._popup_container()
        if view is None or container is None:
            return

        if isinstance(view, _ComboPopupView):
            view.set_top_margin(0)
            view.set_top_widget(None)

        if self._search_bar is None:
            bar = _ComboSearchBar(self._combo, container)
            bar.edit.textChanged.connect(self._apply_search_filter)
            bar.edit.installEventFilter(self)
            self._search_bar = bar
            self._search_edit = bar.edit
        else:
            try:
                self._search_bar.setParent(container)
            except RuntimeError:
                self._search_bar = None
                self._search_edit = None
                return

        bar = self._search_bar
        edit = self._search_edit
        edit.blockSignals(True)
        edit.clear()
        edit.blockSignals(False)

        extra = bar.sizeHint().height()
        bar.setFixedHeight(extra)
        # Snapshot Qt's full-list height only when nothing is filtered.
        # Reopening after a filter used to capture the 2-row height and
        # then treat that as "full size" forever.
        if not self._hidden_rows and view.height() > 0:
            if view.height() >= self._qt_list_height:
                self._qt_list_height = view.height()

        self._insert_search_bar(container, bar, view)
        self._suppress_popup_scrollers(container, view)
        bar.show()
        edit.raise_()
        edit.setFocus(Qt.FocusReason.PopupFocusReason)

        self._search_active = True
        self._apply_search_filter("")
        QTimer.singleShot(0, self._suppress_popup_scrollers)

    def _insert_search_bar(self, container, bar, view) -> None:
        """Put the search bar above the list inside the combo popup layout."""
        layout = container.layout()
        if isinstance(layout, QBoxLayout):
            current = layout.indexOf(bar)
            if current >= 0:
                return
            insert_at = 0
            for i in range(layout.count()):
                item = layout.itemAt(i)
                if item is not None and item.widget() is view:
                    insert_at = i
                    break
            # Sit immediately above the list, never above a hidden scroller
            # slot (that reads as a huge blank gap under the filter).
            layout.insertWidget(insert_at, bar)
            layout.setStretch(insert_at, 0)
            view_at = layout.indexOf(view)
            if view_at >= 0:
                layout.setStretch(view_at, 0)
            return
        # No box layout (unusual): park it at the top of the container.
        bar.setParent(container)
        bar.move(0, 0)
        bar.resize(container.width(), bar.sizeHint().height())
        bar.raise_()

    def _popup_scroller_widgets(self, container=None, view=None):
        """Qt's hidden combo arrow strips (``QComboBoxPrivateScroller``)."""
        view = view if view is not None else self._combo.view()
        container = container if container is not None else self._popup_container()
        found = []
        if container is None:
            return found
        for child in container.children():
            if not isinstance(child, QWidget):
                continue
            if child.parent() is not container:
                continue
            if child is view or child is self._search_bar:
                continue
            found.append(child)
        return found

    def _suppress_popup_scrollers(self, container=None, view=None) -> None:
        """Hide the native up/down scroller rows and keep them from coming back.

        ``QComboBoxPrivateContainer::updateScrollers`` shows those arrow bars
        whenever the list can scroll. They steal height from the last row and
        look like a broken extra item.
        """
        for scroller in self._popup_scroller_widgets(container, view):
            try:
                scroller.hide()
                scroller.setMaximumHeight(0)
                scroller.setSizePolicy(
                    QSizePolicy.Policy.Ignored, QSizePolicy.Policy.Ignored
                )
                scroller.installEventFilter(self)
            except RuntimeError:
                continue

    def teardown_overlay(self) -> None:
        self._search_active = False
        self._restore_hidden_rows()
        try:
            self._combo.setMaxVisibleItems(MAX_POPUP_VISIBLE_HEIGHT_ITEMS)
        except Exception:
            pass
        self._clear_popup_height()
        view = self._combo.view()
        if isinstance(view, _ComboPopupView):
            view.set_top_margin(0)
            view.set_top_widget(None)
        if self._search_bar is None:
            return
        try:
            if self._search_edit is not None:
                self._search_edit.blockSignals(True)
                self._search_edit.clear()
                self._search_edit.blockSignals(False)
            self._search_bar.hide()
        except RuntimeError:
            self._search_bar = None
            self._search_edit = None

    def process_event(self, obj, event) -> bool:
        if obj is not self._search_edit or event.type() != QEvent.Type.KeyPress:
            return False
        assert isinstance(event, QKeyEvent)
        key = event.key()
        if key in (
            Qt.Key.Key_Down,
            Qt.Key.Key_Up,
            Qt.Key.Key_PageDown,
            Qt.Key.Key_PageUp,
            Qt.Key.Key_Home,
            Qt.Key.Key_End,
        ):
            self._forward_navigation(event)
            return True
        if key in (Qt.Key.Key_Return, Qt.Key.Key_Enter):
            self._activate_highlighted()
            return True
        if key == Qt.Key.Key_Escape:
            self._combo.hidePopup()
            return True
        if key == Qt.Key.Key_Tab:
            self._combo.hidePopup()
            QApplication.sendEvent(self._combo, event)
            return True
        return False

    def _ensure_popup_view(self) -> None:
        if not isinstance(self._combo.view(), _ComboPopupView):
            self._combo.setView(_ComboPopupView(self._combo))
        if self._combo.maxVisibleItems() <= MAX_POPUP_VISIBLE_HEIGHT_ITEMS:
            self._combo.setMaxVisibleItems(MAX_POPUP_VISIBLE_HEIGHT_ITEMS)

    def _popup_container(self):
        view = self._combo.view()
        return view.parentWidget() if view is not None else None

    def _popup_widgets(self):
        view = self._combo.view()
        if view is None:
            return []
        seen = set()
        widgets = []
        for widget in (self._popup_container(), view, view.window()):
            if widget is not None and id(widget) not in seen:
                seen.add(id(widget))
                widgets.append(widget)
        return widgets

    def _popup_anchor(self, width: int, height: int):
        rect = self._combo.rect()
        if getattr(self._combo, 'popup_opens_upward', False):
            pos = self._combo.mapToGlobal(rect.topLeft())
            return pos.x(), pos.y() - height, width, height
        pos = self._combo.mapToGlobal(rect.bottomLeft())
        return pos.x(), pos.y(), width, height

    def _set_popup_height(self, width: int, height: int) -> None:
        view = self._combo.view()
        if view is None:
            return
        popup = view.window()
        container = self._popup_container()
        geo = self._popup_anchor(width, height)

        # Only the framed popup window. The list view keeps its own height
        # (N rows); the search bar is a sibling in the container layout.
        for widget in (popup, container):
            if widget is None or not widget.isVisible():
                continue
            try:
                widget.setMaximumHeight(_QWIDGETSIZE_MAX)
                widget.setMinimumHeight(0)
                if popup is not None and widget is popup:
                    widget.setGeometry(*geo)
                else:
                    widget.resize(width, height)
                widget.setMinimumHeight(height)
                widget.setMaximumHeight(height)
            except RuntimeError:
                continue

    def _clear_popup_height(self) -> None:
        for widget in self._popup_widgets():
            widget.setMinimumHeight(0)
            widget.setMaximumHeight(_QWIDGETSIZE_MAX)

    def _pin_popup(self, width: int, height: int) -> None:
        if not self._search_active:
            return
        view = self._combo.view()
        if view is None:
            return
        popup = view.window()
        if popup is None or not popup.isVisible():
            return
        try:
            popup.setGeometry(*self._popup_anchor(width, height))
        except RuntimeError:
            pass

    def _apply_search_filter(self, text: str) -> None:
        if not self._search_active:
            return
        view = self._combo.view()
        if view is None:
            return
        needle = (text or '').strip().lower()
        total = self._row_count()

        new_hidden: set = set()
        first_visible = -1
        visible_count = 0
        match_count = 0
        for i in range(total):
            if needle and needle not in self._label_at(i).lower():
                new_hidden.add(i)
                continue
            match_count += 1
            if visible_count >= MAX_POPUP_VISIBLE_ROWS:
                new_hidden.add(i)
                continue
            if first_visible < 0:
                first_visible = i
            visible_count += 1

        view.setUpdatesEnabled(False)
        try:
            if not needle:
                for i in range(total):
                    view.setRowHidden(i, False)
                new_hidden = set()
            else:
                for i in self._hidden_rows - new_hidden:
                    view.setRowHidden(i, False)
                for i in new_hidden - self._hidden_rows:
                    view.setRowHidden(i, True)
        finally:
            view.setUpdatesEnabled(True)
        self._hidden_rows = new_hidden
        try:
            if hasattr(view, 'scheduleDelayedItemsLayout'):
                view.scheduleDelayedItemsLayout()
            view.updateGeometries()
            view.viewport().update()
        except (RuntimeError, AttributeError):
            pass

        if first_visible >= 0:
            current = self._combo.currentIndex()
            if (
                not needle
                and current >= 0
                and current not in self._hidden_rows
            ):
                new_idx = self._index_at(current)
            else:
                new_idx = self._index_at(first_visible)
            view.setCurrentIndex(new_idx)

        self._update_search_status(match_count, visible_count, needle, total)
        shown = 0 if match_count <= 0 else min(match_count, MAX_POPUP_VISIBLE_HEIGHT_ITEMS)
        QTimer.singleShot(0, partial(self._layout_popup, shown, 0))

    def _popup_row_height(self, view) -> int:
        cap = max(1, MAX_POPUP_VISIBLE_HEIGHT_ITEMS)
        if self._qt_list_height >= cap * 12:
            return max(12, self._qt_list_height // cap)
        try:
            model = view.model()
            if model is not None and model.rowCount() > 0:
                hint = view.sizeHintForRow(0)
                if 12 <= hint <= 48:
                    return hint
        except (RuntimeError, AttributeError):
            pass
        return max(20, view.fontMetrics().height() + 2 * _ITEM_V_PAD)

    def _popup_list_height(self, view, display_rows: int) -> int:
        if display_rows <= 0:
            return max(12, view.fontMetrics().height() // 2)
        return self._popup_row_height(view) * display_rows

    def _popup_frame_pad(self, container) -> int:
        if container is None:
            return _POPUP_FRAME_PAD
        try:
            return max(_POPUP_FRAME_PAD, int(container.frameWidth()) * 2)
        except RuntimeError:
            return _POPUP_FRAME_PAD

    def _sync_popup_scrollbar(self, view, display_rows: int) -> None:
        try:
            unhidden = max(0, self._row_count() - len(self._hidden_rows))
            if unhidden > display_rows:
                view.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAsNeeded)
            else:
                view.setVerticalScrollBarPolicy(Qt.ScrollBarPolicy.ScrollBarAlwaysOff)
            current = view.currentIndex()
            if current.isValid() and not view.isRowHidden(current.row()):
                view.scrollTo(current, _ENSURE_VISIBLE)
            else:
                bar = view.verticalScrollBar()
                if bar is not None:
                    bar.setValue(0)
            self._suppress_popup_scrollers()
        except RuntimeError:
            pass

    def _search_bar_height(self) -> int:
        bar = self._search_bar
        if bar is None:
            return 0
        try:
            if not bar.isVisible():
                return 0
            return max(bar.sizeHint().height(), bar.height())
        except RuntimeError:
            return 0

    def _layout_popup(self, display_rows: int, attempt: int = 0) -> None:
        if not self._search_active:
            return
        view = self._combo.view()
        if view is None:
            return

        unhidden = max(0, self._row_count() - len(self._hidden_rows))
        cap = MAX_POPUP_VISIBLE_HEIGHT_ITEMS
        full_list_h = self._qt_list_height or self._popup_list_height(view, cap)

        if display_rows <= 0:
            list_h = max(12, view.fontMetrics().height() // 2)
            shown_cap = 1
        elif unhidden > cap or display_rows >= cap:
            list_h = full_list_h
            shown_cap = cap
        else:
            list_h = self._popup_list_height(view, display_rows)
            shown_cap = max(1, display_rows)

        try:
            self._combo.setMaxVisibleItems(shown_cap)
        except Exception:
            pass

        if list_h <= 0 and attempt < _POPUP_LAYOUT_MAX_ATTEMPTS:
            QTimer.singleShot(
                _POPUP_LAYOUT_RETRY_MS,
                partial(self._layout_popup, display_rows, attempt + 1),
            )
            return

        try:
            view.setMinimumHeight(0)
            view.setMaximumHeight(_QWIDGETSIZE_MAX)
            view.setMinimumHeight(list_h)
            view.setMaximumHeight(list_h)
        except RuntimeError:
            return

        container = self._popup_container()
        width = self._combo.width() or (container.width() if container is not None else 0)
        height = self._search_bar_height() + list_h + self._popup_frame_pad(container)
        self._set_popup_height(width, height)
        self._sync_popup_scrollbar(view, shown_cap if display_rows else 0)
        self._pin_popup(width, height)
        QTimer.singleShot(0, partial(self._pin_popup, width, height))

    def _update_search_status(
        self, match_count: int, visible_count: int, needle: str, total: int
    ) -> None:
        if self._search_edit is None:
            return
        if needle:
            if match_count == 0:
                tip = self._combo.tr("No matches")
            elif match_count > visible_count:
                tip = self._combo.tr("Showing {0} of {1} matches - keep typing...").format(
                    visible_count, match_count
                )
            else:
                tip = self._combo.tr("{0} matches").format(match_count)
        elif total > MAX_POPUP_VISIBLE_ROWS:
            tip = self._combo.tr("Type to filter ({0} of {1} shown)").format(
                MAX_POPUP_VISIBLE_ROWS, total
            )
        else:
            tip = self._combo.tr("Type to filter...")
        self._search_edit.setPlaceholderText(tip)
        # Don't put the placeholder on the tooltip — it pops up over list
        # rows while typing/clearing (looks like a stuck filter).
        if needle:
            self._search_edit.setToolTip(tip)
        else:
            self._search_edit.setToolTip('')

    def _forward_navigation(self, event: QKeyEvent) -> None:
        view = self._combo.view()
        if view is None:
            return
        QApplication.sendEvent(view, event)

    def _activate_highlighted(self) -> None:
        view = self._combo.view()
        if view is None:
            self._combo.hidePopup()
            return
        idx = view.currentIndex()
        if idx.isValid() and not view.isRowHidden(idx.row()):
            self._combo.setCurrentIndex(idx.row())
        self._combo.hidePopup()

    def eventFilter(self, obj, event):  # noqa: N802 - Qt API
        etype = event.type()
        show_to_parent = getattr(QEvent.Type, 'ShowToParent', None)
        if etype == QEvent.Type.Show or (show_to_parent is not None and etype == show_to_parent):
            if obj is not self._search_edit and obj is not self._search_bar:
                try:
                    parent = obj.parent()
                except RuntimeError:
                    parent = None
                if parent is not None and parent is self._popup_container():
                    if obj is not self._combo.view():
                        try:
                            obj.hide()
                        except RuntimeError:
                            pass
                        return True
        if self.process_event(obj, event):
            return True
        return super().eventFilter(obj, event)


class GwAsyncComboBox(QComboBox):
    """Non-editable combobox that loads its items asynchronously and lets the
    user type-to-filter inside the popup.

    UX
        - The widget is **not editable**: clicking on it just opens the popup,
          the user can never type into the combo's display itself.
        - When the popup opens, a small `QLineEdit` is overlaid at the top of
          the popup container. It receives focus immediately so the user can
          start typing right away to narrow the visible items.
        - Up/Down/PageUp/PageDown navigate the visible (non-hidden) rows in
          the popup view. Enter activates the highlighted row. Escape closes
          the popup without changing the selection.
        - Filtering is done by hiding rows in the popup view (`setRowHidden`)
          so the underlying model is never modified — every other API
          (`combo.count()`, `combo.itemData(i)`,
          `tools_qt.get_combo_value`/`set_combo_value`) keeps seeing the full
          list, regardless of the filter.
        - After open/filter, the popup is resized to the painted row span
          (not Qt's default `maxVisibleItems` height). Set
          ``popup_opens_upward = True`` on status-bar combos that open above
          the widget.

    Lifecycle
        1. Widget is constructed and immediately shows a single placeholder
           row so `tools_qt.get_combo_value(...)` returns `''` while loading.
        2. `start_loading(query)` schedules a `GwComboLoaderTask`. The widget
           bumps an internal *token* so older tasks are ignored if multiple
           loads are queued (e.g. parent combo changed).
        3. When the task finishes, `_on_rows_loaded` swaps the model contents
           in O(1) and re-applies any pending selection.

    Markers
        - ``_gw_is_async_combo``: True; used by external helpers to detect
          an async combo without importing this module.
        - ``rows_loaded`` Qt property: False while loading, True afterwards.
    """

    popup_opens_upward = False

    def __init__(self, parent=None):
        super().__init__(parent)
        self._gw_is_async_combo = True
        self._token = 0
        self._task: Optional[GwComboLoaderTask] = None
        self._pending_selected_id: Optional[str] = None
        self._pending_select_index: int = 0
        self._is_null_value: bool = False
        self._loading: bool = False

        self.setProperty('rows_loaded', False)
        self.setFocusPolicy(Qt.FocusPolicy.StrongFocus)
        self.setEditable(False)
        self.setInsertPolicy(QComboBox.InsertPolicy.NoInsert)
        # On GTK+ / macOS / KDE Breeze, `SH_ComboBox_Popup` is true by
        # default which makes Qt show a native popup that ignores
        # `maxVisibleItems`. The proxy style flips that single hint so the
        # cap is honored everywhere.
        #
        # Skip on Windows: the Windows/Vista style already returns false
        # for `SH_ComboBox_Popup`, so the proxy is unnecessary there — and
        # avoiding it dodges any QStyle ownership / lifetime weirdness on
        # platforms where it isn't needed in the first place.
        #
        # We also must hand `QProxyStyle` a fresh `QStyleFactory.create(...)`
        # instance — passing `self.style()` would let the proxy reparent
        # (and later free) the application style, which crashes any
        # subsequent `style()` lookup (e.g. `QMenuPrivate::init`).
        _style_closed_combo(self)
        self.setMaxVisibleItems(MAX_POPUP_VISIBLE_HEIGHT_ITEMS)

        # Use a custom QAbstractListModel; this is the whole point of the
        # widget — populating 15k+ rows must be a constant-cost operation.
        self._list_model = _ComboListModel(self)
        self.setModel(self._list_model)

        # Custom view with a configurable top margin so the search edit gets
        # its own reserved space at the top of the popup.
        self._popup_view = _ComboPopupView(self)
        self.setView(self._popup_view)

        self._popup_search = _ComboPopupSearchController(
            self,
            label_at=self._popup_row_label,
            row_count=lambda: self._list_model.rowCount(),
            index_at=lambda i: self._list_model.index(i, 0),
        )

        self._show_placeholder('')

    def _popup_row_label(self, row: int) -> str:
        rows = self._list_model.get_rows()
        if row < 0 or row >= len(rows):
            return ''
        return rows[row][1]

    # region Wheel event (match CustomQComboBox)
    def wheelEvent(self, event):  # noqa: N802 - Qt API
        if self.hasFocus():
            return QComboBox.wheelEvent(self, event)
        return None
    # endregion

    # region Write API overrides
    # Our custom QAbstractListModel is read-only by design (faster bulk
    # population). Forward the few mutating QComboBox calls callers might use
    # to the underlying list so things like `tools_qt.set_combo_value`'s
    # fall-back `addItem(...)` keep working on async combos.
    def addItem(self, *args, **kwargs):  # noqa: N802 - Qt API
        text, user_data = self._extract_text_and_data(args, kwargs)
        row_id, row_idval = self._row_from_user_data(text, user_data)
        self._list_model.append_row((row_id, row_idval))

    def insertItem(self, *_args, **_kwargs):  # noqa: N802 - Qt API
        # Treat as append; we don't support arbitrary insertion points.
        text, user_data = self._extract_text_and_data(_args[1:], _kwargs)
        row_id, row_idval = self._row_from_user_data(text, user_data)
        self._list_model.append_row((row_id, row_idval))

    def clear(self):
        self._list_model.set_rows([])

    @staticmethod
    def _extract_text_and_data(args, kwargs):
        text = ''
        user_data = None
        if args:
            text = args[0]
            if len(args) > 1:
                user_data = args[1]
        if 'text' in kwargs:
            text = kwargs['text']
        if 'userData' in kwargs:
            user_data = kwargs['userData']
        return text, user_data

    @staticmethod
    def _row_from_user_data(text, user_data) -> _ComboRow:
        if isinstance(user_data, (list, tuple)) and len(user_data) >= 2:
            return ('' if user_data[0] is None else str(user_data[0]),
                    '' if user_data[1] is None else str(user_data[1]))
        # Fall back to using `text` as the visible label only.
        return ('' if user_data is None else str(user_data), '' if text is None else str(text))

    def itemData(self, index: int, role: int = Qt.ItemDataRole.UserRole):  # noqa: N802 - Qt API
        """Expose ``UserRole`` row payload for ``tools_qt.get_combo_value``."""
        if index < 0:
            return None
        model_index = self._list_model.index(index, 0)
        if not model_index.isValid():
            return None
        data = self._list_model.data(model_index, role)
        if data is not None:
            return data
        return super().itemData(index, role)
    # endregion

    # region Public API used by tools_gw / tools_qt
    def set_null_value_enabled(self, is_null: bool) -> None:
        """Toggle whether an empty placeholder row is prepended to the data."""
        self._is_null_value = bool(is_null)

    def set_pending_selection(self, value, index: int = 0) -> None:
        """Defer selection until the items finish loading.

        Called by `tools_qt.set_combo_value` (via duck typing) when the combo
        hasn't been populated yet. The value is reapplied in `apply_rows`.
        """
        self._pending_selected_id = None if value in (None, '') else str(value)
        self._pending_select_index = int(index) if index is not None else 0
        if self.property('rows_loaded'):
            # If rows are already there, apply immediately.
            self._apply_pending_selection()

    def has_loaded_rows(self) -> bool:
        return bool(self.property('rows_loaded'))

    def start_loading(self, query: str) -> None:
        """Begin (or restart) loading the combo's items in the background."""
        if not query:
            # Child combo waiting for a parent value, or an intentional no-op.
            # Keep the placeholder; do not mark rows as loaded with an empty model
            # (count 0 blocks the popup and breaks child combos in info forms).
            self._show_placeholder('')
            self.setProperty('rows_loaded', False)
            self._loading = False
            return

        # Bump token: older tasks finishing later will be ignored.
        self._token += 1
        token = self._token

        cached_rows = get_combo_rows_cached(query)
        if cached_rows is not None:
            self._loading = False
            self._task = None
            self.apply_rows(cached_rows)
            return

        self._loading = True
        self.setProperty('rows_loaded', False)
        self._show_placeholder(self.tr('Loading...'))

        # Try to cancel the previous task if it is still running.
        if self._task is not None:
            try:
                self._task.cancel()
            except Exception:
                pass
            self._task = None

        description = f"GwAsyncComboBox load {self.objectName() or '(no name)'}"
        task = GwComboLoaderTask(description, query, token)
        task.rows_loaded.connect(self._on_rows_loaded)
        self._task = task
        QgsApplication.taskManager().addTask(task)

    def apply_rows(self, rows: Sequence) -> None:
        """Replace the combo contents with `rows` and restore selection.

        Implementation note: we never iterate `addItem` for thousands of rows.
        We build a Python list of tuples (cheap, ~1ms per 10k rows) and hand
        it to the custom model in a single `set_rows` call. The model emits
        a single `modelReset`, so the QComboBox refreshes once.
        """
        items: List[_ComboRow] = []
        if self._is_null_value:
            items.append(('', ''))
        for row in rows or []:
            row_id = '' if row[0] is None else str(row[0])
            idval = row[1] if len(row) > 1 and row[1] is not None else row_id
            items.append((row_id, str(idval)))

        # New row set invalidates any hidden-rows bookkeeping from a
        # previous model state.
        self._popup_search.clear_filter_state()

        # Block signals across the model swap + selection so external
        # handlers don't fire intermediate `currentIndexChanged` events
        # while the combo is rebuilding.
        self.blockSignals(True)
        try:
            self._list_model.set_rows(items)
            self._apply_pending_selection()
            # Plain QComboBox selects index 0 after addItem(); model reset leaves
            # currentIndex at -1 unless we restore it explicitly.
            if (
                self.currentIndex() < 0
                and self.count() > 0
                and self._pending_selected_id is None
            ):
                self.setCurrentIndex(0)
        finally:
            self.blockSignals(False)

        self.setProperty('rows_loaded', True)
        self._loading = False

        # Single coalesced signal so child combo loaders / `get_values` /
        # widgetfunctions can react to the final state.
        try:
            self.currentIndexChanged.emit(self.currentIndex())
        except Exception:
            pass
    # endregion

    # region Popup with type-to-filter
    def showPopup(self):  # noqa: N802 - Qt API
        self._popup_search._restore_hidden_rows()
        try:
            self.setMaxVisibleItems(MAX_POPUP_VISIBLE_HEIGHT_ITEMS)
        except Exception:
            pass
        super().showPopup()
        self._popup_search.install_overlay()

    def hidePopup(self):  # noqa: N802 - Qt API
        self._popup_search.teardown_overlay()
        super().hidePopup()
    # endregion

    # region Internals
    def _show_placeholder(self, text: str) -> None:
        # Single placeholder row with empty `id` so get_combo_value() returns
        # '' while the combo is loading. The displayed `idval` carries the
        # placeholder text (e.g. `Loading...`).
        self._list_model.set_rows([('', text)])

    def _on_rows_loaded(self, token: int, rows: list, error: str) -> None:
        if token != self._token:
            # Stale task result - ignore.
            return
        self._task = None
        if error:
            # Show a single, clearly disabled-looking row. We don't disable
            # the widget so the user can still type/retry via parent combo.
            self.blockSignals(True)
            try:
                self._list_model.set_rows([('', self.tr('Error loading values'))])
                self.setProperty('rows_loaded', True)
                self._loading = False
            finally:
                self.blockSignals(False)
            try:
                self.currentIndexChanged.emit(self.currentIndex())
            except Exception:
                pass
            return
        self.apply_rows(rows)

    def _apply_pending_selection(self) -> None:
        if self._pending_selected_id is None:
            return
        target = str(self._pending_selected_id)
        idx = self._pending_select_index or 0
        # Iterate the Python list directly — much cheaper than calling
        # itemData(i) once per row through Qt for 10k+ entries.
        rows = self._list_model.get_rows()
        for i, item in enumerate(rows):
            try:
                value = item[idx]
            except (IndexError, KeyError, TypeError):
                continue
            if str(value) == target:
                self.setCurrentIndex(i)
                self._pending_selected_id = None
                return
        # Value not found in the loaded rows: leave selection unchanged.
        # We keep _pending_selected_id so a later reload (e.g. parent combo
        # changed) can pick it up.
    # endregion


def attach_combo_popup_search(combo: QComboBox) -> None:
    """Add type-to-filter popup search to a plain ``QComboBox`` in-place."""
    if combo is None:
        return
    if getattr(combo, '_gw_is_async_combo', False):
        return
    if getattr(combo, '_gw_popup_search', None) is not None:
        return

    controller = _ComboPopupSearchController(
        combo,
        label_at=combo.itemText,
        row_count=combo.count,
    )
    _style_closed_combo(combo)
    controller.attach_to_plain_combo()
    combo._gw_popup_search = controller
    combo.setProperty('_gw_popup_search', True)
