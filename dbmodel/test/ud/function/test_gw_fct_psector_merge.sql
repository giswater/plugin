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

SELECT plan(4);

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
    (gw_fct_psector_merge($${"client":{"device":4, "lang":"nl_NL", "infoType":1, "epsg":25831}, 
    "form":{}, "feature":{}, "data":{"filterFields":{}, "pageInfo":{}, "parameters":{"psector_ids":"1009", 
    "new_psector_name":"test"}, "aux_params":null}}$$)::JSON)->>'status',
    'Accepted',
    'Check if gw_fct_psector_merge returns status "Accepted"'
);

-- Two compatible psectors, each with an other-price. The old SQL inserted `descript`
-- (column is `observ`) and kept the source psector_id, so the merge died or left
-- the prices on the old psectors.
SELECT lives_ok(
    $$INSERT INTO plan_psector (name, psector_type, expl_id, priority, status)
      SELECT 'gw_merge_a', psector_type, expl_id, priority, status FROM plan_psector WHERE psector_id = 1;
      INSERT INTO plan_psector (name, psector_type, expl_id, priority, status)
      SELECT 'gw_merge_b', psector_type, expl_id, priority, status FROM plan_psector WHERE psector_id = 1;
      INSERT INTO plan_psector_x_other (price_id, measurement, psector_id, observ)
      SELECT 'PROTECT_SERVICES', 10.00, psector_id, 'from a' FROM plan_psector WHERE name = 'gw_merge_a';
      INSERT INTO plan_psector_x_other (price_id, measurement, psector_id, observ)
      SELECT 'PROTECT_SERVICES', 5.50, psector_id, 'from b' FROM plan_psector WHERE name = 'gw_merge_b';
      INSERT INTO plan_psector_x_other (price_id, measurement, psector_id, observ)
      SELECT 'SECURITY_HEALTH', 2.00, psector_id, NULL FROM plan_psector WHERE name = 'gw_merge_b';$$,
    'fixture: two psectors with plan_psector_x_other'
);

SELECT is(
    (gw_fct_psector_merge(
        json_build_object(
            'client', json_build_object('device', 4, 'lang', 'nl_NL', 'infoType', 1, 'epsg', 25831),
            'form', '{}'::json,
            'feature', '{}'::json,
            'data', json_build_object(
                'filterFields', '{}'::json,
                'pageInfo', '{}'::json,
                'parameters', json_build_object(
                    'psector_ids', (
                        SELECT string_agg(psector_id::text, ',' ORDER BY name)
                        FROM plan_psector WHERE name IN ('gw_merge_a', 'gw_merge_b')
                    ),
                    'new_psector_name', 'gw_merged'
                )
            )
        )
    ))->>'status',
    'Accepted',
    'merge of psectors that have other prices returns Accepted'
);

SELECT is(
    (SELECT measurement FROM plan_psector_x_other o
     JOIN plan_psector p ON p.psector_id = o.psector_id
     WHERE p.name = 'gw_merged' AND o.price_id = 'PROTECT_SERVICES'),
    15.50::numeric(12,2),
    'shared other price is summed onto the new psector'
);

SELECT is(
    (SELECT count(*)::int FROM plan_psector_x_other o
     JOIN plan_psector p ON p.psector_id = o.psector_id
     WHERE p.name = 'gw_merged'),
    2,
    'both other prices land on the new psector'
);

-- Finish the test
SELECT finish();

ROLLBACK;
