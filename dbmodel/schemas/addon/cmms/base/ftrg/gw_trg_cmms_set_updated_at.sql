/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

CREATE OR REPLACE FUNCTION cmms.set_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = cmms, public
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
