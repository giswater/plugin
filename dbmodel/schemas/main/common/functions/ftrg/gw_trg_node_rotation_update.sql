/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 1348

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_trg_node_rotation_update()
  RETURNS trigger AS
$BODY$
DECLARE
	v_version text;
	v_project_type text;
	rec_arc Record;
	v_hemisphere boolean;
	hemisphere_rotation_aux float;
	v_rotation float;
	arc_id_aux  varchar;
	arc_geom    public.geometry;
	state_aux 	integer;
	intersect_loc	 double precision;
	v_rotation_disable boolean;
	v_rotation_disable_complete boolean;
	v_numarcs integer;


	v_dist_xlab numeric;
	v_dist_ylab numeric;
	v_label_point public.geometry;
	v_rot1 numeric = 0;
	v_rot2 numeric = 0;
	v_geom public.geometry;
	v_cur_rotation numeric;
	v_cur_quadrant TEXT;
	v_new_lab_position public.geometry;
	v_dist_sign numeric;
	v_srid integer = SRID_VALUE;

	v_sql text;


BEGIN

-- The goal of this function are two:
--1) to update automatic rotation node values using the hemisphere values when the variable edit_noderotation_disable_update is TRUE
--2) when node is disconnected from arcs update rotation taking values from nearest arc if exists and use also hemisphere if it's configured

	EXECUTE 'SET search_path TO '||quote_literal(TG_TABLE_SCHEMA)||', public';

	-- select config values
	SELECT giswater, upper(project_type) INTO v_version, v_project_type FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get parameters;
	IF v_project_type = 'WS' THEN
		SELECT choose_hemisphere INTO v_hemisphere FROM cat_feature_node JOIN cat_node ON cat_feature_node.id=cat_node.node_type WHERE cat_node.id=NEW.nodecat_id limit 1;
		SELECT num_arcs INTO v_numarcs FROM cat_feature_node JOIN cat_node ON cat_feature_node.id=cat_node.node_type WHERE cat_node.id=NEW.nodecat_id limit 1;
	ELSIF v_project_type = 'UD' then
		SELECT choose_hemisphere INTO v_hemisphere FROM cat_feature_node JOIN cat_node ON cat_feature_node.id=cat_node.node_type WHERE cat_node.id=NEW.nodecat_id limit 1;
		SELECT num_arcs INTO v_numarcs FROM cat_feature_node JOIN cat_node ON cat_feature_node.id=cat_node.node_type WHERE cat_node.id=NEW.nodecat_id limit 1;
	END IF;
	SELECT value::boolean INTO v_rotation_disable FROM config_param_user WHERE parameter='edit_disable_noderotation' AND cur_user=current_user;
	SELECT value::boolean INTO v_rotation_disable_complete FROM config_param_user WHERE parameter='edit_disable_noderotation_complete' AND cur_user=current_user;

	NEW.rotation := ROUND(NEW.rotation::numeric, 4)::double precision;
	NEW.hemisphere := ROUND(NEW.hemisphere::numeric, 4)::double precision;

	IF v_rotation_disable_complete IS TRUE THEN
		RETURN NEW;
	END IF;

	-- for disconnected nodes
	IF v_numarcs = 0 THEN

		-- Find closest arc inside tolerance
		SELECT arc_id, state, the_geom INTO arc_id_aux, state_aux, arc_geom  FROM ve_arc AS a 
		WHERE ST_DWithin(NEW.the_geom, a.the_geom, 0.01) ORDER BY ST_Distance(NEW.the_geom, a.the_geom) LIMIT 1;

		IF arc_id_aux IS NOT NULL THEN 

			--  Locate position of the nearest point
			intersect_loc := ST_LineLocatePoint(arc_geom, NEW.the_geom);
			IF intersect_loc < 1 THEN
				IF intersect_loc > 0.5 THEN
					v_rotation=st_azimuth(ST_LineInterpolatePoint(arc_geom,intersect_loc), ST_LineInterpolatePoint(arc_geom,intersect_loc-0.01)); 
				ELSE
					v_rotation=st_azimuth(ST_LineInterpolatePoint(arc_geom,intersect_loc), ST_LineInterpolatePoint(arc_geom,intersect_loc+0.01)); 
				END IF;
					IF v_rotation> 3.14159 THEN
					v_rotation = v_rotation-3.14159;
				END IF;
			END IF;

			IF v_hemisphere IS true THEN

				IF (NEW.hemisphere >180)  THEN
					UPDATE node set rotation=(v_rotation*(180/3.14159)+90) where node_id=NEW.node_id;
				ELSE
					UPDATE node set rotation=(v_rotation*(180/3.14159)-90) where node_id=NEW.node_id;
				END IF;
			ELSE
				UPDATE node set rotation=(v_rotation*(180/3.14159)-90) where node_id=NEW.node_id;
			END IF;
		END IF;
	END IF;

	-- for all nodes
	IF v_rotation_disable IS TRUE THEN
    		UPDATE node SET rotation=NEW.hemisphere WHERE node_id=NEW.node_id;
	END IF;

    IF TG_OP = 'UPDATE' THEN
        IF v_rotation_disable IS FALSE AND ((NEW.hemisphere != OLD.hemisphere)
        OR (OLD.hemisphere IS NULL AND NEW.hemisphere IS NOT NULL)) THEN
			if v_hemisphere IS TRUE THEN
	            NEW.rotation=NEW.rotation - 180;
	           	IF NEW.rotation > 360 then
	           		NEW.rotation=NEW.rotation-360;
	           	ELSIF NEW.rotation < 0 then
	           		NEW.rotation=NEW.rotation+360;
	           	end if;

	        else
	        	new.rotation=new.hemisphere;
	        end if;

	       	UPDATE node SET rotation=new.rotation where node_id=NEW.node_id;

        END IF;
    END IF;

	IF v_project_type = 'UD' then
		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>0  
		FROM cat_feature WHERE id = '||quote_literal(new.node_type)||'					
		' INTO v_dist_xlab;

		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>1  
		FROM cat_feature WHERE id = '||quote_literal(new.node_type)||'					
		' INTO v_dist_ylab;
	ELSIF v_project_type = 'WS' THEN
		
		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>0  
		FROM cat_feature JOIN cat_node on cat_feature.id = cat_node.node_type WHERE cat_node.id = '||quote_literal(new.nodecat_id)||'					
		' INTO v_dist_xlab;

		EXECUTE '
		SELECT addparam->''labelPosition''->''dist''->>1  
		FROM cat_feature JOIN cat_node on cat_feature.id = cat_node.node_type WHERE cat_node.id = '||quote_literal(new.nodecat_id)||'					
		' INTO v_dist_ylab;
		
	END IF;


	if new.label_x != old.label_x or new.label_y != old.label_y then

		update node set label_x = new.label_x, label_y = new.label_y where node_id = new.node_id;

		v_dist_ylab = null;
		v_dist_xlab = null;

	end if;

	
	new.rotation = coalesce(new.rotation, 0);

	if v_dist_ylab is not null and v_dist_xlab is not null and 
	(SELECT value::boolean FROM config_param_user WHERE parameter='edit_disable_noderotation' AND cur_user=current_user) IS FALSE
	then -- only start the process with not-null values

		-- prev calc: intermediate rotations according to dist_x and dist_y from cat_feature
		if (v_dist_xlab > 0 and v_dist_ylab > 0) -- top right
		or (v_dist_xlab < 0 and v_dist_ylab < 0) -- bottom left
		then 
			v_rot1 = 90+new.rotation; 
			v_rot2 = 0+new.rotation; 
		
		elsif (v_dist_xlab > 0 and v_dist_ylab < 0) -- bottom right
		or 	  (v_dist_xlab < 0 and v_dist_ylab > 0) -- top left
		then
			v_rot1 = -90+new.rotation;
			v_rot2 = -180+new.rotation;

			v_dist_xlab = v_dist_xlab * (-1);
			v_dist_ylab = v_dist_ylab * (-1);

		end if;

		-- prev calc: label position according to cat_feature
		v_sql = '
		with mec as (
		select the_geom, ST_Project(ST_Transform(the_geom, 4326)::geography, '||v_dist_xlab||', radians('||v_rot1||')) as eee
		FROM node WHERE node_id = '||QUOTE_LITERAL(new.node_id)||'), lab_point as (
		SELECT ST_Project(ST_Transform(eee::geometry, 4326)::geography, '||v_dist_ylab||', radians('||v_rot2||')) as fff
		from mec)
		select st_transform(fff::geometry, '||v_srid||') as label_p from lab_point';		

		execute v_sql into v_label_point;	
	
		-- prev calc: current angle between node and label position
		v_sql = '
		with mec as (
			SELECT 
			n.the_geom as vertex_point,
			n.rotation as rotation_node,
			$1 as point1,
			ST_LineInterpolatePoint(a.the_geom, ST_LineLocatePoint(a.the_geom, n.the_geom)) as point2
			from node n, arc a  where n.node_id = $2 and st_dwithin (a.the_geom, n.the_geom, 0.001) limit 1
		)
		select degrees(ST_Azimuth(vertex_point, point1))
		from mec';

		execute v_sql into v_cur_rotation using v_label_point, new.node_id;
		
		-- prev calc: current label_quadrant according to cat_feature
		if v_dist_xlab > 0 and v_dist_ylab > 0 then -- top right
			v_cur_quadrant = 'TR';
		elsif v_dist_xlab < 0 and v_dist_ylab > 0 then -- top left
			v_cur_quadrant = 'TL';
		elsif v_dist_xlab > 0 and v_dist_ylab < 0 then --bottom right
			v_cur_quadrant = 'BR';
		elsif v_dist_xlab < 0 and v_dist_ylab < 0 then -- bottom left
			v_cur_quadrant = 'BL';
		end if;
	
	end if;	

	if new.rotation > 360 then
		new.rotation = new.rotation - 360;
	elsif new.rotation <0 then
		new.rotation = 360 + new.rotation;
	end if;

	-- set label_x and label_y according to cat_feature
	update node set label_x = st_x(v_label_point)::numeric(12,2) where node_id = new.node_id;
	update node set label_y = st_y(v_label_point)::numeric(12,2) where node_id = new.node_id;

	update node set label_quadrant = v_cur_quadrant where node_id = new.node_id;
	update node set label_rotation =  new.rotation where node_id = new.node_id;

	-- CASE: if label_quadrant changes
	if new.label_quadrant != old.label_quadrant then

		if new.label_quadrant ilike 'B%' then
			v_dist_ylab = v_dist_ylab * (-1);
		end if;

		if new.label_quadrant ilike '%L' then
			v_dist_xlab = v_dist_xlab * (-1);
		end if;
	
		if new.label_quadrant ilike 'B%' then
			if new.label_quadrant ilike '%L' then
				v_rot1 = -90;					
			elsif new.label_quadrant ilike '%R' then
				v_rot1 = 90;
			end if;
		end if;
	
		if new.label_quadrant ilike 'T%' then
			if new.label_quadrant ilike '%L' then
				v_rot1 = 90;
			elsif new.label_quadrant ilike '%R' then	
				v_rot1 = -90;
			end if;
		end if;

		if (v_dist_xlab > 0 and v_dist_ylab > 0) -- top right
		or (v_dist_xlab < 0 and v_dist_ylab < 0) -- bottom left
		then 
			v_rot1 = 90+new.rotation; 
			v_rot2 = 0+new.rotation; 
		
		elsif (v_dist_xlab > 0 and v_dist_ylab < 0) -- bottom right
		or 	  (v_dist_xlab < 0 and v_dist_ylab > 0) -- top left
		then
			v_rot1 = -90+new.rotation;
			v_rot2 = -180+new.rotation;

			v_dist_xlab = v_dist_xlab * (-1);
			v_dist_ylab = v_dist_ylab * (-1);

		end if;

		v_rot1=coalesce(v_rot1, 0);			
		v_rot2=coalesce(v_rot2, 0);			

		v_sql = '
		with mec as (
		select the_geom, ST_Project(ST_Transform(the_geom, 4326)::geography, '||v_dist_xlab||', radians('||v_rot1||')) as eee
		FROM node WHERE node_id = '||QUOTE_LITERAL(new.node_id)||'), lab_point as (
		SELECT ST_Project(ST_Transform(eee::geometry, 4326)::geography, '||v_dist_ylab||', radians('||v_rot2||')) as fff
		from mec)
		select st_transform(fff::geometry, '||v_srid||') as label_p from lab_point';		

		execute v_sql into v_new_lab_position;	
	
		-- update label position
		update node set label_x = st_x(v_new_lab_position) where node_id = new.node_id;
		update node set label_y = st_y(v_new_lab_position) where node_id = new.node_id;
	
		update node set label_quadrant = new.label_quadrant where node_id = new.node_id;
		update node set label_rotation = rotation where node_id = new.node_id;

	end if;


	-- CASE: if rotation of the node changes
	if new.rotation != old.rotation then
	
		-- prev calc: current label position
		select st_setsrid(st_makepoint(label_x::numeric, label_y::numeric), v_srid) into v_label_point from node where node_id = new.node_id;
	
		-- prev calc: geom of the node
		execute 'select the_geom from node where node_id = '||quote_literal(new.node_id)||''  into v_geom;
		
		-- prev calc: current angle between node and its label
		v_sql = '
		with mec as (
			SELECT 
			n.the_geom as vertex_point,
			n.rotation as rotation_node,
			$1 as point1,
			ST_LineInterpolatePoint(a.the_geom, ST_LineLocatePoint(a.the_geom, n.the_geom)) as point2
			from node n, arc a  where n.node_id = $2 and st_dwithin (a.the_geom, n.the_geom, 0.001) limit 1
		)
		select degrees(ST_Azimuth(vertex_point, point1))
		from mec';
	
		execute v_sql into v_cur_rotation using v_label_point, new.node_id;
	
		-- prev calc: intermediate rotations according to dist_x and dist_y   		
	   	if (v_dist_xlab > 0 and v_dist_ylab > 0) -- top right
		or (v_dist_xlab < 0 and v_dist_ylab < 0) -- bottom left
		then 
			v_rot1 = 90+new.rotation; 
			v_rot2 = 0+new.rotation; 
		
		elsif (v_dist_xlab > 0 and v_dist_ylab < 0) -- bottom right
		or 	  (v_dist_xlab < 0 and v_dist_ylab > 0) -- top left
		then
			v_rot1 = -90+new.rotation;
			v_rot2 = -180+new.rotation;

			v_dist_xlab = v_dist_xlab * (-1);
			v_dist_ylab = v_dist_ylab * (-1);

		end if;

		v_rot1=coalesce(v_rot1, 0);			
		v_rot2=coalesce(v_rot2, 0);	

		-- label position
		v_sql = '
		with mec as (
		select the_geom, ST_Project(ST_Transform(the_geom, 4326)::geography, '||coalesce(v_dist_xlab, 0)||', radians('||coalesce(v_rot1, 0)||')) as eee
		FROM node WHERE node_id = '||QUOTE_LITERAL(new.node_id)||'), lab_point as (
		SELECT ST_Project(ST_Transform(eee::geometry, 4326)::geography, '||coalesce(v_dist_ylab, 0)||', radians('||coalesce(v_rot2, 0)||')) as fff
		from mec)
		select st_transform(fff::geometry, '||v_srid||') as label_p from lab_point';
		execute v_sql into v_label_point;

		update node set label_rotation = rotation where node_id = new.node_id;
		update node set label_x = st_x(v_label_point) where node_id = new.node_id;
		update node set label_y = st_y(v_label_point) where node_id = new.node_id;
	
	end if;
	
	UPDATE node SET rotation = NEW.rotation WHERE node_id = NEW.node_id;

	RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;