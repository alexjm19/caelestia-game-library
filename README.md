# Caelestia Game Library

A game library widget for the [Caelestia](https://github.com/caelestia-kde/caelestia) bar (Quickshell on KDE Plasma 6). It lists every game installed on the PC with its cover, launches it with one click, and lets you mark favorites and sort the list.

Works with **Steam**, **Heroic** (Epic, GOG and Amazon), **Lutris** and any `.desktop` file with `Categories=Game;`.

| Feature | What it does |
|---|---|
| **All launchers** | Steam libraries from `libraryfolders.vdf`, Heroic's `installed.json` files, Lutris' `pga.db`, and game `.desktop` entries. Skips Proton, runtimes, redistributables and launcher/tool entries. |
| **Covers** | Reads Steam's local `librarycache`, Heroic's `images-cache`, Lutris' `coverart`, and the icon theme for desktop entries. Falls back to a gamepad icon. |
| **Favorites** | Heart on every cover. Favorites are always shown first, whatever the sort order. Stored as game IDs in the shell settings. |
| **Sort** | Recent (last played), Name (A–Z) or Store (grouped by launcher). The last choice is remembered. |
| **Filters** | Search by name, filter by store, or show only favorites. The header shows `N of M` when a filter is active. |
| **Languages** | Spanish and English UI. `Auto` follows the Caelestia shell language; it can also be forced from the plugin settings. |
| **Keyboard** | `Meta+J` opens the panel. Arrows move the selection, `Enter` launches, `Esc` closes. |

The UI is available in Spanish and English; `Auto` follows the Caelestia shell language.

## Requirements

- [caelestia-kde](https://github.com/caelestia-kde/caelestia) with its Quickshell stack. Tested with caelestia **2.7.5** on Fedora 45, KDE Plasma 6.
- Python 3 (standard library only).
- Optional: Steam, Heroic and/or Lutris. The widget only shows the stores that are installed.

The lister is read-only: it never launches a game, writes to a launcher's files, or makes network requests.

## Install

Clone the repository directly into the Caelestia plugin directory, using the folder name `biblioteca-gaming`:

```bash
git clone https://github.com/alexjm19/caelestia-game-library.git \
  ~/.config/caelestia/plugins/biblioteca-gaming
systemctl --user restart caelestia-shell
```

Then add the widget to the bar:

- **Nexus** (`Meta+U`) → **Bar** → add **Biblioteca gaming** (id `bibliotecaGaming`), or
- add `"bibliotecaGaming"` to `bar.entries` in `~/.config/caelestia/shell.json` and restart the shell.

`Meta+J` is registered automatically by the plugin.

## Usage

- Click a cover to launch the game.
- Click the **heart** on a cover to add or remove it from favorites. The heart click does not launch the game.
- Use the chips under the search box to change the sort order or show only favorites.
- The store chips (`Todas`/`All`, `Steam`, `Otros`/`Others`…) filter by launcher.

## Settings

The plugin's own settings appear in the Caelestia/Nexus plugin settings:

| Key | Default | Meaning |
|---|---|---|
| `ocultar` | empty | Comma-separated game names to hide. |
| `columnas` | `5` | Columns (3–8). |
| `filas` | `3` | Visible rows (1–6); the rest scroll. |
| `cerrarAlLanzar` | `true` | Close the panel when a game is launched. |
| `idioma` | `Auto` | `Auto` follows the shell language; `Español` or `English` force one. |

The panel also persists its UI state in `~/.config/Caelestia/caelestia-shell.conf` under `[Plugin_biblioteca-gaming]`:

```ini
favoritos=steam:1091500,lutris:some-slug
idioma=Auto
orden=recientes
soloFavoritos=false
tienda=Steam
```

`favoritos` is a comma-separated list of IDs (`steam:<appid>`, `heroic:<runner>:<app>`, `lutris:<slug>`, `app:<desktop-file>`). Editing the file by hand is safe; restart the shell or reopen the panel to pick up changes.

## Translations

`BibliotecaIdioma.qml` keeps the English strings next to the Spanish source text. `Auto` uses `Translations.activeLanguage` from Caelestia and falls back to `Qt.locale()`. To add another language, add a map to that singleton and expose it in the language selector.

The plugin does not install a `caelestia_<lang>.qm` catalog on purpose: Caelestia's translation loader keeps a single translator, so a plugin catalog would shadow the shell's own catalog instead of merging with it.

## How it works

`bin/listar-juegos` is a Python 3 script that reads the launchers' local metadata and prints one JSON array. `Popout.qml` runs it when the panel opens, then filters, sorts and renders the cards. Covers are loaded from local files with `file://` URLs.

Some limits that come from the launchers themselves:

- Heroic and `.desktop` games do not expose a last-played date, so they sort as never played under `Recientes`.
- Heroic covers are matched by app ID from its `images-cache`; if Heroic has not downloaded a cover, the card shows an icon.
- Steam must be installed in a standard location (`~/.local/share/Steam`). Extra Steam libraries listed in `libraryfolders.vdf` are included.
- Flatpak variants of the launchers are detected for Heroic (its Flatpak config) and for `.desktop` entries; the `steam`/`lutris` launch commands assume the native packages are on `PATH`.

## Privacy

The plugin reads local launcher files and local image caches. It does not send telemetry, does not use the network and does not contain any personal paths. The only write it performs is the Caelestia settings file for favorites and UI preferences.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).

Copyright (C) 2026 alexjm19.
