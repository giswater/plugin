/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = cm, public, pg_catalog;


CREATE OR REPLACE VIEW v_ui_doc_x_gully
AS
SELECT
	doc_x_gully.doc_id,
	doc_x_gully.gully_id,
	doc.name,
	doc.doc_type,
	doc.path,
	doc.observ,
	doc.date,
	doc.user_name,
	doc_x_gully.gully_uuid
FROM cm.doc_x_gully
JOIN cm.doc ON doc.id::text = doc_x_gully.doc_id::text;

GRANT ALL ON TABLE v_ui_doc_x_gully TO role_addon_cm_manager;
GRANT ALL ON TABLE v_ui_doc_x_gully TO role_addon_cm_field;



DROP TRIGGER IF EXISTS gw_trg_ui_doc_x_gully ON cm.v_ui_doc_x_gully;
CREATE TRIGGER gw_trg_ui_doc_x_gully
INSTEAD OF INSERT OR DELETE OR UPDATE
ON cm.v_ui_doc_x_gully
FOR EACH ROW
EXECUTE FUNCTION cm.gw_trg_ui_doc('gully');


DROP TRIGGER IF EXISTS trg_lot_x_gully_feature_before ON cm.om_campaign_lot_x_gully;
DROP TRIGGER IF EXISTS trg_lot_x_gully_feature_after ON cm.om_campaign_lot_x_gully;

CREATE TRIGGER trg_lot_x_gully_feature_before BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_gully
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('gully');

CREATE TRIGGER trg_lot_x_gully_feature_after AFTER INSERT OR DELETE ON cm.om_campaign_lot_x_gully
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature('gully');

DROP TRIGGER IF EXISTS trg_validate_lot_x_gully_feature ON cm.om_campaign_lot_x_gully;
CREATE TRIGGER trg_validate_lot_x_gully_feature BEFORE INSERT OR UPDATE ON cm.om_campaign_lot_x_gully
FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_lot_x_feature_check_campaign('gully');

DO $$
DECLARE
    v_rec record;
    v_view_name text;
    v_trigger_name text;
    v_feature_id text;
    v_feature_type text;
BEGIN
    FOR v_rec IN
        SELECT id, feature_type FROM PARENT_SCHEMA.cat_feature WHERE feature_type = 'GULLY'
    LOOP
        v_feature_id := lower(v_rec.id);
        v_feature_type := lower(v_rec.feature_type);

        v_view_name := 've_' || 'PARENT_SCHEMA' || '_lot_' || v_feature_id;
        v_trigger_name := 'trg_PARENT_SCHEMA_edit_lot_' || v_feature_type;

        EXECUTE
        'CREATE OR REPLACE TRIGGER ' || v_trigger_name || ' INSTEAD OF
        INSERT OR DELETE OR UPDATE
        ON cm.' || v_view_name ||' FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_edit_feature(' || quote_literal(v_feature_type) || ')';
		
        EXECUTE
        'CREATE OR REPLACE TRIGGER ' || v_trigger_name || '_geom INSTEAD OF
        INSERT OR UPDATE
        ON cm.' || v_view_name ||' FOR EACH ROW EXECUTE FUNCTION cm.gw_trg_cm_feature_geom(' || quote_literal(v_feature_type) || ')';
    END LOOP;
END
$$;
