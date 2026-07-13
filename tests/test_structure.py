from __future__ import annotations

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class StructureTest(unittest.TestCase):
    def test_skill_fits_codex_initial_injection_limit(self) -> None:
        skill = ROOT / "SKILL.md"
        self.assertLessEqual(skill.stat().st_size, 8000)

    def test_reference_surface_is_intentionally_small(self) -> None:
        references = sorted(path.name for path in (ROOT / "references").glob("*.md"))
        self.assertEqual(["background.md", "experiment.md", "workflow.md"], references)
        skill = (ROOT / "SKILL.md").read_text(encoding="utf-8")
        for reference in references:
            self.assertIn(f"references/{reference}", skill)

    def test_runtime_surface_is_intentionally_small(self) -> None:
        scripts = {path.name for path in (ROOT / "scripts").glob("autoresearch*.py")}
        self.assertEqual(
            {"autoresearch.py", "autoresearch_core.py", "autoresearch_report.py"},
            scripts,
        )

    def test_skill_frontmatter_and_product_metadata(self) -> None:
        skill = (ROOT / "SKILL.md").read_text(encoding="utf-8")
        self.assertTrue(skill.startswith("---\nname: codex-autoresearch\n"))
        self.assertRegex(skill, r"(?m)^description: .+measurable.+$")
        metadata = (ROOT / "agents" / "openai.yaml").read_text(encoding="utf-8")
        self.assertIn('display_name: "Codex Autoresearch"', metadata)
        self.assertIn("allow_implicit_invocation: false", metadata)

    def test_local_markdown_links_resolve(self) -> None:
        markdown_files = [
            ROOT / "README.md",
            ROOT / "CONTRIBUTING.md",
            *(ROOT / "docs").rglob("*.md"),
        ]
        pattern = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
        missing: list[str] = []
        for source in markdown_files:
            for target in pattern.findall(source.read_text(encoding="utf-8")):
                if target.startswith(("http://", "https://", "#")):
                    continue
                clean = target.split("#", 1)[0]
                if clean and not (source.parent / clean).resolve().exists():
                    missing.append(f"{source.relative_to(ROOT)} -> {target}")
        self.assertEqual([], missing)


if __name__ == "__main__":
    unittest.main()
