#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

required=(
  "$ROOT/SKILL.md"
  "$ROOT/README.md"
  "$ROOT/CONTRIBUTING.md"
  "$ROOT/agents/openai.yaml"
  "$ROOT/docs/INSTALL.md"
  "$ROOT/docs/GUIDE.md"
  "$ROOT/docs/EXAMPLES.md"
  "$ROOT/references/workflow.md"
  "$ROOT/references/experiment.md"
  "$ROOT/references/background.md"
  "$ROOT/scripts/autoresearch.py"
  "$ROOT/scripts/autoresearch_core.py"
  "$ROOT/scripts/autoresearch_report.py"
)

for path in "${required[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
done

skill_bytes="$(wc -c < "$ROOT/SKILL.md" | tr -d ' ')"
if [[ "$skill_bytes" -gt 8000 ]]; then
  echo "SKILL.md exceeds the 8,000-byte Codex prompt limit: $skill_bytes bytes" >&2
  exit 1
fi

reference_count="$(find "$ROOT/references" -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')"
if [[ "$reference_count" -ne 3 ]]; then
  echo "Expected exactly 3 model references, found $reference_count" >&2
  exit 1
fi

runtime_script_count="$(find "$ROOT/scripts" -maxdepth 1 -type f -name 'autoresearch*.py' | wc -l | tr -d ' ')"
if [[ "$runtime_script_count" -ne 3 ]]; then
  echo "Expected exactly 3 autoresearch Python modules, found $runtime_script_count" >&2
  exit 1
fi

translation_count="$(find "$ROOT/docs/i18n" -maxdepth 1 -type f -name 'README_*.md' | wc -l | tr -d ' ')"
if [[ "$translation_count" -ne 8 ]]; then
  echo "Expected 8 translated READMEs, found $translation_count" >&2
  exit 1
fi

grep -q '^name: codex-autoresearch$' "$ROOT/SKILL.md" || {
  echo "SKILL.md name metadata is missing or invalid" >&2
  exit 1
}
grep -q '^description:' "$ROOT/SKILL.md" || {
  echo "SKILL.md description metadata is missing" >&2
  exit 1
}
grep -q 'allow_implicit_invocation: false' "$ROOT/agents/openai.yaml" || {
  echo "Explicit invocation policy is missing" >&2
  exit 1
}

python3 -m py_compile \
  "$ROOT/scripts/autoresearch.py" \
  "$ROOT/scripts/autoresearch_core.py" \
  "$ROOT/scripts/autoresearch_report.py"
python3 -m unittest discover -s "$ROOT/tests" -p 'test_structure.py' -q

echo "Skill structure valid: $skill_bytes-byte SKILL.md, 3 references, 3 runtime modules."
