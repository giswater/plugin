/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = "SCHEMA_NAME", public, pg_catalog;

INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('N/I', 'No information', '{NODE,ARC,CONNEC,ELEMENT,GULLY,LINK}', NULL, NULL, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('Concrete', 'Concrete', '{NODE,ARC,CONNEC,ELEMENT,GULLY,LINK}', NULL, 0.0140, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('Brick', 'Brick', '{NODE,ARC,CONNEC,GULLY,LINK}', NULL, 0.0140, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('PEAD', 'PEAD', '{NODE,ARC,CONNEC,GULLY,LINK}', NULL, 0.0110, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('PEC', 'PEC', '{ARC,CONNEC}', NULL, 0.0120, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('PVC', 'PVC', '{NODE,ARC,CONNEC,GULLY,LINK}', NULL, 0.0110, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('Virtual', 'Virtual', '{NODE,ARC,CONNEC,LINK}', NULL, 0.0120, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('FD', 'FD', '{NODE,ELEMENT,GULLY}', NULL, NULL, NULL, true);
INSERT INTO cat_material (id, descript, feature_type, featurecat_id, n, link, active) VALUES('Iron', 'Iron', '{NODE,ELEMENT,GULLY}', NULL, NULL, NULL, true);

INSERT INTO cat_element VALUES ('COVER70', 'ECOVER', 'FD', '70 cm', 'Cover iron Ø70cm', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL);
INSERT INTO cat_element VALUES ('COVER70X70', 'ECOVER', 'FD', '70x70cm', 'Cover iron 70x70cm', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL);
INSERT INTO cat_element VALUES ('STEP200', 'ESTEP', 'Iron', '20x20X20cm', 'Step iron 20x20cm', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL);
INSERT INTO cat_element VALUES ('PUMP_ABS', 'EPUMP', 'Iron', NULL, 'Model ABS AFP 1001 M300/4-43', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL);
INSERT INTO cat_element VALUES ('HYDROGEN SULFIDE SENSOR', 'EIOT_SENSOR', 'Iron', '10x10x10cm', 'Hydrogen sulfide sensor', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL);
INSERT INTO cat_element VALUES ('WEEL PROTECTOR', 'EPROTECTOR', 'Iron', '50x10x5cm', 'Weel protector', NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL);
INSERT INTO cat_element (id, element_type, matcat_id, geometry, descript, link, brand, "type", model, svg, active, geom1, geom2, isdoublegeom) VALUES('GATE-01', 'EGATE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, NULL, NULL, NULL);

INSERT INTO cat_arc VALUES ('SIPHON-CC100', 'SIPHON', NULL, 'CIRCULAR', 1.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 1.30, 0.7854, 2.20, 0.15, 'm', 'A_CON_DN100', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('WACCEL-CC020', 'WACCEL', NULL, 'CIRCULAR', 0.2000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.26, 0.0314, 1.40, 0.03, 'm', 'A_PVC_DN20', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('WEIR_60', 'VARC', NULL, 'VIRTUAL', 0.6000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Weir', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.78, 0.2827, 1.80, 0.09, 'm', 'A_WEIR_60', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('PUMP_01', 'VARC', NULL, 'VIRTUAL', 0.1800, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Pump', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.24, 0.0254, 1.38, 0.03, 'm', 'A_PRE_PE_DN20', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('CC100', 'CONDUIT', NULL, 'CIRCULAR', 1.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 1.30, 0.7854, 2.20, 0.15, 'm', 'A_CON_DN100', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('CC040', 'CONDUIT', NULL, 'CIRCULAR', 0.4000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.52, 0.1257, 1.60, 0.06, 'm', 'A_PVC_DN40', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('CC060', 'CONDUIT', NULL, 'CIRCULAR', 0.6000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.78, 0.2827, 1.80, 0.09, 'm', 'A_PVC_DN60', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('CC080', 'CONDUIT', NULL, 'CIRCULAR', 0.8000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 1.04, 0.5027, 2.00, 0.12, 'm', 'A_PVC_DN80', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('CC020', 'CONDUIT', NULL, 'CIRCULAR', 0.2000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.26, 0.0314, 1.40, 0.03, 'm', 'A_PVC_DN20', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('CC315', 'CONDUIT', NULL, 'CIRCULAR', 0.3150, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.42, 0.0920, 1.50, 0.06, 'm', 'A_PEC_DN315', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('EG150', 'CONDUIT', NULL, 'EGG', 1.5000, 1.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 1.15, 1.5000, 2.70, 0.22, 'm', 'A_CON_O150', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('RC150', 'CONDUIT', NULL, 'RECT_CLOSED', 1.5000, 1.5000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 1.94, 2.2500, 2.70, 0.22, 'm', 'A_CON_R150', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('RC200', 'SIPHON', NULL, 'RECT_CLOSED', 2.0000, 2.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Conduit', NULL, NULL, NULL, NULL, 0.10, 0.10, 2.60, 4.0000, 3.20, 0.30, 'm', 'A_CON_R200', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('PP020', 'PUMP_PIPE', NULL, 'FORCE_MAIN', 0.1800, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Pump pipe', NULL, NULL, NULL, NULL, 0.10, 0.10, 0.26, 0.0314, 1.40, 0.03, 'm', 'A_PRE_PE_DN20', 'S_REP', 'S_NULL', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);
INSERT INTO cat_arc VALUES ('VIRTUAL', 'VARC', NULL, 'VIRTUAL', 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, NULL, 'Virtual', NULL, NULL, NULL, NULL, 0.00, 0.00, 0.00, 0.0000, 0.00, 0.00, 'm', 'VIRTUAL_M', 'VIRTUAL_M2', 'VIRTUAL_M3', true, NULL, NULL, NULL, NULL, 'N_CONNECTION', NULL);

INSERT INTO cat_brand VALUES ('brand1', NULL, NULL, true, '{SIPHON, JUMP, VALVE, HIGHPOINT}');
INSERT INTO cat_brand VALUES ('brand2', NULL, NULL, true, '{CJOIN, GINLET, PGULLY, VGULLY}');
INSERT INTO cat_brand VALUES ('brand3', NULL, NULL, true, '{EPUMP, VALVE, REGISTER, HIGHPOINT, JUNCTION}');

INSERT INTO cat_brand_model VALUES ('model1', 'brand1', NULL, NULL, true, '{SIPHON, JUMP, VALVE}');
INSERT INTO cat_brand_model VALUES ('model2', 'brand1', NULL, NULL, true, '{CJOIN, GINLET, PGULLY, VGULLY}');
INSERT INTO cat_brand_model VALUES ('model3', 'brand2', NULL, NULL, true, '{SIPHON, HIGHPOINT}');
INSERT INTO cat_brand_model VALUES ('model4', 'brand2', NULL, NULL, true, '{REGISTER, HIGHPOINT, JUNCTION}');
INSERT INTO cat_brand_model VALUES ('model5', 'brand3', NULL, NULL, true, '{CJOIN, GINLET}');
INSERT INTO cat_brand_model VALUES ('model6', 'brand3', NULL, NULL, true, '{EPUMP, VALVE, REGISTER}');

INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('PVC-CC025_D', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CON-CC040_I', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('PVC-CC025_T', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('PVC-CC030_D', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CON-CC020_D', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CON-CC030_D', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('VIRTUAL', 'VLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CC025_D', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CC040_I', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CC025_T', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CC030_D', 'CONDUITLINK', NULL, true);
INSERT INTO cat_link (id, link_type, matcat_id, active) VALUES ('CC020_D', 'CONDUITLINK', NULL, true);

INSERT INTO cat_feature (id, feature_class, feature_type, parent_layer, child_layer, active) VALUES ('SAMPLEPOINT', 'SAMPLEPOINT','CONNEC', 've_connec', 've_connec_samplepoint', true) ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_connec (id, connec_type, matcat_id, shape, geom1, geom2, geom3, geom4, geom_r, descript, link, brand_id, model_id, svg, active, "label", estimated_depth)
VALUES('DIRECT-CONNECTION', 'CJOIN', NULL, 'CIRCULAR', 0.2000, 0.0000, 0.0000, 0.0000, NULL, 'Connec', NULL, NULL, NULL, NULL, true, NULL, NULL);
INSERT INTO cat_connec (id, connec_type, matcat_id, shape, geom1, geom2, geom3, geom4, geom_r, descript, link, brand_id, model_id, svg, active, "label", estimated_depth)
VALUES('INSPECTION-CHAMBER', 'CJOIN', NULL, 'CIRCULAR', 0.2000, 0.0000, 0.0000, 0.0000, NULL, 'Connec', NULL, NULL, NULL, NULL, true, NULL, NULL);
INSERT INTO cat_connec (id, connec_type, matcat_id, shape, geom1, geom2, geom3, geom4, geom_r, descript, link, brand_id, model_id, svg, active, "label", estimated_depth)
VALUES('GREASE-TRAP', 'CJOIN', NULL, 'CIRCULAR', 0.2000, 0.0000, 0.0000, 0.0000, NULL, 'Connec', NULL, NULL, NULL, NULL, true, NULL, NULL);
INSERT INTO cat_connec (id, connec_type, matcat_id, shape, geom1, geom2, geom3, geom4, geom_r, descript, link, brand_id, model_id, svg, active, "label", estimated_depth)
VALUES('SAMPLING-CHAMBER', 'CJOIN', NULL, 'CIRCULAR', 0.2000, 0.0000, 0.0000, 0.0000, NULL, 'Connec', NULL, NULL, NULL, NULL, true, NULL, NULL);
INSERT INTO cat_connec (id, connec_type, matcat_id, shape, geom1, geom2, geom3, geom4, geom_r, descript, link, brand_id, model_id, svg, active, "label", estimated_depth)
VALUES ('VIRTUAL', 'VCONNEC', NULL, 'VIRTUAL', 0.3000, 0.0000, 0.0000, 0.0000, NULL, 'Virtual connec', NULL, NULL, NULL, NULL, true, NULL, NULL);
INSERT INTO cat_connec (id, connec_type, matcat_id, shape, geom1, geom2, geom3, geom4, geom_r, descript, link, brand_id, model_id, svg, active, "label", estimated_depth)
VALUES ('SAMPLEPOINT', 'SAMPLEPOINT', NULL, 'CIRCULAR', 0.2500, 0.0000, 0.0000, 0.0000, NULL, 'Samplepoint', NULL, NULL, NULL, NULL, true, NULL, NULL);


INSERT INTO cat_node VALUES ('CHAMBER-01', 'CHAMBER', NULL, NULL, 3.00, 2.50, 3.00, 'Chamber 3x2.5x3m', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_CH300x250-H300', true, NULL, NULL);
INSERT INTO cat_node VALUES ('HIGH POINT-01', 'HIGHPOINT', NULL, NULL, 1.00, 1.00, NULL, 'High point', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD80-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('JUMP-01', 'JUMP', NULL, NULL, 1.00, 1.00, NULL, 'Circular jump manhole ø100cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_JUMP100', true, NULL, NULL);
INSERT INTO cat_node VALUES ('NETGULLY-01', 'NETGULLY', NULL, NULL, 1.00, 1.00, NULL, 'Network gully', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD80-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('SEW_STORAGE-01', 'SEWER_STORAGE', NULL, NULL, 5.00, 3.50, 4.75, 'Sewer storage 5x3.5x4.5m', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_STR500x350x475', true, NULL, NULL);
INSERT INTO cat_node VALUES ('VALVE-01', 'VALVE', NULL, NULL, 1.00, 1.00, NULL, 'Network valve', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_VAL_01', true, NULL, NULL);
INSERT INTO cat_node VALUES ('WEIR-01', 'WEIR', NULL, NULL, 1.50, 2.00, NULL, 'Rectangular weir 150x200cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'A_WEIR_60', true, NULL, NULL);
INSERT INTO cat_node VALUES ('NETINIT-01', 'NETINIT', NULL, NULL, 1.00, 1.00, NULL, 'Network init', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('NETELEMENT-01', 'NETELEMENT', NULL, NULL, 1.00, 1.00, NULL, 'Netelement rectangular', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('JUNCTION-01', 'JUNCTION', NULL, NULL, 1.00, 1.00, NULL, 'Juntion', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('OUTFALL-01', 'OUTFALL', NULL, NULL, 2.00, 1.00, NULL, 'Outfall', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('NODE-01', 'VIRTUAL_NODE', NULL, NULL, 1.00, 1.00, NULL, 'Virtual node', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD80-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('VIR_NODE-01', 'VIRTUAL_NODE', NULL, NULL, 1.00, 1.00, NULL, 'Virtual node', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD80-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('WWTP-01', 'WWTP', NULL, NULL, 1.00, 1.00, NULL, 'Wastewater treatment plant', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRQ150-H250', true, NULL, NULL);
INSERT INTO cat_node VALUES ('C_MANHOLE_100', 'CIRC_MANHOLE', NULL, NULL, 1.00, 1.00, NULL, 'Circular manhole ø100cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('C_MANHOLE_80', 'CIRC_MANHOLE', NULL, NULL, 0.80, 1.00, NULL, 'Circular manhole ø80cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD80-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('R_MANHOLE_100', 'RECT_MANHOLE', NULL, NULL, 1.00, 1.00, NULL, 'Rectangular manhole 100x100cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRQ100-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('R_MANHOLE_150', 'RECT_MANHOLE', NULL, NULL, 1.50, 1.50, NULL, 'Rectangular manhole 150x150cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRQ150-H250', true, NULL, NULL);
INSERT INTO cat_node VALUES ('R_MANHOLE_200', 'RECT_MANHOLE', NULL, NULL, 2.00, 2.00, NULL, 'Rectangular manhole 200x200cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRQ200-H250', true, NULL, NULL);

INSERT INTO cat_owner VALUES ('owner1', NULL, NULL, true);
INSERT INTO cat_owner VALUES ('owner2', NULL, NULL, true);
INSERT INTO cat_owner VALUES ('owner3', NULL, NULL, true);

INSERT INTO cat_pavement VALUES ('Asphalt', NULL, NULL, 0.10, 'P_ASPHALT-10', true);
INSERT INTO cat_pavement VALUES ('pavement1', NULL, NULL, 0.10, 'P_ASPHALT-10', true);
INSERT INTO cat_pavement VALUES ('pavement2', NULL, NULL, 0.10, 'P_ASPHALT-10', true);

INSERT INTO cat_soil VALUES ('soil1', 'soil 1', NULL, 7.00, 0.25, 0.60, 'S_EXC', 'S_REB', 'S_TRANS', 'S_TRENCH', true);
INSERT INTO cat_soil VALUES ('soil2', 'soil 2', NULL, 7.00, 0.20, 0.25, 'S_EXC', 'S_REB', 'S_TRANS', 'S_TRENCH', true);
INSERT INTO cat_soil VALUES ('soil3', 'soil 3', NULL, 5.00, 0.20, 0.00, 'S_EXC', 'S_REB', 'S_TRANS', 'S_TRENCH', true);

INSERT INTO cat_work VALUES ('work1', NULL, NULL, NULL, NULL, NULL, NULL, true);
INSERT INTO cat_work VALUES ('work2', NULL, NULL, NULL, NULL, NULL, NULL, true);
INSERT INTO cat_work VALUES ('work3', NULL, NULL, NULL, NULL, NULL, NULL, true);
INSERT INTO cat_work VALUES ('work4', NULL, NULL, NULL, NULL, NULL, NULL, true);

INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('SGRT3', 'GINLET', 'FD', 64.0000, 30.0000, 693.0000/1920.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('SGRT6', 'GINLET', 'FD', 56.5000, 29.5000, 725.0000/1667.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('BGRT4', 'GINLET', 'FD', 12.4000, 100.0000, 582.4000/1240.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('SGRT1', 'GINLET', 'FD', 78.0000, 36.4000, 1214.0000/2839.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('SGRT2', 'GINLET', 'FD', 78.0000, 34.1000, 873.0000/2659.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('SGRT5', 'GINLET', 'FD', 97.5000, 47.5000, 1400.0000/4825.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('SGRT7', 'GINLET', 'FD', 50.0000, 25.0000, 400.0000/860.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('BGRT1', 'GINLET', 'Iron', 32.5000, 100.0000, 1112.4000/3020.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('BGRT5', 'GINLET', 'FD', 47.5000, 100.0000, 1400.0000/4825.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('SGRT4', 'GINLET', 'FD', 77.6000, 34.5000, 1050.0000/2677.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('BGRT2', 'GINLET', 'FD', 19.5000, 100.0000, 751.9000/1950.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('BGRT3', 'GINLET', 'FD', 10.0000, 100.0000, 397.4000/1140.0000, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('N/I', 'GINLET', 'N/I', 0.0000, 0.0000, NULL, true);
INSERT INTO cat_gully (id, gully_type, matcat_id, length, width, efficiency, active) VALUES ('VGULLY', 'VGULLY', 'FD', 10.0000, 100.0000, 397.4000/1140.0000, true);

-----------------------------
-- Records of man_type_category
-- ----------------------------
INSERT INTO man_type_category VALUES ('St. Category', '{NODE, ARC, CONNEC, ELEMENT, GULLY}', NULL, NULL, true);

-- ----------------------------
-- Records of man_type_location
-- ----------------------------
INSERT INTO man_type_location VALUES ('St. Location', '{NODE, ARC, CONNEC, ELEMENT, GULLY}', NULL, NULL, true);

-- ----------------------------
-- Records of man_type_function
-- ----------------------------
INSERT INTO man_type_function VALUES ('St. Function', '{NODE, ARC, CONNEC, ELEMENT, GULLY}', NULL, NULL, true);

-- ----------------------------
-- Update shortcuts
-- ----------------------------

UPDATE cat_feature SET shortcut_key=NULL;

UPDATE cat_feature SET shortcut_key='B' WHERE id = 'CHAMBER';
UPDATE cat_feature SET shortcut_key='E' WHERE id = 'CHANGE';
UPDATE cat_feature SET shortcut_key='M' WHERE id = 'CIRC_MANHOLE';
UPDATE cat_feature SET shortcut_key='Alt+X' WHERE id = 'CONDUIT';
UPDATE cat_feature SET shortcut_key='Alt+C' WHERE id = 'CONNEC';
UPDATE cat_feature SET shortcut_key='Alt+M' WHERE id = 'GULLY';
UPDATE cat_feature SET shortcut_key='H' WHERE id = 'HIGHPOINT';
UPDATE cat_feature SET shortcut_key='J' WHERE id = 'JUMP';
UPDATE cat_feature SET shortcut_key='N' WHERE id = 'JUNCTION';
UPDATE cat_feature SET shortcut_key='A' WHERE id = 'NETELEMENT';
UPDATE cat_feature SET shortcut_key='Y' WHERE id = 'NETGULLY';
UPDATE cat_feature SET shortcut_key='I' WHERE id = 'NETINIT';
UPDATE cat_feature SET shortcut_key='O' WHERE id = 'OUTFALL';
UPDATE cat_feature SET shortcut_key='G' WHERE id = 'OVERFLOW_STORAGE';
UPDATE cat_feature SET shortcut_key='Alt+K' WHERE id = 'PGULLY';
UPDATE cat_feature SET shortcut_key='Alt+U' WHERE id = 'PUMP_PIPE';
UPDATE cat_feature SET shortcut_key='P' WHERE id = 'PUMP_STATION';
UPDATE cat_feature SET shortcut_key='R' WHERE id = 'RECT_MANHOLE';
UPDATE cat_feature SET shortcut_key='U' WHERE id = 'REGISTER';
UPDATE cat_feature SET shortcut_key='X' WHERE id = 'SANDBOX';
UPDATE cat_feature SET shortcut_key='L' WHERE id = 'SEWER_STORAGE';
UPDATE cat_feature SET shortcut_key='Alt+B' WHERE id = 'SIPHON';
UPDATE cat_feature SET shortcut_key='V' WHERE id = 'VALVE';
UPDATE cat_feature SET shortcut_key='Alt+Q' WHERE id = 'VARC';
UPDATE cat_feature SET shortcut_key='Q' WHERE id = 'VIRTUAL_NODE';
UPDATE cat_feature SET shortcut_key='Alt+G' WHERE id = 'WACCEL';
UPDATE cat_feature SET shortcut_key='F' WHERE id = 'WEIR';
UPDATE cat_feature SET shortcut_key='W' WHERE id = 'WWTP';
UPDATE cat_feature SET shortcut_key='Alt+N' WHERE id = 'EMBORNAL_FICTICI';
UPDATE cat_feature SET shortcut_key='Alt+Z' WHERE id = 'ESCOMESA_FICTICIA';
UPDATE cat_feature SET shortcut_key='Alt+1' WHERE id = 'VGULLY';
UPDATE cat_feature SET shortcut_key='Alt+2' WHERE id = 'VCONNEC';

INSERT INTO cat_feature (id, feature_class, feature_type, parent_layer, child_layer, active) VALUES ('EORIFICE', 'FRELEM','ELEMENT', 've_element', 've_element_orifice', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO cat_feature (id, feature_class, feature_type, parent_layer, child_layer, active) VALUES ('EOUTLET', 'FRELEM','ELEMENT', 've_element', 've_element_outlet', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO cat_feature (id, feature_class, feature_type, parent_layer, child_layer, active) VALUES ('EWEIR', 'FRELEM','ELEMENT', 've_element', 've_element_eweir', true) ON CONFLICT (id) DO NOTHING;
INSERT INTO cat_feature (id, feature_class, feature_type, parent_layer, child_layer, active) VALUES ('EPUMP', 'FRELEM','ELEMENT', 've_element', 've_element_pump', true) ON CONFLICT (id) DO NOTHING;

UPDATE cat_feature_node SET epa_default='OUTFALL', num_arcs=1, isexitupperintro=2, graph_delimiter='{DWFZONE}' WHERE id='OUT_MANHOLE';

UPDATE cat_feature_element SET epa_default='FRPUMP' WHERE id = 'EPUMP';
UPDATE cat_feature_element SET epa_default='FRWEIR' WHERE id = 'EWEIR';
UPDATE cat_feature_element SET epa_default='FRORIFICE' WHERE id = 'EORIFICE';
UPDATE cat_feature_element SET epa_default='FROUTLET' WHERE id = 'EOUTLET';

INSERT INTO cat_element (id, element_type, active) VALUES ('ORIFICE-01', 'EORIFICE', TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO cat_element (id, element_type, active) VALUES ('OUTLET-01', 'EOUTLET', TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO cat_element (id, element_type, active) VALUES ('WEIR-01', 'EWEIR', TRUE) ON CONFLICT (id) DO NOTHING;
INSERT INTO cat_element (id, element_type, active) VALUES ('PUMP-01', 'EPUMP', TRUE) ON CONFLICT (id) DO NOTHING;

UPDATE cat_link SET link_type='VLINK' WHERE id='VIRTUAL';

INSERT INTO cat_node VALUES ('C_OUTMANHOLE_100', 'OUT_MANHOLE', NULL, NULL, 1.00, 1.00, NULL, 'Out manhole ø100cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD100-H160', true, NULL, NULL);
INSERT INTO cat_node VALUES ('C_OUTMANHOLE_80', 'OUT_MANHOLE', NULL, NULL, 0.80, 1.00, NULL, 'Out manhole ø80cm', NULL, NULL, NULL, NULL, 2.00, 'u', 'N_PRD80-H160', true, NULL, NULL);
