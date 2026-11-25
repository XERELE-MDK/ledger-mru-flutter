# Home screens — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

- `lib/screens/home.dart` (Overview), `lib/screens/home_alt.dart` (the other three).
- `lib/main.dart`, `Shell`: a `switch (s.homeStyle)` picks the widget.
- Pebbles: diameter = `56 + √(amount / max) × 86`. The eye compares **areas**, hence the square root.
- `inkOn()` picks the ink colour from the background luminance.

Adding a home screen: one widget, one case in the `switch`, one line in `settings.dart`, two strings in `l10n.dart`, and one entry in the matrix of `test/i18n_theme_test.dart`.
