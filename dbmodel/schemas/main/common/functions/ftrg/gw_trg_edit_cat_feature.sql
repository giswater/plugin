/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3146

CREATE OR REPLACE FUNCTION "SCHEMA_NAME".gw_trg_edit_cat_feature()
  RETURNS trigger AS
$BODY$
DECLARE

v_table text;
v_project_type text;
v_version text;

BEGIN

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';
	v_table:= TG_ARGV[0];

		SELECT lower(project_type), giswater  INTO v_project_type, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	IF TG_OP = 'INSERT' THEN

		-- control nulls
		IF NEW.code_autofill IS NULL THEN NEW.code_autofill=true; END IF;
		IF NEW.active IS NULL THEN NEW.active=true; END IF;

		INSERT INTO cat_feature(id, feature_class, shortcut_key, descript, link_path, code_autofill, abrevation, active)
		VALUES (NEW.id, NEW.system_id, NEW.shortcut_key, NEW.descript, NEW.link_path, NEW.code_autofill, NEW.abrevation, NEW.active);

		IF v_table='arc' THEN

			UPDATE cat_feature_arc SET epa_default=NEW.epa_default WHERE id=NEW.id;

		ELSIF v_table='connec' THEN

			-- control nulls
			IF NEW.double_geom IS NULL THEN NEW.double_geom='{"activated":false,"value":1}'; END IF;

			UPDATE cat_feature_connec SET double_geom=NEW.double_geom::json WHERE id=NEW.id;

			IF v_project_type='ws' THEN
				UPDATE cat_feature_connec SET epa_default=NEW.epa_default WHERE id=NEW.id;
			END IF;

		ELSIF v_table='node' THEN

			-- control nulls
			IF NEW.choose_hemisphere IS NULL THEN NEW.choose_hemisphere=true; END IF;
			IF NEW.isprofilesurface IS NULL THEN NEW.isprofilesurface=true; END IF;
			IF NEW.isarcdivide IS NULL THEN NEW.isarcdivide=true; END IF;
			IF NEW.double_geom IS NULL THEN NEW.double_geom='{"activated":false,"value":1}'; END IF;
			IF NEW.num_arcs IS NULL THEN NEW.num_arcs=9; END IF;

			IF v_project_type='ws' THEN

				UPDATE cat_feature_node SET epa_default=NEW.epa_default, isarcdivide=NEW.isarcdivide, isprofilesurface=NEW.isprofilesurface, choose_hemisphere=NEW.choose_hemisphere,
				double_geom=NEW.double_geom::json, num_arcs=NEW.num_arcs, graph_delimiter=NEW.graph_delimiter  WHERE id=NEW.id;

			ELSIF v_project_type='ud' THEN

				-- control nulls
				IF NEW.isexitupperintro IS NULL THEN NEW.isexitupperintro=1; END IF;

				UPDATE cat_feature_node SET epa_default=NEW.epa_default, isarcdivide=NEW.isarcdivide, isprofilesurface=NEW.isprofilesurface, choose_hemisphere=NEW.choose_hemisphere,
				double_geom=NEW.double_geom::json, num_arcs=NEW.num_arcs, isexitupperintro=NEW.isexitupperintro  WHERE id=NEW.id;
			END IF;

		ELSIF v_table='gully' THEN

			IF NEW.double_geom IS NULL THEN NEW.double_geom='{"activated":false,"value":1}'; END IF;

			UPDATE cat_feature_gully SET double_geom=NEW.double_geom::json, epa_default=NEW.epa_default WHERE id=NEW.id;

		ELSIF v_table='element' THEN

			UPDATE cat_feature_element SET epa_default=NEW.epa_default WHERE id=NEW.id;
		END IF;

		RETURN NEW;

	ELSIF TG_OP = 'UPDATE' THEN

		UPDATE cat_feature SET id=NEW.id, feature_class=NEW.system_id, shortcut_key=NEW.shortcut_key, descript=NEW.descript, link_path=NEW.link_path,
		code_autofill=NEW.code_autofill, abrevation=NEW.abrevation, active=NEW.active WHERE id=OLD.id;

		IF v_table='arc' THEN

			UPDATE cat_feature_arc SET epa_default=NEW.epa_default WHERE id=NEW.id;

		ELSIF v_table='connec' THEN

			UPDATE cat_feature_connec SET double_geom=NEW.double_geom::json WHERE id=NEW.id;

			IF v_project_type='ws' THEN
				UPDATE cat_feature_connec SET epa_default=NEW.epa_default WHERE id=NEW.id;
			END IF;

		ELSIF v_table='node' THEN
			IF v_project_type='ws' THEN
				UPDATE cat_feature_node SET epa_default=NEW.epa_default, isarcdivide=NEW.isarcdivide, isprofilesurface=NEW.isprofilesurface, choose_hemisphere=NEW.choose_hemisphere,
				double_geom=NEW.double_geom::json, num_arcs=NEW.num_arcs, graph_delimiter=NEW.graph_delimiter  WHERE id=NEW.id;

			ELSIF v_project_type='ud' THEN
				UPDATE cat_feature_node SET epa_default=NEW.epa_default, isarcdivide=NEW.isarcdivide, isprofilesurface=NEW.isprofilesurface, choose_hemisphere=NEW.choose_hemisphere,
				double_geom=NEW.double_geom::json, num_arcs=NEW.num_arcs, isexitupperintro=NEW.isexitupperintro  WHERE id=NEW.id;
			END IF;

		ELSIF v_table='gully' THEN
			UPDATE cat_feature_gully SET double_geom=NEW.double_geom::json WHERE id=NEW.id;

		ELSIF v_table='element' THEN
			UPDATE cat_feature_element SET epa_default=NEW.epa_default WHERE id=NEW.id;

		END IF;

		-- manage mandatory values of config_param_user where feature is deprecated
		DELETE FROM sys_param_user WHERE id IN (SELECT sys_param_user.id FROM sys_param_user, cat_feature
		WHERE active=false AND concat(lower(cat_feature.id),'_vdefault') = sys_param_user.id);

		RETURN NEW;

	ELSIF TG_OP = 'DELETE' THEN

		EXECUTE 'DELETE FROM cat_feature_'||lower(v_table)||' WHERE id = '||quote_literal(OLD.id)||';';

		DELETE FROM cat_feature WHERE id = OLD.id;

		RETURN NULL;
	END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;