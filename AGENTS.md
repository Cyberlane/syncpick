# syncpick Agent Instructions

## Operating Baseline

- Be concise, direct, and candid. Separate verified facts, assumptions, and uncertainty.
- Preserve the user's original goal and constraints; keep changes focused and simple.
- Ask questions only when a decision is materially ambiguous, risky, or needs explicit approval.
- Verify observable behavior before claiming completion, and report blockers, outcomes, and evidence.
- Preserve unrelated work. Do not take destructive local or remote filesystem actions beyond what the user authorized.

## Project Context

syncpick is a Zsh/fzf picker that uses SSH and rsync to copy selected remote folders locally. It can be safe and read-only by default, but flags like `--delete`, `--inplace`, and `--yes` can have real filesystem effects.

## Safety Rules

- Prefer `--dry-run` for any real server or large transfer investigation.
- Do not run a real rsync transfer, `--delete`, `--inplace`, or `--yes` unless the user explicitly approves the exact source, destination, and flags.
- Do not print private hostnames, usernames, directory trees, or media paths unless needed for the task; summarize where possible.
- Never store SSH keys, passphrases, passwords, or server secrets in this repo.
- Preserve safe defaults: confirmation before transfer, no deletion by default, and temporary-file writes by default.

## Verification

Use fixture or dry-run coverage where possible. For shell changes, run syntax checks and a focused command path without contacting a real server unless authorized.

## Structural Similarity Gate

- Before implementing new behavior, search `syncpick` and `install` for an existing command path or helper that already provides it.
- At the start of source-changing work, compare `.mori-version` with `gh api repos/Cyberlane/mori/releases/latest --jq .tag_name` when network access is available. If a newer release exists, update the verified binary, project skill, configuration, and any baseline in a separate reviewed change before continuing.
- Before committing shell changes, read `.agents/skills/mori-review-similarity/SKILL.md`, verify that `mori version` matches `.mori-version`, and run `mori scan --changed-since HEAD --format json .`.
- Inspect every focused Mori group in both source locations. Scores are structural review leads, never proof of equivalent command behavior or side effects.
- Resolve likely duplication or explain why the shell paths must remain separate. Do not create a baseline, lower thresholds, or enable statement blocks merely to make the gate pass.
