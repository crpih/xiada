# Log the word that triggers a pruning rule

## Objective
Extend the existing pruning-rule diagnostic so Docker stderr logs show both the matched rule and the actual word(s) in the matched window that triggered it.

## Problem and rationale
The Galician Xiada pruning system already reports the rule pattern when it prunes, but patterns may contain alternatives, wildcards, or negations and do not identify the actual sentence token. Printing the observed window words alongside the rule is the smallest useful diagnostic and avoids adding a tracing subsystem.

## Scope and constraints
- Branch: `feat/pruning-rule-trigger-word`.
- Worktree: `/home/david/repos/xiada-pruning-rule-log`, based on `dev`.
- Keep changes limited to the pruning compiler/generated runtime and focused test coverage.
- Preserve the main checkout's unrelated proper-noun modifications.
- No database rebuild; link databases before any database-dependent test.
- No push or PR without explicit user authorization. User authorized the work-unit commit and merge into `dev` on 2026-10-08.

## Tasks
- [x] T1 — Add focused coverage proving diagnostics report actual matched words, not only the rule pattern.
- [x] T2 — Extend generated pruning diagnostics with indexed observed window words without changing pruning behavior.
- [x] T3 — Run focused checks and inspect exact diff; record skipped checks.
- [x] T4 — Create a Jira Task in Corga (`COR`) and record its key: [COR-257](https://nlpgo.atlassian.net/browse/COR-257).

## Acceptance criteria
- A matching rule emits its description and actual window word values with indices to stderr.
- Matching and breaking-point return value remain unchanged.
- Focused test distinguishes actual word from pattern.
- Change remains minimal and isolated.

## Verification
- Focused generated/runtime test using alternative or wildcard rule pattern.
- Direct Galician Xiada pruning smoke test.
- `git diff --check` and scoped diff review.
- No full suite unless focused checks indicate need.

## Progress and evidence
- Exploration confirmed the existing `STDERR` rule log and the compiler's access to the matching `window`.
- Direct smoke test before implementation confirmed pruning activates on `dev`-equivalent code; no database was needed.
- ODD task doc and isolated worktree created on `feat/pruning-rule-trigger-word`, based on `dev`.
- Extended generated stderr messages to retain the rule and report indexed window words; nil slots print `<empty>`. Pruning match logic and breaking-point returns are unchanged.
- Test-first evidence: RED exposed missing word output; a second RED exposed nil dereference; GREEN passed after the nil-safe correction.
- Focused test: `bundle exec ruby test/pruning_system_test.rb` — 1 run, 5 assertions, 0 failures/errors/skips.
- `git diff --check` on the three implementation files passed; reviewer notes this command did not inspect the untracked test file.
- Regenerated only `running/galician_xiada/pruning_system.rb` from the compiler.
- No full suite or database-dependent tests run.
- Jira task created: [COR-257](https://nlpgo.atlassian.net/browse/COR-257), type Task, Medium priority. Board `CORGA/XIADA` (ID 17) is Kanban and has no backlog; the issue is visible on the board in status BACKLOG. Explicit backlog-assignment API attempt was rejected because the Kanban board has no backlog.
- Implementation work-unit commit: `c12cd31` (`[COR-257] feat: log matched pruning words`).
- Merge to `dev` is authorized and pending.
