HOW TO TRANSLATE:
-----------------

As Giswater works on two environments (QGIS and PostgreSQL) two variables have the control to manage with translate
	QGIS -> locale definition (xx_XX). Plugin has one method (tools_qgis.get_locale) to return locale xx_XX definition 
	getting from QGIS as well as userLocale or globalLocale in function if user overwrites the system definition or not

	POSTGRES -> locale is managed on table sys_version, column language. This is setted when new project database schema is created.
	
	As it's shown, you can work with front-end in one locale but to have defined into database other locale. Be carefull here!!!!
	
On the other hand, Giswater works with QGIS templates (composers and project files), Python and PL-SQL languages environment and for this reason
    source and target keys to translate are stored in source code in on:

	1 - QGIS templates: https://github.com/giswater/plugin/resources/templates/
	2 - Python messages and dialogs: https://github.com/giswater/plugin/i18n/ *_ts files
	3 - PL-SQL messages and dialogs: https://github.com/giswater/giswater_db_model/updates/  i18n folders (each new version on new i18n folder)
	
	Regarding the QGIS templates (https://github.com/giswater/plugin/resources/templates) you may known that in order to optimize your work, 
	we recommend only translate ud_admin_sample & ws_admin_sample. 
	Rest of QGIS templates must be translated after, only deleting layers from the translated ones  (ud_admin_sample, ws_admin_sample)
		
	Regarding dialogs, and thanks to the Giswater Back-end approach, based on the powerful collection of stored procedures, some forms used on QGIS are built-up into database 
	and send to front-end using the response of called procedure. On the other side, the client has an interpreter to decode the json and rebuild the form 
	composed on database. The ui dialogs working with this strategy, that are only empty templates to be filled, are:
		- info_generic.ui
		- info_catalog.ui
		- info_workcat.ui
		- info_corssect.ui
		- info_feature.ui
		- search.ui
		- toolbox.ui
		- toolbox_tool.ui
		- config.ui
		- print.ui
		- go2epa_options.ui
		- selector.ui
		
	Rest of dialogs works as standard pyQt approach.
	
	Regarding messages, and thanks again to the Giswater Back-end approach, based on the powerful collection of stored procedures, 
	some messages are stored on database code (PL-SQL) as well as other messages are stored on python code

As result, in order to make easier the software's translation, we have created a translation environment to assist the Python and PL-SQL messages and dialogs translate
	based on a PostgreSQL database on URL: community.giswater.org::5433 (giswater.i18n)
	If you are interested to translate it, we encourage you to put in contact with the admin team saying in which language you are interested on in order to enable 
	for you an user/password to work with the assistant enviroment. 
	
After that, inside the PostgreSQL database you will find six tables:
		Catalog:	cat_language
		Python: 	pytoolbar table
					pydialog table
					pymessage table
		PL-SQL: 	dbdialog table
					dbmessage table
	
	with columns related to your language. As well as pydialog and dbdialog tables has lots of rows, to update both, 
	you can use SQL scripts stored on plugin/resources/i18n/:
		- help4dbdialog.sql
		- help4pydialog.sql
		
All your work will be checked before release and if proceed, released on new version of Giswater. But on the other hand, if you prefer do not wait for this new release, 
you can implement by yourself, work done for you into your current version of Giswater. In order to do this:

	Python: Use admin button of Giswater to create your ts and qm files, ready to work

	PL-SQL: Use admin button to Giswater to create the tree SQL script files: (ws.sql, utils.sql, ud.sql) 
		ready to work on the folder: dbmodel/updates/XX/XXXXX/i18n/xx_XX
		That files will be read on next new project schema, or neeed to be executed using PgConsole in case of one existing schema
		Remember that when you update i18n database, gw_fct_admin_schema_i18n is executed under rule to overwrite (or not) managed 
		by system variable 'admin_i18n_update_mode' 
					
			0: update always owerwriting current values
			1: update only when value is null
			2: newer update
						
		Check it variable before proceed