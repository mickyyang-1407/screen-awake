# Screen Awake

Keep your Mac's display awake with one switch. Turn it off to return to your normal display sleep settings.

[Download for macOS](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.dmg) · [ZIP](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.zip) · [繁體中文](README.zh-Hant.md)

macOS 14 or later · Apple silicon and Intel · English and 繁體中文 · MIT

![Screen Awake in English](assets/screenshots/en-light-on.png)

## Use it

Download the DMG and drag **Screen Awake** into **Applications**, then open it. You can also unzip the ZIP and open the app directly.

**Keep display awake** keeps the display on while you're away from the keyboard. Turn the switch off to return to the system's idle display sleep settings.

Closing the window leaves the app running. Its menu bar icon or Dock icon reopens it; **⌘Q** quits and releases its keep-awake request. Your switch and language choices are remembered.

The language menu lets you choose English or Traditional Chinese instantly. The initial choice follows your system language.

Other apps may also keep the display awake. Screen Awake releases only its own request. Manual sleep, screen locking, lid close and macOS power safeguards remain under system control.

## A small native app

- Swift and AppKit, with no third-party runtime or dependencies.
- macOS power management API, with no simulated mouse movement or repeated disk scanning.
- No accounts, analytics or network requests. It does not read your documents or media; preferences stay on your Mac.

## Build from source

Use Xcode with Swift 6.2 or later:

```sh
git clone https://github.com/mickyyang-1407/screen-awake.git
cd screen-awake
zsh scripts/build.sh
open "build/Screen Awake.app"
```

The native SDK build produces a universal app with a local ad-hoc signature. No signing certificate is needed and no dependencies are downloaded.

Bug reports and focused improvements are welcome. Please include your macOS version, chosen language and expected behavior when opening an issue.

[MIT license](LICENSE). Made by [Micky Yang](https://github.com/mickyyang-1407).
