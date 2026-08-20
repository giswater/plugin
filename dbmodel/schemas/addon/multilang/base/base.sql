/*
This file is part of Giswater
The program is free software: you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.
*/

SET search_path = multilang, public, pg_catalog;

CREATE TABLE sys_version (
    id serial4 NOT NULL,
    giswater varchar(16) NOT NULL,
    project_type varchar(16) NOT NULL,
    postgres varchar(512) NOT NULL,
    postgis varchar(512) NOT NULL,
    "date" timestamp(6) DEFAULT now() NOT NULL,
    "language" varchar(50) NOT NULL,
    epsg int4 NOT NULL,
    addparam jsonb NULL,
    CONSTRAINT sys_version_pkey PRIMARY KEY (id)
);

CREATE TABLE cat_language (
    id text NOT NULL,
    idval text NULL,
    CONSTRAINT cat_language_idval_key UNIQUE (idval),
    CONSTRAINT cat_language_pkey PRIMARY KEY (id)
);

CREATE TABLE config_form_fields (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    formname text NOT NULL,
    formtype text NOT NULL,
    tabname text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    lb text NULL,
    tt text NULL,
    pl text NULL,
    -- NULL = exact formname match; non-NULL = LIKE pattern (feat seeds '%_arc%' → 've_arc%').
    formname_like text GENERATED ALWAYS AS (
        CASE
            WHEN length(formname) >= 4
             AND left(formname, 2) = '%_'
             AND right(formname, 1) = '%'
             AND position('%' IN substring(formname FROM 3 FOR length(formname) - 3)) = 0
            THEN 've_' || substring(formname FROM 3 FOR length(formname) - 3) || '%'
            WHEN position('%' IN formname) > 0 THEN formname
            ELSE NULL
        END
    ) STORED,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_form_fields_id_uniq UNIQUE (id),
    CONSTRAINT config_form_fields_pkey PRIMARY KEY (tabname, context, formname, formtype, project_type, "source", lang),
    CONSTRAINT config_form_fields_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_form_fields_json (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    formname text NOT NULL,
    formtype text NOT NULL,
    tabname text NOT NULL,
    "source" text NOT NULL,
    hint text NOT NULL DEFAULT 'widgetcontrols',
    lang text NOT NULL DEFAULT 'en_us',
    "text" jsonb NULL,
    formname_like text GENERATED ALWAYS AS (
        CASE
            WHEN length(formname) >= 4
             AND left(formname, 2) = '%_'
             AND right(formname, 1) = '%'
             AND position('%' IN substring(formname FROM 3 FOR length(formname) - 3)) = 0
            THEN 've_' || substring(formname FROM 3 FOR length(formname) - 3) || '%'
            WHEN position('%' IN formname) > 0 THEN formname
            ELSE NULL
        END
    ) STORED,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_form_fields_json_id_uniq UNIQUE (id),
    CONSTRAINT config_form_fields_json_pkey PRIMARY KEY (tabname, context, formname, formtype, project_type, "source", hint, lang),
    CONSTRAINT config_form_fields_json_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_form_tabs (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    formname text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    lb text NULL,
    tt text NULL,
    vl text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_form_tabs_id_uniq UNIQUE (id),
    CONSTRAINT config_form_tabs_pkey PRIMARY KEY (project_type, context, formname, "source", lang),
    CONSTRAINT config_form_tabs_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_param_system (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    lb text NULL,
    tt text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_param_system_id_uniq UNIQUE (id),
    CONSTRAINT config_param_system_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT config_param_system_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE sys_fprocess (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    ex text NULL,
    "in" text NULL,
    na varchar(250) NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT sys_fprocess_id_uniq UNIQUE (id),
    CONSTRAINT sys_fprocess_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT sys_fprocess_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE sys_function (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    ds text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT sys_function_id_uniq UNIQUE (id),
    CONSTRAINT sys_function_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT sys_function_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE sys_message (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    ms text NULL,
    ht text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT sys_message_id_uniq UNIQUE (id),
    CONSTRAINT sys_message_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT sys_message_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE sys_param_user (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    lb text NULL,
    tt text NULL,
    CONSTRAINT sys_param_user_id_uniq UNIQUE (id),
    CONSTRAINT sys_param_user_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT sys_param_user_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE sys_table (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    ds text NULL,
    al text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT sys_table_id_uniq UNIQUE (id),
    CONSTRAINT sys_table_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT sys_table_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE sys_label (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    vl text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT sys_label_id_uniq UNIQUE (id),
    CONSTRAINT sys_label_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT sys_label_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_csv (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    al text NULL,
    ds text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_csv_id_uniq UNIQUE (id),
    CONSTRAINT config_csv_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT config_csv_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_form_tableview (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    columnname text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    al text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_form_tableview_id_uniq UNIQUE (id),
    CONSTRAINT config_form_tableview_pkey PRIMARY KEY (project_type, context, "source", columnname, lang),
    CONSTRAINT config_form_tableview_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_json (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    hint text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    "text" jsonb NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_json_id_uniq UNIQUE (id),
    CONSTRAINT config_json_pkey PRIMARY KEY (project_type, context, "source", hint, lang),
    CONSTRAINT config_json_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_report (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    al text NULL,
    ds text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_report_id_uniq UNIQUE (id),
    CONSTRAINT config_report_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT config_report_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_toolbox (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    al text NULL,
    ob text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_toolbox_id_uniq UNIQUE (id),
    CONSTRAINT config_toolbox_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT config_toolbox_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_typevalue (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    formname text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    tt text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_typevalue_id_uniq UNIQUE (id),
    CONSTRAINT config_typevalue_pkey PRIMARY KEY (project_type, context, formname, "source", lang),
    CONSTRAINT config_typevalue_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE typevalue (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    typevalue text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    vl text NULL,
    ds text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT typevalue_id_uniq UNIQUE (id),
    CONSTRAINT typevalue_pkey PRIMARY KEY (project_type, context, typevalue, "source", lang),
    CONSTRAINT typevalue_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE TABLE config_visit_parameter (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    ds text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT config_visit_parameter_id_uniq UNIQUE (id),
    CONSTRAINT config_visit_parameter_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT config_visit_parameter_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);
CREATE TABLE value_state (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    na text NULL,
    ob text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT value_state_id_uniq UNIQUE (id),
    CONSTRAINT value_state_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT value_state_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);
CREATE TABLE value_state_type (
    id serial4 NOT NULL,
    project_type text NOT NULL,
    context text NOT NULL,
    "source" text NOT NULL,
    lang text NOT NULL DEFAULT 'en_us',
    na text NULL,
    updated_by text DEFAULT CURRENT_USER NULL,
    updated_on timestamptz DEFAULT now() NULL,
    CONSTRAINT value_state_type_id_uniq UNIQUE (id),
    CONSTRAINT value_state_type_pkey PRIMARY KEY (project_type, context, "source", lang),
    CONSTRAINT value_state_type_lang_fkey FOREIGN KEY (lang) REFERENCES cat_language(id)
);

CREATE INDEX idx_config_form_fields_exact ON config_form_fields
    USING btree (lang, project_type, context, formtype, tabname, source, formname)
    WHERE formname_like IS NULL;
CREATE INDEX idx_config_form_fields_pattern ON config_form_fields
    USING btree (lang, project_type, context, formtype, tabname, source)
    WHERE formname_like IS NOT NULL;
CREATE INDEX idx_config_form_fields_json_exact ON config_form_fields_json
    USING btree (lang, project_type, context, formtype, tabname, source, hint, formname)
    WHERE formname_like IS NULL;
CREATE INDEX idx_config_form_fields_json_pattern ON config_form_fields_json
    USING btree (lang, project_type, context, formtype, tabname, source, hint)
    WHERE formname_like IS NOT NULL;
CREATE INDEX idx_config_param_system_lang ON config_param_system USING btree (lang);
CREATE INDEX idx_config_typevalue_lang ON config_typevalue USING btree (lang);
CREATE INDEX idx_typevalue_lang ON typevalue USING btree (lang);
CREATE INDEX idx_config_visit_parameter_lang ON config_visit_parameter USING btree (lang);
CREATE INDEX idx_value_state_lang ON value_state USING btree (lang);
CREATE INDEX idx_value_state_type_lang ON value_state_type USING btree (lang);
CREATE INDEX idx_config_toolbox_lang ON config_toolbox USING btree (lang);
CREATE INDEX idx_config_report_lang ON config_report USING btree (lang);
CREATE INDEX idx_config_json_lang ON config_json USING btree (lang);
CREATE INDEX idx_config_form_tableview_lang ON config_form_tableview USING btree (lang);
CREATE INDEX idx_config_csv_lang ON config_csv USING btree (lang);
CREATE INDEX idx_sys_label_lang ON sys_label USING btree (lang);

GRANT ALL ON SCHEMA multilang TO role_basic;
GRANT SELECT ON ALL TABLES IN SCHEMA multilang TO role_basic;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA multilang TO role_basic;
