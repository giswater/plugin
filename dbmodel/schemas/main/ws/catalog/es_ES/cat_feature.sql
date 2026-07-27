/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = "SCHEMA_NAME", public, pg_catalog;

-- Replace catalog seeded by updates with locale-specific naming conventions.

DELETE FROM cat_element;
DELETE FROM cat_link;
DELETE FROM cat_connec;
DELETE FROM cat_arc;
DELETE FROM cat_node;
DELETE FROM cat_feature_element;
DELETE FROM cat_feature_link;
DELETE FROM cat_feature_connec;
DELETE FROM cat_feature_arc;
DELETE FROM cat_feature_node;
DELETE FROM cat_feature;

DELETE FROM cat_material;

-- Legacy _type columns exist until lastprocess; disable trigger for explicit catalog seed.
ALTER TABLE cat_feature_arc DROP COLUMN IF EXISTS _type;
ALTER TABLE cat_feature_node DROP COLUMN IF EXISTS _type;
ALTER TABLE cat_feature_connec DROP COLUMN IF EXISTS _type;

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

INSERT INTO cat_feature (id, feature_class, feature_type, active, parent_layer, child_layer) VALUES
('VANTIRET', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vantiret'),
('VVENTOSA', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vventosa'),
('VREGQ', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vregq'),
('VRED', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vred'),
('VDESC', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vdesc'),
('VCOMP', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vcomp'),
('VSOST', 'VALVE', 'NODE', TRUE, 've_node', 've_node_vost'),
('REDUC', 'REDUCTION', 'NODE', TRUE, 've_node', 've_node_reduc'),
('HIDRANTE', 'HYDRANT', 'NODE', TRUE, 've_node', 've_node_hidrante'),
('ACORED', 'NETWJOIN', 'NODE', FALSE, 've_node', 've_node_acored'),
('FINAL', 'JUNCTION', 'NODE', FALSE, 've_node', 've_node_final'),
('POZO', 'WATERWELL', 'NODE', FALSE, 've_node', 've_node_pozo'),
('ETAP', 'WTP', 'NODE', TRUE, 've_node', 've_node_etap'),
('UNION', 'JUNCTION', 'NODE', TRUE, 've_node', 've_node_union'),
('CAPTACION', 'SOURCE', 'NODE', FALSE, 've_node', 've_node_captacion'),
('FILTRO', 'FILTER', 'NODE', FALSE, 've_node', 've_node_filtro'),
('BRIEGORED', 'NETWJOIN', 'NODE', FALSE, 've_node', 've_node_briego'),
('BOMBEO', 'PUMP', 'NODE', TRUE, 've_node', 've_node_bombeo'),
('DEPOSITO', 'TANK', 'NODE', TRUE, 've_node', 've_node_deposito'),
('CAUDALIM', 'METER', 'NODE', TRUE, 've_node', 've_node_caudalim'),
('MEDPRES', 'METER', 'NODE', FALSE, 've_node', 've_node_medpres'),
('TRAMO', 'PIPE', 'ARC', TRUE, 've_arc', 've_arc_tramo'),
('TRAMOV', 'VARC', 'ARC', TRUE, 've_arc', 've_arc_tramov'),
('RAMAL', 'PIPELINK', 'LINK', TRUE, 've_link', 've_link_ramal'),
('RAMALV', 'VLINK', 'LINK', FALSE, 've_link', 've_link_ramalv'),
('FUENTE', 'TAP', 'CONNEC', TRUE, 've_connec', 've_connec_fuente'),
('ORNAMENTAL', 'FOUNTAIN', 'CONNEC', FALSE, 've_connec', 've_connec_ornamental'),
('BRIEGO', 'GREENTAP', 'CONNEC', FALSE, 've_connec', 've_connec_briegogreen'),
('ACOMETIDA', 'WJOIN', 'CONNEC', TRUE, 've_connec', 've_connec_acometida'),
('ACOMETIDAV', 'VCONNEC', 'CONNEC', FALSE, 've_connec', 've_connec_acometidav'),
('TAPA', 'GENELEM', 'ELEMENT', TRUE, 've_element', 've_element_tapa'),
('EPUMP', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_epump'),
('EVALVE', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_evalve'),
('EMETER', 'FRELEM', 'ELEMENT', TRUE, 've_element', 've_element_emeter')
ON CONFLICT (id) DO UPDATE SET feature_class = EXCLUDED.feature_class, feature_type = EXCLUDED.feature_type, active = EXCLUDED.active, parent_layer = EXCLUDED.parent_layer, child_layer = EXCLUDED.child_layer;

-- 
INSERT INTO cat_feature_node (id, epa_default, isarcdivide, graph_delimiter) VALUES
('VANTIRET', 'JUNCTION', TRUE, '{NONE}'),
('VVENTOSA', 'UNDEFINED', FALSE, '{NONE}'),
('VREGQ', 'VALVE', TRUE, '{NONE}'),
('VRED', 'VALVE', TRUE, '{PRESSZONE}'),
('VDESC', 'JUNCTION', TRUE, '{NONE}'),
('VCOMP', 'SHORTPIPE', TRUE, '{NONE}'),
('VSOST', 'VALVE', TRUE, '{NONE}'),
('REDUC', 'JUNCTION', TRUE, '{NONE}'),
('HIDRANTE', 'JUNCTION', TRUE, '{NONE}'),
('ACORED', 'JUNCTION', TRUE, '{NONE}'),
('FINAL', 'JUNCTION', TRUE, '{NONE}'),
('POZO', 'RESERVOIR', TRUE, '{SECTOR}'),
('ETAP', 'RESERVOIR', TRUE, '{SECTOR}'),
('UNION', 'JUNCTION', TRUE, '{NONE}'),
('CAPTACION', 'RESERVOIR', TRUE, '{SECTOR}'),
('FILTRO', 'JUNCTION', TRUE, '{NONE}'),
('BRIEGORED', 'JUNCTION', TRUE, '{NONE}'),
('BOMBEO', 'PUMP', TRUE, '{PRESSZONE}'),
('DEPOSITO', 'TANK', TRUE, '{SECTOR, DMA, PRESSZONE}'),
('CAUDALIM', 'SHORTPIPE', TRUE, '{DMA}'),
('MEDPRES', 'JUNCTION', TRUE, '{NONE}')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default, isarcdivide = EXCLUDED.isarcdivide, graph_delimiter = EXCLUDED.graph_delimiter;

INSERT INTO cat_feature_arc (id, epa_default) VALUES
('TRAMO', 'PIPE'),
('TRAMOV', 'PIPE')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_link (id) VALUES
('RAMAL'),
('RAMALV')
ON CONFLICT (id) DO NOTHING;

INSERT INTO cat_feature_connec (id, epa_default) VALUES 
('FUENTE', 'JUNCTION'),
('ORNAMENTAL', 'JUNCTION'),
('BRIEGO', 'JUNCTION'),
('ACOMETIDA', 'JUNCTION'),
('ACOMETIDAV', 'JUNCTION')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;

INSERT INTO cat_feature_element (id, epa_default) VALUES
('TAPA', 'UNDEFINED'),
('EPUMP', 'FRPUMP'),
('EVALVE', 'FRVALVE'),
('EMETER', 'FRSHORTPIPE')
ON CONFLICT (id) DO UPDATE SET epa_default = EXCLUDED.epa_default;


INSERT INTO cat_node (id, node_type) VALUES 
('VANTIRET', 'VANTIRET'),
('VVENTOSA', 'VVENTOSA'),
('VREGQ', 'VREGQ'),
('VRED', 'VRED'),
('VDESC', 'VDESC'),
('VCOMP', 'VCOMP'),
('VSOST', 'VSOST'),
('REDUCCION', 'REDUC'),
('HIDRANTE', 'HIDRANTE'),
('ACORED', 'ACORED'),
('FINAL', 'FINAL'),
('POZO', 'POZO'),
('ETAP', 'ETAP'),
('UNION', 'UNION'),
('CAPTACION', 'CAPTACION'),
('FILTRO', 'FILTRO'),
('BRIEGOTOP', 'BRIEGORED'),
('BOMBEO', 'BOMBEO'),
('DEPOSITO', 'DEPOSITO'),
('CAUDALIM', 'CAUDALIM'),
('MEDPRES', 'MEDPRES')
ON CONFLICT (id) DO UPDATE SET node_type = EXCLUDED.node_type;

INSERT INTO cat_arc (id, arc_type, matcat_id, dnom) VALUES
('PVC110', 'TRAMO', 'PVC', 110),
('PVC160', 'TRAMO', 'PVC', 160),
('PE63', 'TRAMO', 'PE', 63),
('PE110', 'TRAMO', 'PE', 110),
('PE160', 'TRAMO', 'PE', 160),
('FD150', 'TRAMO', 'FD', 150),
('FD200', 'TRAMO', 'FD', 200),
('TRAMOV', 'TRAMOV', NULL, 0)
ON CONFLICT (id) DO UPDATE SET arc_type = EXCLUDED.arc_type, matcat_id = EXCLUDED.matcat_id, dnom = EXCLUDED.dnom;


INSERT INTO cat_connec (id, connec_type) VALUES
('FACHADA', 'ACOMETIDA'),
('CAUDAL', 'ACOMETIDA'),
('INTERIOR', 'ACOMETIDA'),
('PROVISIONAL', 'ACOMETIDA'),
('BRIEGO', 'BRIEGO'),
('FUENTE', 'FUENTE'),
('ORNAMENTAL', 'ORNAMENTAL'),
('ACOMETIDAV', 'ACOMETIDAV')
ON CONFLICT (id) DO UPDATE SET connec_type = EXCLUDED.connec_type;

INSERT INTO cat_link (id, link_type, matcat_id, dnom) VALUES
('PE25', 'RAMAL', 'PE', 25),
('PE32', 'RAMAL', 'PE', 32),
('PE50', 'RAMAL', 'PE', 50),
('RAMALV', 'RAMALV', NULL, 0)
ON CONFLICT (id) DO UPDATE SET link_type = EXCLUDED.link_type, matcat_id = EXCLUDED.matcat_id, dnom = EXCLUDED.dnom;

INSERT INTO cat_element (id, element_type, matcat_id) VALUES
('TAPA40X40', 'TAPA', 'FD'),
('TAPA60X60', 'TAPA', 'FD')
ON CONFLICT (id) DO UPDATE SET element_type = EXCLUDED.element_type, matcat_id = EXCLUDED.matcat_id;

ALTER TABLE cat_feature ENABLE TRIGGER gw_trg_cat_feature_after;

