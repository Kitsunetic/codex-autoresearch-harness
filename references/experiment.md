# Experiment Contract

Read this before any active foreground iteration. Background workers receive the same contract from the controller.

## Source Of Truth

`autoresearch-results/run.json` is immutable run configuration. `autoresearch-results/events.jsonl` is the append-only state history. Current status is derived by validating every event in order; no cache or conversation summary overrides it.

Never edit either file manually. Use only `<skill-root>/scripts/autoresearch.py`.

## One Iteration

1. Run `status` and read recent `iteration` events.
2. Inspect code and evidence. State a concrete hypothesis internally.
3. Make one coherent change in the configured scope.
4. Do not commit. Call `finish --description ...`.
5. Read the returned outcome:
   - `keep`: the metric improved and the guard passed; continue from the retained commit.
   - `discard`: the metric did not improve or the guard failed; the trial was committed and reverted; choose a different hypothesis.
   - `complete`: target reached; stop.
   - error: stop and diagnose the exact invariant, command log, or Git problem.

`finish` is deliberately the only closeout path. It checks that the branch and retained commit still match, rejects out-of-scope changes, creates the trial commit, captures full command output, and records the resulting commit lineage.

## Measurement

The verify command must:

- be deterministic enough to compare consecutive experiments;
- exit zero when measurement succeeds, even when the measured result is bad;
- emit UTF-8;
- put either one finite number or one JSON object on its final non-empty stdout line;
- avoid modifying tracked or untracked project files.

The guard is different: its exit code is the result. It must pass at baseline. A trial with an improved metric but failing guard is discarded.

If a benchmark is noisy, fix the benchmark methodology or choose a stable aggregate before launch. Do not reinterpret a worse number as success inside the loop.

## Git Boundary

Initialization requires a clean named branch and a working Git author/committer identity. During a run:

- autoresearch owns only its own trial and revert commits;
- the user or another process must not switch branches, move HEAD, or edit the repo concurrently;
- `autoresearch-results/` remains uncommitted;
- scope is a list of path prefixes, not shell globs;
- generated files from verify or guard are treated as an error, not silently deleted.

Failed trials use `git revert`, preserving a visible audit trail without destructive reset. The next experiment always starts from the commit recorded by the latest valid event.

## Failure Semantics

Fail immediately on malformed JSON, duplicate keys, unknown schema fields, missing or partial event lines, invalid transitions, nonnumeric metrics, command timeout, non-UTF-8 output, unexpected Git state, or rollback failure.

Do not reconstruct missing state from logs, infer a metric from prose, skip a failed guard, or mark work complete because a worker ran out of time. Full verify/guard output lives under `autoresearch-results/logs/`; background lifecycle events live in `runtime.log`.

## Blocked

A difficult problem is still active. A run is blocked only when every meaningful experiment depends on unavailable human information, credentials, data, hardware, service access, or another external state change.

For foreground Goals, confirm that the same blocker persists across three consecutive Goal turns before recording `block` and marking the Goal blocked. For background, a worker may block only with a precise, actionable reason and a clean repository.
