"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
import configparser
import json
import os
import sys
from functools import partial
from importlib.metadata import PackageNotFoundError, version as pkg_version

from qgis.PyQt.QtCore import QObject, QSysInfo, Qt, QUrl
from qgis.PyQt.QtGui import QDesktopServices, QFont, QPixmap
from qgis.PyQt.QtWidgets import QApplication, QLabel, QSizePolicy
from qgis.PyQt.sip import isdeleted
from qgis.core import Qgis

from ..ui.ui_manager import GwAboutUi
from ..utils import tools_gw
from ...libs import lib_vars, tools_db, tools_qgis, tools_qt


_RELEASES_URL = "https://github.com/giswater/plugin/releases"
_TAG_URL = "https://github.com/giswater/plugin/releases/tag/v{0}"
_PLUGIN_COMMIT_URL = "https://github.com/giswater/plugin/commit/{0}"
_LIBS_COMMIT_URL = "https://github.com/giswater/libs/commit/{0}"
_HOME_URL = "https://www.giswater.org"
_ISSUES_URL = "https://github.com/giswater/plugin/issues"

# PyPI names shown on the About page. Add a package here to show its version.
_PYTHON_PACKAGES = (
    "wntr",
    "numpy",
    "matplotlib",
    "shapely",
    "pyproj",
    "osmnx",
    "PyPDF2",
    "swmm-api",
)


class GwAbout(QObject):
    """About dialog: diagnostics, members and license."""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.dlg = None
        self._release_cache = None

    def open(self):
        dlg = self.dlg
        if dlg is not None and not isdeleted(dlg) and dlg.isVisible():
            tools_gw.focus_open_dialog(dlg)
            return

        dlg = GwAboutUi(self)
        self.dlg = dlg
        tools_gw.load_settings(dlg)

        icon_path = os.path.join(
            lib_vars.plugin_dir, "resources", "templates", "qgiscomposer", "logo.png"
        )
        if os.path.exists(icon_path):
            pixmap = QPixmap(icon_path)
            dlg.lbl_icon.setPixmap(pixmap.scaledToHeight(
                64, Qt.TransformationMode.SmoothTransformation
            ))

        self._translate_sidebar(dlg)
        self._fill_info(dlg)
        self._fill_whatsnew(dlg)
        self._fill_names(dlg.lyt_members, self._metadata_names("member"), 3)
        self._fill_translations(dlg)
        self._fill_names(dlg.lyt_acknowledgments, self._readme_list("Acknowledgments"), 2)
        dlg.txt_license.setPlainText(self._license_text())

        dlg.btn_copy.clicked.connect(self._copy_text)
        dlg.btn_homepage.clicked.connect(partial(QDesktopServices.openUrl, QUrl(_HOME_URL)))
        dlg.btn_issue.clicked.connect(partial(QDesktopServices.openUrl, QUrl(_ISSUES_URL)))
        dlg.cmb_version.currentIndexChanged.connect(partial(self._show_release, dlg))
        dlg.btn_release.clicked.connect(partial(self._open_release, dlg))
        dlg.txt_whatsnew.anchorClicked.connect(QDesktopServices.openUrl)
        dlg.txt_whatsnew.document().setDocumentMargin(12)
        dlg.txt_license.document().setDocumentMargin(12)
        dlg.btn_close.clicked.connect(dlg.reject)
        dlg.rejected.connect(partial(tools_gw.close_dialog, dlg))
        dlg.lst_menu.setCurrentRow(0)

        title = "About Giswater"
        tools_gw.open_dialog(dlg, dlg_name='about', title=title, skip_db_check=True)
        btn_help = tools_qt.get_widget(dlg, 'btn_help')
        if btn_help is not None:
            btn_help.hide()
        flags = dlg.windowFlags() & ~Qt.WindowType.WindowMaximizeButtonHint
        dlg.setWindowFlags(flags)
        dlg.setWindowModality(Qt.WindowModality.NonModal)
        dlg.setModal(False)
        dlg.show()

    def _translate_sidebar(self, dlg):
        """QListWidget items are not covered by _translate_form."""

        title = "About"
        dlg.lst_menu.item(0).setText(tools_qt.tr(title))
        title = "What's New"
        dlg.lst_menu.item(1).setText(tools_qt.tr(title))
        title = "Members"
        dlg.lst_menu.item(2).setText(tools_qt.tr(title))
        title = "Translations"
        dlg.lst_menu.item(3).setText(tools_qt.tr(title))
        title = "Acknowledgments"
        dlg.lst_menu.item(4).setText(tools_qt.tr(title))
        title = "License"
        dlg.lst_menu.item(5).setText(tools_qt.tr(title))

    def _copy_text(self):
        """Copy the diagnostics to the clipboard, to paste into a bug report."""

        QApplication.clipboard().setText(self._rows_as_text())
        msg = "Copied to clipboard"
        tools_qgis.show_success(msg)

    def _rows_as_text(self):
        """Serialize About rows: label[TAB]value, or label-only headers."""

        lines = []
        for _key, label, value, _url in self._info_rows():
            if value:
                lines.append(f"{label}\t{value}")
            elif label:
                lines.append(label)
        return "\n".join(lines)

    def _fill_info(self, dlg):
        """Two equal columns of label and value, one row per diagnostic."""

        lyt = dlg.lyt_info
        lyt.setColumnStretch(0, 1)
        lyt.setColumnStretch(1, 1)
        row = 0
        for _key, label, value, url in self._info_rows():
            if value is None:
                lyt.addWidget(self._info_label(label, header=True), row, 0, 1, 2)
            else:
                lyt.addWidget(self._info_label(label), row, 0)
                lyt.addWidget(self._info_label(value, url=url), row, 1)
            row += 1
        lyt.setRowStretch(row, 1)

    def _info_label(self, text, header=False, url=None):
        """Selectable label of a diagnostic row. Styled, not fonted, so that
        normalize_dialog_fonts does not drop the bold of the section headers.
        """

        label = QLabel()
        label.setWordWrap(True)
        if url:
            label.setText('<a href="{0}">{1}</a>'.format(url, text))
            label.setOpenExternalLinks(True)
            label.setTextInteractionFlags(Qt.TextInteractionFlag.TextBrowserInteraction)
        else:
            label.setText(text)
            label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse)
        if header:
            label.setStyleSheet("font-weight: bold; margin-top: 8px;")
        return label

    def _fill_translations(self, dlg):
        """Flag, name and % from config/translations.json. No .ts scan.

        Percents are written into that file by another workflow. Dialog
        open never hits the network or i18n/.
        """

        lyt = dlg.lyt_translations
        lyt.setColumnStretch(0, 0)
        lyt.setColumnStretch(1, 1)
        lyt.setColumnStretch(2, 0)
        rows = self._translation_catalog()
        if not rows:
            msg = "N/A"
            lyt.addWidget(self._info_label(tools_qt.tr(msg)), 0, 0, 1, 3)
            lyt.setRowStretch(1, 1)
            return
        msg = "Language"
        lyt.addWidget(self._info_label(tools_qt.tr(msg), header=True), 0, 0, 1, 2)
        msg = "Finished %"
        percent_header = self._info_label(tools_qt.tr(msg), header=True)
        percent_header.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        lyt.addWidget(percent_header, 0, 2)
        for row, entry in enumerate(rows, start=1):
            lyt.addWidget(self._flag_label(entry.get("flag") or ""), row, 0)
            lyt.addWidget(self._info_label(entry.get("name") or entry.get("locale") or ""), row, 1)
            lyt.addWidget(self._percent_label(entry.get("percent")), row, 2)
        lyt.setRowStretch(len(rows) + 1, 1)

    def _translation_catalog(self):
        try:
            data = json.loads(self._read_plugin_file(os.path.join("config", "translations.json")))
        except ValueError:
            return []
        if not isinstance(data, list):
            return []
        rows = [entry for entry in data if isinstance(entry, dict)]
        rows.sort(key=lambda entry: (-self._percent_rank(entry), (entry.get("name") or "").lower()))
        return rows

    def _percent_rank(self, entry):
        value = entry.get("percent")
        if value is None or value == "":
            return -1
        try:
            return int(round(float(value)))
        except (TypeError, ValueError):
            return -1

    def _flag_label(self, code):
        """ISO2 PNG from icons/flags, else a regional-indicator emoji."""

        label = QLabel()
        label.setFixedWidth(28)
        label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        code = (code or "").strip()
        iso = code.upper() if len(code) == 2 and code.isalpha() else ""
        png = os.path.join(lib_vars.plugin_dir, "icons", "flags", "{0}.png".format(iso.lower())) if iso else ""
        if png and os.path.exists(png):
            pixmap = QPixmap(png)
            label.setPixmap(pixmap.scaledToHeight(16, Qt.TransformationMode.SmoothTransformation))
            return label
        if iso:
            label.setFont(QFont("Segoe UI Emoji", 12))
            label.setText("".join(chr(0x1F1E6 + ord(char) - 65) for char in iso))
        else:
            label.setText(code)
        return label

    def _percent_label(self, value):
        if value is None or value == "":
            return self._info_label("—")
        try:
            percent = round(float(value), 2)
        except (TypeError, ValueError):
            return self._info_label("—")
        msg = "{0}%"
        label = self._info_label(tools_qt.tr(msg, list_params=("{0:.2f}".format(percent),)))
        label.setAlignment(Qt.AlignmentFlag.AlignRight | Qt.AlignmentFlag.AlignVCenter)
        label.setSizePolicy(QSizePolicy.Policy.Maximum, QSizePolicy.Policy.Preferred)
        if percent >= 99:
            color = "#3c8c40"
        elif percent >= 80:
            color = "#6b8e23"
        else:
            color = "#888888"
        label.setStyleSheet(
            "background-color: {0}; color: #ffffff; border-radius: 3px; "
            "padding: 1px 8px; font-weight: bold;".format(color)
        )
        return label

    def _fill_whatsnew(self, dlg):
        """One release per combo entry, notes of the selected one below.

        As in QgsAbout::setWhatsNew the notes come from a file shipped with
        the plugin, never from the network. CHANGELOG.md is the same source
        prepare_release.py publishes as the GitHub release body, and Qt
        renders its markdown as is.
        """

        dlg.cmb_version.clear()
        for release in self._releases():
            dlg.cmb_version.addItem("{0}  -  {1}".format(release[0], release[1]))
        dlg.cmb_version.setCurrentIndex(0)
        self._show_release(dlg)

    def _show_release(self, dlg, _index=None):
        """Render the notes of the release selected in the combo."""

        release = self._current_release(dlg)
        body = release[2] if release else None
        if not body:
            msg = "The notes of this release are published on GitHub."
            body = tools_qt.tr(msg)
        if hasattr(dlg.txt_whatsnew, "setMarkdown"):
            dlg.txt_whatsnew.setMarkdown(body)
        else:
            dlg.txt_whatsnew.setPlainText(body)

    def _open_release(self, dlg):
        """Open the GitHub page of the selected release."""

        release = self._current_release(dlg)
        QDesktopServices.openUrl(QUrl(release[3] if release else _RELEASES_URL))

    def _current_release(self, dlg):
        """Release selected in the combo, whose order matches _releases()."""

        releases = self._releases()
        index = dlg.cmb_version.currentIndex()
        if 0 <= index < len(releases):
            return releases[index]
        return None

    def _releases(self):
        """[(version, date, markdown body or None, url)] newest first.

        Two sources, because CHANGELOG.md only goes back to 4.5.0: its
        sections carry the notes, and config/releases.json lists the older
        releases, which are shown as a link to GitHub. That index is frozen,
        every new release is written to CHANGELOG.md by prepare_release.py.
        """

        if self._release_cache is not None:
            return self._release_cache

        self._release_cache = self._changelog_releases() + self._indexed_releases()
        self._release_cache.sort(key=lambda release: release[1], reverse=True)
        return self._release_cache

    def _changelog_releases(self):
        """Released sections of CHANGELOG.md, notes included.

        A section with no date is [Unreleased]: no tag on GitHub, and not
        what anybody is running.
        """

        headings = []
        for line in self._read_plugin_file("CHANGELOG.md").splitlines():
            if line.startswith("## "):
                headings.append((line[3:].strip(), []))
            elif line.startswith("[") and "]: " in line:
                continue  # link definitions of the compare block, not content
            elif headings:
                headings[-1][1].append(line)

        releases = []
        for heading, body in headings:
            version, _sep, date = heading.partition(" - ")
            if not date.strip():
                continue
            version = version.strip().strip("[]")
            releases.append((
                "v{0}".format(version),  # shown as a tag, like the indexed ones
                date.strip(),
                "\n".join(body).strip(),
                _TAG_URL.format(version),
            ))
        return releases

    def _indexed_releases(self):
        """Releases older than CHANGELOG.md, from config/releases.json."""

        try:
            index = json.loads(self._read_plugin_file(os.path.join("config", "releases.json")))
        except ValueError:
            return []
        return [
            (entry["tag"], entry.get("date", ""), entry.get("notes"), entry["url"])
            for entry in index
            if entry.get("tag") and entry.get("url")
        ]

    def _info_rows(self):
        """(key, translated label, value, url). value=None is a section header."""

        msg = "N/A"
        na = tools_qt.tr(msg)
        msg = "Not installed"
        missing = tools_qt.tr(msg)

        plugin_dir = lib_vars.plugin_dir
        libs_dir = os.path.join(plugin_dir, "libs") if plugin_dir else None
        plugin_version, _ = tools_qgis.get_plugin_version()
        project_open = bool(lib_vars.schema_name and tools_db.dao is not None)
        db_open = tools_db.dao is not None

        rows = []
        msg = "Giswater version"
        rows.append(("plugin", tools_qt.tr(msg), plugin_version or na, None))
        msg = "QGIS version"
        rows.append(("qgis", tools_qt.tr(msg), f"{Qgis.QGIS_VERSION} ({Qgis.QGIS_RELEASE_NAME})", None))
        msg = "OS version"
        rows.append(("os", tools_qt.tr(msg), QSysInfo.prettyProductName(), None))

        plugin_sha = self._git_short_sha(plugin_dir)
        msg = "Giswater code revision"
        rows.append((
            "plugin_commit", tools_qt.tr(msg), plugin_sha or na,
            _PLUGIN_COMMIT_URL.format(plugin_sha) if plugin_sha else None,
        ))
        libs_sha = self._git_short_sha(libs_dir)
        msg = "Giswater (libs) code revision"
        rows.append((
            "libs_commit", tools_qt.tr(msg), libs_sha or na,
            _LIBS_COMMIT_URL.format(libs_sha) if libs_sha else None,
        ))

        msg = "Libraries"
        rows.append(("libraries", tools_qt.tr(msg), None, None))
        msg = "Python version"
        rows.append(("python", tools_qt.tr(msg), sys.version.split()[0], None))
        if project_open:
            schema_name = lib_vars.schema_name.replace('"', '')
            msg = "Schema version"
            rows.append(("schema", tools_qt.tr(msg), self._db_value(
                f"SELECT giswater FROM {schema_name}.sys_version ORDER BY id DESC LIMIT 1"
            ) or na, None))
        msg = "PostgreSQL version"
        rows.append(("postgresql", tools_qt.tr(msg),
                     (self._db_value("SHOW server_version") if db_open else None) or na, None))
        msg = "PostGIS version"
        rows.append(("postgis", tools_qt.tr(msg), (self._db_value(
            "SELECT extversion FROM pg_extension WHERE extname = 'postgis'"
        ) if db_open else None) or na, None))
        msg = "pgRouting version"
        rows.append(("pgrouting", tools_qt.tr(msg), (self._db_value(
            "SELECT extversion FROM pg_extension WHERE extname = 'pgrouting'"
        ) if db_open else None) or na, None))

        msg = "Python packages"
        rows.append(("packages", tools_qt.tr(msg), None, None))
        for dist_name in _PYTHON_PACKAGES:
            key = dist_name.lower().replace("-", "_")
            rows.append((key, dist_name, self._package_version(dist_name, missing), None))
        return rows

    def _git_short_sha(self, path):
        """12-char HEAD from .git on disk. Does not call git.exe.

        QGIS on Windows is usually started without Git on PATH, so
        ``git rev-parse`` (what the original About used) returns nothing
        even in a checkout. The files are still there.
        """

        git_dir = self._git_dir(path)
        if not git_dir:
            return None
        try:
            with open(os.path.join(git_dir, "HEAD"), encoding="utf-8") as handler:
                head = handler.read().strip()
        except OSError:
            return None
        if head.startswith("ref:"):
            ref = head.split(":", 1)[1].strip()
            sha = self._git_ref_sha(git_dir, ref)
        else:
            sha = head
        return sha[:12] if sha else None

    def _git_dir(self, path):
        """Resolved .git directory, including submodule gitdir files."""

        if not path:
            return None
        git_path = os.path.join(path, ".git")
        if os.path.isdir(git_path):
            return git_path
        if not os.path.isfile(git_path):
            return None
        try:
            with open(git_path, encoding="utf-8") as handler:
                line = handler.read().strip()
        except OSError:
            return None
        if not line.lower().startswith("gitdir:"):
            return None
        return os.path.normpath(os.path.join(path, line.split(":", 1)[1].strip()))

    def _git_ref_sha(self, git_dir, ref):
        ref_path = os.path.join(git_dir, *ref.split("/"))
        try:
            with open(ref_path, encoding="utf-8") as handler:
                return handler.read().strip()
        except OSError:
            pass
        packed = os.path.join(git_dir, "packed-refs")
        try:
            with open(packed, encoding="utf-8") as handler:
                for line in handler:
                    line = line.strip()
                    if not line or line.startswith("#") or line.startswith("^"):
                        continue
                    parts = line.split()
                    if len(parts) >= 2 and parts[1] == ref:
                        return parts[0]
        except OSError:
            return None
        return None

    def _package_version(self, dist_name, missing):
        try:
            return pkg_version(dist_name)
        except PackageNotFoundError:
            return missing

    def _db_value(self, sql):
        row = tools_db.get_row(sql, is_admin=True, log_info=False)
        if row and row[0] is not None:
            return str(row[0])
        return None

    def _read_plugin_metadata(self):
        parser = configparser.ConfigParser(comment_prefixes=";", allow_no_value=True, strict=False)
        parser.read(os.path.join(lib_vars.plugin_dir, "metadata.txt"), encoding="utf-8")
        return parser["general"] if parser.has_section("general") else {}

    def _read_plugin_file(self, filename):
        """Read a text file shipped with the plugin, relative to its root."""

        path = os.path.join(lib_vars.plugin_dir, filename)
        try:
            with open(path, encoding="utf-8") as handler:
                return handler.read()
        except OSError:
            return ""

    def _fill_names(self, layout, names, columns):
        """Lay names out in columns, filling column by column.

        Reading down a column keeps the source order visible, which matters
        because metadata.txt and README.md are ordered on purpose.
        """

        if not names:
            msg = "N/A"
            names = [tools_qt.tr(msg)]
        rows = -(-len(names) // columns)  # ceil, so the last column is the short one
        for position, name in enumerate(names):
            layout.addWidget(
                self._info_label(name), position % rows, position // rows
            )
        for column in range(columns):
            layout.setColumnStretch(column, 1)
        layout.setRowStretch(rows, 1)

    def _metadata_names(self, key):
        """Comma-separated names from a metadata.txt key, listed order kept."""

        value = self._read_plugin_metadata().get(key, "").strip()
        return [name.strip() for name in value.split(",") if name.strip()]

    def _readme_list(self, heading):
        """Bullet names under a ## heading in README.md."""

        text = self._read_plugin_file("README.md")
        if not text:
            return []
        marker = "## {0}".format(heading)
        start = text.find(marker)
        if start < 0:
            return []
        section = text[start + len(marker):]
        next_h = section.find("\n## ")
        if next_h >= 0:
            section = section[:next_h]
        names = []
        for line in section.splitlines():
            stripped = line.strip()
            if stripped.startswith("- "):
                names.append(stripped[2:].strip())
        return names

    def _license_text(self):
        """Full GPL-3 text from the LICENSE file shipped with the plugin."""

        text = self._read_plugin_file("LICENSE")
        if text:
            return text
        msg = "N/A"
        return tools_qt.tr(msg)
