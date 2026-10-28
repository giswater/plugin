/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

BEGIN;

-- Suppress NOTICE messages
SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT * FROM no_plan();

SELECT hasnt_table('om_scada_graph_json'::name, 'Table om_scada_graph_json should have been dropped');
SELECT hasnt_table('_om_scada_graph_json_'::name, 'Leftover _om_scada_graph_json_ should have been dropped');
SELECT hasnt_function('gw_fct_scada_graph_export'::name, 'Function gw_fct_scada_graph_export should have been dropped');

SELECT * FROM finish();

ROLLBACK;
