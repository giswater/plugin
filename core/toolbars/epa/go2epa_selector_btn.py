"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
"""
# -*- coding: utf-8 -*-
from ..dialog import GwAction
from ...ui.ui_manager import GwGo2EpaSelectorUi
from ...utils import tools_gw
from .... import global_vars
from ....libs import tools_qt, tools_db, tools_qgis, tools_os


class GwGo2EpaSelectorButton(GwAction):
    """ Button 44: Go2epa selector """

    def __init__(self, icon_path, action_name, text, toolbar, action_group):

        super().__init__(icon_path, action_name, text, toolbar, action_group)
        self.project_type = global_vars.project_type

    def clicked_event(self):
        """ Button 44: Epa result selector """

        self._open_dialog()

    def _open_dialog(self):
        """ Open Epa Selector Dialog dynamic """

        user = tools_db.current_user
        form = {"formName": "generic", "formType": "epa_selector"}
        body = {"client": {"cur_user": user}, "form": form}

        json_result = tools_gw.execute_procedure('gw_fct_get_epa_selector', body)

        self.dlg_go2epa_result = GwGo2EpaSelectorUi(self, 'go2epa')
        tools_gw.load_settings(self.dlg_go2epa_result)
        tools_gw.manage_dlg_widgets(self, self.dlg_go2epa_result, json_result)
        tools_gw.open_dialog(self.dlg_go2epa_result, 'go2epa_result')


def set_combo_values(**kwargs):
    """ Update values of combo childs """

    dialog = kwargs["dialog"]
    combo_childs = kwargs["func_params"]["cmbListToChange"]

    form = _get_form_with_combos(dialog)
    user = tools_db.current_user
    feature = {"childs": combo_childs}

    body = {"client": {"cur_user": user}, "form": form, "feature": feature}

    # db fct
    combo_list = tools_gw.execute_procedure('gw_fct_get_epa_selector', body)["body"]

    for combo_name, combo in combo_list.items():
        combo_widget = tools_qt.get_widget(dialog, f"tab_time_{combo_name}")
        combo_items = None if not combo["values"] else [(item, item) for item in combo["values"]]
        tools_qt.fill_combo_values(combo_widget, combo_items)
        tools_qt.set_combo_value(combo_widget, combo["selectedValue"], 0)


def accept(**kwargs):
    """ Update current values to the table """

    dialog = kwargs["dialog"]

    # Get form
    form = _get_form_with_combos(dialog)

    user = tools_db.current_user
    body = {"client": {"cur_user": user}, "form": form}

    # db fct
    tools_gw.execute_procedure('gw_fct_set_epa_selector', body)

    tools_qgis.set_cursor_wait()
    try:
        _load_result_layers()
        if form.get('tab_result_result_name_compare') and form.get('tab_result_result_name_compare') != '':
            _load_compare_layers()
    except Exception:
        pass
    tools_qgis.restore_cursor()

    # Force a map refresh
    tools_qgis.force_refresh_map_canvas()

    # Show message to user
    msg = "Values has been updated"
    tools_qgis.show_info(msg)
    tools_gw.close_dialog(dialog)


def close_dlg(**kwargs):
    """ Close form """

    dialog = kwargs["dialog"]
    tools_gw.close_dialog(dialog)


# region private functions

def _get_form_with_combos(dialog):
    """ Get combo values of tab result """

    form = {}
    form["tab_result_result_name_show"] = tools_qt.get_combo_value(dialog, "tab_result_result_name_show", 1)
    form["tab_result_result_name_compare"] = tools_qt.get_combo_value(dialog, "tab_result_result_name_compare", 1)

    # check project type
    project_type = tools_gw.get_project_type()
    if project_type == "ud":
        form["tab_time_selector_date"] = tools_qt.get_combo_value(dialog, "tab_time_selector_date", 1)
        form["tab_time_selector_time"] = tools_qt.get_combo_value(dialog, "tab_time_selector_time", 1)
        form["tab_time_compare_date"] = tools_qt.get_combo_value(dialog, "tab_time_compare_date", 1)
        form["tab_time_compare_time"] = tools_qt.get_combo_value(dialog, "tab_time_compare_time", 1)
    elif project_type == "ws":
        form["tab_time_time_show"] = tools_qt.get_combo_value(dialog, "tab_time_time_show", 1)
        form["tab_time_time_compare"] = tools_qt.get_combo_value(dialog, "tab_time_time_compare", 1)

    return form


def _load_result_layers():
    """Adds any missing EPA Results layers to TOC."""

    if not tools_os.set_boolean(tools_gw.get_config_parser('btn_go2epa_selector', 'load_result_layers', "user", "init"), default=False):
        return

    tools_gw.load_missing_layers_by_context("EPA", "RESULTS")


def _load_compare_layers():
    """Adds any missing EPA Compare layers to TOC."""

    if not tools_os.set_boolean(tools_gw.get_config_parser('btn_go2epa_selector', 'load_compare_layers', "user", "init"), default=False):
        return

    tools_gw.load_missing_layers_by_context("EPA", "COMPARE")

# end region
