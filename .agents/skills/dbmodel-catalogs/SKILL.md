---
name: dbmodel-catalogs
description: The Giswater catalog tables - the cat_feature and cat_feature_node/arc/connec/gully/element/link feature-type registry versus the physical cat_node/cat_arc/cat_connec/cat_element/cat_gully/cat_link catalogs, the single cat_material table, shapes, brands, management catalogs like cat_work and cat_owner, modelling catalogs like cat_dscenario, cat_dwf and cat_hydrology, and which must be populated before a project works. Use when working with cat_ tables, feature types, epa_default, isarcdivide, graph_delimiter, double_geom, or a *cat_id foreign key.
---

# dbmodel: catalogs

Covers both catalog tiers: the feature-type registry that drives behaviour, and the physical product catalogs.

Read `.agents/skills/giswater-dbmodel/catalogs.md` now, then answer.

If you also need the naming conventions, the view families or the procedure for looking up a table or column reliably, read `.agents/skills/giswater-dbmodel/SKILL.md`.

Related: `.agents/skills/giswater-dbmodel/inventory.md` for the parent/child/view pattern the registry wires together.
