# Background Runtime

Read this only for detached runs.

## Architecture

`launch` validates the baseline, writes the run configuration, and starts one detached controller. The controller starts one `codex exec` worker at a time. Each worker completes exactly one experiment through `finish` or records one genuine blocker through `block`, then exits.

```text
Codex TUI -> detached controller -> worker 1 -> worker 2 -> ... -> terminal event
```

The controller reads the append-only event log after every worker. It launches another worker only when the previous worker exited successfully, produced exactly one valid iteration, and the run remains active. It does not poll a second background service or use Codex hooks.

## Permissions

`danger-full-access` is the default because `finish` must write Git commits and reverts. Confirm this policy before launch. `workspace-write` is available only when the user explicitly chooses it; sandbox policy may prevent writes under `.git`, causing a visible error rather than an automatic fallback.

Background workers never create official Codex Goals. Goal continuation is a foreground feature; the controller is the background continuation mechanism.

## Lifecycle

- `status` validates the full event history and reports controller/worker PIDs.
- `stop` writes a run-scoped request. The controller terminates the active worker process tree and records `stopped` only after the repository is back at a validated boundary.
- `resume --note ...` appends the new direction and starts one new controller. It rejects completed runs, dirty repos, commit drift, and duplicate live controllers.
- An unexpected worker exit, missing event, invalid event pattern, dead controller, or controller exception is observable in `runtime.log` and becomes `error` or `orphaned`; it is never treated as progress. A live orphaned worker blocks stop/resume/archive until it exits or the user terminates it explicitly.

The foreground task should not tail the run after launch unless the user explicitly asks. Report these paths instead:

```text
autoresearch-results/events.jsonl
autoresearch-results/runtime.json
autoresearch-results/runtime.log
autoresearch-results/logs/
```

## Worker Contract

Workers receive the confirmed goal, current metric, target, scope, prior event history, and exact control-script path. They may inspect and edit the repository, but they must not:

- ask the sleeping user a question;
- launch another controller;
- create a Goal;
- commit or revert directly;
- edit run artifacts;
- perform more than one finalized experiment.

If a worker returns without a valid iteration or blocker event, the controller stops with a precise contract error. This prevents silent early exits and accidental infinite relaunch loops.
