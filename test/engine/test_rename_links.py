"""rename_parent_links_sql quotes names and rewrites every parent-link key."""

from giswater_admin.engine.builder import rename_parent_links_sql


def test_rename_parent_links_sql_quotes_and_covers_keys() -> None:
    sql = rename_parent_links_sql("o'brien", "new_name")
    assert "v_old text := 'o''brien';" in sql
    assert "v_new text := 'new_name';" in sql
    assert "'parent_schemas'" in sql
    assert "'network_parents'" in sql
    assert "'ws_current_schema'" in sql
    assert "'ud_current_schema'" in sql
