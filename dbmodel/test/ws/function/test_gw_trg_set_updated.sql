/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

SET client_min_messages TO WARNING;
SET search_path = "SCHEMA_NAME", public, pg_catalog;

SELECT plan(16);

INSERT INTO config_param_user (parameter, value, cur_user)
VALUES ('edit_disable_editcontrols', 'true', current_user)
ON CONFLICT (parameter, cur_user) DO UPDATE SET value = 'true';

SELECT has_function('gw_trg_set_updated'::name, 'Function gw_trg_set_updated should exist');

SELECT has_trigger('arc', 'gw_trg_set_updated', 'Table arc should have gw_trg_set_updated');
SELECT has_trigger('node', 'gw_trg_set_updated', 'Table node should have gw_trg_set_updated');
SELECT has_trigger('connec', 'gw_trg_set_updated', 'Table connec should have gw_trg_set_updated');
SELECT has_trigger('link', 'gw_trg_set_updated', 'Table link should have gw_trg_set_updated');
SELECT has_trigger('element', 'gw_trg_set_updated', 'Table element should have gw_trg_set_updated');
SELECT has_trigger('dma', 'gw_trg_set_updated', 'Table dma should have gw_trg_set_updated');
SELECT has_trigger('sector', 'gw_trg_set_updated', 'Table sector should have gw_trg_set_updated');

UPDATE arc SET updated_at = '2000-01-01', updated_by = 'nobody' WHERE arc_id = (SELECT min(arc_id) FROM arc);
SELECT ok((SELECT updated_at FROM arc WHERE arc_id = (SELECT min(arc_id) FROM arc)) > now() - interval '1 minute',
	'UPDATE arc stamps updated_at even when SET to a stale value');
SELECT is((SELECT updated_by::text FROM arc WHERE arc_id = (SELECT min(arc_id) FROM arc)), current_user::text,
	'UPDATE arc stamps updated_by');

UPDATE node SET updated_at = '2000-01-01', updated_by = 'nobody' WHERE node_id = (SELECT min(node_id) FROM node);
SELECT ok((SELECT updated_at FROM node WHERE node_id = (SELECT min(node_id) FROM node)) > now() - interval '1 minute',
	'UPDATE node stamps updated_at');
SELECT is((SELECT updated_by::text FROM node WHERE node_id = (SELECT min(node_id) FROM node)), current_user::text,
	'UPDATE node stamps updated_by');

UPDATE link SET updated_at = '2000-01-01', updated_by = 'nobody' WHERE link_id = (SELECT min(link_id) FROM link);
SELECT ok((SELECT updated_at FROM link WHERE link_id = (SELECT min(link_id) FROM link)) > now() - interval '1 minute',
	'UPDATE link stamps updated_at without requiring the_geom change');
SELECT is((SELECT updated_by::text FROM link WHERE link_id = (SELECT min(link_id) FROM link)), current_user::text,
	'UPDATE link stamps updated_by');

UPDATE element SET updated_at = '2000-01-01', updated_by = 'nobody' WHERE element_id = (SELECT min(element_id) FROM element);
SELECT ok((SELECT updated_at FROM element WHERE element_id = (SELECT min(element_id) FROM element)) > now() - interval '1 minute',
	'UPDATE element stamps updated_at');
SELECT is((SELECT updated_by::text FROM element WHERE element_id = (SELECT min(element_id) FROM element)), current_user::text,
	'UPDATE element stamps updated_by');

SELECT * FROM finish();
ROLLBACK;
