/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2446

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_edit_psector()
  RETURNS trigger AS
$BODY$

DECLARE
	v_sql varchar;
	v_projectype text;
	rec_type record;
	rec record;
	v_statetype_obsolete integer;
	v_statetype_onservice integer;
	v_auto_downgrade_link boolean;
	v_ischild text;
	v_parent_id integer;
	v_state_obsolete_planified integer;
	v_psector_geom geometry;
BEGIN

    EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

    v_projectype := (SELECT project_type FROM sys_version ORDER BY id DESC LIMIT 1);

    IF TG_OP = 'INSERT' THEN

		-- Scale_vdefault
		IF (NEW.scale IS NULL) THEN
			NEW.scale := (SELECT "value" FROM config_param_user WHERE "parameter"='psector_scale_vdefault' AND "cur_user"="current_user"())::numeric (8,2);
		END IF;

		-- Rotation_vdefault
		IF (NEW.rotation IS NULL) THEN
			NEW.rotation := (SELECT "value" FROM config_param_user WHERE "parameter"='psector_rotation_vdefault' AND "cur_user"="current_user"())::numeric (8,4);
		END IF;

		-- Gexpenses_vdefault
		IF (NEW.gexpenses IS NULL) THEN
			NEW.gexpenses := (SELECT "value" FROM config_param_user WHERE "parameter"='plan_psector_gexpenses_vdefault' AND "cur_user"="current_user"())::numeric(4,2);
		END IF;

		-- Vat_vdefault
		IF (NEW.vat IS NULL) THEN
			NEW.vat := (SELECT "value" FROM config_param_user WHERE "parameter"='plan_psector_vat_vdefault' AND "cur_user"="current_user"())::numeric(4,2);
		END IF;

		-- Other_vdefault
		IF (NEW.other IS NULL) THEN
			NEW.other := (SELECT "value" FROM config_param_user WHERE "parameter"='plan_psector_other_vdefault' AND "cur_user"="current_user"())::numeric(4,2);
		END IF;

		-- Type_vdefault
		IF (NEW.psector_type IS NULL) THEN
			NEW.psector_type := (SELECT "value" FROM config_param_user WHERE "parameter"='psector_type_vdefault' AND "cur_user"="current_user"())::integer;
		END IF;

		IF NEW.workcat_id NOT IN (SELECT id FROM cat_work) THEN
			NEW.workcat_id = NULL;
		END IF;

		IF NEW.creation_date IS NULL THEN
			NEW.creation_date = NOW();
		END IF;

		NEW.psector_id:= (SELECT nextval('plan_psector_id_seq'));

		-- archived is false by default
		INSERT INTO plan_psector (psector_id, name, psector_type, descript, priority, text1, text2, observ, rotation, scale,
		 atlas_id, gexpenses, vat, other, the_geom, expl_id, active, ext_code, status, text3, text4, text5, text6, num_value, workcat_id, workcat_id_plan, parent_id, creation_date)
		VALUES  (NEW.psector_id, NEW.name, NEW.psector_type, NEW.descript, NEW.priority, NEW.text1, NEW.text2, NEW.observ, NEW.rotation,
		NEW.scale, NEW.atlas_id, NEW.gexpenses, NEW.vat, NEW.other, NEW.the_geom, NEW.expl_id, NEW.active,
		NEW.ext_code, NEW.status, NEW.text3, NEW.text4, NEW.text5, NEW.text6, NEW.num_value, NEW.workcat_id, NEW.workcat_id_plan, NEW.parent_id, NEW.creation_date);

	    RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN

		--get obsolete_planified state_type
		v_state_obsolete_planified:= (SELECT value::json ->> 'plan_statetype_obsolete_planned' FROM config_param_system WHERE parameter='plan_statetype_vdefault');

		-- get state_type default values
		IF (OLD.status != NEW.status) THEN
			SELECT value::integer INTO v_statetype_obsolete FROM config_param_user WHERE parameter='edit_statetype_0_vdefault' AND cur_user=current_user;
			IF v_statetype_obsolete IS NULL THEN
					EXECUTE 'SELECT SCHEMA_NAME.gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3134", "function":"2446","parameters":null}}$$);';
			END IF;

			SELECT value::integer INTO v_statetype_onservice FROM config_param_user WHERE parameter='edit_statetype_1_vdefault' AND cur_user=current_user;
			IF v_statetype_onservice IS NULL THEN
					EXECUTE 'SELECT SCHEMA_NAME.gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
				"data":{"message":"3136", "function":"2446","parameters":null}}$$);';
			END IF;
		END IF;

		UPDATE plan_psector
		SET psector_id=NEW.psector_id, name=NEW.name, psector_type=NEW.psector_type, descript=NEW.descript, priority=NEW.priority, text1=NEW.text1,
		text2=NEW.text2, observ=NEW.observ, rotation=NEW.rotation, scale=NEW.scale, atlas_id=NEW.atlas_id,
		gexpenses=NEW.gexpenses, vat=NEW.vat, other=NEW.other, expl_id=NEW.expl_id, active=NEW.active, ext_code=NEW.ext_code, status=NEW.status,
		text3=NEW.text3, text4=NEW.text4, text5=NEW.text5, text6=NEW.text6, num_value=NEW.num_value, workcat_id=new.workcat_id, workcat_id_plan=new.workcat_id_plan, 
		parent_id=new.parent_id, updated_at=now(), updated_by=current_user, creation_date=NEW.creation_date
		WHERE psector_id=OLD.psector_id;

		-- update psector status to MADE OPERATIONAL (Archived)
		IF (OLD.status != NEW.status) AND (NEW.status = 5) THEN

			-- get workcat id
			IF NEW.workcat_id IS NULL THEN
				NEW.workcat_id = (SELECT value FROM config_param_user WHERE parameter= 'edit_workcat_vdefault' AND cur_user=current_user);

				IF NEW.workcat_id IS NULL THEN
					EXECUTE 'SELECT SCHEMA_NAME.gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
					"data":{"message":"4456", "function":"2446","parameters":null}}$$);';
				END IF;
			END IF;


			-- get psector geometry
			v_psector_geom = (SELECT the_geom FROM plan_psector WHERE psector_id=NEW.psector_id);

			-- Set archived = true for arc/node/connec/gully (no need to copy data, just mark as archived)
			UPDATE plan_psector_x_arc SET archived = true WHERE psector_id = NEW.psector_id;
			UPDATE plan_psector_x_node SET archived = true WHERE psector_id = NEW.psector_id;
			UPDATE plan_psector_x_connec SET archived = true WHERE psector_id = NEW.psector_id;
			IF v_projectype = 'UD' THEN
				UPDATE plan_psector_x_gully SET archived = true WHERE psector_id = NEW.psector_id;
			END IF;

			--temporary remove topology control
			UPDATE config_param_user SET value = 'true' WHERE parameter='edit_disable_statetopocontrol' AND cur_user=current_user;

			--use automatic downgrade link variable
			SELECT value::boolean INTO v_auto_downgrade_link FROM config_param_user WHERE parameter='edit_connect_downgrade_link' AND cur_user=current_user;
			IF v_auto_downgrade_link IS NULL THEN
				INSERT INTO config_param_user VALUES ('edit_connect_downgrade_link', 'true', current_user);
			END IF;

			--change state/state_type of psector features acording to its current status on the psector_x_* table
			FOR rec_type IN (SELECT * FROM sys_feature_type WHERE classlevel = 1 OR classlevel = 2 ORDER BY id asc) LOOP

				v_sql = 'SELECT '||rec_type.id||'_id as id, state FROM plan_psector_x_'||lower(rec_type.id)||' WHERE psector_id = '||OLD.psector_id||' ORDER BY '||rec_type.id||'_id DESC;';

				FOR rec IN EXECUTE v_sql LOOP

					IF lower(rec_type.id) = 'arc' THEN

						-- capture if arc is child in order to add their parents' relations
						SELECT ((addparam::json) ->> 'arcDivide') INTO v_ischild FROM plan_psector_x_arc WHERE arc_id=rec.id AND psector_id=OLD.psector_id;

						IF v_ischild='child' THEN
							-- get its parent_id
							SELECT arc_id::integer INTO v_parent_id FROM audit_arc_traceability WHERE (arc_id1=rec.id::text) or (arc_id2=rec.id::text);

							--insert related documents to child arc
							INSERT INTO doc_x_arc(doc_id, arc_id)
							SELECT doc_id, rec.id FROM (SELECT doc_id FROM doc_x_arc WHERE arc_id::integer=v_parent_id)a;

							--insert related elements to child arc
							INSERT INTO element_x_arc(element_id, arc_id)
							SELECT element_id, rec.id FROM (SELECT element_id FROM element_x_arc WHERE arc_id::integer=v_parent_id)a;

							--insert related visits to child arc
							INSERT INTO om_visit_x_arc(visit_id, arc_id)
							SELECT visit_id, rec.id FROM (SELECT visit_id FROM om_visit_x_arc WHERE arc_id::integer=v_parent_id)a;

						END IF;

						-- manage obsolete arcs for arc divide
						IF (SELECT value::json->>'setArcObsolete' FROM config_param_system WHERE parameter = 'edit_arc_divide')::boolean = TRUE THEN

							EXECUTE 'UPDATE arc SET state = 0, workcat_id_end = '||quote_literal(NEW.workcat_id)||', state_type = '||v_statetype_obsolete||
							' FROM plan_psector_x_arc p WHERE arc.arc_id = p.arc_id AND p.state = 1 AND p.psector_id='||OLD.psector_id||
							' AND p.arc_id = '''||rec.id||''' AND arc.state_type='||v_state_obsolete_planified||';';
						ELSE
							EXECUTE 'DELETE FROM plan_psector_x_arc  WHERE arc_id = '''||rec.id||''' AND psector_id='||OLD.psector_id||';';
							EXECUTE 'DELETE FROM arc WHERE arc_id = '''||rec.id||''';';
						END IF;

					END IF;

					-- set obsolete features where psector_x_* state is 0
					EXECUTE 'UPDATE '||lower(rec_type.id)||' n SET state = 0, workcat_id_end = '||quote_literal(NEW.workcat_id)||', state_type = '||v_statetype_obsolete||' 
					FROM plan_psector_x_'||lower(rec_type.id)||' p WHERE n.'||lower(rec_type.id)||'_id = p.'||lower(rec_type.id)||'_id 
					AND p.state = 0 AND p.psector_id='||OLD.psector_id||' AND n.'||lower(rec_type.id)||'_id = '''||rec.id||''';';

					-- set on service features where psector_x_* state is 1
					EXECUTE 'UPDATE '||lower(rec_type.id)||' n SET state = 1, workcat_id = '||quote_literal(NEW.workcat_id)||', workcat_id_plan = '||quote_nullable(NEW.workcat_id_plan)||
					', state_type = '||v_statetype_onservice||'	FROM plan_psector_x_'||lower(rec_type.id)||' p WHERE n.'||lower(rec_type.id)||'_id = p.'||lower(rec_type.id)||'_id 
					AND p.state = 1 AND p.psector_id='||OLD.psector_id||' AND n.'||lower(rec_type.id)||'_id = '''||rec.id||''' AND n.state_type<>'||v_state_obsolete_planified||';';

					IF lower(rec_type.id) IN ('connec', 'gully') THEN

						-- change arc_id for planified connecs (useful when existing connec changes to planified arc)
						EXECUTE 'UPDATE '||lower(rec_type.id)||' n SET arc_id = p.arc_id
						FROM plan_psector_x_'||lower(rec_type.id)||' p WHERE n.'||lower(rec_type.id)||'_id = p.'||lower(rec_type.id)||'_id 
						AND p.state = 1 AND p.psector_id='||OLD.psector_id||' AND n.'||lower(rec_type.id)||'_id = '''||rec.id||''';';

						-- set pjoint_id when pjoint_type=NODE getting it from exit_id on planified link
						EXECUTE 'UPDATE '||lower(rec_type.id)||' n SET pjoint_id = link.exit_id
						FROM plan_psector_x_'||lower(rec_type.id)||' p 
						JOIN link USING (link_id)
						WHERE n.'||lower(rec_type.id)||'_id = p.'||lower(rec_type.id)||'_id 
						AND p.state = 1 AND p.psector_id='||OLD.psector_id||' AND n.'||lower(rec_type.id)||'_id = '''||rec.id||'''
						AND n.pjoint_type=''NODE'';';

						-- set pjoint_id when pjoint_type=ARC getting it from exit_id on planified link
						EXECUTE 'UPDATE '||lower(rec_type.id)||' n SET pjoint_id = link.exit_id
						FROM plan_psector_x_'||lower(rec_type.id)||' p 
						JOIN link USING (link_id)
						WHERE n.'||lower(rec_type.id)||'_id = p.'||lower(rec_type.id)||'_id 
						AND p.state = 1 AND p.psector_id='||OLD.psector_id||' AND n.'||lower(rec_type.id)||'_id = '''||rec.id||'''
						AND n.pjoint_type=''ARC'';';

						-- set links to state 0 when its connec is 0 on psector
						EXECUTE 'UPDATE link SET state=0
						FROM plan_psector_x_'||lower(rec_type.id)||' p WHERE link.link_id = p.link_id 
						AND p.state = 0 AND p.psector_id='||OLD.psector_id||' AND link.feature_id = '''||rec.id||''';';

						-- set links to state 1 when its connec is 1 on psector
						EXECUTE 'UPDATE link SET state=1
						FROM plan_psector_x_'||lower(rec_type.id)||' p WHERE link.link_id = p.link_id 
						AND p.state = 1 AND p.psector_id='||OLD.psector_id||' AND link.feature_id = '''||rec.id||''';';

				END IF;

				-- Don't delete from psector_x_* - keep rows with archived=true for traceability
				-- Features have been updated in parent tables, relations stay marked as archived
			END LOOP;
		END LOOP;

			-- update polygon state from planified (2) to on service (1)
			UPDATE polygon pol SET state = 1
			FROM plan_psector_x_node p
			WHERE pol.feature_id = p.node_id AND p.state = 1 AND p.psector_id = OLD.psector_id AND pol.state = 2;

			UPDATE polygon pol SET state = 1
			FROM plan_psector_x_connec p
			WHERE pol.feature_id = p.connec_id AND p.state = 1 AND p.psector_id = OLD.psector_id AND pol.state = 2;

			IF v_projectype = 'UD' THEN
				UPDATE polygon pol SET state = 1
				FROM plan_psector_x_gully p
				WHERE pol.feature_id = p.gully_id AND p.state = 1 AND p.psector_id = OLD.psector_id AND pol.state = 2;
			END IF;

			--reset downgrade link variable
			IF v_auto_downgrade_link IS NULL THEN
				DELETE FROM config_param_user WHERE parameter='edit_connect_downgrade_link' AND cur_user=current_user;
			END IF;

			-- reset psector geometry and set inactive
			UPDATE plan_psector SET the_geom=v_psector_geom, active=false WHERE psector_id=NEW.psector_id;

			--reset topology control
			UPDATE config_param_user SET value = 'false' WHERE parameter='edit_disable_statetopocontrol' AND cur_user=current_user;

		ELSIF (OLD.status != NEW.status) AND (NEW.status IN (5,6,7)) THEN

			-- get psector geometry
			v_psector_geom = (SELECT the_geom FROM plan_psector WHERE psector_id=NEW.psector_id);
			
			-- Set archived = true for arc/node/connec/gully (no need to copy data, just mark as archived)
			UPDATE plan_psector_x_arc SET archived = true WHERE psector_id = NEW.psector_id;
			UPDATE plan_psector_x_node SET archived = true WHERE psector_id = NEW.psector_id;
			UPDATE plan_psector_x_connec SET archived = true WHERE psector_id = NEW.psector_id;
			IF v_projectype = 'UD' THEN
				UPDATE plan_psector_x_gully SET archived = true WHERE psector_id = NEW.psector_id;
			END IF;

			-- Don't delete from plan_psector_x_* - keep rows with archived=true for traceability
			-- Features stay in parent tables, and psector relations stay with archived flag
			
			-- reset psector geometry and set inactive
			UPDATE plan_psector SET the_geom=v_psector_geom, active=false WHERE psector_id=NEW.psector_id;

		
		ELSIF OLD.status IN (5,6,7) AND NEW.status IN (1,2) THEN -- change the status of the psector in order to restore it
		
			EXECUTE 'SELECT gw_fct_plan_recover_archived($${"data":{"psectorId":"'||NEW.psector_id||'"}}$$)';
	
		END IF;

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
		-- temporary disable trigger gw_trg_fk_array_id_table
		ALTER TABLE arc DISABLE TRIGGER gw_trg_fk_array_id_table;
		ALTER TABLE arc DISABLE TRIGGER gw_trg_fk_array_id_table_update;
		DELETE FROM connec WHERE state = 2 AND connec_id IN (SELECT connec_id FROM plan_psector_x_connec WHERE psector_id = OLD.psector_id);
		IF v_projectype='UD' THEN
			DELETE FROM gully WHERE state = 2 AND gully_id IN (SELECT gully_id FROM plan_psector_x_gully WHERE psector_id = OLD.psector_id);
		END IF;
		DELETE FROM arc WHERE state = 2 AND arc_id IN (SELECT arc_id FROM plan_psector_x_arc WHERE psector_id = OLD.psector_id) ;
		DELETE FROM node WHERE state = 2 AND node_id IN (SELECT node_id FROM plan_psector_x_node WHERE psector_id = OLD.psector_id);
		-- restore trigger gw_trg_fk_array_id_table
		ALTER TABLE arc ENABLE TRIGGER gw_trg_fk_array_id_table;
		ALTER TABLE arc ENABLE TRIGGER gw_trg_fk_array_id_table_update;
		DELETE FROM plan_psector WHERE psector_id = OLD.psector_id;

		RETURN NULL;

    END IF;

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
