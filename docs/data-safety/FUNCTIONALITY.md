# Data safety — how it works

[← All features](../README.md) · [Code walkthrough](CODE_WALKTHROUGH.md)

- Unreadable local data does **not** stop the app from opening.
- An **exact copy** is kept before anything is written. A banner explains it, with "Save the copy"; the button stays in Settings.
- If that copy fails (disk full), **nothing is saved** until the next start, and the app says so.
- Sync is disconnected: the demo on screen cannot overwrite the good copy in the folder.
- To get your data back: reconnect the folder, then "Use folder data".
