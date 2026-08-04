---
title: PostgreSQL Function Design
description: Function design guide
tags: postgres, function, trigger, naming
---

# Function Design

## Naming Conventions

For new functions, use the following naming conventions (we are working on refactoring the existing functions):

- Name: gw_{type}_{name} (type: fct, trg | name in snake_case) (e.g., `gw_fct_get_user`)
- Variables: singular snake_case with v_ prefix (e.g., `v_user_id`, `v_user_name`)
- Parameters: singular snake_case with p_ prefix (e.g., `p_data`, `p_user_id`)

## General Guidelines

- Try to keep the function code as short as possible.