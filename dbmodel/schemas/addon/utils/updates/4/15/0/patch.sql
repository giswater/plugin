/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = utils, public, pg_catalog;

DO $patch$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_attribute a
        JOIN pg_class c ON a.attrelid = c.oid
        JOIN pg_namespace n ON c.relnamespace = n.oid
        WHERE c.relname = 'plot'
            AND n.nspname = current_schema()
            AND a.attname = 'streetaxis_id'
            AND a.attnotnull = true
    ) THEN
        EXECUTE 'ALTER TABLE plot ALTER COLUMN streetaxis_id DROP NOT NULL';
    END IF;
END
$patch$;
