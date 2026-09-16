/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/
BEGIN;

-- Suppress NOTICE messages
SET client_min_messages TO WARNING;

SET search_path = "SCHEMA_NAME", public, pg_catalog;

-- Plan for 1 test
SELECT plan(16);

-- Create roles for testing
CREATE USER plan_user;
GRANT role_plan to plan_user;

CREATE USER epa_user;
GRANT role_epa to epa_user;

CREATE USER edit_user;
GRANT role_edit to edit_user;

CREATE USER om_user;
GRANT role_om to om_user;

CREATE USER basic_user;
GRANT role_basic to basic_user;

-- Extract and test the "status" field from the function's JSON response

-- insert messages
INSERT INTO sys_message
(id, error_message, hint_message, log_level, show_user, project_type, source)
VALUES(-999, 'Test Message: Feature is out of exploitation, feature_id: %feature_id%', 'Take a look on your map and use the approach of the exploitations!', 1, true, 'utils', 'core');

INSERT INTO sys_message
(id, error_message, hint_message, log_level, show_user, project_type, source)
VALUES(-998, 'Test Message: Feature is out of exploitation, feature_id: %feature_id%', 'Take a look on your map and use the approach of the exploitations!', 2, true, 'utils', 'core');

INSERT INTO sys_message
(id, error_message, hint_message, log_level, show_user, project_type, source)
VALUES(-997, 'Test Message: Feature is out of exploitation, feature_id: %feature_id%', 'Take a look on your map and use the approach of the exploitations!', 3, true, 'utils', 'core');

INSERT INTO sys_message
(id, error_message, hint_message, log_level, show_user, project_type, source)
VALUES(-996, 'Test Message: Feature is out of exploitation, feature_id: %feature_id%', 'Take a look on your map and use the approach of the exploitations!', 0, true, 'utils', 'core');


-- insert function
INSERT INTO sys_function
(id, function_name, project_type, function_type)
VALUES (-995, 'gw_test_function', 'utils', 'trigger');

SELECT throws_ok(
    'SELECT (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-999", "function":"-995","parameters":null, "variables":"value", "is_process":true}}$$))',
        'GW001',
        'Function: [gw_test_function] - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: %FEATURE_ID%. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS! - value',
        'Checking gw_fct_getmessage when parameters are missing'
);


SELECT throws_ok(
    'SELECT (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-999", "function":"-995","parameters":{"expl_id": 1}, "variables":"value", "is_process":true}}$$))',
        'GW001',
        'Function: [gw_test_function] - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: %FEATURE_ID%. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS! - value',
        'Checking gw_fct_getmessage when parameters name are wrong'
);

--v_debug = false

-- Extract and test the "text" field from the function's JSON response when parameters recieved are wrong
SELECT throws_ok(
    'SELECT (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-999", "function":"-995","parameters":{"feature_id": 1, "expl_id": 2}, "variables":"value", "is_process":true}}$$))',
        'GW001',
        'Function: [gw_test_function] - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS! - value',
        'Checking gw_fct_getmessage when there are more parameters than needed'
);

-- Extract and test the "text" field from the function's JSON response when message does not exist
SELECT is (
    (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
    "data":{"message":"-1000", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$)::JSON)->'message'->>'text',
    'The process has returned an error code, but this error code is not present on the sys_message table. Please contact with your system administrator in order to update your sys_message table',
    'Checking gw_fct_getmessage when message does not exist in sys_message'
);


-- Test JSON response when function does not exist
    SELECT is(
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"-999", "function":"-994","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$)::JSON)->'message'->>'text',
            'Function does not exist',
            'Checking gw_fct_getmessage when message function does not exist'
    );

-- is_process = true

    -- Test message raised when log_level is 1
    SELECT throws_ok(
        'SELECT (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"-999", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$))',
            'GW001',
            'Function: [gw_test_function] - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS! - value',
            'Checking gw_fct_getmessage when log_level is 1, is_process is true'
    );


    -- Test message raised when log_level is 2
    SELECT throws_ok(
        'SELECT (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"-998", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$))',
            'GW002',
            'Function: [gw_test_function] - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS! - value',
            'Checking gw_fct_getmessage when log_level is 2, is_process is true'
    );


    -- Test message raised when log_level is 3
    SELECT is (
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-997", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$)::JSON)->'body'->'data'->'info'->>'text',
        'TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1',
        'Checking gw_fct_getmessage when log_level is 3, is_process is true'
    );


    -- Test message raised when log_level is 0
    SELECT is (
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-996", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$)::JSON)->>'text',
        'TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1',
        'Checking gw_fct_getmessage when log_level is 0, is_process is true'
    );





-- is_process = false

    -- Test message raised when log_level is 1
    SELECT throws_ok(
        'SELECT (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"-999", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$))',
            'GW001',
            'Function: [gw_test_function] - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS! - value',
            'Checking gw_fct_getmessage when log_level is 1, is_process is false'
    );


    -- Test message raised when log_level is 2
    SELECT throws_ok(
        'SELECT (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
            "data":{"message":"-998", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$))',
            'GW002',
            'Function: [gw_test_function] - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS! - value',
            'Checking gw_fct_getmessage when log_level is 2, is_process is false'
    );


    -- Test message raised when log_level is 3
    SELECT is (
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-997", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$)::JSON)->'body'->'data'->'info'->>'text',
        'TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1',
        'Checking gw_fct_getmessage when log_level is 3, is_process is false'
    );

    -- Test message raised when log_level is 0
    SELECT is (
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-996", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$)::JSON)->>'text',
        'TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1',
        'Checking gw_fct_getmessage when log_level is 0, is_process is false'
    );



--v_debug = true
    update config_param_system
    set value = 'true'
    where parameter = 'admin_message_debug';

    -- is_process = true

    --log_level = 3
    SELECT is (
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-997", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":true}}$$)::JSON)->'body'->'data'->'info'->>'text',
        'Function: gw_test_function - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS!.',
        'Checking gw_fct_getmessage when log_level is 3, v_debug is true, is_process is true'
    );

    -- is_process = false


    --log_level = 3
    SELECT is (
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-997", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":false}}$$)::JSON)->'body'->'data'->'info'->>'text',
        'Function: gw_test_function - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS!.',
        'Checking gw_fct_getmessage when log_level is 3, v_debug is true, is_process is false'
    );

    --log_level = 0
    SELECT is (
        (gw_fct_getmessage($${"client":{"device":4, "infoType":1, "lang":"ES"},"feature":{},
        "data":{"message":"-996", "function":"-995","parameters":{"feature_id": 1}, "variables":"value", "is_process":false}}$$)::JSON)->'body'->'data'->'info'->>'text',
        'Function: gw_test_function - TEST MESSAGE: FEATURE IS OUT OF EXPLOITATION, FEATURE_ID: 1. HINT: TAKE A LOOK ON YOUR MAP AND USE THE APPROACH OF THE EXPLOITATIONS!.',
        'Checking gw_fct_getmessage when log_level is 1, v_debug is true, is_process is false'
    );


-- Finish the test
SELECT finish();

ROLLBACK;
