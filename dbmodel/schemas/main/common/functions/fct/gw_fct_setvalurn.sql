/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2464

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_setvalurn();
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_setvalurn()
  RETURNS int8 AS
$BODY$

DECLARE

v_max int8;
v_projecttype text;

BEGIN

	-- search path
	SET search_path = "SCHEMA_NAME", public;
	SELECT project_type INTO v_projecttype FROM sys_version ORDER BY id DESC LIMIT 1;

	--urn
	IF v_projecttype='WS' THEN
		SELECT GREATEST (
		(SELECT max(node_id::int8) FROM node),
		(SELECT max(arc_id::int8) FROM arc),
		(SELECT max(connec_id::int8) FROM connec),
		(SELECT max(link_id::int8) FROM link),
		(SELECT max(element_id::int8) FROM element),
		(SELECT max(pol_id::int8) FROM polygon),
		(SELECT max(omzone_id::int8) FROM omzone),
		(SELECT max(crmzone_id::int8) FROM crmzone),
		(SELECT max(dma_id::int8) FROM dma),
		(SELECT max(presszone_id::int8) FROM presszone),
		(SELECT max(sector_id::int8) FROM sector),
		(SELECT max(dqa_id::int8) FROM dqa),
		(SELECT max(dma_id::int8) FROM plan_netscenario_dma),
		(SELECT max(presszone_id::int8) FROM plan_netscenario_presszone)
		) INTO v_max;
	ELSIF v_projecttype='UD' THEN
		SELECT GREATEST (
		(SELECT max(node_id::int8) FROM node),
		(SELECT max(arc_id::int8) FROM arc),
		(SELECT max(connec_id::int8) FROM connec),
		(SELECT max(link_id::int8) FROM link),
		(SELECT max(gully_id::int8) FROM gully),
		(SELECT max(element_id::int8) FROM element),
		(SELECT max(pol_id::int8) FROM polygon),
		(SELECT max(omzone_id::int8) FROM omzone),
		(SELECT max(dma_id::int8) FROM dma),
		(SELECT max(sector_id::int8) FROM sector),
		(SELECT max(dwfzone_id::int8) FROM dwfzone)
		) INTO v_max;
	END IF;

	-- setval() rejects 0: urn_id_seq starts at 1. Empty projects only have
	-- mapzone rows with id 0, so GREATEST of those maxes is 0.
	RETURN GREATEST(COALESCE(v_max, 1), 1);
END;

$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;