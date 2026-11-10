/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2610

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_api_setfields(json);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setfields(p_data json)
  RETURNS json AS
$BODY$

/* example

-- FEATURE
SELECT SCHEMA_NAME.gw_fct_setfields($${
"client":{"device":4, "infoType":1, "lang":"ES"},
"form":{},
"feature":{"featureType":"node", "tableName":"ve_man_junction", "id":"1251521"},
"data":{"fields":{"macrosector_id": "1", "sector_id": "2",
"inventory": "False", "epa_type": "PUMP", "state": "1", "arc_id": "113854", "publish": "False", "verified": "TO REVIEW",
"expl_id": "1", "builtdate": "2018/11/29", "muni_id": "2", "workcat_id": "22", "buildercat_id": "builder1", "enddate": "2018/11/29",
"soilcat_id": "soil1", "ownercat_id": "owner1", "workcat_id_end": "22"}}}$$)

-- VISIT
SELECT SCHEMA_NAME.gw_fct_setfields('
 {"client":{"device":4, "infoType":1, "lang":"ES"},
 "feature":{"featureType":"arc", "tableName":"ve_visit_multievent_x_arc", "id":1135},
 "data":{"fields":{"class_id":6, "arc_id":"2001", "visitcat_id":1, "ext_code":"testcode", "sediments_arc":1000, "desperfectes_arc":1, "neteja_arc":3},
 "deviceTrace":{"xcoord":8597877, "ycoord":5346534, "compass":123}}}')

-- MAPZONES
SELECT gw_fct_setfields($${"client":{"device":4, "infoType":1, "lang":"ES","epsg":SRID_VALUE}, "form":{},
"feature":{"id":"1295", "tableName":"ve_node_valvula", "featureType":"node" }, "data":{"filterFields":{}, "pageInfo":{}, "fields":{"closed": "False"}, "afterInsert":"False"}}$$)

*/

DECLARE

v_device integer;
v_infotype integer;
v_tablename text;
v_id  character varying;
v_fields json;
v_columntype character varying;
v_querytext varchar;
v_idname varchar;
column_type_id character varying;
v_version text;
v_text text[];
text text;
i integer=1;
n integer=1;
v_field text;
v_value text;
v_return text;
v_schemaname text;
v_featuretype text;
v_jsonfield json;
v_fieldsreload text;
v_columnfromid json;
v_projecttype text;
v_closedstatus boolean;
v_message json;
v_afterinsert boolean;
v_addparam json;
v_idname_array text[];
v_id_array text[];
column_type_id_array text[];
idname text;
v_pkeyfield text;
v_keys_fields text;
v_exists boolean;
v_fktable text;
v_fkatt text;
v_fkhit boolean;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;
	v_schemaname = 'SCHEMA_NAME';

	--  get api version
	SELECT giswater INTO v_version FROM sys_version ORDER BY id DESC LIMIT 1;

        -- get project type
        v_projecttype = (SELECT project_type FROM sys_version ORDER BY id DESC LIMIT 1);

	-- fix diferent ways to say null on client
	p_data = REPLACE (p_data::text, '"NULL"', 'null');
	p_data = REPLACE (p_data::text, '"null"', 'null');
	p_data = REPLACE (p_data::text, '""', 'null');
	p_data = REPLACE (p_data::text, '''''', 'null');

	-- Get input parameters:
	v_device := (p_data ->> 'client')::json->> 'device';
	v_infotype := (p_data ->> 'client')::json->> 'infoType';
	v_featuretype := (p_data ->> 'feature')::json->> 'featureType';
	v_tablename := (p_data ->> 'feature')::json->> 'tableName';
	v_id := (p_data ->> 'feature')::json->> 'id';
	v_idname := (p_data ->> 'feature')::json->> 'idName';
	v_fields := ((p_data ->> 'data')::json->> 'fields')::json;
	v_fieldsreload := (p_data ->> 'data')::json->> 'reload';
	v_afterinsert := json_extract_path_text (p_data,'data','afterInsert')::text;

	select array_agg(row_to_json(a)) into v_text from json_each(v_fields)a;

	-- Get if view has composite primary key
	IF v_idname IS NULL THEN

		-- Manage primary key
		EXECUTE 'SELECT addparam FROM sys_table WHERE id = $1' INTO v_addparam USING v_tablename;
		IF v_addparam IS NOT NULL THEN
			v_idname_array := string_to_array((v_addparam::json->> 'pkey'), ', ');
		END IF;

		if v_idname_array is null THEN
			EXECUTE 'SELECT gw_fct_getpkeyfield('''||v_tablename||''');' INTO v_idname;
			v_idname_array := string_to_array(v_idname, ', ');
		end if;

		v_id_array := string_to_array(v_id, ', ');
		IF v_idname_array IS NOT NULL then
			if array_length(v_idname_array, 1) = 1 then
                v_idname = v_idname_array[1];
            end if;

			FOREACH idname IN ARRAY v_idname_array LOOP
				EXECUTE 'SELECT pg_catalog.format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
				    JOIN pg_class t on a.attrelid = t.oid
				    JOIN pg_namespace s on t.relnamespace = s.oid
				    WHERE a.attnum > 0
				    AND NOT a.attisdropped
				    AND a.attname = $3
				    AND t.relname = $2
				    AND s.nspname = $1
				    ORDER BY a.attnum'
			    USING v_schemaname, v_tablename, idname
			    INTO column_type_id;

				column_type_id_array[i] := column_type_id;
				i=i+1;
			END LOOP;
		END IF;
	END IF;

	--  Get id column, for tables is the key column
	IF v_idname ISNULL THEN
		EXECUTE 'SELECT a.attname FROM pg_index i JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey) WHERE  i.indrelid = $1::regclass AND i.indisprimary'
	        INTO v_idname
	        USING v_tablename;
    END IF;

	-- For views it suposse pk is the first column
	IF v_idname ISNULL THEN
		EXECUTE '
		SELECT a.attname FROM pg_attribute a   JOIN pg_class t on a.attrelid = t.oid  JOIN pg_namespace s on t.relnamespace = s.oid WHERE a.attnum > 0   AND NOT a.attisdropped
		AND t.relname = $1
		AND s.nspname = $2
		ORDER BY a.attnum LIMIT 1'
		INTO v_idname
		USING v_tablename, v_schemaname;
	END IF;

	--   Get id column type
	EXECUTE 'SELECT pg_catalog.format_type(a.atttypid, a.atttypmod) FROM pg_attribute a
	    JOIN pg_class t on a.attrelid = t.oid
	    JOIN pg_namespace s on t.relnamespace = s.oid
	    WHERE a.attnum > 0
	    AND NOT a.attisdropped
	    AND a.attname = $3
	    AND t.relname = $2
	    AND s.nspname = $1
	    ORDER BY a.attnum'
            USING v_schemaname, v_tablename, v_idname
            INTO column_type_id;

	v_querytext = 'SELECT EXISTS(SELECT 1 FROM ' || quote_ident(v_tablename) ||'';
	IF cardinality(v_idname_array) > 1 AND cardinality(v_id_array) > 1 THEN
		i = 1;
		v_querytext := v_querytext || ' WHERE ';
		FOREACH idname IN ARRAY v_idname_array LOOP
			v_querytext := v_querytext || quote_ident(idname) || ' = CAST(' || quote_literal(v_id_array[i]) || ' AS ' || column_type_id_array[i] || ') AND ';
			i=i+1;
		END LOOP;
		v_querytext = substring(v_querytext, 0, length(v_querytext)-4);
	ELSIF cardinality(v_idname_array) > 1 THEN
		i = 1;
		v_querytext := v_querytext || ' WHERE ';
		FOREACH idname IN ARRAY v_idname_array LOOP
			v_querytext := v_querytext || quote_ident(idname) || ' = CAST(' || quote_literal(v_fields->>idname) || ' AS ' || column_type_id_array[i] || ') AND ';
			i=i+1;
		END LOOP;

		v_querytext = substring(v_querytext, 0, length(v_querytext)-4);
	ELSE
		v_querytext := v_querytext || ' WHERE ' || quote_ident(v_idname) || ' = CAST(' || quote_literal(v_id) || ' AS ' || column_type_id || ')';
	END IF;
	EXECUTE v_querytext||');' INTO v_exists;


	-- Remove from v_text any keys that are in v_idname_array
	IF v_text IS NOT NULL AND v_idname_array IS NOT NULL THEN
		v_text := ARRAY(
			SELECT elem
			FROM unnest(v_text) AS elem
			WHERE NOT ((elem::json)->>'key') = ANY(v_idname_array)
		);
	END IF;

	IF v_text IS NOT NULL THEN
		i = 1;

		IF v_exists THEN
			-- query text for UPDATE, step1
			v_querytext := 'UPDATE ' || quote_ident(v_tablename) ||' SET ';
		ELSE
			-- query text for INSERT, step1
			v_querytext := 'INSERT INTO ' || quote_ident(v_tablename) ||' (' || v_idname;
			-- Build column list
			FOREACH text IN ARRAY v_text LOOP
				SELECT v_text[i] INTO v_jsonfield;
				v_field := (SELECT (v_jsonfield ->> 'key'));
				v_querytext := concat(v_querytext, ', ', quote_ident(v_field));
				i := i + 1;
			END LOOP;
			v_querytext := v_querytext || ') VALUES (' || v_id || ', ';
			i := 1;
		END IF;

		-- query text, step2
		FOREACH text IN ARRAY v_text
		LOOP
			SELECT v_text [i] into v_jsonfield;
			v_field:= (SELECT (v_jsonfield ->> 'key')) ;
			v_value := (SELECT (v_jsonfield ->> 'value')) ;

			-- Unselected combos arrive as '', '-1' or 'null'. Integer mapzones
			-- (sector, dma, presszone, dqa) really use -1, so drop the sentinel
			-- only when this column is a foreign key and the target has no such row.
			IF v_value IN ('', '-1', 'null', 'None') THEN
				SELECT format('%I.%I', nr.nspname, rt.relname), ra.attname
				INTO v_fktable, v_fkatt
				FROM pg_constraint c
				JOIN pg_class st ON st.oid = c.conrelid
				JOIN pg_namespace ns ON ns.oid = st.relnamespace AND ns.nspname = v_schemaname
				JOIN pg_attribute sa ON sa.attrelid = st.oid AND sa.attnum = c.conkey[1] AND sa.attname = v_field
				JOIN pg_class rt ON rt.oid = c.confrelid
				JOIN pg_namespace nr ON nr.oid = rt.relnamespace
				JOIN pg_attribute ra ON ra.attrelid = rt.oid AND ra.attnum = c.confkey[1]
				WHERE c.contype = 'f'
				  AND cardinality(c.conkey) = 1
				LIMIT 1;

				IF v_fktable IS NOT NULL THEN
					EXECUTE 'SELECT EXISTS (SELECT 1 FROM ' || v_fktable || ' WHERE ' || quote_ident(v_fkatt) || '::text = $1)'
						INTO v_fkhit
						USING v_value;
					IF NOT COALESCE(v_fkhit, false) THEN
						v_value := NULL;
					END IF;
				END IF;
			END IF;

			-- getting closed status if exists to work with graphanalytics functions in case of valves
			IF v_field = 'closed' THEN
				v_closedstatus = v_value;
			END IF;

			-- Get column type
			EXECUTE 'SELECT udt_name::regtype as data_type FROM information_schema.columns  WHERE table_schema = $1 AND table_name = ' || quote_literal(v_tablename) || ' AND column_name = $2'
				USING v_schemaname, v_field
				INTO v_columntype;

			-- control column_type
			IF v_columntype IS NULL THEN
				v_columntype='text';
			END IF;

			-- control geometry fields
			IF v_field ='the_geom' OR v_field ='geom' THEN
				v_columntype='geometry';
			END IF;

			IF v_field='state' THEN
				PERFORM gw_fct_state_control(json_build_object('parameters', json_build_object('feature_type_aux', v_featuretype, 'feature_id_aux', v_id, 'state_aux', v_value::integer, 'tg_op_aux', 'UPDATE')));
			END IF;

			IF v_field in ('geom', 'the_geom') THEN
				v_value := (SELECT ST_SetSRID((v_value)::geometry, SRID_VALUE));
			END IF;

			-- Handle array types - format value with curly braces if it's an array
			IF v_columntype LIKE '%[]' AND v_value IS NOT NULL AND v_value != '' THEN
				-- Replace [ with { and ] with } for array input
				IF v_value LIKE '[%' THEN
					v_value := replace(replace(v_value, '[', '{'), ']', '}');
				ELSIF v_value NOT LIKE '{%}' THEN
					v_value := '{' || v_value || '}';
				END IF;
			END IF;

			--building the query text
			IF v_exists THEN
				-- For UPDATE
				IF n=1 THEN
					v_querytext := concat (v_querytext, quote_ident(v_field) , ' = CAST(' , quote_nullable(v_value) , ' AS ' , v_columntype , ')');
				ELSIF i>1 THEN
					v_querytext := concat (v_querytext, ' , ',  quote_ident(v_field) , ' = CAST(' , quote_nullable(v_value) , ' AS ' , v_columntype , ')');
				END IF;
			ELSE
				-- For INSERT
				IF i=1 THEN
					v_querytext := concat(v_querytext, 'CAST(', quote_nullable(v_value), ' AS ', v_columntype, ')');
				ELSE
					v_querytext := concat(v_querytext, ', CAST(', quote_nullable(v_value), ' AS ', v_columntype, ')');
				END IF;
			END IF;
			n=n+1;
			i=i+1;

		END LOOP;

		-- query text, final step
		if v_idname_array is null then
			v_idname_array := string_to_array(v_idname, ', ');
			v_id_array := string_to_array(v_id, ', ');
		end if;

		IF v_exists THEN
			IF cardinality(v_idname_array) > 1 AND cardinality(v_id_array) > 1 then
				i = 1;
				v_querytext := v_querytext || ' WHERE ';
				FOREACH idname IN ARRAY v_idname_array loop
					v_querytext := v_querytext || quote_ident(idname) || ' = CAST(' || quote_literal(v_id_array[i]) || ' AS ' || column_type_id_array[i] || ') AND ';
					i=i+1;
				END LOOP;
				v_querytext = substring(v_querytext, 0, length(v_querytext)-4);
			ELSIF cardinality(v_idname_array) > 1 THEN
				i = 1;
				v_querytext := v_querytext || ' WHERE ';
				FOREACH idname IN ARRAY v_idname_array loop
					v_querytext := v_querytext || quote_ident(idname) || ' = CAST(' || quote_literal(v_fields->>idname) || ' AS ' || column_type_id_array[i] || ') AND ';
					i=i+1;
				END LOOP;

				v_querytext = substring(v_querytext, 0, length(v_querytext)-4);
			ELSE
				v_querytext := v_querytext || ' WHERE ' || quote_ident(v_idname) || ' = CAST(' || quote_literal(v_id) || ' AS ' || column_type_id || ')';
			END IF;
		ELSE
			v_querytext := v_querytext || ')';
		END IF;

		-- execute query text
		EXECUTE v_querytext;
		IF v_fieldsreload IS NOT NULL THEN
			SELECT array_agg(key) INTO v_keys_fields
  				FROM json_object_keys(v_fields::json) AS key;

			EXECUTE 'SELECT gw_fct_getcolumnsfromid($${
				"client":{"device":4, "infoType":1, "lang":"ES"},
				"form":{},
				"feature":{"tableName":"'|| v_tablename ||'", "id":"'|| v_id ||'", "fieldsReload":"'|| v_fieldsreload ||'", "parentField":"'||v_keys_fields||'"},
				"data":{}}$$)' INTO v_columnfromid;
		END IF;
	END IF;

	v_message = '{"level": 3, "text": "Feature have been succesfully updated."}';

	-- Control NULL's
	v_version := COALESCE(v_version, '');
	v_columnfromid := COALESCE(v_columnfromid, '{}');
	-- Return
	RETURN ('{"status":"Accepted", "message":'||v_message||', "version":"' || v_version || '"'||
	      ',"body":{"data":{"fields":' || v_columnfromid || '}'||
	      '}'||'}')::json;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
	RETURN json_build_object('status', 'Failed', 'message', json_build_object('level', 2, 'text', SQLERRM),  'version', v_version, 'SQLSTATE', SQLSTATE)::json;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;