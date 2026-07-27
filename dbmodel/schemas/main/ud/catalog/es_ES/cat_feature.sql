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
('CAJON', 'RECT_CLOSED'),
('FORZADA', 'FORCE_MAIN'),
('CIRCULAR', 'CIRCULAR'),
('VIRTUAL', 'VIRTUAL')
ON CONFLICT (id) DO UPDATE SET epa = EXCLUDED.epa;

INSERT INTO cat_feature (id, feature_class, feature_type, active, parent_layer, child_layer) VALUES
('ARQUETA', 'JUNCTION', 'NODE', FALSE, 've_node', 've_node_arqueta'),
('CAMARA', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_camara'),
('TANQUE', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_tanque'),
('VERTIDO', 'OUTFALL', 'NODE', TRUE, 've_node', 've_node_vertido'),
('EDAR', 'WWTP', 'NODE', TRUE, 've_node', 've_node_edar'),
('INICIO', 'NETINIT', 'NODE', TRUE, 've_node', 've_node_inicio'),
('UNION', 'JUNCTION', 'NODE', TRUE, 've_node', 've_node_union'),
('POZO', 'MANHOLE', 'NODE', TRUE, 've_node', 've_node_pozo'),
('ALIVIADERO', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_aliviadero'),
('FOSASEP', 'CHAMBER', 'NODE', TRUE, 've_node', 've_node_fosasep'),
('SALTO', 'WJUMP', 'NODE', FALSE, 've_node', 've_node_salto'),
('TRAMO', 'CONDUIT', 'ARC', TRUE, 've_arc', 've_arc_tramo'),
('IMPULSION', 'CONDUIT', 'ARC', TRUE, 've_arc', 've_arc_impulsion'),
('TRAMOV', 'VARC', 'ARC', FALSE, 've_arc', 've_arc_tramov'),
('ACOMETIDA', 'CJOIN', 'CONNEC', TRUE, 've_connec', 've_connec_acometida'),
('ACOMETIDAV', 'VCONNEC', 'CONNEC', FALSE, 've_connec', 've_connec_acometidav'),
('SUMIDERO', 'GINLET', 'GULLY', TRUE, 've_gully', 've_gully_sumidero'),
('REJA', 'GINLET', 'GULLY', TRUE, 've_gully', 've_gully_reja'),
('CONEXION', 'CONDUITLINK', 'LINK', TRUE, 've_link', 've_link_conexion'),
('CONEXIONV', 'VLINK', 'LINK', FALSE, 've_link', 've_link_conexionv'),
('TAPA', 'GENELEM', 'ELEMENT', TRUE, 've_element', 've_element_tapa'),
('EPUMP', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_epump'),
('EWEIR', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_eweir'),
('EORIFICE', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_eorifice'),
('EOUTLET', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_eoutlet')
ON CONFLICT (id) DO UPDATE SET feature_class = EXCLUDED.feature_class, feature_type = EXCLUDED.feature_type, active = EXCLUDED.active, parent_layer = EXCLUDED.parent_layer, child_layer = EXCLUDED.child_layer;

INSERT INTO cat_feature_node (id, epa_default, isarcdivide, graph_delimiter) VALUES
('ARQUETA', 'JUNCTION', TRUE, '{NONE}'),
('CAMARA', 'STORAGE', TRUE, '{NONE}'),
('TANQUE', 'STORAGE', TRUE, '{NONE}'),
('VERTIDO', 'OUTFALL', TRUE, '{DWFZONE}'),
('EDAR', 'JUNCTION', TRUE, '{DWFZONE}'),
('INICIO', 'JUNCTION', TRUE, '{NONE}'),
('UNION', 'JUNCTION', TRUE, '{NONE}'),
('POZO', 'JUNCTION', TRUE, '{OMUNIT}'),
('ALIVIADERO', 'JUNCTION', TRUE, '{NONE}'),
('FOSASEP', 'STORAGE', TRUE, '{NONE}'),
('SALTO', 'JUNCTION', TRUE, '{NONE}')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default, isarcdivide = EXCLUDED.isarcdivide, graph_delimiter = EXCLUDED.graph_delimiter;

INSERT INTO cat_feature_arc (id, epa_default) VALUES
('TRAMO', 'CONDUIT'),
('IMPULSION', 'CONDUIT'),
('TRAMOV', 'CONDUIT')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_connec (id) VALUES
('ACOMETIDA'),
('ACOMETIDAV')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_feature_link (id) VALUES
('CONEXION'),
('CONEXIONV')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_feature_gully (id, epa_default) VALUES
('SUMIDERO', 'GULLY'),
('REJA', 'GULLY')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_element (id, epa_default) VALUES
('TAPA', 'UNDEFINED'),
('EPUMP', 'FRPUMP'),
('EWEIR', 'FRWEIR'),
('EORIFICE', 'FRORIFICE'),
('EOUTLET', 'FROUTLET')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_node (id, node_type) VALUES
('ARQUETA', 'ARQUETA'),
('CAMARA', 'CAMARA'),
('TANQUE', 'TANQUE'),
('VERTIDO', 'VERTIDO'),
('EDAR', 'EDAR'),
('INICIO', 'INICIO'),
('UNION', 'UNION'),
('POZO', 'POZO'),
('ALIVIADERO', 'ALIVIADERO'),
('FOSASEP', 'FOSASEP'),
('SALTO', 'SALTO')
ON CONFLICT (id) DO UPDATE SET node_type = EXCLUDED.node_type;

INSERT INTO cat_arc (id, arc_type, shape, geom1, geom2) VALUES
('CC315', 'TRAMO', 'CIRCULAR', 0.315, NULL),
('CC40', 'TRAMO', 'CIRCULAR', 0.4, NULL),
('CC50', 'TRAMO', 'CIRCULAR', 0.5, NULL),
('CC60', 'TRAMO', 'CIRCULAR', 0.6, NULL),
('CC70', 'TRAMO', 'CIRCULAR', 0.7, NULL),
('CC80', 'TRAMO', 'CIRCULAR', 0.8, NULL),
('CC100', 'TRAMO', 'CIRCULAR', 1, NULL),
('CC120', 'TRAMO', 'CIRCULAR', 1.2, NULL),
('RC150X200', 'TRAMO', 'CAJON', 1.5, 2),
('RC200X200', 'TRAMO', 'CAJON', 2, 2),
('IMPULSION200', 'IMPULSION', 'FORZADA', NULL, NULL),
('TRAMOV', 'TRAMOV', 'VIRTUAL', 0, NULL)
ON CONFLICT (id) DO UPDATE SET arc_type = EXCLUDED.arc_type, shape = EXCLUDED.shape, geom1 = EXCLUDED.geom1, geom2 = EXCLUDED.geom2;

INSERT INTO cat_connec (id, connec_type) VALUES
('DIRECTA', 'ACOMETIDA'),
('REGISTRO', 'ACOMETIDA'),
('SGRASAS', 'ACOMETIDA'),
('TMUESTRA', 'ACOMETIDA'),
('ACOMETIDAV', 'ACOMETIDAV')
ON CONFLICT (id) DO UPDATE SET connec_type = EXCLUDED.connec_type;

INSERT INTO cat_link (id, link_type) VALUES
('CC15', 'CONEXION'),
('CC20', 'CONEXION'),
('CC25', 'CONEXION'),
('CC30', 'CONEXION'),
('CC40', 'CONEXION'),
('CONEXIONV', 'CONEXIONV')
ON CONFLICT (id) DO UPDATE SET link_type = EXCLUDED.link_type;

INSERT INTO cat_gully (id, gully_type, matcat_id) VALUES
('SU100X30', 'SUMIDERO', 'FE'),
('REJA50', 'REJA', 'FD')
ON CONFLICT (id) DO UPDATE SET gully_type = EXCLUDED.gully_type, matcat_id = EXCLUDED.matcat_id;

INSERT INTO cat_element (id, element_type, matcat_id) VALUES
('TAPAD80', 'TAPA', 'FD'),
('TAPAD100', 'TAPA', 'FD')
ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, matcat_id = EXCLUDED.matcat_id;

ALTER TABLE cat_feature ENABLE TRIGGER gw_trg_cat_feature_after;

