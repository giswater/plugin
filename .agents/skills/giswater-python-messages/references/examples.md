# Worked examples

Each example shows the required form first, then the variants to avoid.

## 1. Static message

```python
# GOOD
msg = "Layer not found"
tools_qgis.show_warning(msg)

# BAD - inline string, invisible to the scanner
tools_qgis.show_warning("Layer not found")

# BAD - bypasses the Giswater helpers
iface.messageBar().pushMessage("Warning", "Layer not found", level=1)
```

## 2. One dynamic value

```python
# GOOD
msg = "Layer {0} not found"
msg_params = (layer_name,)
tools_qgis.show_warning(msg, msg_params=msg_params)

# BAD - f-string, skipped by the scanner
msg = f"Layer {layer_name} not found"

# BAD - concatenation, extracted as "Layer  not found"
msg = "Layer " + layer_name + " not found"

# BAD - percent / format, placeholder lost
msg = "Layer %s not found" % layer_name
msg = "Layer {} not found".format(layer_name)
```

Keep the trailing comma on single-element tuples: `msg_params = (layer_name,)`. A bare value still works at runtime, but the tuple form is the convention across the codebase and stays correct when a second placeholder is added later.

## 3. Several dynamic values

```python
# GOOD
msg = "Hello {0} and {1}"
msg_params = (first_name, last_name)
tools_qgis.show_info(msg, msg_params=msg_params)

# GOOD - technical names stay as parameters
msg = "Function {0} returned {1}"
msg_params = (fn_name, status)
tools_qgis.show_info(msg, msg_params=msg_params)
```

Placeholders are indexed so translators can reorder them; the tuple order never changes.

## 4. Counts and results

```python
# GOOD
msg = "{0} features updated"
msg_params = (len(updated),)
tools_qgis.show_info(msg, msg_params=msg_params)

# GOOD - one complete sentence per branch
if errors:
    msg = "Import finished with {0} errors. Check the log for details."
    msg_params = (len(errors),)
    tools_qgis.show_warning(msg, msg_params=msg_params)
else:
    msg = "Import finished successfully. {0} rows imported."
    msg_params = (len(rows),)
    tools_qgis.show_info(msg, msg_params=msg_params)

# BAD - sentence assembled from fragments, untranslatable
msg = "Import finished"
if errors:
    msg += " with " + str(len(errors)) + " errors"
tools_qgis.show_warning(msg)
```



## 5. Info and warning boxes

```python
# GOOD
msg = "Language files downloaded and locale activated ({0})."
msg_params = (locale,)
tools_qt.show_info_box(msg, msg_params=msg_params)

# GOOD
msg = "Could not delete language files ({0}): {1}"
msg_params = (locale, error or "unknown error")
tools_qt.show_warning_box(msg, msg_params=msg_params)

# GOOD - box with its own title
msg = "Process finished for schema {0}"
title = "Success"
msg_params = (schema_name,)
tools_qt.show_info_box(msg, title=title, msg_params=msg_params)

# BAD
tools_qt.show_info_box(f"Language files downloaded ({locale}).")
```



## 6. Questions with title

```python
# GOOD
msg = "Do you want to update local language files for ({0})?"
title = "Update language files?"
msg_params = (locale,)
if not tools_qt.show_question(msg, title, msg_params=msg_params):
    return

# GOOD - placeholders in the title too
msg = "Delete feature {0}?"
title = "Delete from {0}"
msg_params = (feature_id,)
title_params = (table_name,)
if not tools_qt.show_question(msg, title, msg_params=msg_params, title_params=title_params):
    return

# GOOD - custom buttons, message rules unchanged
msg = "The project has unsaved changes. What do you want to do?"
title = "Unsaved changes"
if tools_qt.show_question(msg, title, buttons=["Save", "Discard"]):
    self._save()

# BAD
if not tools_qt.show_question(f"Delete feature {feature_id}?", "Delete"):
    return
```



## 7. Messages inside a dialog

```python
# GOOD - message bar of the dialog, not the main window
msg = "Selected arc: {0}"
msg_params = (arc_id,)
tools_qgis.show_info(msg, dialog=self.dlg_mincut, msg_params=msg_params)

# GOOD - explicit level
msg = "Mapzone {0} created"
msg_params = (mapzone_name,)
tools_qgis.show_message(msg, Qgis.MessageLevel.Success, dialog=dialog, msg_params=msg_params)

# BAD
tools_qgis.show_info(f"Selected arc: {arc_id}", dialog=self.dlg_mincut)
```



## 8. Exceptions and error details

```python
# GOOD
msg = "Task '{0}' Exception: {1}"
msg_params = (task_name, e)
tools_qgis.show_warning(msg, msg_params=msg_params)

# GOOD
msg = "Configuration file couldn't be imported:\n{0}"
msg_params = (file_path,)
tools_qgis.show_warning(msg, msg_params=msg_params)

# GOOD - exception dialog: title first, then message
title = "Unexpected error"
msg = "The operation could not be completed: {0}"
msg_params = (e,)
tools_qt.show_exception_message(title, msg, msg_params=msg_params)

# BAD
msg = "Task '" + task_name + "' Exception: " + str(e)
tools_qgis.show_warning(msg)
```



## 9. Validation before an action

```python
# GOOD
if not selected_ids:
    msg = "Select at least one feature to continue"
    tools_qgis.show_warning(msg, dialog=dialog)
    return

# GOOD - the invalid value belongs in the sentence
if value < 0:
    msg = "Value {0} is not valid for field {1}"
    msg_params = (value, field_name)
    tools_qgis.show_warning(msg, msg_params=msg_params, dialog=dialog)
    return
```



## 10. Messages built inside a loop

Build the list of values first, then emit one message.

```python
# GOOD
missing = [layer for layer in required_layers if layer not in project_layers]
if missing:
    msg = "The following layers are missing: {0}"
    msg_params = (", ".join(missing),)
    tools_qgis.show_warning(msg, msg_params=msg_params)

# BAD - one message per iteration, and concatenated text
for layer in required_layers:
    if layer not in project_layers:
        tools_qgis.show_warning("Missing layer: " + layer)
```



## 11. Progress and label text

Widget text does not go through the message helpers; translate it explicitly with `tools_qt.tr`, which uses `list_params` instead of `msg_params`.

```python
# GOOD
msg = "Downloading language files for ({0})..."
msg_params = (locale,)
self.lbl_downloading.setText(tools_qt.tr(msg, list_params=msg_params))

# BAD
self.lbl_downloading.setText(f"Downloading language files for ({locale})...")
```



## 12. Long messages

```python
# GOOD - parenthesized literals, joined by the scanner into one message
msg = (
    "The schema could not be updated. "
    "Restore the backup {0} before retrying."
)
msg_params = (backup_name,)
tools_qt.show_warning_box(msg, msg_params=msg_params)

# GOOD - triple-quoted literal
msg = """The project contains unsupported layers.
Remove them and run the check again."""
tools_qt.show_info_box(msg)
```



## 13. Variable name `message`

`message` is accepted alongside `msg`; use whichever the surrounding file already uses.

```python
# GOOD
message = "No features selected"
tools_qgis.show_info(message)

# GOOD
message = "{0} features updated"
msg_params = (count,)
tools_qgis.show_info(message, msg_params=msg_params)

# BAD - name not recognized by the scanner
warning_text = "No features selected"
tools_qgis.show_info(warning_text)
```



## 14. Do not pre-translate

```python
# GOOD
msg = "Node layer not found in the project."
tools_qgis.show_warning(msg)

# BAD - the helper already calls tr()
tools_qgis.show_warning(tools_qt.tr("Node layer not found in the project."))
```



## 15. Rewriting existing calls

When touching a call that inlines text or appends values, move it to the canonical pattern even if the wording stays identical.

```python
# BEFORE
tools_qgis.show_warning("Mapzone dynamic widgets not found", parameter=", ".join(missing))

# AFTER
msg = "Mapzone dynamic widgets not found: {0}"
msg_params = (", ".join(missing),)
tools_qgis.show_warning(msg, msg_params=msg_params)
```

```python
# BEFORE
tools_qt.show_question("Do you want to update the symbology?", "Update symbology", force_action=True)

# AFTER
msg = "Do you want to update the symbology?"
title = "Update symbology"
result = tools_qt.show_question(msg, title, force_action=True)
```



## 16. Non user-facing text

Debug output and developer traces are not translated and do not follow this pattern — but they still belong in `tools_log`, not in `print`.

```python
# GOOD
tools_log.log_info(f"Executing {function_name} with params {params}")

# BAD
print("Executing", function_name)
```

