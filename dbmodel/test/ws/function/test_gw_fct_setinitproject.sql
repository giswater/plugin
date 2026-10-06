/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(2);

DELETE FROM selector_expl WHERE cur_user = current_user;

SELECT is(
    (gw_fct_setinitproject($${"client":{"device":4, "lang":"en_US", "infoType":1, "epsg":SRID_VALUE}, "form":{}, "feature":{}, "data":{}}$$))::json->>'status',
    'Accepted',
    'gw_fct_setinitproject --> empty selector_expl returns Accepted'
);

SELECT ok(
    EXISTS (SELECT 1 FROM cat_users WHERE id = current_user AND active IS TRUE),
    'gw_fct_setinitproject --> inserts current_user into cat_users'
);

SELECT finish();

ROLLBACK;
