#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-skill}"

case "$MODE" in
  docs)
    bash "$ROOT/scripts/validate_skill_structure.sh"
    ;;
  skill)
    bash "$ROOT/scripts/validate_skill_structure.sh"
    python3 -m unittest discover -s "$ROOT/tests" -q
    bash "$ROOT/scripts/run_skill_e2e.sh" foreground-smoke --clean
    bash "$ROOT/scripts/run_skill_e2e.sh" runtime-smoke --clean
    ;;
  help|-h|--help)
    echo "Usage: bash scripts/run_contributor_gate.sh [docs|skill]"
    ;;
  *)
    echo "Unknown gate: $MODE" >&2
    exit 2
    ;;
esac
