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

SELECT * FROM no_plan();

SELECT has_view('v_synoptic_line_scada'::name, 'View v_synoptic_line_scada should exist');
SELECT has_view('v_synoptic_point_scada'::name, 'View v_synoptic_point_scada should exist');
SELECT has_view('v_synoptic_line_dma'::name, 'View v_synoptic_line_dma should exist');
SELECT has_view('v_synoptic_point_dma'::name, 'View v_synoptic_point_dma should exist');
SELECT has_view('v_synoptic_line_sector'::name, 'View v_synoptic_line_sector should exist');
SELECT has_view('v_synoptic_point_sector'::name, 'View v_synoptic_point_sector should exist');
SELECT has_view('v_synoptic_line_dwfzone'::name, 'View v_synoptic_line_dwfzone should exist');
SELECT has_view('v_synoptic_point_dwfzone'::name, 'View v_synoptic_point_dwfzone should exist');
SELECT hasnt_view('v_synoptic_line_dqa'::name, 'WS-only synoptic line view should not exist on ud');
SELECT hasnt_view('v_synoptic_point_dqa'::name, 'WS-only synoptic point view should not exist on ud');
SELECT hasnt_view('v_synoptic_line_presszone'::name, 'WS-only synoptic line view should not exist on ud');
SELECT hasnt_view('v_synoptic_point_presszone'::name, 'WS-only synoptic point view should not exist on ud');
SELECT hasnt_view('v_synoptic_line_supplyzone'::name, 'WS-only synoptic line view should not exist on ud');
SELECT hasnt_view('v_synoptic_point_supplyzone'::name, 'WS-only synoptic point view should not exist on ud');

SELECT columns_are(
    'v_synoptic_line_scada',
    ARRAY['synoptic_id', 'synoptic_type', 'node_1', 'node_type_1', 'label_1', 'node_2', 'node_type_2', 'label_2', 'flow_sign', 'the_geom'],
    'View v_synoptic_line_scada should have the correct columns'
);

SELECT columns_are(
    'v_synoptic_point_scada',
    ARRAY['synoptic_id', 'synoptic_type', 'node_id', 'node_type', 'label', 'flow_sign', 'is_zone', 'the_geom'],
    'View v_synoptic_point_scada should have the correct columns'
);

SELECT columns_are(
    'v_synoptic_line_dma',
    ARRAY['synoptic_id', 'synoptic_type', 'node_1', 'node_type_1', 'label_1', 'node_2', 'node_type_2', 'label_2', 'flow_sign', 'the_geom'],
    'View v_synoptic_line_dma should have the correct columns'
);

SELECT columns_are(
    'v_synoptic_point_dma',
    ARRAY['synoptic_id', 'synoptic_type', 'node_id', 'node_type', 'label', 'flow_sign', 'is_zone', 'the_geom'],
    'View v_synoptic_point_dma should have the correct columns'
);

SELECT col_type_is('v_synoptic_line_scada', 'synoptic_id', 'int4', 'synoptic_id should be int4');
SELECT col_type_is('v_synoptic_line_scada', 'the_geom', 'geometry(linestring, 0)', 'SCADA line geometry is the schematic layout');
SELECT col_type_is('v_synoptic_point_scada', 'the_geom', 'geometry(point, 0)', 'SCADA point geometry is the schematic layout');
SELECT col_type_is('v_synoptic_point_scada', 'is_zone', 'bool', 'is_zone should be bool');
SELECT col_type_is('v_synoptic_line_dma', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'DMA line geometry uses the project SRID');
SELECT col_type_is('v_synoptic_point_dma', 'the_geom', 'geometry(point, SRID_VALUE)', 'DMA point geometry uses the project SRID');
SELECT col_type_is('v_synoptic_line_dwfzone', 'the_geom', 'geometry(linestring, SRID_VALUE)', 'DWF line geometry uses the project SRID');

SELECT * FROM finish();

ROLLBACK;
