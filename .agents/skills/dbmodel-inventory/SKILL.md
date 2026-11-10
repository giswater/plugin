---
name: dbmodel-inventory
description: The Giswater asset inventory - the trunk feature tables node, arc, connec, gully, link, element and polygon, their man_ child tables and ve_ views, user-defined fields via sys_addfields, the three states and their state_type substates, the arc-node and link-network topology rules, double geometry, workcat lifecycle, and the anl_/review_/audit_ families. Use when working with feature tables or columns, feature types, states, topology errors, or when asked where a feature attribute lives.
---

# dbmodel: inventory

Covers the trunk feature tables and everything attached directly to them.

Read `.agents/skills/giswater-dbmodel/inventory.md` now, then answer.

If you also need the naming conventions, the view families or the procedure for looking up a table or column reliably, read `.agents/skills/giswater-dbmodel/SKILL.md`.

Related: `.agents/skills/giswater-dbmodel/catalogs.md` for the `cat_*` tables a feature points at. Feature-type and elevation columns differ between ws and ud; resolve type through the catalog or branch on `sys_version.project_type`.
