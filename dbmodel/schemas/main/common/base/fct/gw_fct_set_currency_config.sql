/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

--FUNCTION CODE: 3524

DROP FUNCTION IF EXISTS SCHEMA_NAME.gw_fct_set_currency_config(numeric);
CREATE OR REPLACE FUNCTION SCHEMA_NAME.gw_fct_set_currency_config(p_value numeric)
RETURNS text AS
$BODY$

/*EXAMPLE
SELECT SCHEMA_NAME.gw_fct_set_currency_config(134734523.45);
SELECT SCHEMA_NAME.gw_fct_set_currency_config(134734523);
*/

DECLARE
v_currency_symbol text;
v_separator text;
v_decimals boolean;
v_format text;

BEGIN

	-- Set search path to local schema
	SET search_path = "SCHEMA_NAME", public;

	-- Get currency configuration
	SELECT 
		value::json->>'symbol',
		value::json->>'separator',
		COALESCE((value::json->>'decimals')::boolean, true)
	INTO v_currency_symbol, v_separator, v_decimals
	FROM v_config_param_system 
	WHERE parameter = 'admin_currency';

	-- Default values if not configured
	v_currency_symbol := COALESCE(v_currency_symbol, '€');
	v_separator := COALESCE(v_separator, ',');
	v_decimals := COALESCE(v_decimals, true);

	-- Determine format pattern based on separator and decimals
	IF v_decimals = false THEN
		-- No decimals
		IF v_separator = '.' THEN
			v_format := 'FM999G999G999';  -- European: 1.234.567
		ELSE
			v_format := 'FM999,999,999';  -- US/UK: 1,234,567
		END IF;
	ELSE
		-- With decimals
		IF v_separator = '.' THEN
			v_format := 'FM999G999G999D00';  -- European: 1.234.567,89
		ELSE
			v_format := 'FM999,999,999.00';  -- US/UK: 1,234,567.89
		END IF;
	END IF;

	-- Format and return
	RETURN to_char(p_value, v_format) || ' ' || v_currency_symbol;

	-- Exception handling
	EXCEPTION WHEN OTHERS THEN
		RETURN p_value::text || ' ' || COALESCE(v_currency_symbol, '€');

END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

