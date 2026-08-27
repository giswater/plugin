---

## name: giswater-python-messages
description: >
  Makes Giswater Python user-facing text translatable end-to-end: write it so
  i18n_searcher can detect it, then apply translation via helpers or explicit
  tools_qt.tr. Use when writing, reviewing, or fixing show_info, show_warning,
  show_critical, show_message, show_info_box, show_warning_box, show_question,
  show_exception_message, tools_qt.tr, msg_params, title_params, dialog titles,
  menu/actions text, translations, or i18n strings — and whenever a task adds
  or changes user-facing text even if the user did not mention messages or i18n.
  Load before the first show_* call, msg/title/message assignment, or tools_qt.tr
  for UI copy. Example questions: "How should I write this warning?", "Why is
  this message not translated?", "Fix this f-string show_info", "Set a dialog
  title", "Add a menu action", "Rewrite this message for i18n".
metadata:
  author: giswater
version: "0.4.0"



# Giswater Python Messages



## Objective

**All Giswater Python user-facing texts must be translated.** That requires two steps:

1. **Detect** the texts so a human (or the translations API) can translate them.
2. **Apply** the translation at runtime so the UI shows the localized string.

Skip either step and the text stays untranslated for users.

Load this skill whenever you create or change user-facing Python text — including when you add it because the task needs it, not only when the user asks about i18n.

---



## 1. Detect — format for `i18n_searcher`

`scripts/i18n_searcher.py` finds candidate strings. **Detection only works if the format is exact.** Wrong format ⇒ string never enters the translation tables ⇒ users never see a translation, even if you call `tr` correctly.

### Required assignment form

Put every translatable string in a variable named `msg`, `title`, `message`, or `inf_text`, on a line that **starts** with that name, then `=`, then a string literal (or `(` / `"""` for multi-line):

```python
msg = "Layer {0} not found"
msg_params = (layer_name,)
```

```python
title = "Confirm delete"
```



### Format rules (indispensable)


| Rule                                                                        | Why                                                              |
| --------------------------------------------------------------------------- | ---------------------------------------------------------------- |
| Line starts with `msg` / `title` / `message` / `inf_text` then `=`          | Scanner only matches those names at line start                   |
| Right-hand side is a **plain string literal**                               | f-strings are skipped; variables / expressions are not extracted |
| No `+`, f-strings, `.format()`, `%`, ternaries                              | Corrupts or drops the extracted text                             |
| Dynamic parts use `{0}`, `{1}`, … and a `msg_params` / `title_params` tuple | Translators can reorder; values stay out of the catalog key      |
| Source language is English                                                  | Catalog baseline                                                 |


Multi-line literals are fine:

```python
msg = (
    "The process finished with errors. "
    "Check the log file {0} for details."
)
```



### What the scanner sees


| Written as                                   | Result                           |
| -------------------------------------------- | -------------------------------- |
| `msg = "Layer {0} not found"`                | detected                         |
| `msg = f"Layer {name} not found"`            | **skipped**                      |
| `self.msg = "..."`, `error_msg = "..."`      | **not detected**                 |
| `msg = other_variable`                       | **not detected**                 |
| `msg = "Layer " + name`                      | **corrupted**                    |
| `tools_qgis.show_warning("Layer not found")` | **not detected** — no assignment |


---



## 2. Apply — show the translated string

Detection alone is not enough. At runtime the English catalog key must go through translation.

### Helpers already translate (usual case)

`tools_qgis.show_*`, `tools_qt.show_*_box` / `show_question` / `show_exception_message`, and similar helpers call `tools_qt.tr` internally. Pass the **raw** English `msg` / `title` and optional `msg_params` — do **not** wrap them in `tr` yourself:

```python
msg = "Hello {0} and {1}"
msg_params = (a, b)
tools_qgis.show_warning(msg, msg_params=msg_params)
```

```python
msg = "Layer not found"
tools_qgis.show_warning(msg)
```



### Explicit `tools_qt.tr` (when there is no helper)

For UI copy that is not routed through a message helper — dialog titles, menu/actions, labels, placeholders, button text, etc. — assign the English string first (so the scanner finds it), then call `tools_qt.tr` when setting the widget:

```python
title = "Manage fields"
dlg.setWindowTitle(tools_qt.tr(title))
```

```python
title = "Get help"
action = menu.addAction(tools_qt.tr(title))
```

```python
msg = "Type to search..."
widget.setPlaceholderText(tools_qt.tr(msg))
```

With placeholders, helpers use `msg_params=`; `tools_qt.tr` uses `list_params=`:

```python
title = "Project {0}"
title_params = (name,)
dlg.setWindowTitle(tools_qt.tr(title, list_params=title_params))
```



### Choose the helper


| Need                                      | Call                                                                                       |
| ----------------------------------------- | ------------------------------------------------------------------------------------------ |
| Message bar, info / warning / error       | `tools_qgis.show_info` / `show_warning` / `show_critical`                                  |
| Message bar, explicit level               | `tools_qgis.show_message(..., level, msg_params=...)`                                      |
| Modal info / warning / yes-no / exception | `tools_qt.show_info_box` / `show_warning_box` / `show_question` / `show_exception_message` |
| Widget / title / action text (no helper)  | assign `msg`/`title`, then `tools_qt.tr(...)`                                              |
| Log only (not user-facing UI)             | `tools_log.log_info(msg)` — still use assignment form if the text is catalogued            |


Inside a dialog, pass `dialog=self.dlg_...` to `tools_qgis.show_*` so the bar attaches to that dialog.

---



## Anti-patterns


| Anti-pattern                                  | Fix                                                                        |
| --------------------------------------------- | -------------------------------------------------------------------------- |
| `show_info(f"Found {n} arcs")`                | `msg = "Found {0} arcs"` + `msg_params = (n,)`                             |
| `msg = "Error: " + str(e)`                    | `msg = "Error: {0}"` + `msg_params = (e,)`                                 |
| `show_warning(tools_qt.tr("Node not found"))` | `msg = "Node not found"` + `show_warning(msg)` — helper already translates |
| `dlg.setWindowTitle("Manage fields")`         | `title = "Manage fields"` + `setWindowTitle(tools_qt.tr(title))`           |
| `menu.addAction("Get help")`                  | `title = "Get help"` + `addAction(tools_qt.tr(title))`                     |
| `iface.messageBar()` / raw `QMessageBox`      | Use Giswater helpers                                                       |
| Sentence built from fragments across branches | One complete `msg` literal per branch                                      |


`parameter=` may append a raw technical value after a full sentence; prefer `msg_params` when the value is part of the sentence.

---



## Self-check

For every user-facing string you touched:

- [ ] **Detectable:** assigned to `msg` / `title` / `message` / `inf_text` at line start; plain English literal; `{0}`… + params tuple if dynamic
- [ ] **Applied:** shown via a helper that translates, **or** explicit `tools_qt.tr` for titles/actions/widgets
- [ ] No double-`tr` on helper paths; no inline/f-string in the call

Quick scan for missed inline message calls:

```bash
rg -n -g "*.py" "show_(info|warning|critical|message|info_box|warning_box|question)\(\s*f?[\x22\x27]" <path>
```



## Reference

- Worked examples: [references/examples.md](references/examples.md)

