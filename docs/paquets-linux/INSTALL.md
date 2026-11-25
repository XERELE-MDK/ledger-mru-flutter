# Paquets Linux — mise en place

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md) · [Parcours du code](CODE_WALKTHROUGH.md)

## Compiler soi-même

```bash
sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev rpm   # Debian / Ubuntu
sudo pacman -S clang cmake ninja gtk3 rpm-tools dpkg                   # Arch
packaging/build_packages.sh
```

## Vérifier un téléchargement

```bash
sha256sum -c SHA256SUMS --ignore-missing
```
