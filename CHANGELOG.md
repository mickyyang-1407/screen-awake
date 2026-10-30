# Changelog

## 1.5.2

- The bilingual in-app setup guide now starts with the download, Copy instructions for AI and natural-language workflow.
- Explain AI-created daily schedules and countdowns, how to cancel each, and how to check the next action.
- Expand the English and Traditional Chinese GitHub tutorials with examples, display-wake limits and optional password setup.

## 1.3.0

- Wake and Dim buttons in the main window and menu bar.
- Dim releases the app’s keep-awake request before asking macOS to turn off the display.
- Background command execution keeps the UI responsive, with progress, error feedback and duplicate-action prevention.

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
