/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:2886

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_fill_om_tables()
	RETURNS void AS
$BODY$

DECLARE
	v_now timestamp := left(date_trunc('second', now())::text, 19)::timestamp;

BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;

	--Delete previous
	DELETE FROM om_visit_event_photo CASCADE;
	DELETE FROM om_visit_event CASCADE;
	DELETE FROM om_visit CASCADE;
	DELETE FROM om_visit_x_arc;
	DELETE FROM om_visit_x_node;
	DELETE FROM om_visit_x_connec;
	DELETE FROM om_visit_x_link;
	DELETE FROM om_visit_x_gully;
	DELETE FROM om_visit_cat CASCADE;

	--Insert Catalog of visit
	INSERT INTO om_visit_cat (id, name, startdate, enddate, alias)
	VALUES(1, 'Test', now(), (now()+'1hour'::INTERVAL * ROUND(RANDOM() * 5)), 'Test');

	-- Bulk insert bypasses ve_visit_* INSTEAD OF triggers (row-by-row max(id) + information_schema)
	ALTER TABLE om_visit DISABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_arc DISABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_node DISABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_connec DISABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_link DISABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_gully DISABLE TRIGGER gw_trg_om_visit;

	-- ARC class 1: inspection
	WITH features AS (
		SELECT arc_id, expl_id, row_number() OVER (ORDER BY arc_id) AS rn
		FROM arc WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 1, 4, 1, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.arc_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_arc (visit_id, arc_id)
	SELECT visit_id, arc_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_arc xa ON xa.visit_id = v.id
		WHERE v.class_id = 1
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('sediments_arc', '2'),
		('defect_arc', '1'),
		('clean_arc', '1'),
		('insp_observ', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- ARC class 5: incident
	WITH features AS (
		SELECT arc_id, expl_id, row_number() OVER (ORDER BY arc_id) AS rn
		FROM arc WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 5, 4, 2, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.arc_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_arc (visit_id, arc_id)
	SELECT visit_id, arc_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_arc xa ON xa.visit_id = v.id
		WHERE v.class_id = 5
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('incident_type', '6'),
		('incident_comment', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- NODE class 2: inspection
	WITH features AS (
		SELECT node_id, expl_id, row_number() OVER (ORDER BY node_id) AS rn
		FROM node WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 2, 4, 1, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.node_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_node (visit_id, node_id)
	SELECT visit_id, node_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_node xn ON xn.visit_id = v.id
		WHERE v.class_id = 2
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('sediments_node', '2'),
		('defect_node', '1'),
		('clean_node', '1'),
		('insp_observ', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- NODE class 6: incident (20 random)
	WITH features AS (
		SELECT node_id, expl_id, row_number() OVER (ORDER BY node_id) AS rn
		FROM node WHERE state = 1
		ORDER BY random() LIMIT 20
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 6, 4, 2, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.node_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_node (visit_id, node_id)
	SELECT visit_id, node_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_node xn ON xn.visit_id = v.id
		WHERE v.class_id = 6
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('incident_type', '1'),
		('incident_comment', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- CONNEC class 3: inspection
	WITH features AS (
		SELECT connec_id, expl_id, row_number() OVER (ORDER BY connec_id) AS rn
		FROM connec WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 3, 4, 1, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.connec_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_connec (visit_id, connec_id)
	SELECT visit_id, connec_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_connec xc ON xc.visit_id = v.id
		WHERE v.class_id = 3
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('sediments_connec', '2'),
		('defect_connec', '1'),
		('clean_connec', '1'),
		('insp_observ', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- CONNEC class 7: incident
	WITH features AS (
		SELECT connec_id, expl_id, row_number() OVER (ORDER BY connec_id) AS rn
		FROM connec WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 7, 4, 2, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.connec_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_connec (visit_id, connec_id)
	SELECT visit_id, connec_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_connec xc ON xc.visit_id = v.id
		WHERE v.class_id = 7
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('incident_type', '6'),
		('incident_comment', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- GULLY class 4: inspection
	WITH features AS (
		SELECT gully_id, expl_id, row_number() OVER (ORDER BY gully_id) AS rn
		FROM gully WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 4, 4, 1, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.gully_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_gully (visit_id, gully_id)
	SELECT visit_id, gully_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_gully xg ON xg.visit_id = v.id
		WHERE v.class_id = 4
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('sediments_gully', '2'),
		('defect_gully', '1'),
		('clean_gully', '1'),
		('smells_gully', 'false'),
		('insp_observ', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- GULLY class 8: incident
	WITH features AS (
		SELECT gully_id, expl_id, row_number() OVER (ORDER BY gully_id) AS rn
		FROM gully WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 8, 4, 2, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.gully_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_gully (visit_id, gully_id)
	SELECT visit_id, gully_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_gully xg ON xg.visit_id = v.id
		WHERE v.class_id = 8
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('incident_type', '7'),
		('incident_comment', 'Urgent cleaning'),
		('photo', 'false')
	) AS p(param, val);

	-- LINK class 9: inspection
	WITH features AS (
		SELECT link_id, expl_id, row_number() OVER (ORDER BY link_id) AS rn
		FROM link WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 9, 4, 1, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.link_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_link (visit_id, link_id)
	SELECT visit_id, link_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_link xl ON xl.visit_id = v.id
		WHERE v.class_id = 9
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('sediments_link', '2'),
		('defect_link', '1'),
		('clean_link', '1'),
		('insp_observ', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	-- LINK class 10: incident
	WITH features AS (
		SELECT link_id, expl_id, row_number() OVER (ORDER BY link_id) AS rn
		FROM link WHERE state = 1
	),
	visits AS (
		INSERT INTO om_visit (visitcat_id, startdate, enddate, user_name, expl_id, class_id, status, visit_type, publish)
		SELECT 1, v_now, v_now, 'postgres', expl_id, 10, 4, 2, true FROM features ORDER BY rn
		RETURNING id
	),
	visit_map AS (
		SELECT v.id AS visit_id, f.link_id
		FROM (SELECT id, row_number() OVER (ORDER BY id) AS rn FROM visits) v
		JOIN features f USING (rn)
	)
	INSERT INTO om_visit_x_link (visit_id, link_id)
	SELECT visit_id, link_id FROM visit_map;

	WITH visit_map AS (
		SELECT v.id AS visit_id
		FROM om_visit v
		JOIN om_visit_x_link xl ON xl.visit_id = v.id
		WHERE v.class_id = 10
	)
	INSERT INTO om_visit_event (visit_id, parameter_id, value)
	SELECT visit_id, param, val
	FROM visit_map
	CROSS JOIN (VALUES
		('incident_type', '6'),
		('incident_comment', 'No other problems'),
		('photo', 'false')
	) AS p(param, val);

	ALTER TABLE om_visit ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_arc ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_node ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_connec ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_link ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_gully ENABLE TRIGGER gw_trg_om_visit;

	RETURN;

EXCEPTION WHEN OTHERS THEN
	ALTER TABLE om_visit ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_arc ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_node ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_connec ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_link ENABLE TRIGGER gw_trg_om_visit;
	ALTER TABLE om_visit_x_gully ENABLE TRIGGER gw_trg_om_visit;
	RAISE;

END;$BODY$
	LANGUAGE plpgsql VOLATILE
	COST 100;
