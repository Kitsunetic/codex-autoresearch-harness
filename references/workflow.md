# Workflow

Read this reference for every `$codex-autoresearch` invocation.

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
8. Ask for one confirmation before initialization. Do not turn each inferred field into a separate question when the repo already answers it.

Use this confirmation shape:

```text
Goal: ...
Scope: ...
Metric: ... (baseline ..., target ..., lower/higher is better)
Verify: ...
Guard: ... / none
Mode: foreground / background
Rollback: failed trials are reverted with Git
```

If the target, scope, or external side effects are ambiguous, ask about those. Do not ask users to choose internal protocol details.

## Foreground

After approval:

1. Run `init` and surface any failure verbatim.
2. If initialization reports `complete`, do not create a Goal.
3. Otherwise reuse a matching official Goal or create one whose objective names codex-autoresearch, the run id, metric, and target.
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

## Existing Run

Always trust validated events, not conversational memory.

- `active` foreground: continue in the current/resumed Goal task.
- `active` background with runtime `running`: report status; do not launch another controller.
- `active` background with runtime `orphaned`: report whether the recorded worker is still alive. Never resume or archive while an orphaned worker is alive. Once no worker remains, `stop` can close the event state before resume.
- `blocked`, `error`, or `stopped`: inspect the exact reason and logs. Resume only after the cause is addressed, with a note describing what changed.
- `complete`: report the result; archive before a different goal.

If the user wants a different goal, stop a live background controller first. For an active foreground run, ask the user to clear the old official Goal with `/goal clear`; the control script cannot own TUI Goal state. Then ask before running `archive`. Archiving is explicit because it changes the active run, though it preserves all prior artifacts.

If initialization failed before `run.json` was written, surface `init-error.json` and its command logs. Archive that failed attempt explicitly before retrying.

## Suitable Tasks

Autoresearch fits any task with a repeatable numeric outcome: failing test count, coverage, benchmark latency, warnings, binary size, reproducible security findings, or a project-owned score.

Do not force it onto one-shot edits, subjective design review, deployment, publishing, or tasks whose success cannot be measured repeatedly. First help the user define a reproducible metric, then start a run.
