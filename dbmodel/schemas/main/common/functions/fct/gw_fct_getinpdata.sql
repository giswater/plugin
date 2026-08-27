/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3310

DROP FUNCTION IF EXISTS "SCHEMA_NAME".gw_fct_getinpdata(JSON);
CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_fct_getinpdata(input_param json)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_status TEXT := 'Accepted';
    v_message TEXT := 'Data retrieved successfully';
    v_node JSON;
    v_result_point JSON;
    v_result_line JSON;
    v_result_polygon JSON := '{}'; -- Without polygon, empty
    result_ids text[];  -- Declare result_ids to store extracted array of text

BEGIN

	-- Set search path to local schema
    SET search_path = "SCHEMA_NAME", public;

    -- Extract result_ids from the input JSON
    -- We assume the input JSON has a key "result_ids" containing an array of text
    SELECT array_agg(value::text)
    INTO result_ids
    FROM json_array_elements_text(input_param->'result_ids');

    -- Check if result_ids is NULL or has an invalid value
    IF result_ids IS NULL OR array_length(result_ids, 1) IS NULL THEN
        RETURN gw_fct_json_create_return(
            '{"status":"Failed", "message":{"level":3, "text":"Invalid input"}}'::json, 3310, null, null, null
        );
    END IF;

    -- Get GeoJSON from rpt_inp_node (Point)
    SELECT jsonb_build_object(
        'type', 'FeatureCollection',
        'layerName', 'Rpt INP Node',
        'features', jsonb_agg(jsonb_build_object(
            'type', 'Feature',
            'geometry', ST_AsGeoJSON(ST_Transform(t.the_geom, 4326))::jsonb,
            'properties', to_jsonb(t) - 'the_geom'
        ))
    ) INTO v_node FROM rpt_inp_node t WHERE result_id = ANY(result_ids);

    -- Get GeoJSON from rpt_inp_arc (LineString)
    SELECT jsonb_build_object(
        'type', 'FeatureCollection',
        'layerName', 'Rpt INP Arc',
        'features', jsonb_agg(jsonb_build_object(
            'type', 'Feature',
            'geometry', ST_AsGeoJSON(ST_Transform(t.the_geom, 4326))::jsonb,
            'properties', to_jsonb(t) - 'the_geom'
        ))
    ) INTO v_result_line FROM rpt_inp_arc t WHERE result_id = ANY(result_ids);

    -- Construct the JSON
    RETURN gw_fct_json_create_return(
        ('{"status":"' || v_status || '", "message":{"level":3, "text":"' || v_message || '"},' ||
        '"body":{"data":{' ||
        '"point":' || COALESCE(v_node::text, '{"type":"FeatureCollection","features":[]}') || ',' ||
        '"line":' || COALESCE(v_result_line::text, '{"type":"FeatureCollection","features":[]}') || ',' ||
        '"polygon":' || COALESCE(v_result_polygon::text, '{"type":"FeatureCollection","features":[]}') || '}}}'
        )::json, 3310, null, null, null
    );

EXCEPTION
    WHEN OTHERS THEN
        RETURN gw_fct_json_create_return(
            json_build_object(
                'status', 'Failed',
                'message', json_build_object(
                    'level', 3,
                    'text', replace(SQLERRM, '"', '\"')
                )
            ), 3310, null, null, null
        );
END;
$function$;