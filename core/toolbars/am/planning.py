"""
Pure planning helpers shared by Asset Manage calculation workers.
"""
# -*- coding: utf-8 -*-


def assign_replacement_years(assets, yearly_budget, start_year, target_year):
    """Place already-sorted assets into budget years.

    An asset that does not fit the remaining money of the current year starts the
    next year. An asset more expensive than one year is placed alone and consumes
    that year. Assets past target_year are left out. cum_cost is the spend inside
    the assigned year, not the running total of the whole plan.
    """
    selected = []
    current_year = start_year
    year_cost = 0.0
    budget = float(yearly_budget)
    for asset in assets:
        cost = max(float(asset.get("estimated_cost") or 0), 0)
        if year_cost > 0 and year_cost + cost > budget:
            current_year += 1
            year_cost = 0.0
        if current_year > target_year:
            break
        year_cost += cost
        asset["replacement_year"] = current_year
        asset["cum_cost"] = year_cost
        selected.append(asset)
        # An asset can exceed one year's budget, but it must occupy that year alone.
        if year_cost >= budget:
            current_year += 1
            year_cost = 0.0
    return selected
