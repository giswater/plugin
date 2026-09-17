/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE:

CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_pg2epa_autorepair_epatype(p_data json)
RETURNS json AS 
$BODY$

/* example

-- execute
SELECT SCHEMA_NAME.gw_fct_pg2epa_autorepair_epatype($${"client":{"device":4, "infoType":1, "lang":"ES"}}$$);


ALTER TABLE SCHEMA_NAME.cat_feature_node DROP CONSTRAINT node_type_epa_table_check;

ALTER TABLE SCHEMA_NAME.cat_feature_node
  ADD CONSTRAINT node_type_epa_table_check CHECK (epa_table::text = ANY (ARRAY['inp_virtualvalve'::text, 'inp_inlet'::text, 'not_defined'::text, 'inp_junction'::text, 'inp_pump'::text, 'inp_reservoir'::text, 'inp_tank'::text, 'inp_valve'::text, 'inp_shortpipe'::text]));


-- log
SELECT * FROM ws.audit_check_data where fid = 214 AND criticity  > 1 order by id

-- check
SELECT * FROM 
(SELECT epa_type, count(*) as count_node FROM node where state > 0 group by epa_type order by 2)a
FULL JOIN
(SELECT 'JUNCTION' AS epa_type, count(*) as count_inp FROM inp_junction join node using (node_id ) where state > 0
union
SELECT 'RESERVOIR', count(*) FROM inp_reservoir join node using (node_id ) where state > 0
union
SELECT 'PUMP', count(*) FROM inp_pump join node using (node_id ) where state > 0
union
SELECT 'TANK', count(*) FROM inp_tank join node using (node_id ) where state > 0
union
SELECT 'SHORTPIPE', count(*) FROM inp_shortpipe join node using (node_id ) where state > 0
union
SELECT 'VALVE', count(*) FROM inp_valve join node using (node_id ) where state > 0
union
SELECT 'INLET', count(*) FROM inp_inlet join node using (node_id ) where state > 0)b
USING (epa_type)




SELECT * FROM 
(SELECT epa_type, count(*) as count_node FROM node where state > 0 group by epa_type order by 2)a
FULL JOIN
(SELECT 'JUNCTION' AS epa_type, count(*) as count_inp FROM inp_junction join node using (node_id ) where state > 0
union
SELECT 'STORAGE', count(*) FROM inp_storage join node using (node_id ) where state > 0  
union
SELECT 'DIVIDER', count(*) FROM inp_divider join node using (node_id ) where state > 0 
union
SELECT 'OUTFALL', count(*) FROM inp_outfall join node using (node_id ) where state > 0  )b
USING (epa_type)


SELECT * FROM 
(SELECT epa_type, count(*) as count_node FROM arc where state > 0 group by epa_type order by 2)a
FULL JOIN
(SELECT 'CONDUIT' AS epa_type, count(*) as count_inp FROM inp_conduit join arc using (arc_id ) where state > 0
union
SELECT 'WEIR', count(*) FROM inp_weir join arc using (arc_id ) where state > 0  
union
SELECT 'OUTLET', count(*) FROM inp_outlet join arc using (arc_id ) where state > 0 
union
SELECT 'ORIFICE', count(*) FROM inp_orifice join arc using (arc_id ) where state > 0 
union
SELECT 'VIRTUAL', count(*) FROM inp_virtual join arc using (arc_id ) where state > 0
union
SELECT 'PUMP', count(*) FROM inp_pump join arc using (arc_id ) where state > 0  )b
USING (epa_type)


*/


DECLARE
v_version text;
v_error_context text;
v_projecttype text;
v_affectrow integer;
v_fid integer = 214;
v_criticity integer = 0;
v_networkmode integer;
rec_feature record;
v_autorepair boolean;

BEGIN


	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;
	
	--  get version
	SELECT project_type, giswater INTO v_projecttype, v_version FROM sys_version ORDER BY id DESC LIMIT 1;

	-- get user values
	v_networkmode = (SELECT value FROM config_param_user WHERE parameter='inp_options_networkmode' AND cur_user=current_user); 
	
	-- get system values
	v_autorepair = (SELECT value::boolean FROM config_param_system WHERE parameter='epa_autorepair');

	IF v_autorepair THEN 
		
		-- delete auxiliar tables
		DELETE FROM audit_check_data WHERE fid = v_fid;
		
		IF v_projecttype  = 'WS' THEN
		
			-- node ws
			DELETE FROM inp_junction j
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = j.node_id AND n.epa_type = 'JUNCTION' AND n.state > 0);

			DELETE FROM inp_reservoir r
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = r.node_id AND n.epa_type = 'RESERVOIR' AND n.state > 0);

			DELETE FROM inp_tank t
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = t.node_id AND n.epa_type = 'TANK' AND n.state > 0);

			DELETE FROM inp_inlet i
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = i.node_id AND n.epa_type = 'INLET' AND n.state > 0);

			DELETE FROM inp_valve v
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = v.node_id AND n.epa_type = 'VALVE' AND n.state > 0);

			DELETE FROM inp_pump p
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = p.node_id AND n.epa_type = 'PUMP' AND n.state > 0);

			DELETE FROM inp_shortpipe s
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = s.node_id AND n.epa_type = 'SHORTPIPE' AND n.state > 0);

			INSERT INTO inp_junction (node_id)
			SELECT node_id FROM node WHERE state >0 and epa_type = 'JUNCTION'
			ON CONFLICT (node_id) DO NOTHING;

			INSERT INTO inp_reservoir (node_id)
			SELECT node_id FROM node WHERE state >0 and epa_type = 'RESERVOIR'
			ON CONFLICT (node_id) DO NOTHING;

			INSERT INTO inp_tank (node_id)
			SELECT node_id FROM node WHERE state >0 and epa_type = 'TANK'
			ON CONFLICT (node_id) DO NOTHING;
			
			INSERT INTO inp_inlet (node_id)
			SELECT node_id FROM node WHERE state >0 and epa_type = 'INLET'
			ON CONFLICT (node_id) DO NOTHING;
			
			INSERT INTO inp_valve (node_id)
			SELECT node_id FROM node WHERE state >0 and epa_type = 'VALVE'
			ON CONFLICT (node_id) DO NOTHING;
			
			INSERT INTO inp_pump (node_id)
			SELECT node_id FROM node WHERE state >0 and epa_type = 'PUMP'
			ON CONFLICT (node_id) DO NOTHING;

			INSERT INTO inp_shortpipe (node_id)
			SELECT node_id FROM node WHERE state >0 and epa_type = 'SHORTPIPE'
			ON CONFLICT (node_id) DO NOTHING;
			
			-- connec ws
			DELETE FROM inp_connec c
			WHERE NOT EXISTS (SELECT 1 FROM connec cc WHERE cc.connec_id = c.connec_id AND cc.epa_type = 'JUNCTION' AND cc.state > 0);

			INSERT INTO inp_connec
			SELECT connec_id FROM connec WHERE state >0 AND epa_type = 'JUNCTION'
			ON CONFLICT (connec_id) DO NOTHING;
			
			-- arc ws
			DELETE FROM inp_virtualvalve vv
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = vv.arc_id AND a.epa_type = 'VIRTUALVALVE' AND a.state > 0);

			DELETE FROM inp_virtualpump vp
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = vp.arc_id AND a.epa_type = 'VIRTUALPUMP' AND a.state > 0);

			DELETE FROM inp_pipe p
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = p.arc_id AND a.epa_type = 'PIPE' AND a.state > 0);

			INSERT INTO inp_virtualvalve SELECT arc_id FROM arc WHERE state >0 and epa_type = 'VIRTUALVALVE' ON CONFLICT (arc_id) DO NOTHING;
			INSERT INTO inp_virtualpump SELECT arc_id FROM arc WHERE state >0 and epa_type = 'VIRTUALPUMP' ON CONFLICT (arc_id) DO NOTHING;
			INSERT INTO inp_pipe SELECT arc_id FROM arc WHERE state >0 and epa_type = 'PIPE' ON CONFLICT (arc_id) DO NOTHING;

		ELSE 
			-- node ud
			DELETE FROM inp_junction j
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = j.node_id AND n.epa_type = 'JUNCTION' AND n.state > 0);

			DELETE FROM inp_storage s
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = s.node_id AND n.epa_type = 'STORAGE' AND n.state > 0);

			DELETE FROM inp_outfall o
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = o.node_id AND n.epa_type = 'OUTFALL' AND n.state > 0);

			DELETE FROM inp_divider d
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = d.node_id AND n.epa_type = 'DIVIDER' AND n.state > 0);

			DELETE FROM inp_netgully g
			WHERE NOT EXISTS (SELECT 1 FROM node n WHERE n.node_id = g.node_id AND n.epa_type = 'NETGULLY' AND n.state > 0);

			INSERT INTO inp_junction
			SELECT node_id FROM node WHERE state >0 and epa_type = 'JUNCTION'
			ON CONFLICT (node_id) DO NOTHING;

			INSERT INTO inp_storage
			SELECT node_id FROM node WHERE state >0 and epa_type = 'STORAGE'
			ON CONFLICT (node_id) DO NOTHING;

			INSERT INTO inp_outfall
			SELECT node_id FROM node WHERE state >0 and epa_type = 'OUTFALL'
			ON CONFLICT (node_id) DO NOTHING;
			
			INSERT INTO inp_divider
			SELECT node_id FROM node WHERE state >0 and epa_type = 'DIVIDER'
			ON CONFLICT (node_id) DO NOTHING;

			INSERT INTO inp_netgully
			SELECT node_id FROM node WHERE state >0 and epa_type = 'NETGULLY'
			ON CONFLICT (node_id) DO NOTHING;

			-- arc ud
			DELETE FROM inp_conduit c
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = c.arc_id AND a.epa_type = 'CONDUIT' AND a.state > 0);

			DELETE FROM inp_pump p
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = p.arc_id AND a.epa_type = 'PUMP' AND a.state > 0);

			DELETE FROM inp_virtual v
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = v.arc_id AND a.epa_type = 'VIRTUAL' AND a.state > 0);

			DELETE FROM inp_weir w
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = w.arc_id AND a.epa_type = 'WEIR' AND a.state > 0);

			DELETE FROM inp_orifice o
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = o.arc_id AND a.epa_type = 'ORIFICE' AND a.state > 0);

			DELETE FROM inp_outlet o
			WHERE NOT EXISTS (SELECT 1 FROM arc a WHERE a.arc_id = o.arc_id AND a.epa_type = 'OUTLET' AND a.state > 0);

			INSERT INTO inp_conduit
			SELECT arc_id FROM arc WHERE state >0 and epa_type = 'CONDUIT'
			ON CONFLICT (arc_id) DO NOTHING;

			INSERT INTO inp_pump
			SELECT arc_id FROM arc WHERE state >0 and epa_type = 'PUMP'
			ON CONFLICT (arc_id) DO NOTHING;

			INSERT INTO inp_virtual
			SELECT arc_id FROM arc WHERE state >0 and epa_type = 'VIRTUAL'
			ON CONFLICT (arc_id) DO NOTHING;
			
			INSERT INTO inp_weir
			SELECT arc_id FROM arc WHERE state >0 and epa_type = 'WEIR'
			ON CONFLICT (arc_id) DO NOTHING;

			INSERT INTO inp_orifice
			SELECT arc_id FROM arc WHERE state >0 and epa_type = 'ORIFICE'
			ON CONFLICT (arc_id) DO NOTHING;

			INSERT INTO inp_outlet
			SELECT arc_id FROM arc WHERE state >0 and epa_type = 'OUTLET'
			ON CONFLICT (arc_id) DO NOTHING;
			
		END IF;
		
	END IF;
	     
	-- Return
	RETURN '{"status":"Accepted"}';

END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;