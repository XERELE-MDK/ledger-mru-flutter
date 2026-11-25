# Ledger MRU — Flutter

[![CI](https://github.com/XERELE-MDK/ledger-mru-flutter/actions/workflows/ci.yml/badge.svg)](https://github.com/XERELE-MDK/ledger-mru-flutter/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/XERELE-MDK/ledger-mru-flutter)](https://github.com/XERELE-MDK/ledger-mru-flutter/releases/latest)
[![Licence: GPL-3.0](https://img.shields.io/badge/licence-GPL--3.0-blue)](LICENSE)

**Personal bookkeeping in Mauritanian ouguiya (MRU).** Real double-entry accounting, hidden behind a Simple mode: you say "I spent 300 on a taxi", the app writes the debit and the credit.

No account, no server, no ads. Your book is one JSON file that stays on your devices.

<p>
  <img src="docs/images/overview.png" width="180" alt="Overview home screen">
  <img src="docs/images/editorial.png" width="180" alt="Editorial home screen">
  <img src="docs/images/pebbles.png" width="180" alt="Pebbles home screen">
  <img src="docs/images/opening-balances.png" width="180" alt="Opening balances">
</p>

This repository holds **the Dart code** (screens, logic, tests) and **the Linux desktop version**. The Android app is built from this same code.

## Download

| Platform | Get it | Notes |
|---|---|---|
| 📱 **Android** 7.0+ | [ledger-mru-mobile → Releases](https://github.com/XERELE-MDK/ledger-mru-mobile/releases/latest) | take `arm64-v8a` (almost every phone since 2017) |
| 🐧 **Linux**, same app as the phone | [Releases](https://github.com/XERELE-MDK/ledger-mru-flutter/releases/latest) | `.pkg.tar.zst` · `.deb` · `.rpm` · `.tar.gz` (no root) |
| 🪶 **Linux**, lightweight | [ledger-mru-rust → Releases](https://github.com/XERELE-MDK/ledger-mru-rust/releases/latest) | ~21 MiB of memory, English only, 2 themes |

```bash
sudo pacman -U ledger-mru-flutter-*.pkg.tar.zst   # Arch, Manjaro
sudo apt install ./ledger-mru-flutter_*.deb        # Debian 12+, Ubuntu 22.04+
sudo dnf install ./ledger-mru-flutter-*.rpm        # Fedora 35+, openSUSE
```

Check a download: `sha256sum -c SHA256SUMS --ignore-missing`. More in [Linux packages](docs/linux-packages/FUNCTIONALITY.md).

## Two-minute tour

1. **First launch**: three months of demo data, in your device's language. Look around.
2. **Start for real**: *Start with an empty book* removes the demo, and only the demo.
3. **Say what you own and owe**: *Accounts → Opening balances* (cash, bank, debts). One balanced entry, not income.
4. **Add entries** with **+**: Expense, Income or Transfer. Type amounts however you like: `1 250,50`, `1,250.50`, `1250.5`.
5. **Read your month**: Journal, Ledger, Reports (trial balance, 6 months, budgets).
6. **Sync your devices** (optional): point every device at the same shared folder.

## Features

| | |
|---|---|
| ✍️ [Adding an entry](docs/entry/FUNCTIONALITY.md) | Simple mode (expense / income / transfer) or Accountant mode (pick debit and credit) |
| 📖 [Journal](docs/journal/FUNCTIONALITY.md) · [Ledger](docs/ledger/FUNCTIONALITY.md) | The month by day; one account with its running balance |
| 📊 [Reports](docs/reports/FUNCTIONALITY.md) | Trial balance, 6-month comparison, budgets (orange at 80 %, red past 100 %) |
| 🗂️ [Accounts and budgets](docs/accounts-and-budgets/FUNCTIONALITY.md) | Assets, liabilities, equity, income, expenses; a monthly budget per category |
| 🏁 [Opening balances](docs/opening-balances/FUNCTIONALITY.md) | What you have and owe on day one |
| 🧪 [Empty book and demo](docs/empty-book-and-demo/FUNCTIONALITY.md) | Try with examples, then start clean |
| 🏠 [Home screens](docs/home-screens/FUNCTIONALITY.md) | Overview, Editorial, T-account, Pebbles |
| 🎨 [Themes](docs/themes/FUNCTIONALITY.md) · 🌍 [Languages](docs/languages/FUNCTIONALITY.md) | 6 themes, 3 languages (below) |
| 📤 [Import and export](docs/import-export/FUNCTIONALITY.md) | One JSON file, merged or replaced, with a preview and Undo |
| 🔄 [Sync](docs/sync/FUNCTIONALITY.md) | Across devices through a shared folder (Syncthing…), no server |
| 🛟 [Data safety](docs/data-safety/FUNCTIONALITY.md) | Unreadable data is kept aside, never overwritten |

### Themes

Each theme changes colours **and** fonts. All fonts are bundled.

| Theme | Mode | Fonts (headings / body) |
|---|---|---|
| **Organic** | light or dark, follows the system | Caprasimo / Figtree |
| **Cappuccino** | dark | DM Serif Display / Nunito |
| **AMOLED Black** | dark, pure black | Space Grotesk / Inter |
| **Arctic** | light | Comfortaa / Lexend |
| **Sahara** | light | Playfair Display / Karla |
| **Sakura** | light | Quicksand / Mulish |

### Languages

| Language | Amounts | Dates |
|---|---|---|
| **English** (default) | `1,250.50` | `Fri, Nov 20` |
| **Français** | `1 250,50` | `ven. 20 nov.` |
| **日本語** | `1,250.50` | `11月20日(金)` |

The device language is used when supported; change it any time in Settings, no restart.

## Sync in three steps

1. Share a folder between your devices with [Syncthing](https://syncthing.net) (or any file-copying tool).
2. On the device with your real data: *Settings → Data & sync → Choose sync folder*.
3. On the others: same folder, then *Merge* (or *Use folder data* if the device has nothing to keep).

Each device writes **only its own file** and merges the others', so there are no conflicts. [How it works](docs/sync/FUNCTIONALITY.md).

## Privacy

- Everything stays on your devices; the Android app has **no Internet permission**.
- No account, no analytics, no ads.
- Files are plain JSON: readable, exportable, yours. They are not encrypted.

## The Ledger MRU family

| Repository | What | For |
|---|---|---|
| [ledger-mru-flutter](https://github.com/XERELE-MDK/ledger-mru-flutter) (here) | Dart: screens, logic, tests, Linux build | Linux PC, same app as the phone |
| [ledger-mru-mobile](https://github.com/XERELE-MDK/ledger-mru-mobile) | Android project, uses this code as a submodule | phone |
| [ledger-mru-rust](https://github.com/XERELE-MDK/ledger-mru-rust) | Rust + Slint rewrite | Linux PC, lightweight |

All three read and write **the same JSON file**. The Dart and Rust logics are checked against the same test cases (`CONTRACT.sha256`).

## Build from source

Flutter **3.44.4** (stable).

```bash
git clone https://github.com/XERELE-MDK/ledger-mru-flutter.git
cd ledger-mru-flutter
flutter pub get
flutter test
flutter run -d linux
```

| Folder | Role |
|---|---|
| `lib/` | `model.dart` (book, merge), `sync.dart`, `l10n.dart`, `theme.dart`, `screens/` |
| `test/` | unit and widget tests, shared fixtures with Rust |
| `assets/fonts/` | bundled fonts (SIL OFL) |
| `branding/` | icon generator |
| `packaging/` | Arch, Debian, RPM, rootless archive |

## Documentation

[**docs/**](docs/README.md) — one folder per feature: what it does, how it is coded. Also: [Changelog](CHANGELOG.md) · [Versioning](docs/VERSIONING.md).

## Licence

[GPL-3.0](LICENSE). Fonts: SIL OFL 1.1, see [assets/fonts/LICENSES.md](assets/fonts/LICENSES.md).
