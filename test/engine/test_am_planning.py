"""Unit tests for Asset Manage annual budget planning."""

from core.toolbars.am.planning import assign_replacement_years


def test_assign_replacement_years_rolls_before_exceeding_budget():
    assets = [
        {"estimated_cost": 60},
        {"estimated_cost": 60},
        {"estimated_cost": 40},
    ]

    selected = assign_replacement_years(assets, 100, 2027, 2028)

    assert [asset["replacement_year"] for asset in selected] == [2027, 2028, 2028]
    assert [asset["cum_cost"] for asset in selected] == [60, 60, 100]


def test_assign_replacement_years_puts_oversized_asset_alone():
    assets = [
        {"estimated_cost": 150},
        {"estimated_cost": 20},
    ]

    selected = assign_replacement_years(assets, 100, 2027, 2028)

    assert [asset["replacement_year"] for asset in selected] == [2027, 2028]
    assert [asset["cum_cost"] for asset in selected] == [150, 20]


def test_assign_replacement_years_stops_at_horizon():
    assets = [
        {"estimated_cost": 100},
        {"estimated_cost": 100},
        {"estimated_cost": 100},
    ]

    selected = assign_replacement_years(assets, 100, 2027, 2028)

    assert len(selected) == 2
