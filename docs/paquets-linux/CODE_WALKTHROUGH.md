# Paquets Linux — parcours du code

[← Toutes les fonctionnalités](../README.md) · [Fonctionnement](FUNCTIONALITY.md) · [Mise en place](INSTALL.md)

`packaging/build_packages.sh` installe l'app dans une arborescence, puis l'emballe en quatre formats.

- `options=('!strip')` : retirer les symboles de `libapp.so` casse Flutter.
- La glibc minimale est **mesurée** sur les binaires et reportée dans le `.deb`.
- `user-install.sh` réécrit `Exec=` en chemin absolu : un lanceur n'a pas toujours `~/.local/bin` dans son `PATH`.
- `.github/workflows/release.yml` refait tout à chaque étiquette `v*`.
