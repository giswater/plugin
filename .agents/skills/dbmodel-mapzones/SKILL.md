---
name: dbmodel-mapzones
description: Giswater mapzones - exploitation, sector, dma, presszone, dqa, supplyzone, omzone, omunit, minsector, drainzone, dwfzone and crmzone, the expl_id/sector_id/dma_id/omzone_id foreign keys and drainzone_outfall on features, config_mapzones, graphconfig json (nodeParent/toArc/ignore/forceClosed) and cat_feature_node.graph_delimiter as text[], the gw_fct_graphanalytics_mapzones trace, config_graph_mincut, and the utils_graphanalytics and edit_mapzones system variables. Use when working with mapzone tables or columns, computing or debugging zones, valve-bounded areas, or when features are missing because of a selector.
---

# dbmodel: mapzones

Covers the polygonal management zones, their foreign keys on features, and how they are computed from the network graph.

Read `.agents/skills/giswater-dbmodel/mapzones.md` now, then answer.

If you also need the naming conventions, the view families or the procedure for looking up a table or column reliably, read `.agents/skills/giswater-dbmodel/SKILL.md`.

Related: `.agents/skills/giswater-dbmodel/inventory.md` for the FKs on features. ws has presszone, dqa, supplyzone and crmzone; ud has drainzone, dwfzone and omunit. Mincut (`om_mincut*`) runs on the minsector graph.
