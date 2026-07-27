/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = audit, public, pg_catalog;

CREATE TABLE user_log
(
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  type text,
  process_name text,
  user_name text,
  old_data text,
  new_data text,
  tstamp timestamp without time zone DEFAULT now()
);
