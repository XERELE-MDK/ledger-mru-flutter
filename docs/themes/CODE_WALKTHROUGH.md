# Themes — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

`lib/theme.dart`

- `AppTheme`: colours, 100–900 ramps, fonts.
- `AppTheme.generate()` builds a whole theme from **5 colours** (background, surface, text, accent, second accent).
- `C`: the facade every screen reads (`C.bg`, `C.a700`). No hard-coded colour anywhere else.
- Rule: 100–300 = tinted backgrounds, 700–900 = text drawn on them, in every theme.
- Display fonts often lack "−" (U+2212) or Japanese: the body font, then the system fonts (Noto CJK…), fill the gaps.

Switching theme changes the `key` of `MaterialApp`: the whole tree is rebuilt and reads `C` again.

Adding a theme: one `AppTheme.generate(...)` in `themes`, its name in `S.themeName`, its fonts in `assets/fonts/` and `pubspec.yaml`.

Tests: WCAG contrast of every theme, presence of every font.
