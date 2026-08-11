"""
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

String catalogue for ``scripts/i18n_searcher.py``.

This module is intentionally not imported by runtime code. It only holds
``message = "..."`` assignments so the extractor can pick up user-facing
strings that live outside normal Python call sites (e.g. SQL/UI fragments).
Do not add logic here.
"""
message = "File name"
message = "Function name"
message = "Detail"
message = "Context"
message = "Message error"
message = "Key"
message = "Key container"
message = "Python file"
message = "Python function"
message = "There have been errors translating:"
message = "Database translation canceled."
message = "Database translation failed."
message = "Database translation successful to"
message = "Do you want to copy its values to the current node?"
message = "Selected snapped feature_id to copy values from"
message = "Clicking an item will check/uncheck it. "
message = "Checking any item will not uncheck any other item."
message = "Checking any item will uncheck all other items unless Shift is pressed."
message = "Checking any item will uncheck all other items."
message = "This behaviour can be configured in the table 'config_param_system' (parameter = 'basic_selector"
message = "Pipes with invalid arccat_ids: {0}."
message = "Invalid arccat_ids: {0}."
message = "Do you want to proceed?"
message = ("An arccat_id is considered invalid if it is not listed in the catalog configuration table. "
            "As a result, these pipes will NOT be assigned a priority value.")
message = "Pipes with invalid diameters: {0}."
message = "Invalid diameters: {1}."
message = ("A diameter value is considered invalid if it is zero, negative, NULL "
            "or greater than the maximum diameter in the configuration table. "
            "As a result, these pipes will NOT be assigned a priority value.")
message = "A material is considered invalid if it is not listed in the material configuration table."
message = ("As a result, the material of these pipes will be treated "
            "as the configured unknown material, {0}.")
message = ("These pipes will NOT be assigned a priority value "
            "as the configured unknown material, {1}, "
            "is not listed in the configuration tab for materials.")
message = "Pipes with invalid materials: {2}."
message = "Invalid materials: {3}."
message = "Field child_layer of id: "
message = "is not defined in table cat_feature"
message = "widgettype not found. "
message = "layoutorder not found."
message = "widgetname not found. "
message = "widgettype is wrongly configured. Needs to be in "
message = "Information about exception"
message = "Error type"
message = "Line number"
message = "Description"
message = "Schema name"
message = "SQL"
message = "SQL File"
message = "Python translation successful"
message = "Python translation failed"
message = "Python translation canceled"
message = "translation successful"
message = "translation failed in table"
message = "translation canceled"
message = ('Interpolate tool.\n'
        'To modify columns (top_elev, ymax, elev among others) to be interpolated set variable '
        'edit_node_interpolate on table config_param_user')
message = "Inp Options"
message = "IMPORT INP"
message = ("This wizard will help with the process of importing a network from a {0} INP "
            "file into the Giswater database.")
message = "There are multple tabs in order to configure all the necessary catalogs."
message = ("The first tab is the 'Basic' tab, where you can select the exploitation, sector, "
            "municipality, and other basic information.")
message = ("The second tab is the 'Features' tab, where you can select the corresponding feature "
            "classes for each type of feature on the network.")
message = ("Here you can choose how the pumps and valves will be imported, either left as arcs "
            "(virual arcs) or converted to nodes.")
message = ("The third tab is the 'Materials' tab, where you can select the corresponding material "
            "for each roughness value.")
message = ("Here you can choose how the pumps, weirs, orifices, and outlets will be imported, either "
            "left as arcs (virual arcs) or converted to flwreg.")
message = ("The third tab is the 'Materials' tab, where you can select the corresponding roughness value "
            "for each material.")
message = ("The fourth tab is the 'Nodes' tab, where you can select the catalog for each type of node "
            "on the network.")
message = ("The fifth tab is the 'Arcs' tab, where you can select the catalog for each type of arc "
            "on the network.")
message = ("If you chose to import the flow regulators as flwreg objects, the sixth tab is where you "
            "can select the catalog for each flow regulator (pumps, weirs, orifices, outlets) on the network.")
message = "If not, you can ignore the tab."
message = ("Once you have configured all the necessary catalogs, you can click on the 'Accept' button to "
            "start the import process.")
message = "It will then show the log of the process in the last tab."
message = ("You can save the current configuration to a file and load it later, or load the last saved "
            "configuration.")
message = "If you have any questions, please contact the Giswater team via"
message = "GitHub Issues"
message = "or"
message = "our website"
message = "Export INP finished. "
message = "Error near line"
message = "EPA model finished. "
message = "Import RPT file finished."
message = "Are you sure you want to delete these records:"
message = "This will also delete the database user(s):"
message = "PostgreSQL version"
message = "PostGis version"
message = "PgRouting version"
message = "Version"
message = "Schema name"
message = "Language"
message = "Date of creation"
message = "Date of last update"
message = "Creation type"
message = "In schema"
message = "Dscenario manager"
message = "Hydrology scenario manager"
message = "DWF scenario manager"
message = "Psector could not be updated because of the following errors: "
message = "KEEP OPERATIVE"
message = "DOWNGRADE NODE"
message = "REMOVE NODE"
message = "Connec to network"
message = "Gully to network"