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

-- Check table
SELECT has_table('cat_link'::name, 'Table cat_link should exist');

-- Check columns (UD: same physical layout as cat_arc)
SELECT columns_are(
    'cat_link',
    ARRAY[
        'id', 'link_type', 'matcat_id', 'shape', 'geom1', 'geom2',
        'geom3', 'geom4', 'geom5', 'geom6', 'geom7', 'geom8',
        'geom_r', 'descript', 'link', 'brand_id', 'model_id', 'svg',
        'z1', 'z2', 'width', 'area', 'estimated_depth', 'thickness',
        'cost_unit', 'cost', 'm2bottom_cost', 'm3protec_cost', 'active', 'label',
        'tsect_id', 'curve_id', 'acoeff', 'connect_cost', 'visitability_vdef', 'code'
    ],
    'Table cat_link should have the correct columns'
);

-- Check column types
SELECT col_type_is('cat_link', 'id', 'varchar(30)', 'Column id should be varchar(30)');
SELECT col_type_is('cat_link', 'link_type', 'varchar(30)', 'Column link_type should be varchar(30)');
SELECT col_type_is('cat_link', 'matcat_id', 'varchar(16)', 'Column matcat_id should be varchar(16)');
SELECT col_type_is('cat_link', 'shape', 'varchar(16)', 'Column shape should be varchar(16)');
SELECT col_type_is('cat_link', 'geom1', 'numeric(12,4)', 'Column geom1 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom2', 'numeric(12,4)', 'Column geom2 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom3', 'numeric(12,4)', 'Column geom3 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom4', 'numeric(12,4)', 'Column geom4 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom5', 'numeric(12,4)', 'Column geom5 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom6', 'numeric(12,4)', 'Column geom6 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom7', 'numeric(12,4)', 'Column geom7 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom8', 'numeric(12,4)', 'Column geom8 should be numeric(12,4)');
SELECT col_type_is('cat_link', 'geom_r', 'varchar(20)', 'Column geom_r should be varchar(20)');
SELECT col_type_is('cat_link', 'descript', 'varchar(255)', 'Column descript should be varchar(255)');
SELECT col_type_is('cat_link', 'link', 'varchar(512)', 'Column link should be varchar(512)');
SELECT col_type_is('cat_link', 'brand_id', 'varchar(30)', 'Column brand_id should be varchar(30)');
SELECT col_type_is('cat_link', 'model_id', 'varchar(30)', 'Column model_id should be varchar(30)');
SELECT col_type_is('cat_link', 'svg', 'varchar(50)', 'Column svg should be varchar(50)');
SELECT col_type_is('cat_link', 'z1', 'numeric(12,2)', 'Column z1 should be numeric(12,2)');
SELECT col_type_is('cat_link', 'z2', 'numeric(12,2)', 'Column z2 should be numeric(12,2)');
SELECT col_type_is('cat_link', 'width', 'numeric(12,2)', 'Column width should be numeric(12,2)');
SELECT col_type_is('cat_link', 'area', 'numeric(12,4)', 'Column area should be numeric(12,4)');
SELECT col_type_is('cat_link', 'estimated_depth', 'numeric(12,2)', 'Column estimated_depth should be numeric(12,2)');
SELECT col_type_is('cat_link', 'thickness', 'numeric(12,2)', 'Column thickness should be numeric(12,2)');
SELECT col_type_is('cat_link', 'cost_unit', 'varchar(3)', 'Column cost_unit should be varchar(3)');
SELECT col_type_is('cat_link', 'cost', 'varchar(16)', 'Column cost should be varchar(16)');
SELECT col_type_is('cat_link', 'm2bottom_cost', 'varchar(16)', 'Column m2bottom_cost should be varchar(16)');
SELECT col_type_is('cat_link', 'm3protec_cost', 'varchar(16)', 'Column m3protec_cost should be varchar(16)');
SELECT col_type_is('cat_link', 'active', 'bool', 'Column active should be bool');
SELECT col_type_is('cat_link', 'label', 'varchar(255)', 'Column label should be varchar(255)');
SELECT col_type_is('cat_link', 'tsect_id', 'varchar(16)', 'Column tsect_id should be varchar(16)');
SELECT col_type_is('cat_link', 'curve_id', 'varchar(16)', 'Column curve_id should be varchar(16)');
SELECT col_type_is('cat_link', 'acoeff', 'float8', 'Column acoeff should be float8');
SELECT col_type_is('cat_link', 'connect_cost', 'text', 'Column connect_cost should be text');
SELECT col_type_is('cat_link', 'visitability_vdef', 'int4', 'Column visitability_vdef should be int4');
SELECT col_type_is('cat_link', 'code', 'text', 'Column code should be text');

-- Check foreign keys
SELECT has_fk('cat_link', 'Table cat_link should have foreign keys');

SELECT fk_ok('cat_link', 'link_type', 'cat_feature_link', 'id', 'FK link_type → cat_feature_link.id');
SELECT fk_ok('cat_link', 'brand_id', 'cat_brand', 'id', 'FK brand_id → cat_brand.id');
SELECT fk_ok('cat_link', 'cost', 'plan_price', 'id', 'FK cost → plan_price.id');
SELECT fk_ok('cat_link', 'curve_id', 'inp_curve', 'id', 'FK curve_id → inp_curve.id');
SELECT fk_ok('cat_link', 'm2bottom_cost', 'plan_price', 'id', 'FK m2bottom_cost → plan_price.id');
SELECT fk_ok('cat_link', 'm3protec_cost', 'plan_price', 'id', 'FK m3protec_cost → plan_price.id');
SELECT fk_ok('cat_link', 'shape', 'cat_arc_shape', 'id', 'FK shape → cat_arc_shape.id');
SELECT fk_ok('cat_link', 'tsect_id', 'inp_transects', 'id', 'FK tsect_id → inp_transects.id');
SELECT fk_ok('cat_link', 'model_id', 'cat_brand_model', 'id', 'FK model_id → cat_brand_model.id');

-- Finish
SELECT * FROM finish();

ROLLBACK;
