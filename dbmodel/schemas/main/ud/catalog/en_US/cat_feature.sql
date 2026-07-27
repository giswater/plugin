/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = "SCHEMA_NAME", public, pg_catalog;

-- Replace catalog seeded by updates with locale-specific naming conventions.

DELETE FROM cat_element;
DELETE FROM cat_gully;
DELETE FROM cat_link;
DELETE FROM cat_connec;
DELETE FROM cat_arc;
DELETE FROM cat_node;
DELETE FROM cat_feature_element;
DELETE FROM cat_feature_gully;
DELETE FROM cat_feature_link;
DELETE FROM cat_feature_connec;
DELETE FROM cat_feature_arc;
DELETE FROM cat_feature_node;
DELETE FROM cat_feature;

DELETE FROM cat_material;
DELETE FROM cat_arc_shape;


-- Legacy _type columns exist until lastprocess; disable trigger for explicit catalog seed.
ALTER TABLE cat_feature_arc DROP COLUMN IF EXISTS _type;
ALTER TABLE cat_feature_node DROP COLUMN IF EXISTS _type;
ALTER TABLE cat_feature_connec DROP COLUMN IF EXISTS _type;
ALTER TABLE cat_feature_gully DROP COLUMN IF EXISTS _type;

ALTER TABLE cat_feature DISABLE TRIGGER gw_trg_cat_feature_after;

INSERT INTO cat_material (id, descript) VALUES 
('FE', 'Iron'),
('FD', 'Fundición dúctil'),
('FG', 'Fundición gris'),
('PE', 'Polietileno'),
('PVC', 'PVC'),
('FC', 'Fibrocemento'),
('DESC', 'Desconocido'),
('HOR', 'Hormigón'),
('ACER', 'Acero')
ON CONFLICT (id) DO UPDATE SET descript = EXCLUDED.descript;

INSERT INTO cat_arc_shape (id, epa) VALUES
('RECT_CLOSED', 'RECT_CLOSED'),
('FORCE_MAIN', 'FORCE_MAIN'),
('CIRCULAR', 'CIRCULAR'),
('VIRTUAL', 'VIRTUAL')
ON CONFLICT (id) DO UPDATE SET epa = EXCLUDED.epa;

INSERT INTO cat_feature (id, feature_class, feature_type, active, parent_layer, child_layer) VALUES
('REGISTER', 'JUNCTION', 'NODE', FALSE, 've_node', 've_node_register'),
('CHAMBER', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_chamber'),
('STORAGE', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_storage'),
('OUTFALL', 'OUTFALL', 'NODE', TRUE, 've_node', 've_node_outfall'),
('WWTP', 'WWTP', 'NODE', TRUE, 've_node', 've_node_wwtp'),
('NETINIT', 'NETINIT', 'NODE', TRUE, 've_node', 've_node_netinit'),
('JUNCTION', 'JUNCTION', 'NODE', TRUE, 've_node', 've_node_junction'),
('MANHOLE', 'MANHOLE', 'NODE', TRUE, 've_node', 've_node_manhole'),
('WEIR', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_weir'),
('SEPTICTANK', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_septictank'),
('WJUMP', 'WJUMP', 'NODE', FALSE, 've_node', 've_node_wjump'),
('CONDUIT', 'CONDUIT', 'ARC', TRUE, 've_arc', 've_arc_conduit'),
('FORCEMAIN', 'CONDUIT', 'ARC', TRUE, 've_arc', 've_arc_forcemain'),
('VARC', 'VARC', 'ARC', FALSE, 've_arc', 've_arc_varc'),
('SERVCON', 'CJOIN', 'CONNEC', TRUE, 've_connec', 've_connec_servcon'),
('VSERVCON', 'VCONNEC', 'CONNEC', FALSE, 've_connec', 've_connec_vservcon'),
('GULLY', 'GINLET', 'GULLY', TRUE, 've_gully', 've_gully_gully'),
('GRATE', 'GINLET', 'GULLY', TRUE, 've_gully', 've_gully_grate'),
('CONDLINK', 'CONDUITLINK', 'LINK', TRUE, 've_link', 've_link_condlink'),
('VLINK', 'VLINK', 'LINK', FALSE, 've_link', 've_link_vlink'),
('COVER', 'GENELEM', 'ELEMENT', TRUE, 've_element', 've_element_cover'),
('EPUMP', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_epump'),
('EWEIR', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_eweir'),
('EORIFICE', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_eorifice'),
('EOUTLET', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_eoutlet')
ON CONFLICT (id) DO UPDATE SET feature_class = EXCLUDED.feature_class, feature_type = EXCLUDED.feature_type, active = EXCLUDED.active, parent_layer = EXCLUDED.parent_layer, child_layer = EXCLUDED.child_layer;

INSERT INTO cat_feature_node (id, epa_default, isarcdivide, graph_delimiter) VALUES
('REGISTER', 'JUNCTION', TRUE, '{NONE}'),
('CHAMBER', 'STORAGE', TRUE, '{NONE}'),
('STORAGE', 'STORAGE', TRUE, '{NONE}'),
('OUTFALL', 'OUTFALL', TRUE, '{DWFZONE}'),
('WWTP', 'JUNCTION', TRUE, '{DWFZONE}'),
('NETINIT', 'JUNCTION', TRUE, '{NONE}'),
('JUNCTION', 'JUNCTION', TRUE, '{NONE}'),
('MANHOLE', 'JUNCTION', TRUE, '{OMUNIT}'),
('WEIR', 'JUNCTION', TRUE, '{NONE}'),
('SEPTICTANK', 'STORAGE', TRUE, '{NONE}'),
('WJUMP', 'JUNCTION', TRUE, '{NONE}')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default, isarcdivide = EXCLUDED.isarcdivide, graph_delimiter = EXCLUDED.graph_delimiter;

INSERT INTO cat_feature_arc (id, epa_default) VALUES
('CONDUIT', 'CONDUIT'),
('FORCEMAIN', 'CONDUIT'),
('VARC', 'CONDUIT')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_connec (id) VALUES
('SERVCON'),
('VSERVCON')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_feature_link (id) VALUES
('CONDLINK'),
('VLINK')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_feature_gully (id, epa_default) VALUES
('GULLY', 'GULLY'),
('GRATE', 'GULLY')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_element (id, epa_default) VALUES
('COVER', 'UNDEFINED'),
('EPUMP', 'FRPUMP'),
('EWEIR', 'FRWEIR'),
('EORIFICE', 'FRORIFICE'),
('EOUTLET', 'FROUTLET')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_node (id, node_type) VALUES
('REGISTER', 'REGISTER'),
('CHAMBER', 'CHAMBER'),
('STORAGE', 'STORAGE'),
('OUTFALL', 'OUTFALL'),
('WWTP', 'WWTP'),
('NETINIT', 'NETINIT'),
('JUNCTION', 'JUNCTION'),
('MANHOLE', 'MANHOLE'),
('WEIR', 'WEIR'),
('SEPTICTANK', 'SEPTICTANK'),
('WJUMP', 'WJUMP')
ON CONFLICT (id) DO UPDATE SET node_type = EXCLUDED.node_type;

INSERT INTO cat_arc (id, arc_type, shape, geom1, geom2) VALUES
('CC315', 'CONDUIT', 'CIRCULAR', 0.315, NULL),
('CC40', 'CONDUIT', 'CIRCULAR', 0.4, NULL),
('CC50', 'CONDUIT', 'CIRCULAR', 0.5, NULL),
('CC60', 'CONDUIT', 'CIRCULAR', 0.6, NULL),
('CC70', 'CONDUIT', 'CIRCULAR', 0.7, NULL),
('CC80', 'CONDUIT', 'CIRCULAR', 0.8, NULL),
('CC100', 'CONDUIT', 'CIRCULAR', 1, NULL),
('CC120', 'CONDUIT', 'CIRCULAR', 1.2, NULL),
('RC150X200', 'CONDUIT', 'RECT_CLOSED', 1.5, 2),
('RC200X200', 'CONDUIT', 'RECT_CLOSED', 2, 2),
('FORCEMAIN200', 'FORCEMAIN', 'FORCE_MAIN', NULL, NULL),
('VARC', 'VARC', 'VIRTUAL', 0, NULL)
ON CONFLICT (id) DO UPDATE SET arc_type = EXCLUDED.arc_type, shape = EXCLUDED.shape, geom1 = EXCLUDED.geom1, geom2 = EXCLUDED.geom2;

INSERT INTO cat_connec (id, connec_type) VALUES
('DIRECTCON', 'SERVCON'),
('REGISTER', 'SERVCON'),
('FOGSEP', 'SERVCON'),
('SAMPLING', 'SERVCON'),
('VSERVCON', 'VSERVCON')
ON CONFLICT (id) DO UPDATE SET connec_type = EXCLUDED.connec_type;

INSERT INTO cat_link (id, link_type) VALUES
('CC15', 'CONDLINK'),
('CC20', 'CONDLINK'),
('CC25', 'CONDLINK'),
('CC30', 'CONDLINK'),
('CC40', 'CONDLINK'),
('VILINK', 'VLINK')
ON CONFLICT (id) DO UPDATE SET link_type = EXCLUDED.link_type;

INSERT INTO cat_gully (id, gully_type, matcat_id) VALUES
('GU100X30', 'GULLY', 'FE'),
('GRATE50', 'GRATE', 'FD')
ON CONFLICT (id) DO UPDATE SET gully_type = EXCLUDED.gully_type, matcat_id = EXCLUDED.matcat_id;

INSERT INTO cat_element (id, element_type, matcat_id) VALUES
('COVERD80', 'COVER', 'FD'),
('COVERD100', 'COVER', 'FD')
ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, matcat_id = EXCLUDED.matcat_id;

ALTER TABLE cat_feature ENABLE TRIGGER gw_trg_cat_feature_after;

