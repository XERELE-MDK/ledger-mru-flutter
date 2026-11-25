# Opening balances — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

| File | Role |
|---|---|
| `lib/sheets.dart` | `showOpeningSheet`, `_Opening` |
| `lib/model.dart` | `openingRows`, `openingDate`, `setOpening`, `isOpeningEntry` |
| `lib/main.dart` | `_EmptyCard` |

## Recognising the entry

Its id starts with `o` followed by the time in milliseconds (`o1795…-3fa2`). That is what lets the app replace it without touching anything else.

## Balancing

```dart
final diff = (lines.fold(0.0, (t, l) => t + l.dr - l.cr) * 100).round() / 100;
if (diff != 0) lines.add(diff > 0 ? Line(eq, 0, diff) : Line(eq, -diff, 0));
```

Rounding to the cent avoids a ghost line: `0.1 + 0.2 - 0.3` is not exactly 0 in binary.

Same rules as `Book::set_opening` (Rust). Tests: `test/opening_test.dart`.
