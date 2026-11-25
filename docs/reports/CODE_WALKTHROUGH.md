# Reports — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md)

`lib/screens/reports.dart`: `_TrialBalance`, `_Monthly`, `_Budgets`, picked by `s.report`.

- The trial balance hides balances below 0.005 and calls itself balanced within 0.01: amounts are `double`s.
- Bars are `FractionallySizedBox`es; the scale is the largest amount over the 6 months.
- `compareText()` is reused by the Editorial home screen.
