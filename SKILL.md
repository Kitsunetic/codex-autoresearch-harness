---
name: codex-autoresearch-harness
description: "Run autonomous, measurable experiments in a Git repository: change one hypothesis, verify a numeric metric, keep improvements, and revert failures. Use when the user wants Codex to keep iterating toward a numeric target in the foreground or as a detached background run. Do not use for ordinary one-shot coding, open-ended work without a mechanical metric, or non-Git directories."
metadata:
  short-description: "Run measurable autonomous experiments"
---

# Codex Autoresearch Harness

Turn a repo-level goal into a controlled loop:

`inspect -> change one thing -> verify -> keep or revert -> repeat`

Codex supplies the engineering judgment. The bundled control script supplies strict Git boundaries, measurement, rollback, state, and logs.

## Load

- Read `references/workflow.md` for every invocation, including status, history, report, stop, and resume.
- Read `references/experiment.md` before starting or continuing an active run.
- Read `references/background.md` only for a background run.

Resolve commands from this skill's own directory as `<skill-root>/scripts/autoresearch.py`. Never assume the target repository contains the script.

## Before Starting

1. Require one Git repository root. If the task spans repositories, ask the user to choose one run per repository.
2. Check for `autoresearch-results/run.json` with:

   ```bash
   python3 <skill-root>/scripts/autoresearch.py status --repo <repo>
   ```

   `not_initialized` is fresh. Any other status or schema error must be surfaced; do not infer state from other files.
3. For a fresh run, inspect the repo and propose:
   - one plain-language goal,
   - repository-relative file or directory scopes (no globs),
   - one numeric metric and whether lower or higher is better,
   - a command whose final non-empty stdout line is that number, or a JSON object plus one explicit key,
   - a numeric target,
   - an optional baseline-passing guard command,
   - foreground or background,
   - orchestration policy: detected enabled LazyCodex defaults to `lazycodex`, otherwise `direct`; an explicit choice wins,
   - an optional iteration limit.
4. Run candidate measurement commands read-only if needed, then show one concise confirmation. Include the baseline, target, scope, commands, mode, orchestration policy, and the fact that each trial is committed and failed trials are reverted.
5. Do not write project files, initialize artifacts, create a Goal, or launch a controller before clear user approval such as `go`.

## Start

After approval, use the exact confirmed values.

### Foreground

Initialize once:

```bash
python3 <skill-root>/scripts/autoresearch.py init \
  --repo <repo> --goal <goal> --scope <path> \
  --metric-name <name> --direction <lower|higher> \
  --verify <command> [--metric-key <key>] --target <number> \
  [--guard <command>] [--max-iterations <n>] \
  [--orchestration-policy <direct|lazycodex>]
```

Then call `get_goal`. Reuse a matching unfinished Goal, otherwise call `create_goal`. The Goal objective must identify this as codex-autoresearch-harness, include the returned run id, metric and target, and say to continue the validated experiment loop until terminal status. If a different unfinished Goal exists, stop and explain the conflict. Official Codex Goal continuation owns foreground persistence; this skill does not install hooks or modify Codex configuration.

If Goal tools are unavailable, do not claim the foreground run can continue autonomously across turns. Explain that the installed Codex does not expose the required Goal capability.

### Background

Launch once with the same configuration:

```bash
python3 <skill-root>/scripts/autoresearch.py launch \
  --repo <repo> --goal <goal> --scope <path> \
  --metric-name <name> --direction <lower|higher> \
  --verify <command> [--metric-key <key>] --target <number> \
  [--guard <command>] [--max-iterations <n>] \
  [--orchestration-policy <direct|lazycodex>] \
  --execution-policy <danger-full-access|workspace-write>
```

Background defaults to `danger-full-access`; show this in the confirmation. Use `workspace-write` only when the user explicitly prefers the sandbox and accepts that Git operations may be restricted. Do not create a Codex Goal for background runs.

After a successful launch, report the run id, baseline, controller PID, results path, and status command. Do not poll unless asked.

## Experiment Loop

For each foreground iteration:

1. Read validated status and recent events.
2. Inspect evidence and choose one focused hypothesis that differs from discarded attempts. If `run.json` selects `lazycodex`, apply the bounded routing contract in `references/experiment.md`; the main task still owns the hypothesis, integration review, and finalization.
3. Modify only confirmed scopes. Do not manually commit, revert, or edit `autoresearch-results/`.
4. Finalize exactly once:

   ```bash
   python3 <skill-root>/scripts/autoresearch.py finish \
     --repo <repo> --description <short-description>
   ```

`finish` checks scope and Git provenance, creates the trial commit, runs the metric and guard, keeps an improvement, reverts a failed trial, appends the audit event, and marks the run complete when the target is reached.

Continue immediately while status is `active`. On `complete`, verify status, call `update_goal(status="complete")`, and summarize the baseline, final metric, iterations, and retained commits.

Use `block` only when progress truly requires external input or an environment change, and only after the same blocker has prevented progress on three consecutive Goal turns:

```bash
python3 <skill-root>/scripts/autoresearch.py block --repo <repo> --reason <reason>
```

Then call `update_goal(status="blocked")`. A failed hypothesis, difficult bug, or lack of immediate improvement is not a blocker.

## Existing Runs

- History request: run `history --repo <repo>`; use `--format tsv` only for tabular export.
- HTML report request: run `report --repo <repo>` and return its generated path. Both views validate the complete event history; neither is runtime state.
- Same foreground goal: validate `status`, resume the matching official Goal, and continue.
- Background `status`, `stop`, or `resume`: use the corresponding script command. Resume requires a user note or new direction.
- Different goal: show the current run. Stop a live background run first; for an active foreground run, ask the user to clear its official Goal with `/goal clear`. Then ask before `archive` and initialize the fresh run.
- `complete`: never resume it. Archive before a new goal.
- Invalid JSON, unknown schema, event gap, Git mismatch, stale controller, out-of-scope change, or malformed metric output: stop and report the exact error and log path. Never reconstruct, guess, or silently repair state.
- A failed initialization may leave `init-error.json` and command logs but no `run.json`. Report the diagnostic and use explicit `archive` before retrying; do not treat it as a fresh run.

## Invariants

1. Ask before the first write or launch.
2. Require a clean named Git branch at initialization.
3. Keep one authoritative configuration in `run.json` and one append-only state history in `events.jsonl`.
4. Use one numeric metric and one target. A guard is pass/fail and must pass at baseline.
5. One focused experiment per `finish`; one repository per run.
6. Never stage autoresearch artifacts or touch paths outside confirmed scope.
7. Verification commands must exit zero, emit UTF-8, and use an explicit scalar or JSON-key parser. Parsing or command errors stop the run.
8. Never hide failures with fallback parsing, old-layout recovery, or synthetic success.
9. Never ask "should I continue?" after launch. Continue until target, user stop, iteration limit, or a verified external blocker.
10. Preserve command output and controller events under `autoresearch-results/` for diagnosis.
