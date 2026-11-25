# Languages — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

`lib/l10n.dart`, class `S`: every string is written once with its three versions.

```dart
String get tabHome => _t('Home', 'Accueil', 'ホーム');
```

A missing translation does not compile. `lib/format.dart` reads `S.current` for number and date formats. `flutter_localizations` translates the Material widgets.

In French, `:` `;` `»` are preceded by a **no-break space** (U+00A0).

Adding a language: its code in `languages` (top of `lib/l10n.dart`), one more argument to `_t`, its formats in `format.dart`.

Tests: a matrix of 3 languages × 6 themes × 10 screens at 360 dp, with no overflow.
