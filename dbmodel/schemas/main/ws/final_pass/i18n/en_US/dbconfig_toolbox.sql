/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = SCHEMA_NAME, public, pg_catalog;
UPDATE config_toolbox AS t SET alias = v.alias, observ = v.observ FROM (
	VALUES
	(2102, 'Check arcs without node start/end', NULL),
    (2104, 'Check arcs with same start/end node', NULL),
    (2106, 'Check connecs duplicated', NULL),
    (2108, 'Check nodes duplicated', NULL),
    (2110, 'Check nodes orphan', NULL),
    (2118, 'Build nodes using arcs start & end vertices', NULL),
    (2436, 'Check plan data', NULL),
    (2670, 'Check data for o&m process', NULL),
    (2760, 'Get values from raster DEM', NULL),
    (2772, 'Flow trace analytics', NULL),
    (2776, 'Check backend configuration', NULL),
    (2826, 'Linear Reference System', NULL),
    (2890, 'Reconstruction cost & amortization values', NULL),
    (2922, 'Reset user profile', NULL),
    (2998, 'User check data', NULL),
    (3008, 'Arc reverse', NULL),
    (3040, 'Check arcs duplicated', NULL),
    (3042, 'Manage Dscenario values', NULL),
    (3052, 'Arcs shorter/bigger than specific length', NULL),
    (3080, 'Repair nodes duplicated (one by one)', NULL),
    (3130, 'Topocontrol for data migration', NULL),
    (3134, 'Create empty Dscenario', NULL),
    (3156, 'Duplicate dscenario', NULL),
    (3172, 'Check nodes T candidates', NULL),
    (3198, 'Get address values from closest street number', NULL),
    (3280, 'Massive node rotation update', NULL),
    (3284, 'Merge two or more psectors into one', NULL),
    (3336, 'Macrominsector analysis', NULL),
    (3426, 'Integrate campaign into production', NULL),
    (3482, 'Macromapzones analysis', NULL),
    (2302, 'Check node topological consistency', NULL),
    (2430, 'Check data according to EPA rules', NULL),
    (2496, 'Reconnect arcs with closest nodes', NULL),
    (2706, 'Minsector analysis', NULL),
    (2768, 'Análisis de Mapzones', NULL),
    (2790, 'Check data for graphanalytics process', NULL),
    (2970, 'Config mapzones', NULL),
    (3108, 'Create Network Dscenario from ToC', NULL),
    (3110, 'Create Demand Dscenario from CRM', NULL),
    (3112, 'Create Demand Dscenario from ToC', NULL),
    (3142, 'Water balance by Exploitation and Period', NULL),
    (3158, 'Create valve dscenario from mincut', NULL),
    (3160, 'Calculate the reach of hydrants', 'Function requires street data inserted on table om_streetaxis, where each street is divided into short lines between intersections.'),
    (3236, 'Show current mincuts', NULL),
    (3256, 'Mapzones Netscenario analysis', NULL),
    (3258, 'Set pattern values on demand dscenario', NULL),
    (3260, 'Create empty Netscenario', NULL),
    (3262, 'Create Netscenario from ToC', NULL),
    (3264, 'Duplicate Netscenario', NULL),
    (3268, 'Set initlevel values from executed simulation', NULL),
    (3308, 'Create full Network dscenario', NULL),
    (3322, 'Set cost for removed material on psectors', NULL)
) AS v(id, alias, observ)
WHERE t.id = v.id;