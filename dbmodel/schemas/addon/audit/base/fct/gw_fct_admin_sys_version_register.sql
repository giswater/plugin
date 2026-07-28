/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION audit.gw_fct_admin_sys_version_register(p_data json)
RETURNS json AS
$BODY$
DECLARE
	v_gwversion text;
	v_language text;
	v_projecttype text;
	v_epsg integer;
	v_isnew boolean;
	v_prev record;
BEGIN
	SET search_path = audit, public;
	v_gwversion := (p_data -> 'data') ->> 'gwVersion';
	v_language := COALESCE((p_data -> 'client') ->> 'lang', 'en_US');
	v_projecttype := (p_data -> 'data') ->> 'projectType';
	v_epsg := NULLIF((p_data -> 'data') ->> 'epsg', '')::integer;
	v_isnew := lower(COALESCE((p_data -> 'data') ->> 'isNewProject', 'false')) IN ('true', 't', '1');
	SELECT * INTO v_prev FROM audit.sys_version ORDER BY id DESC LIMIT 1;
	IF v_gwversion IS NULL AND v_prev IS NOT NULL THEN
		v_gwversion := v_prev.giswater;
	END IF;
	IF v_isnew IS NOT TRUE AND v_prev IS NOT NULL THEN
		v_language := COALESCE(v_prev.language, v_language);
		v_epsg := COALESCE(v_epsg, v_prev.epsg);
		v_projecttype := COALESCE(v_projecttype, v_prev.project_type);
	ELSIF v_isnew IS TRUE AND v_epsg IS NULL THEN
		v_epsg := 25831;
	END IF;
	INSERT INTO audit.sys_version (giswater, project_type, postgres, postgis, language, epsg)
	VALUES (v_gwversion, upper(COALESCE(v_projecttype, 'AUDIT')), version(), postgis_version(), v_language, v_epsg);
	RETURN json_build_object('status', 'Accepted', 'version', v_gwversion);
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
