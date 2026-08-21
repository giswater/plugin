import re
from pathlib import Path

root = Path(__file__).resolve().parent
pattern = re.compile(
    r"\b(edit_typevalue|om_typevalue|plan_typevalue|sys_typevalue|config_visit_parameter)\b"
)
dirs = [
    root / "dbmodel/schemas/main/ws/final_pass/config_form_fields",
    root / "dbmodel/schemas/main/ud/final_pass/config_form_fields",
]
changed = []
for folder in dirs:
    for path in folder.glob("*.sql"):
        text = path.read_text(encoding="utf-8")
        new = pattern.sub(r"v_\1", text)
        if new != text:
            path.write_text(new, encoding="utf-8")
            changed.append(path.name)
print("updated", len(changed), "files")
for name in changed:
    print(name)
