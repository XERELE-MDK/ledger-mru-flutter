# Adding an entry — how it works

[← All features](../README.md) · [Code walkthrough](CODE_WALKTHROUGH.md)

## What it does

The **+** button opens a sheet. In **Simple** mode you pick an intent and the app writes the double entry for you:

| Choice | Debit | Credit | Example |
|---|---|---|---|
| Expense | the category | the means of payment | Taxi 300: Transport / Cash |
| Income | the account that receives | the source | Salary: Bank / Salary |
| Transfer | "Move to" | "Move from" | Withdrawal: Cash / Bank |

In **Accountant** mode you choose the debited and the credited account yourself.

## Rules

- Amount strictly positive, two different accounts.
- Type the amount any way you like: `1 250,50`, `1,250.50`, `1.250,50`, `1250.5`. `1,250` means **1250**, `12,5` means 12.5. A preview shows what was understood.
- Empty note: the app writes a label ("Transport", "Transfer to Savings"…).
- The date offered is today, or the 1st of the month on screen if it is another month.

## Fixing or deleting

An entry is never edited: you delete it and write a new one, as in real bookkeeping. Deleting offers **Undo** for 4 s.
