from __future__ import annotations

import json
from pathlib import Path


source_path = Path("src/math_utils.py")
namespace: dict[str, object] = {}
exec(compile(source_path.read_text(encoding="utf-8"), str(source_path), "exec"), namespace)
add = namespace["add"]
failure_count = int(not callable(add) or add(2, 3) != 5)
print(json.dumps({"failure_count": failure_count}))
