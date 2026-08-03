---
name: giswater-python-messages
description: >
  Writes Giswater Python user messages the way the i18n scanner expects: assign
  text to msg / title / message, call tools_qgis or tools_qt helpers, and use
  indexed placeholders with msg_params instead of f-strings or concatenation.
  Use when writing, reviewing, or fixing show_info, show_warning, show_critical,
  show_message, show_info_box, show_warning_box, show_question,
  show_exception_message, tools_qt.tr, msg_params, title_params, translations,
  or i18n strings. Example questions: "How should I write this warning?",
  "Why is this message not translated?", "Fix this f-string show_info",
  "Add a confirm dialog before delete", "Rewrite this message for i18n".
metadata:
    author: giswater
    version: "0.3.0"
---

# Giswater Python Messages

## When to use this skill

Apply this skill whenever user-facing Python text is created or changed. Typical questions:

- "How should I write this warning / info message?"
- "Add a confirm dialog before deleting this feature"
- "Why is this message not translated / not in the i18n tables?"
- "Fix this f-string / concatenated `show_info`"
- "Rewrite these messages so the scanner can detect them"
- "Show an error box when the import fails"
- "Update the progress label while downloading"

## Note: message standard

> **Write every user message so Giswater and the i18n scanner can find and translate it.**
>
> 1. **Show it with a Giswater helper** — e.g. `tools_qgis.show_warning`, `tools_qt.show_info_box`, `tools_qt.show_question`. Do not call `QMessageBox` or `iface.messageBar()` directly.
> 2. **Put the text in a variable first** — assign to `msg`, `title`, or `message` on its own line, then pass that variable to the helper. Inline strings are invisible to the scanner.
> 3. **Keep the string whole and use placeholders** — do not build the text with `+`, f-strings, or `.format()`. Write `msg = "Hello {0} and {1}"` and pass values as `msg_params = (a, b)`.

## Canonical pattern

Always these three lines, in this order:

```python
msg = "Hello {0} and {1}"
msg_params = (a, b)
tools_qgis.show_warning(msg, msg_params=msg_params)
```

Without dynamic values, drop `msg_params`:

```python
msg = "Layer not found"
tools_qgis.show_warning(msg)
```

## Rules

1. **Route every user-facing text through a Giswater helper** — never `iface.messageBar().pushMessage(...)`, `QMessageBox(...)`, or `print(...)`.
2. **Assign the text to `msg`, `title`, or `message` first** — these three names are the only ones the scanner recognizes, and the assignment must start the line.
3. **The assigned value is a plain string literal** — no f-strings, no `+`, no `.format()`, no `%`, no ternaries, no pre-translation.
4. **Use indexed placeholders** `{0}`, `{1}`, … in the order they read in English.
5. **Pass dynamic values as a tuple** in `msg_params` (and `title_params` for the title).
6. **Write the source string in English**; the helper translates it.

## Choose the helper

| Need | Call |
|------|------|
| Message bar, informational | `tools_qgis.show_info(msg, msg_params=msg_params)` |
| Message bar, warning | `tools_qgis.show_warning(msg, msg_params=msg_params)` |
| Message bar, error | `tools_qgis.show_critical(msg, msg_params=msg_params)` |
| Message bar, explicit level / success | `tools_qgis.show_message(msg, Qgis.MessageLevel.Success, msg_params=msg_params)` |
| Modal, informational | `tools_qt.show_info_box(msg, title=title, msg_params=msg_params)` |
| Modal, warning | `tools_qt.show_warning_box(msg, msg_params=msg_params)` |
| Modal, yes/no decision | `tools_qt.show_question(msg, title, msg_params=msg_params)` |
| Modal, caught exception | `tools_qt.show_exception_message(title, msg, msg_params=msg_params)` |
| Widget text (`setText`, labels) | `widget.setText(tools_qt.tr(msg, list_params=msg_params))` |
| Log file / QGIS log only, not user-facing | `tools_log.log_info(msg)` |

Inside a dialog, pass `dialog=self.dlg_...` to the `tools_qgis.show_*` helpers so the message lands on that dialog's message bar.

Note the kwarg difference: helpers take `msg_params`, while `tools_qt.tr` takes `list_params`.

## What the scanner sees

`scripts/i18n_searcher.py` extracts messages by reading lines that **begin** with `msg`, `message`, or `title` followed by `=` and a quote or `(`. Anything else is invisible or extracted wrong — the text then never reaches the translation tables, and users see untranslated or truncated strings.

| Written as | Result |
|------------|--------|
| `msg = "Layer {0} not found"` | detected correctly |
| `msg = f"Layer {name} not found"` | **skipped entirely** — f-strings are explicitly excluded |
| `self.msg = "..."`, `error_msg = "..."`, `msg2 = "..."` | **not detected** — the line must start with `msg` / `message` / `title` |
| `msg = other_variable` | **not detected** — no string literal on the right side |
| `msg = "Layer " + name + " missing"` | **corrupted** — extracted as `Layer  missing` |
| `msg = "Yes" if flag else "No"` | **corrupted** — all literals are glued into `YesNo` |
| `tools_qgis.show_warning("Layer not found")` | **not detected** — no assignment |

These multi-line forms are detected correctly, so use them for long text:

```python
msg = (
    "The process finished with errors. "
    "Check the log file {0} for details."
)
msg_params = (log_path,)
tools_qgis.show_warning(msg, msg_params=msg_params)
```

```python
msg = """Line one.
Line two with {0}."""
msg_params = (value,)
tools_qt.show_info_box(msg)
```

## Anti-patterns and their fix

| Anti-pattern | Fix |
|--------------|-----|
| `show_info(f"Found {n} arcs")` | `msg = "Found {0} arcs"` + `msg_params = (n,)` |
| `msg = "Error: " + str(e)` | `msg = "Error: {0}"` + `msg_params = (e,)` |
| `msg = "Deleted {} rows".format(n)` | `msg = "Deleted {0} rows"` + `msg_params = (n,)` |
| `show_warning(tools_qt.tr("Node not found"))` | `msg = "Node not found"` + `show_warning(msg)` — the helper already translates |
| `show_warning(msg, parameter=", ".join(missing))` when the value belongs in the sentence | `msg = "Widgets not found: {0}"` + `msg_params = (", ".join(missing),)` |
| Building a sentence from fragments across `if` branches | One complete `msg` literal per branch |
| Same text repeated with different word order per language | One `msg` with `{0}` / `{1}`, reordered by translators |

`parameter=` is still fine for appending a raw technical value (an ID, a stack trace) after a complete sentence — but prefer `msg_params` whenever the value reads as part of the sentence.

## Self-check

Before finishing, verify each message you touched:

- [ ] Goes through a `tools_qgis.*` / `tools_qt.*` helper
- [ ] Text assigned to `msg`, `title`, or `message` at the start of a line
- [ ] Right side is a plain literal: no f-string, `+`, `.format()`, `%`, ternary, or `tr()`
- [ ] Placeholders indexed `{0}`, `{1}`, … and `msg_params` is a tuple in the same order
- [ ] Single-value tuples written with the trailing comma: `msg_params = (locale,)`
- [ ] `title` follows the same rules, with `title_params` when it has placeholders

Scan the files you changed for inline strings and f-strings in message calls:

```bash
rg -n -g "*.py" "show_(info|warning|critical|message|info_box|warning_box|question)\(\s*f?[\x22\x27]" <path>
```

Any hit is a message to rewrite into the canonical pattern.

## Reference

- Worked examples for common situations (counts, exceptions, loops, questions, dialogs, progress labels, batch results): [references/examples.md](references/examples.md)
