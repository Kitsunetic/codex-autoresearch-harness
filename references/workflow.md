# Workflow

Read this reference for every `$codex-autoresearch-harness` invocation.

## Fresh Run

1. Locate the Git root and check for an existing run with `status`. Only `not_initialized` is fresh.
2. Read the relevant source, tests, project commands, and current Git status.
3. Find a metric that directly represents the requested outcome. Prefer a project-owned scoring command over output scraping.
4. Make parsing explicit:
   - scalar: the final non-empty stdout line is a finite number;
   - JSON: the final non-empty stdout line is an object and `--metric-key` names one finite numeric field.
5. Choose repo-relative scope prefixes. Use `src`, `tests/api`, or a file path; never pass globs or absolute paths.
6. Pick a target that means the user's goal is achieved. The baseline alone is not a target.
7. Select a guard only if it passes before any edits and protects behavior not already represented by the metric.
8. Resolve orchestration from the enabled Codex plugin configuration: use `lazycodex` when `omo@sisyphuslabs` is enabled, otherwise `direct`. An explicit user choice overrides detection. Even under `lazycodex`, work directly when delegation overhead exceeds the bounded child task.
9. Ask for one confirmation before initialization. Do not turn each inferred field into a separate question when the repo already answers it.

Use this confirmation shape:

```text
Goal: ...
Scope: ...
Metric: ... (baseline ..., target ..., lower/higher is better)
Verify: ...
Guard: ... / none
Mode: foreground / background
Orchestration: direct / lazycodex
Rollback: failed trials are reverted with Git
```

If the target, scope, or external side effects are ambiguous, ask about those. Do not ask users to choose internal protocol details.

## Foreground

After approval:

1. Run `init` and surface any failure verbatim.
2. If initialization reports `complete`, do not create a Goal.
3. Otherwise reuse a matching official Goal or create one whose objective names codex-autoresearch-harness, the run id, metric, and target.
4. Follow `experiment.md` until the event status is terminal.
5. Keep normal Codex progress updates concise. The event log is the detailed audit trail.

An Escape interruption pauses official Goal execution. On a resumed task, validate the run with `status` before continuing. Do not create a second Goal for the same run.

## Background

After approval, run `launch` once. The detached controller owns continuation; the foreground task should return control to the user after the launch receipt.

Use the same skill entry for controls:

- "status" -> `status --repo <repo>`
- "stop" -> `stop --repo <repo>`
- "resume with this direction" -> `resume --repo <repo> --note <direction>`

Read `background.md` before launching or controlling a detached run.

## Read-Only Views

For any initialized run:

- "show history" -> `history --repo <repo>`
- "export TSV" -> `history --repo <repo> --format tsv`
- "generate an HTML report" -> `report --repo <repo>`

Each command validates `run.json` and the complete `events.jsonl` before rendering. The HTML file is a replaceable snapshot under `autoresearch-results/report.html`, not state and never a recovery source.

## Existing Run

Always trust validated events, not conversational memory.

- `active` foreground: continue in the current/resumed Goal task.
- `active` background with runtime `running`: report status; do not launch another controller.
- `active` background with runtime `orphaned`: report whether the recorded worker is still alive. Never resume or archive while an orphaned worker is alive. Once no worker remains, `stop` can close the event state before resume.
- `blocked`: after the external cause changes, run `resume --repo <repo> --note <what-changed>`. A foreground run then continues through the same official Goal; a background run starts a new controller.
- `error`: resume with the same command only when status reports a consistent repository and no unreverted trial. Otherwise recover Git manually and archive the run.
- `stopped`: a user-stopped background run may resume with a note. A run stopped by its iteration limit must be archived and started again with a newly confirmed limit.
- `complete`: report the result; archive before a different goal.

If the user wants a different goal, stop a live background controller first. For an active foreground run, ask the user to clear the old official Goal with `/goal clear`; the control script cannot own TUI Goal state. Then ask before running `archive`. Archiving is explicit because it changes the active run, though it preserves all prior artifacts.

If initialization failed before `run.json` was written, surface `init-error.json` and its command logs. Archive that failed attempt explicitly before retrying.

## Suitable Tasks

Autoresearch fits any task with a repeatable numeric outcome: failing test count, coverage, benchmark latency, warnings, binary size, reproducible security findings, or a project-owned score.

Do not force it onto one-shot edits, subjective design review, deployment, publishing, or tasks whose success cannot be measured repeatedly. First help the user define a reproducible metric, then start a run.
