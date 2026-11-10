/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
*/


SET search_path = am, public;
UPDATE config_engine_def AS t SET label = v.label, descript = v.descript, placeholder = v.placeholder FROM (
	VALUES
	('bratemain0', 'SH', 'Breakage rate coefficient', 'Pipe leak growth rate', NULL),
    ('compliance', 'SH', 'Regulatory weight', 'Weight in final matrix for regulatory compliance', NULL),
    ('compliance_1', 'WM', 'Regulatory', NULL, NULL),
    ('compliance_2', 'WM', 'Regulatory', NULL, NULL),
    ('drate', 'SH', 'Discount rate (%)', 'Real price discount rate. Takes into account price increases by discounting inflation.', NULL),
    ('expected_year', 'SH', 'Expected annual weight', 'Weight in final matrix per year of renewal', NULL),
    ('flow_1', 'WM', 'Working capital', NULL, NULL),
    ('flow_2', 'WM', 'Working capital', NULL, NULL),
    ('longevity_1', 'WM', 'Longevity', NULL, NULL),
    ('longevity_2', 'WM', 'Longevity', NULL, NULL),
    ('mleak_1', 'WM', 'Probability of failure', NULL, NULL),
    ('mleak_2', 'WM', 'Probability of failure', NULL, NULL),
    ('nrw_1', 'WM', 'ANC', NULL, NULL),
    ('nrw_2', 'WM', 'ANC', NULL, NULL),
    ('rleak_1', 'WM', 'Actual breaks', NULL, NULL),
    ('rleak_2', 'WM', 'Actual breaks', NULL, NULL),
    ('strategic', 'SH', 'Strategic weight', 'Weight in final matrix by strategic factors', NULL),
    ('strategic_1', 'WM', 'Strategic', NULL, NULL),
    ('strategic_2', 'WM', 'Strategic', NULL, NULL)
) AS v(parameter, method, label, descript, placeholder)
WHERE t.parameter = v.parameter AND t.method = v.method;