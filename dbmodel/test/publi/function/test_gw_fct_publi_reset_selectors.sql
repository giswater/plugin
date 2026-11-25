/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

BEGIN;

SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT * FROM no_plan();

-- ===========================
-- PREPARE DATA: minimal source schema with selectors
-- ===========================
CREATE SCHEMA publi_tsel;
CREATE TABLE publi_tsel.exploitation (expl_id integer PRIMARY KEY, name text);
CREATE TABLE publi_tsel.value_state (id integer PRIMARY KEY, name text);
CREATE TABLE publi_tsel.selector_expl (expl_id integer REFERENCES publi_tsel.exploitation, cur_user text, PRIMARY KEY (expl_id, cur_user));
CREATE TABLE publi_tsel.selector_state (state_id integer REFERENCES publi_tsel.value_state, cur_user text, PRIMARY KEY (state_id, cur_user));
CREATE TABLE publi_tsel.selector_psector (psector_id integer, cur_user text, PRIMARY KEY (psector_id, cur_user));
CREATE TABLE publi_tsel.arc (arc_id integer PRIMARY KEY, expl_id integer, state integer);

INSERT INTO publi_tsel.exploitation VALUES (1, 'one'), (2, 'two'), (3, 'three');
INSERT INTO publi_tsel.value_state VALUES (0, 'Obsolete'), (1, 'On service'), (2, 'Planified');
INSERT INTO publi_tsel.selector_expl VALUES (1, current_user), (2, 'someone_else');
INSERT INTO publi_tsel.selector_psector VALUES (7, current_user);
INSERT INTO publi_tsel.arc VALUES (1, 1, 1), (2, NULL, 1), (3, NULL, 0);

CREATE TEMP TABLE tst_res AS
SELECT publi.gw_fct_publi_reset_selectors('{"data":{"sourceSchema":"publi_tsel"}}') AS res;

SELECT is((SELECT res ->> 'status' FROM tst_res), 'Accepted', 'status Accepted');
SELECT set_eq($$SELECT expl_id FROM publi_tsel.selector_expl WHERE cur_user = current_user$$, ARRAY[1, 2, 3],
    'selector_expl: every exploitation for current_user');
SELECT is((SELECT count(*)::int FROM publi_tsel.selector_expl WHERE cur_user = 'someone_else'), 1,
    'selector_expl: other users untouched');
SELECT set_eq($$SELECT state_id FROM publi_tsel.selector_state WHERE cur_user = current_user$$, ARRAY[0, 1, 2],
    'selector_state: every state when none given');
SELECT is((SELECT count(*)::int FROM publi_tsel.selector_psector WHERE cur_user = current_user), 0,
    'selector_psector: emptied, never all');
SELECT is((SELECT (res -> 'body' -> 'data' -> 'nullKeys' ->> 'arc')::int FROM tst_res), 1,
    'nullKeys: operative arc with NULL expl_id reported');

DELETE FROM tst_res;
INSERT INTO tst_res SELECT publi.gw_fct_publi_reset_selectors('{"data":{"sourceSchema":"publi_tsel","states":[1],"psectors":[7]}}');
SELECT set_eq($$SELECT state_id FROM publi_tsel.selector_state WHERE cur_user = current_user$$, ARRAY[1],
    'selector_state: explicit list respected');
SELECT set_eq($$SELECT psector_id FROM publi_tsel.selector_psector WHERE cur_user = current_user$$, ARRAY[7],
    'selector_psector: explicit list respected');

SELECT is((publi.gw_fct_publi_reset_selectors('{"data":{"sourceSchema":"publi_missing"}}')) ->> 'status', 'Failed',
    'missing source schema returns Failed');

SELECT * FROM finish();

ROLLBACK;
