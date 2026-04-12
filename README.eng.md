# Magic Folder

A KDE Plasma 6 panel widget that automatically moves files to predefined folders when you drop them onto the icon — a modern reimplementation of the classic Magic Folder widget from Plasma 4.

![KDE Plasma 6](https://img.shields.io/badge/KDE%20Plasma-6.0%2B-blue?logo=kde)
![License](https://img.shields.io/badge/license-GPL--2.0--or--later-green)

---

## Features

- 📂 **Drag & drop** files onto the panel icon to sort them instantly
- 📋 **9 predefined categories** — Video, Audio, Images, Documents, Ebooks, Archives, APKs, Source code, Binaries
- ✏️ **Graphical rule editor** — add, edit, reorder and delete rules without touching any config file
- 🔔 **Native KDE notifications** showing which files were moved and where
- ⚖️ **Conflict handling** — keep both files (auto-rename), skip, or overwrite
- 🔒 Files with no matching rule are left untouched

## Screenshots

> _Add screenshots here_

---

## Requirements

| Dependency | Package (Debian/Ubuntu) | Notes |
|---|---|---|
| KDE Plasma 6.0+ | — | Required |
| plasma5support | `plasma5support` | Required for command execution |
| notify-send | `libnotify-bin` | Required for notifications |
| kpackagetool6 | `plasma-sdk` | Required for installation |

---

## Installation

### From release

Download the latest `magic-folder.plasmoid` from the [Releases](../../releases) page, then:

```bash
kpackagetool6 -t Plasma/Applet --install magic-folder.plasmoid
```

### From source

```bash
git clone https://github.com/YOUR_USERNAME/magic-folder.git
cd magic-folder
kpackagetool6 -t Plasma/Applet --install .
```

Then **right-click the panel → Add widgets → search "Magic Folder"** and drag it to the panel.

### Reinstall / update

```bash
rm -rf ~/.local/share/plasma/plasmoids/org.kde.plasma.magicfolder
kpackagetool6 -t Plasma/Applet --install magic-folder.plasmoid
plasmashell --replace &
```

---

## Usage

1. Add the widget to your panel
2. Right-click the icon → **Configure Magic Folder**
3. In the **Rules** tab, click the pencil icon on any category and set a destination folder
4. The rule activates automatically once a destination is set
5. Drop files onto the panel icon — done!

### Rule evaluation

Rules are evaluated **top to bottom** — the first match wins. You can reorder rules using the arrow buttons.

Files that don't match any active rule are left in place and appear with `?` in the notification.

### Predefined categories

| Category | Extensions |
|---|---|
| Video | mp4, avi, mkv, mov, wmv, flv, webm, m4v, 3gp, ts |
| Audio | mp3, flac, wav, aac, ogg, m4a, wma, opus, aiff |
| Images | jpg, jpeg, png, gif, webp, bmp, tiff, heic, svg, raw |
| Documents | pdf, doc, docx, xls, xlsx, ppt, pptx, txt, odt, ods, odp, rtf, csv |
| Ebooks | epub, mobi, azw, azw3, fb2, djvu |
| Archives | zip, rar, 7z, tar, gz, bz2, xz |
| APKs | apk, xapk, apks |
| Source code | py, sh, bash, c, cpp, h, kt, java, js, ts, html, json, sql, go, rs… |
| Binaries | exe, msi, deb, rpm, appimage, run, bin, elf, dll, jar… |

---

## Configuration

### Conflict strategy

Configurable in the **General** tab:

| Option | Behavior |
|---|---|
| Skip | Leave the file in place if destination already has a file with the same name |
| **Keep both** _(default)_ | Auto-rename: `file.ext` → `file_1.ext` → `file_2.ext`… |
| Overwrite | Replace the existing file silently |

---

## Uninstall

```bash
kpackagetool6 -t Plasma/Applet --remove org.kde.plasma.magicfolder
```

---

## Troubleshooting

**Widget doesn't appear in the catalog after install**
```bash
plasmashell --replace &
```

**No notifications**
Make sure `libnotify-bin` is installed:
```bash
sudo apt install libnotify-bin
# Test:
notify-send "Test" "Hello"
```

**DBus error on install** (`Invalid object path: /KPackage/`)
This is a known Plasma 6 cosmetic bug — the installation succeeds regardless.

**View live errors**
```bash
journalctl --user -f | grep plasmashell
```

---

## License

GPL-3.0-or-later
