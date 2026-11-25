# Linux packages — code walkthrough

[← All features](../README.md) · [How it works](FUNCTIONALITY.md) · [Setup](INSTALL.md)

`packaging/build_packages.sh` installs the app into a staging tree, then wraps it in four formats.

- `options=('!strip')`: stripping symbols from `libapp.so` breaks Flutter.
- The minimum glibc is **measured** on the binaries and written into the `.deb`.
- `user-install.sh` rewrites `Exec=` as an absolute path: a launcher does not always have `~/.local/bin` in its `PATH`.
- `.github/workflows/release.yml` redoes everything on every `v*` tag.
