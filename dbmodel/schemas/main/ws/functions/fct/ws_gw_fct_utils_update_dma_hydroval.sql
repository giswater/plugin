/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 2638
  
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_utils_update_dma_hydroval()
 RETURNS integer AS
$BODY$

/* example
SELECT SCHEMA_NAME.gw_fct_utils_update_dma_hydroval()

GOAL:
Function with the goal to update ext_rtc_dma_period using daily process, values from CRM in  order to have updated it to make a good hydraulic model
Table ext_rtc_dma_period is inserted value when first register of that cat_period_id is inserted (dma_id, period_id)
Fields updated here are: m3_total_period, m3_total_period_hdyro, effc=1 . As you can see  (m3_total_period = m3_total_period_hdyro) is updated without losses 
After that function table maybe re-updated by function csv2pg_import_patterns updating effc, min, max and pattern values

*/

DECLARE

	
BEGIN

	-- Search path
	SET search_path = "SCHEMA_NAME", public;
	
	UPDATE ext_rtc_dma_period SET m3_total_period=b.billed_volume, m3_total_period_hydro=b.billed_volume, effc=1 
	FROM (	SELECT cat_period_id, dma_id, sum(billed_volume) FROM v_hydrometer_period a
			JOIN v_hydrometer erh ON erh.hydrometer_id=a.hydrometer_id
			JOIN connec c ON erh.feature_customer_code = c.customer_code
			group by cat_period_id, dma_id
			order by 1, 2) b
		WHERE ext_rtc_dma_period.cat_period_id=b.cat_period_id AND ext_rtc_dma_period.dma_id::integer=b.dma_id;

	RETURN 0;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

