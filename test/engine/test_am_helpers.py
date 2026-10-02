"""Unit tests for am parent validation helpers."""

from __future__ import annotations

import os

from giswater_admin.commands import _helpers as h


REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
DBMODEL = os.path.join(REPO_ROOT, "dbmodel")


def test_am_parent_supported_network_types():
    assert h.am_parent_supported(DBMODEL, "ws") is True
    assert h.am_parent_supported(DBMODEL, "ud") is True
    assert h.am_parent_supported(DBMODEL, "") is False
