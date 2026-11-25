# Linux packages — setup

[← All features](../README.md) · [How it works](FUNCTIONALITY.md) · [Code walkthrough](CODE_WALKTHROUGH.md)

## Build it yourself

```bash
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev rpm   # Debian / Ubuntu
sudo pacman -S clang cmake ninja gtk3 rpm-tools dpkg                   # Arch
packaging/build_packages.sh
```

## Check a download

```bash
sha256sum -c SHA256SUMS --ignore-missing
```
