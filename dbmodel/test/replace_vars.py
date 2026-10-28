"""Copy test SQL into a staging tree with SCHEMA_NAME/SRID_VALUE substituted.

Never modifies files under test/ws or test/ud in the repo.
"""
import os
import shutil
import sys

STAGING_DIRNAME = ".run"

PROJECT_SCHEMA = {
    "ws": "ws_40",
    "ud": "ud_40",
    "utils": "utils",
    "cibs": "cibs",
    "cmms": "cmms",
    "network_ws": "ws_40",
    "network_ud": "ud_40",
}


SOURCE_TREE = {
    "network_ws": "network/ws",
    "network_ud": "network/ud",
}


def replace_vars_in_file(file_path: str, replacements: dict) -> None:
    with open(file_path, encoding="utf-8") as file:
        content = file.read()
    for old, new in replacements.items():
        content = content.replace(old, new)
    with open(file_path, "w", encoding="utf-8") as file:
        file.write(content)


def prepare_staging(project_type: str) -> str:
    test_dir = os.path.dirname(os.path.abspath(__file__))
    source_name = SOURCE_TREE.get(project_type, project_type)
    source_root = os.path.join(test_dir, source_name)
    if not os.path.isdir(source_root):
        raise SystemExit(f"Missing test tree: {source_root}")

    staging_root = os.path.join(test_dir, STAGING_DIRNAME, project_type)
    if os.path.exists(staging_root):
        shutil.rmtree(staging_root)
    shutil.copytree(source_root, staging_root)

    schema_name = PROJECT_SCHEMA.get(project_type, f"{project_type}_40")
    replacements = {
        "SCHEMA_NAME": schema_name,
        "SRID_VALUE": "25831",
        "SATELLITE_SCHEMA": "cibs",
    }
    for root, _dirs, files in os.walk(staging_root):
        for name in files:
            if name.endswith(".sql"):
                replace_vars_in_file(os.path.join(root, name), replacements)

    return staging_root


def main(project_type: str) -> None:
    staging_root = prepare_staging(project_type)
    print(staging_root)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python replace_vars.py <ws|ud|utils|cibs|network_ws|network_ud>")
        sys.exit(1)
    main(sys.argv[1])
