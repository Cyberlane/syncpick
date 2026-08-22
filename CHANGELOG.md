# Changelog

All notable changes are documented here. This project follows semantic
versioning.

## [0.3.0] - 2026-08-22

- Removed the modal Vim-style picker state and restored immediate fuzzy
  filtering, native `fzf` navigation and query editing, and consistent `Esc`
  cancellation. Folder-specific `Tab`, `Enter`, and `Ctrl-P` controls remain.
- Lowered the minimum supported fzf version back to 0.46 now that inputless
  NORMAL mode is no longer required.

## [0.2.3] - 2026-08-10

- Hid and disabled query input in NORMAL mode so ordinary typing is ignored;
  `i` and `/` reveal the query field in INSERT mode.
- Changed interactive yes/no prompts to react to a single key without requiring
  Enter.
- Raised the minimum supported fzf version to 0.59 for inputless NORMAL mode.

## [0.2.2] - 2026-08-10

- Fixed Vim navigation by starting every picker in a visible NORMAL mode where
  `j`/`k`, `g`/`G`, and `Ctrl-D`/`Ctrl-U` navigate directly. `i` and `/` enter
  filtering mode, while `Esc` returns to navigation.

## [0.2.1] - 2026-08-10

- Added Vim-style navigation across every picker: `Ctrl-J`/`Ctrl-K` move one
  item and `Ctrl-D`/`Ctrl-U` move half a page while letter keys remain available
  for fuzzy searching.

## [0.2.0] - 2026-08-10

- Added automatic first-run setup and friendly profile names throughout the
  server and settings pickers.
- Added per-source discovery results, absolute destination display, and
  duplicate local-folder collision blocking.
- Added folder-by-folder transfer progress, retryable failures, interruption
  handling, and explicit completion summaries.
- Added optional `--stay` sessions that refresh the remote listing before
  another selection while preserving one-shot exit behavior by default.
- Improved confirmation input, dangerous-mode warnings, dry-run flow, settings
  feedback, narrow-terminal behavior, and `NO_COLOR` support.
- Added isolated end-to-end fixtures for fzf, SSH, and rsync workflows.

## [0.1.0] - 2026-07-19

- Initial public release: configurable SSH/rsync profiles and interactive
  folder selection.
- Added per-profile queued-folder path display settings: full path, shortened
  path, or folder name only. The queue now also uses folder-name highlighting.
