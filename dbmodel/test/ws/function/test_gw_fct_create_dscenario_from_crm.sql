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

SELECT plan(5);

-- Create roles for testing
CREATE USER plan_user;
GRANT role_plan to plan_user;

CREATE USER epa_user;
GRANT role_epa to epa_user;

CREATE USER edit_user;
GRANT role_edit to edit_user;

CREATE USER om_user;
GRANT role_om to om_user;

CREATE USER basic_user;
GRANT role_basic to basic_user;

-- Extract and test the "status" field from the function's JSON response
SELECT is(
    (gw_fct_create_dscenario_from_crm($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":25831}, "form":{},
    "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"name":"dscenario1", "descript":null, "exploitation":"0",
    "period":"5", "pattern":"1", "demandUnits":"LPS", "patternOrDate":"1", "initDate":"2002-01-01", "endDate":"2025-12-12"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_create_dscenario_from_crm with exploitation 0 returns status "Accepted"'
);

SELECT is(
    (gw_fct_create_dscenario_from_crm($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":25831}, "form":{},
    "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"name":"dscenario2", "descript":null, "exploitation":"1",
    "period":"5", "pattern":"1", "demandUnits":"LPS", "patternOrDate":"1", "initDate":"2002-01-01", "endDate":"2025-12-12"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_create_dscenario_from_crm with exploitation 1 returns status "Accepted"'
);

SELECT is(
    (gw_fct_create_dscenario_from_crm($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":25831}, "form":{},
    "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"name":"dscenario3", "descript":null, "exploitation":"2",
    "period":"5", "pattern":"1", "demandUnits":"LPS", "patternOrDate":"2", "initDate":"2002-01-01", "endDate":"2025-12-12"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_create_dscenario_from_crm with exploitation 2 returns status "Accepted"'
);

-- DATE_INTERVAL must log the date range, not the PERIOD combo value (#989)
SELECT like(
    (SELECT log FROM cat_dscenario WHERE name = 'dscenario3'),
    '%"Source CRM Date Interval":"01/01/2002-12/12/2025"%',
    'DATE_INTERVAL stores Source CRM Date Interval in cat_dscenario.log'
);

SELECT ok(
    EXISTS (
        SELECT 1 FROM audit_check_data
        WHERE cur_user = current_user AND fid = 403
        AND error_message ILIKE '%Copy from CRM date interval: 01/01/2002-12/12/2025%'
    ),
    'DATE_INTERVAL Info Log uses message 4760 with the selected dates'
);

-- Finish the test
SELECT finish();

ROLLBACK;
