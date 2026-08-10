# Changelog

All notable changes are documented here. This project follows semantic
versioning.

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
