INSERT INTO config_form_list (listname, query_text, device, listtype, listclass)
	WITH missing_tableviews AS (
		-- QTableView widgets reference a listname via linkedobject
		SELECT DISTINCT listname
		FROM (
			SELECT
				cff.linkedobject AS listname
			FROM config_form_fields cff
			WHERE cff.widgettype = 'tableview'
				AND cff.linkedobject IS NOT NULL
			UNION
			-- Manager/QSqlTableModel objectnames used by set_tablemodel_config
			-- (see core/**/*.py). v_ui_% covers mapzone/visit/doc managers;
			-- the IN list are literal/resolved names that are not v_ui_*.
			SELECT c.relname AS listname
			FROM pg_class c
			JOIN pg_namespace n ON n.oid = c.relnamespace
			WHERE n.nspname = current_schema()
				AND c.relkind IN ('r', 'v', 'm')
				AND (
					c.relname LIKE 'v_ui\_%' ESCAPE '\'
					OR c.relname IN (
						'audit_results',
						'cat_mat_roughness',
						'cat_work',
						'inp_lid',
						'plan_psector_x_arc',
						'plan_psector_x_connec',
						'plan_psector_x_gully',
						'plan_psector_x_node',
						'tbl_workspace_manager',
						've_arc',
						've_cat_dscenario',
						've_connec',
						've_gully',
						've_inp_controls',
						've_inp_curve',
						've_inp_curve_value',
						've_inp_pattern',
						've_inp_pattern_value',
						've_inp_rules',
						've_inp_timeseries',
						've_inp_timeseries_value',
						've_link',
						've_node',
						'vf_hydrometer',
						'v_om_mincut_hydrometer'
					)
				)
		) discovered
		WHERE listname IS NOT NULL
			AND NOT EXISTS (
				SELECT 1
				FROM config_form_list cfl
				WHERE cfl.listname = discovered.listname
			)
	),
	object_sources AS (
		SELECT
			mt.listname,
			COALESCE(
				CASE
					WHEN EXISTS (
						SELECT 1
						FROM information_schema.tables t
						WHERE t.table_schema = current_schema()
							AND t.table_name = mt.listname
					) THEN mt.listname
				END,
				CASE
					WHEN mt.listname LIKE 'tbl\_%' ESCAPE '\'
						AND EXISTS (
							SELECT 1
							FROM information_schema.tables t
							WHERE t.table_schema = current_schema()
								AND t.table_name = 'v_ui_' || substr(mt.listname, 5)
						) THEN 'v_ui_' || substr(mt.listname, 5)
				END,
				CASE
					WHEN mt.listname LIKE 'tbl\_%' ESCAPE '\'
						AND EXISTS (
							SELECT 1
							FROM information_schema.tables t
							WHERE t.table_schema = current_schema()
								AND t.table_name = 've_' || substr(mt.listname, 5)
						) THEN 've_' || substr(mt.listname, 5)
				END
			) AS source_table
		FROM missing_tableviews mt
	),
	id_columns AS (
		SELECT
			os.listname,
			os.source_table,
			COALESCE(
				(
					SELECT a.attname
					FROM pg_class t
					JOIN pg_namespace s ON s.oid = t.relnamespace
					JOIN pg_index i ON i.indrelid = t.oid AND i.indisprimary
					JOIN pg_attribute a ON a.attrelid = t.oid
						AND a.attnum = ANY(i.indkey)
						AND NOT a.attisdropped
					WHERE t.relname = os.source_table
						AND s.nspname = current_schema()
					ORDER BY a.attnum
					LIMIT 1
				),
				(
					SELECT a.attname
					FROM pg_class t
					JOIN pg_namespace s ON s.oid = t.relnamespace
					JOIN pg_attribute a ON a.attrelid = t.oid
					WHERE t.relname = os.source_table
						AND s.nspname = current_schema()
						AND a.attnum > 0
						AND NOT a.attisdropped
					ORDER BY a.attnum
					LIMIT 1
				)
			) AS id_column
		FROM object_sources os
		WHERE os.source_table IS NOT NULL
	)
	SELECT
		ic.listname,
		'SELECT * FROM ' || ic.source_table || ' WHERE ' || ic.id_column || ' IS NOT NULL',
		4,
		'tab',
		'list'
	FROM id_columns ic
	WHERE ic.id_column IS NOT NULL;

UPDATE config_form_tableview SET
	alias = INITCAP(REPLACE(COALESCE(alias, columnname), '_', ' '));

INSERT INTO config_form_tableview (
	location_type,
	project_type,
	objectname,
	columnname,
	columnindex,
	visible,
	alias
	)
	WITH existing_configs AS (
		-- One *real* row per objectname (the one with the highest
		-- columnindex), instead of independently MAX()-ing location_type
		-- and project_type, which could synthesize a (location_type,
		-- project_type) pair that never actually existed together on a
		-- real row.
		SELECT DISTINCT ON (objectname)
			objectname,
			location_type,
			project_type,
			COALESCE(columnindex, 0) AS max_index
		FROM config_form_tableview
		ORDER BY objectname, columnindex DESC NULLS LAST
	),
	missing_lists AS (
		-- Listnames referenced by forms, or manager objectnames used by
		-- set_tablemodel_config (v_ui_% / literal list from core/**/*.py),
		-- with no config_form_tableview rows yet.
		SELECT DISTINCT ON (cfl.listname)
			cfl.listname AS objectname,
			COALESCE(
				(
					SELECT cff.formname || ' form'
					FROM config_form_fields cff
					WHERE cff.linkedobject = cfl.listname
						AND cff.formname IS NOT NULL
					ORDER BY cff.formname
					LIMIT 1
				),
				'utils form'
			) AS location_type,
			'utils'::varchar AS project_type,
			-1 AS max_index,
			cfl.query_text
		FROM config_form_list cfl
		WHERE (
				EXISTS (
					SELECT 1
					FROM config_form_fields cff
					WHERE cff.linkedobject = cfl.listname
				)
				OR cfl.listname LIKE 'v_ui\_%' ESCAPE '\'
				OR cfl.listname IN (
					'audit_results',
					'cat_mat_roughness',
					'cat_work',
					'inp_lid',
					'plan_psector_x_arc',
					'plan_psector_x_connec',
					'plan_psector_x_gully',
					'plan_psector_x_node',
					'tbl_workspace_manager',
					've_arc',
					've_cat_dscenario',
					've_connec',
					've_gully',
					've_inp_controls',
					've_inp_curve',
					've_inp_curve_value',
					've_inp_pattern',
					've_inp_pattern_value',
					've_inp_rules',
					've_inp_timeseries',
					've_inp_timeseries_value',
					've_link',
					've_node',
					'vf_hydrometer',
					'v_om_mincut_hydrometer'
				)
			)
			AND NOT EXISTS (
				SELECT 1
				FROM config_form_tableview x
				WHERE x.objectname = cfl.listname
			)
		ORDER BY cfl.listname, cfl.device DESC NULLS LAST
	),
	existing_sources AS (
		SELECT DISTINCT ON (ec.objectname)
			ec.objectname,
			ec.location_type,
			ec.project_type,
			ec.max_index,
			cfl.query_text,
			COALESCE(
				substring(cfl.query_text from '(?i)FROM\s+(?:[a-zA-Z_][\w]*\.)?([a-zA-Z_][\w]*)'),
				ec.objectname
			) AS source_table,
			-- Computed once per objectname here, instead of once per
			-- column later - avoids re-running the same regex against
			-- the same query_text for every column of a table.
			trim(substring(cfl.query_text from '(?i)SELECT\s+(.*?)\s+FROM\s')) AS select_list
		FROM existing_configs ec
		LEFT JOIN config_form_list cfl
			ON cfl.listname = ec.objectname
		ORDER BY ec.objectname, cfl.device DESC NULLS LAST
	),
	missing_sources AS (
		SELECT
			ml.objectname,
			ml.location_type,
			ml.project_type,
			ml.max_index,
			ml.query_text,
			COALESCE(
				substring(ml.query_text from '(?i)FROM\s+(?:[a-zA-Z_][\w]*\.)?([a-zA-Z_][\w]*)'),
				ml.objectname
			) AS source_table,
			trim(substring(ml.query_text from '(?i)SELECT\s+(.*?)\s+FROM\s')) AS select_list
		FROM missing_lists ml
	),
	object_sources AS (
		-- select_has_star: true only for a bare/qualified star used as a
		-- select-list item (`*`, `t.*`), never for a star used as a
		-- function argument (`count(*)`). The lookbehind/lookahead
		-- exclude a '*' directly touching '(' or ')' or a word character
		-- on either side.
		SELECT *,
			select_list IS NOT NULL
				AND select_list ~ '(?<![\w(])\*(?![\w)])' AS select_has_star
		FROM existing_sources
		UNION ALL
		SELECT *,
			select_list IS NOT NULL
				AND select_list ~ '(?<![\w(])\*(?![\w)])' AS select_has_star
		FROM missing_sources
	),
	new_columns AS (
		SELECT
			os.location_type,
			os.project_type,
			os.objectname,
			c.column_name AS columnname,
			os.max_index,
			ROW_NUMBER() OVER (
				PARTITION BY os.objectname
				ORDER BY c.ordinal_position
			) AS rn,
			-- Visible when the column is selected in query_text
			-- (explicit/qualified name, or a genuine SELECT *).
			CASE
				WHEN os.query_text IS NULL THEN
					c.column_name NOT IN ('id', 'created_at', 'updated_at', 'deleted_at')
				WHEN os.select_has_star THEN
					true
				WHEN os.select_list ~* ('\m' || c.column_name || '\M') THEN
					true
				ELSE
					false
			END AS visible,
			INITCAP(REPLACE(c.column_name, '_', ' ')) AS alias
		FROM object_sources os
		JOIN information_schema.columns c
			ON c.table_schema = current_schema()
			AND c.table_name = os.source_table
		WHERE NOT EXISTS (
			SELECT 1
			FROM config_form_tableview x
			WHERE x.objectname = os.objectname
				AND x.columnname = c.column_name
		)
	)
	SELECT
		location_type,
		project_type,
		objectname,
		columnname,
		(max_index + rn) AS columnindex,
		visible,
		alias
	FROM new_columns;