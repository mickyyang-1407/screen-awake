# Changelog

## 1.2.1

- A consistent monitor icon in the menu bar, with a sun inside when keep-awake is on.
- Direct access to the setup guide from the menu bar, alongside the toggle and window controls.

## 1.2.0

- Refined native light/dark interface and a menu bar icon that reflects the awake state.
- Built-in bilingual setup guide, including the iPhone Mirroring greyed-out password option.
- CLI `wake`, `dim`, `status`, `--help` and `--version` without opening the GUI.
- Handle display-sleep rejection even when pmset exits zero; compatibility path for error 1004.
- Keep-awake now starts off on every launch; the language preference is retained.
- Stage and validate builds before replacing a previous working output.
- Isolated CLI checks and 20 localized state/guide previews.

## 1.1.0

First public release.

- Compact native interface with light and dark appearances.
- English and Traditional Chinese, with an in-app language selector.
- One switch to keep the display awake or return to system settings.
- Menu bar access and remembered preferences.
- Universal macOS app for Apple silicon and Intel.
- MIT-licensed source and ready-to-use downloads.
