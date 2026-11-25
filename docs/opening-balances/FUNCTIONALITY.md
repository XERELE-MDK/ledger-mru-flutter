# Opening balances — how it works

[← All features](../README.md) · [Code walkthrough](CODE_WALKTHROUGH.md)

*Since 1.2.0.*

## What it does

One field per asset account ("what I have") and liability account ("what I owe"), at a given date. The app turns them into **a single balanced entry**: the difference goes to equity. It is **not income**.

> I have 3,000 in cash and 21,000 in the bank, I owe 2,000 → Dr Cash 3,000, Dr Bank 21,000 / Cr Debt 2,000, Cr Opening balance 22,000.

![Opening balances](../images/opening-balances.png)

## Where

- On the home screen, while the book is empty.
- In **Accounts → Opening balances**, at any time.

## Rules

- Reopening the screen shows the saved balances; changing them **replaces** the entry.
- Clearing everything removes it.
- Your own entries on the equity account are never touched.
- If no equity account is left, one is recreated.
