# Contributing

Codex Autoresearch Harness is intentionally small. Contributions should strengthen the single experiment loop rather than add another mode, recovery heuristic, or duplicate state layer.

Read the architecture and design rules below before changing code or protocol.

## Architecture

```text
SKILL.md
├── references/workflow.md
├── references/experiment.md
└── references/background.md

scripts/autoresearch.py         CLI and detached controller
scripts/autoresearch_core.py    strict schema, Git, commands, and events
scripts/autoresearch_report.py  read-only terminal, TSV, and HTML views
```

The user documentation is [README.md](README.md), [Installation](docs/INSTALL.md), [User Guide](docs/GUIDE.md), [Examples](docs/EXAMPLES.md), and synchronized translations under `docs/i18n/`.

## Sources Of Truth

- Product and runtime invariants: this document
- Model entry contract: `SKILL.md`
- Immutable run configuration: `autoresearch-results/run.json`
- Runtime state and audit: `autoresearch-results/events.jsonl`

Do not introduce a second state snapshot or reconstruct events from logs. Logs explain failures; they are not state. Generated history and reports are disposable projections of validated events.

## Design Rules

- Fail on malformed or contradictory input. Do not add fallback parsing.
- Fix the owning state transition, not one caller's symptom.
- Record full command/controller diagnostics before returning an error.
- Keep the initial `SKILL.md` below Codex's 8,000-byte selected-skill prompt limit.
- Keep references one level from `SKILL.md` and avoid duplicated rules.
- Preserve one repository, one metric, one target, and one finalized experiment per iteration.
- Do not add custom Codex hooks. Foreground continuity belongs to official Goals; background continuity belongs to the controller.
- Keep orchestration as immutable run configuration, not another state layer. Under `lazycodex`, the main iteration owns hypothesis selection, integration review, and `finish`; bounded children never own Git or autoresearch state.
- The background controller owns each worker process tree and must terminate it before stopping or failing.
- Do not add compatibility branches for unreleased schemas. A schema change must fail clearly and require an explicit fresh run.

## Validate

Documentation and structure:

```bash
bash scripts/run_contributor_gate.sh docs
```

Behavioral changes:

```bash
bash scripts/run_contributor_gate.sh skill
```

The skill gate runs strict unit tests plus deterministic foreground and background smoke tests. Real-model checks require local Codex authentication and are available separately through `scripts/run_skill_e2e.sh`.

## Pull Requests

Keep changes focused and explain:

1. which product invariant changed;
2. why the existing owner could not express it;
3. how failure remains observable;
4. which deterministic and real-model paths were tested.

If model behavior changes, update `SKILL.md`, the relevant reference, user documentation, and tests in the same pull request. If architecture changes, update the Architecture, Sources Of Truth, and Design Rules sections here too.
