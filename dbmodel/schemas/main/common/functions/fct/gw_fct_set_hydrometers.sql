/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3520

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_set_hydrometers(p_data json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$

/*EXAMPLE

-- Single hydrometer INSERT
SELECT SCHEMA_NAME.gw_fct_set_hydrometers($${"client":{"device":5, "infoType":1, "lang":"ES"},
"data":{"action":"INSERT", "hydrometers":[
    {"code":"H001", "hydro_number":"12345", "feature_id":3001, "link":"http://link.com",
     "state_id":1, "catalog_id":1, "category_id":1, "priority_id":1, "exploitation":1,
     "start_date":"2025-10-30", "end_date":null, "update_date":"2025-10-30", "shutdown_date":null}
]}}$$);

-- Multiple hydrometers INSERT
SELECT SCHEMA_NAME.gw_fct_set_hydrometers($${"client":{"device":5, "infoType":1, "lang":"ES"},
"data":{"action":"INSERT", "hydrometers":[
    {"code":"H001", "hydro_number":"12345", "feature_id":3001, "state_id":1, "catalog_id":1, "category_id":1, "priority_id":1, "exploitation":1},
    {"code":"H002", "hydro_number":"12346", "feature_id":3002, "state_id":1, "catalog_id":1, "category_id":1, "priority_id":1, "exploitation":1}
]}}$$);

-- Single hydrometer UPDATE
SELECT SCHEMA_NAME.gw_fct_set_hydrometers($${"client":{"device":5, "infoType":1, "lang":"ES"},
"data":{"action":"UPDATE", "hydrometers":[
    {"code":"H001", "hydro_number":"12345-UPDATED", "state_id":2}
]}}$$);

-- Multiple hydrometers UPDATE
SELECT SCHEMA_NAME.gw_fct_set_hydrometers($${"client":{"device":5, "infoType":1, "lang":"ES"},
"data":{"action":"UPDATE", "hydrometers":[
    {"code":"H001", "state_id":2},
    {"code":"H002", "state_id":1}
]}}$$);

-- Single hydrometer DELETE
SELECT SCHEMA_NAME.gw_fct_set_hydrometers($${"client":{"device":5, "infoType":1, "lang":"ES"},
"data":{"action":"DELETE", "hydrometers":[
    {"code":"H001"}
]}}$$);

-- Multiple hydrometers DELETE
SELECT SCHEMA_NAME.gw_fct_set_hydrometers($${"client":{"device":5, "infoType":1, "lang":"ES"},
"data":{"action":"DELETE", "hydrometers":[
    {"code":"H001"},
    {"code":"H002"}
]}}$$);

-- REPLACE all hydrometers (delete all existing, insert new ones)
SELECT SCHEMA_NAME.gw_fct_set_hydrometers($${"client":{"device":5, "infoType":1, "lang":"ES"},
"data":{"action":"REPLACE", "hydrometers":[
    {"code":"H001", "hydro_number":"12345", "feature_id":3001, "state_id":1, "catalog_id":1, "category_id":1, "priority_id":1, "exploitation":1},
    {"code":"H002", "hydro_number":"12346", "feature_id":3002, "state_id":1, "catalog_id":1, "category_id":1, "priority_id":1, "exploitation":1}
]}}$$);

*/

DECLARE

v_version text;
v_project_type text;
v_action text;
v_hydrometers jsonb;
v_hydrometer jsonb;
v_count integer := 0;
v_inserted integer := 0;
v_updated integer := 0;
v_deleted integer := 0;
v_error_context text;
v_query text;
v_id integer;
v_code text;
v_hydro_number text;
v_link text;
v_state_id integer;
v_catalog_id integer;
v_category_id integer;
v_priority_id integer;
v_exploitation integer;
v_start_date date;
v_end_date date;
v_update_date date;
v_shutdown_date date;
v_exists boolean;
v_customer_code text;

BEGIN

	-- Set search path
	SET search_path = "SCHEMA_NAME", public;

	-- Get system parameters
	SELECT giswater, project_type INTO v_version, v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- Get input parameters
	v_action = (p_data->>'data')::json->>'action';
	v_hydrometers = (p_data->>'data')::json->>'hydrometers';

	-- Validate action
	IF v_action NOT IN ('INSERT', 'UPDATE', 'DELETE', 'REPLACE') THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"4448", "function":"3520","parameters":{"action":"'||v_action||'"}}}$$);';
	END IF;

	-- Validate hydrometers array
	IF v_hydrometers IS NULL OR jsonb_array_length(v_hydrometers) = 0 THEN
		EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"4450", "function":"3520","parameters":{}}}$$);';
	END IF;

	-- REPLACE action: delete all existing hydrometers first
	IF v_action = 'REPLACE' THEN
		-- Count before deleting
		SELECT count(*) INTO v_deleted FROM v_hydrometer;
		IF (SELECT value::boolean FROM config_param_system WHERE parameter = 'admin_cibs_schema') IS TRUE THEN
			TRUNCATE cibs.hydrometer CASCADE;
		ELSE
			TRUNCATE ext_hydrometer CASCADE;
		END IF;
	END IF;

	-- Process each hydrometer in the array
	FOR v_hydrometer IN SELECT * FROM jsonb_array_elements(v_hydrometers)
	LOOP
		v_count := v_count + 1;

		-- Extract fields from JSON
		v_code := v_hydrometer->>'code';
		v_hydro_number := v_hydrometer->>'hydro_number';
		v_customer_code := (v_hydrometer->>'feature_customer_code');
		v_link := v_hydrometer->>'link';
		v_state_id := (v_hydrometer->>'state_id')::integer;
		v_catalog_id := (v_hydrometer->>'catalog_id')::integer;
		v_category_id := (v_hydrometer->>'category_id')::integer;
		v_priority_id := (v_hydrometer->>'priority_id')::integer;
		v_exploitation := (v_hydrometer->>'exploitation')::integer;

		-- Handle dates
		BEGIN
			v_start_date := (v_hydrometer->>'start_date')::date;
		EXCEPTION WHEN OTHERS THEN
			v_start_date := NULL;
		END;

		BEGIN
			v_end_date := (v_hydrometer->>'end_date')::date;
		EXCEPTION WHEN OTHERS THEN
			v_end_date := NULL;
		END;

		BEGIN
			v_update_date := (v_hydrometer->>'update_date')::date;
		EXCEPTION WHEN OTHERS THEN
			v_update_date := NULL;
		END;

		BEGIN
			v_shutdown_date := (v_hydrometer->>'shutdown_date')::date;
		EXCEPTION WHEN OTHERS THEN
			v_shutdown_date := NULL;
		END;

		-- Validate required fields for INSERT and REPLACE
		IF v_action IN ('INSERT', 'REPLACE') THEN
			IF v_code IS NULL THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"4452", "function":"3520","parameters":{"hydrometer":"'||v_count||'"}}}$$);';
			END IF;
		END IF;

		-- Process based on action
		IF v_action = 'DELETE' THEN
			-- Delete hydrometer
			IF v_code IS NOT NULL THEN
				-- Check if exists first
				SELECT EXISTS(SELECT 1 FROM v_hydrometer WHERE code = v_code) INTO v_exists;

				IF v_exists THEN
					DELETE FROM v_hydrometer WHERE code = v_code;
					v_deleted := v_deleted + 1;
				END IF;
			END IF;

		ELSIF v_action IN ('INSERT', 'REPLACE') THEN
			-- Insert into v_hydrometer
			INSERT INTO v_hydrometer (
				code,
				hydro_number,
				state_id,
				catalog_id,
				category_id,
				priority_id,
				expl_id,
				start_date,
				end_date,
				update_date,
				shutdown_date,
				link,
				feature_customer_code
			) VALUES (
				v_code,
				v_hydro_number,
				v_state_id,
				v_catalog_id,
				v_category_id,
				v_priority_id,
				v_exploitation,
				v_start_date,
				v_end_date,
				v_update_date,
				v_shutdown_date,
				v_link,
				v_customer_code
			) RETURNING hydrometer_id INTO v_id;

			v_inserted := v_inserted + 1;

		ELSIF v_action = 'UPDATE' THEN
			-- Check if hydrometer exists
			SELECT EXISTS(SELECT 1 FROM v_hydrometer WHERE code = v_code) INTO v_exists;

			IF NOT v_exists THEN
				EXECUTE 'SELECT gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},"data":{"message":"4454", "function":"3520","parameters":{"code":"'||v_code||'"}}}$$);';
				CONTINUE;
			END IF;

			-- Build dynamic UPDATE query
			v_query := 'UPDATE v_hydrometer SET ';

			-- Add fields to update (only non-null fields)
			IF v_hydro_number IS NOT NULL THEN
				v_query := concat(v_query, 'hydro_number = ', quote_nullable(v_hydro_number), ', ');
			END IF;

			IF v_state_id IS NOT NULL THEN
				v_query := concat(v_query, 'state_id = ', v_state_id, ', ');
			END IF;

			IF v_catalog_id IS NOT NULL THEN
				v_query := concat(v_query, 'catalog_id = ', v_catalog_id, ', ');
			END IF;

			IF v_category_id IS NOT NULL THEN
				v_query := concat(v_query, 'category_id = ', v_category_id, ', ');
			END IF;

			IF v_priority_id IS NOT NULL THEN
				v_query := concat(v_query, 'priority_id = ', v_priority_id, ', ');
			END IF;

			IF v_exploitation IS NOT NULL THEN
				v_query := concat(v_query, 'expl_id = ', v_exploitation, ', ');
			END IF;

			IF v_start_date IS NOT NULL THEN
				v_query := concat(v_query, 'start_date = ', quote_nullable(v_start_date::text), '::date, ');
			END IF;

			IF v_end_date IS NOT NULL THEN
				v_query := concat(v_query, 'end_date = ', quote_nullable(v_end_date::text), '::date, ');
			END IF;

			IF v_update_date IS NOT NULL THEN
				v_query := concat(v_query, 'update_date = ', quote_nullable(v_update_date::text), '::date, ');
			END IF;

			IF v_shutdown_date IS NOT NULL THEN
				v_query := concat(v_query, 'shutdown_date = ', quote_nullable(v_shutdown_date::text), '::date, ');
			END IF;

			IF v_customer_code IS NOT NULL THEN
				v_query := concat(v_query, 'feature_customer_code = ', v_customer_code, ', ');
			END IF;

			-- Remove trailing comma and space
			v_query := rtrim(v_query, ', ');

			-- Add WHERE clause
			v_query := concat(v_query, ' WHERE code = ', quote_literal(v_code), ' RETURNING hydrometer_id');

			-- Execute update if there are fields to update
			IF v_query NOT LIKE '%SET WHERE%' THEN
				EXECUTE v_query INTO v_id;
				IF FOUND THEN
					v_updated := v_updated + 1;
				END IF;
			END IF;

			-- Update link if provided
			IF v_link IS NOT NULL THEN
				UPDATE v_hydrometer SET link = v_link WHERE code = v_code;
				IF NOT FOUND THEN
					INSERT INTO v_hydrometer (code, link) VALUES (v_code, v_link);
				END IF;
			END IF;
		END IF;

	END LOOP;

	-- Build result message
	v_query := concat('Processed ', v_count, ' hydrometers. ');
	IF v_inserted > 0 THEN
		v_query := concat(v_query, 'Inserted: ', v_inserted, '. ');
	END IF;
	IF v_updated > 0 THEN
		v_query := concat(v_query, 'Updated: ', v_updated, '. ');
	END IF;
	IF v_deleted > 0 THEN
		v_query := concat(v_query, 'Deleted: ', v_deleted, '.');
	END IF;

	-- Return
	RETURN ('{"status":"Accepted", "message":{"level":1, "text":"'||v_query||'"}, "version":"'||v_version||'"'||
			',"body":{"form":{}'||
			',"feature":{}'||
			',"data":{"processed":'||v_count||', "inserted":'||v_inserted||', "updated":'||v_updated||', "deleted":'||v_deleted||'}}'||'}')::json;

EXCEPTION WHEN OTHERS THEN
	GET STACKED DIAGNOSTICS v_error_context = PG_EXCEPTION_CONTEXT;
	RETURN (
		'{"status":"Failed", "message":{"level":3, "text":"'||
		REPLACE(REPLACE(REPLACE(SQLERRM,'\','\\'),'"','\"'), E'\n', '\n') ||
		'"}, "version":"' || v_version || '"'||
		',"body":{"form":{},"feature":{},"data":' || json_build_object('error', v_error_context) || '}}'
	)::json;
END;
$function$
;

