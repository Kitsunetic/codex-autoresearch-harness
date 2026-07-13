from pathlib import Path


print(int(Path("src/value.txt").read_text(encoding="utf-8").strip()))
