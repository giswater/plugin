/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

-- Suppress NOTICE messages
SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

-- Plan for 3 test
SELECT plan(3);

-- Test if the function returns NULL when the SRID is NULL
SELECT is(
    gw_fct_is_geographic_srid(NULL),
    NULL,
    'Check if gw_fct_is_geographic_srid returns NULL when the SRID is NULL'
);

-- Test if the function returns TRUE when the SRID is a geographic SRID
SELECT is(
    gw_fct_is_geographic_srid(4326),
    TRUE,
    'Check if gw_fct_is_geographic_srid returns TRUE when the SRID is a geographic SRID'
);

-- Test if the function returns FALSE when the SRID is a projected SRID
SELECT is(
    gw_fct_is_geographic_srid(25831),
    FALSE,
    'Check if gw_fct_is_geographic_srid returns FALSE when the SRID is a projected SRID'
);


-- Finish the test
SELECT finish();

ROLLBACK;