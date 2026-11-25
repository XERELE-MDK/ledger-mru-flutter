# Changelog

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · numbers: [SemVer](https://semver.org/).
The three repositories ([rust](https://github.com/XERELE-MDK/ledger-mru-rust), [flutter](https://github.com/XERELE-MDK/ledger-mru-flutter), [mobile](https://github.com/XERELE-MDK/ledger-mru-mobile)) move forward with **the same number**.

> Git history starts at **1.1.3**. Earlier versions are listed for the record: their code was not kept, so they have no tag and no downloads.

## [Unreleased]

### Changed
- Documentation and READMEs are now in English.

## [1.2.0] — 2026-11-25

### Added
- **Opening balances**: what you own and owe on day one, as one balanced entry ([doc](docs/opening-balances/FUNCTIONALITY.md)).
- Per-feature documentation, automated builds, GPL-3.0 licence.
### Fixed
- Missing no-break spaces in several French messages.

## [1.1.3] — 2026-11-25

### Added
- "Start with an empty book": removes the demo, and nothing else.
### Fixed
- On first launch the demo was always created in English.
- Two demos in two languages no longer conflict.

## 1.1.2 — 2026-11-25

### Fixed
- Sync loop: an identical file is no longer rewritten.
- An entry typed during a sync could be lost or ignored.
- Undoing a deletion that was already synced did not hold.
- "Reset to demo data" and "Replace" are refused while sync is on.
- An "Undo" banner no longer closed on its own.

## 1.1.1 — 2026-11-25

### Fixed
- Unreadable local data stopped the app from opening, or got overwritten.

## 1.1.0 — 2026-11-24

### Added
- 6 complete themes, 3 languages (English, French, Japanese), Settings screen.
- Editorial, T-account and Pebbles home screens. New icon.
### Fixed
- Typing "1,250", infinite or negative amounts, fake dates on import.

[1.2.0]: https://github.com/XERELE-MDK/ledger-mru-flutter/releases/tag/v1.2.0
[1.1.3]: https://github.com/XERELE-MDK/ledger-mru-flutter/releases/tag/v1.1.3
