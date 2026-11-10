/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

-- One is_last = true per sys_code (visit_x_feature, attachment_x_feature) or
-- per visit (attachment_x_visit): the link with the highest id. The triggers
-- are created in base.sql, because this file is applied before those tables exist.

CREATE OR REPLACE FUNCTION cmms.gw_trg_cmms_is_last()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = cmms, public
AS $$
DECLARE
  v_sys_code text;
  v_visit_id uuid;
BEGIN
  IF TG_TABLE_NAME = 'attachment_x_visit' THEN
    v_visit_id := COALESCE(NEW.visit_id, OLD.visit_id);
    UPDATE cmms.attachment_x_visit AS t
    SET is_last = (t.id = sub.max_id)
    FROM (
      SELECT max(id) AS max_id
      FROM cmms.attachment_x_visit
      WHERE visit_id = v_visit_id
    ) AS sub
    WHERE t.visit_id = v_visit_id
      AND sub.max_id IS NOT NULL;
  ELSIF TG_TABLE_NAME = 'visit_x_feature' THEN
    v_sys_code := COALESCE(NEW.sys_code, OLD.sys_code);
    UPDATE cmms.visit_x_feature AS t
    SET is_last = (t.id = sub.max_id)
    FROM (
      SELECT max(id) AS max_id
      FROM cmms.visit_x_feature
      WHERE sys_code = v_sys_code
    ) AS sub
    WHERE t.sys_code = v_sys_code
      AND sub.max_id IS NOT NULL;
  ELSE
    v_sys_code := COALESCE(NEW.sys_code, OLD.sys_code);
    UPDATE cmms.attachment_x_feature AS t
    SET is_last = (t.id = sub.max_id)
    FROM (
      SELECT max(id) AS max_id
      FROM cmms.attachment_x_feature
      WHERE sys_code = v_sys_code
    ) AS sub
    WHERE t.sys_code = v_sys_code
      AND sub.max_id IS NOT NULL;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;
