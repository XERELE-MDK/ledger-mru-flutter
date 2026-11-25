# Import and export — how it works

[← All features](../README.md) · [Code walkthrough](CODE_WALKTHROUGH.md)

**Export** saves the whole book to a JSON file that all three versions can read.

**Import** checks the **whole** file before touching anything, then offers:

| Choice | Effect |
|---|---|
| **Merge** | keeps both sides, deletions included. The preview says what will change. |
| **Replace** | takes the file as it is. Refused while sync is on. |

**Undo** is offered afterwards.

Known limit: undoing a **merged** import does not hold while sync is on.
