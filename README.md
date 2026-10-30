# Screen Awake

Keep your Mac’s display on with one switch. Includes a small command-line tool for recording scripts, and a built-in setup guide.

[Download for macOS](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.dmg) · [ZIP](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.zip) · [繁體中文](README.zh-Hant.md)

macOS 14 or later · Apple silicon and Intel · English and 繁體中文 · MIT

![Screen Awake in English](assets/screenshots/en-light-on.png)

## Use it

### CLI: wake → record → dim

Build the current source with `zsh scripts/build.sh --cli-only`, then call the executable directly from your agent's shell (no GUI opens). This uses the same Swift sources and skips GUI icon/bundle packaging:

```sh
./build/ScreenAwake status
./build/ScreenAwake wake
# Run your screen-recording command here and wait for it to finish.
./build/ScreenAwake dim
```

`wake` checks `/usr/sbin/sysadminctl -screenLock status` on every call, reports the result, then runs `/usr/bin/caffeinate -u -t 2` and waits for its two-second assertion to end. A successful wake exits 0. `dim` requests display sleep with `pmset displaysleepnow`. If macOS rejects it with error 1004, it tries the display-idle compatibility request (`IORequestIdle`). A successful request exits 0; this confirms acceptance, not that the physical display stayed asleep. Command failures exit nonzero, including when `pmset` reports a display-sleep failure but returns 0 itself; `--help` shows usage. Use a shell `trap` to call `dim` on exit if your recording script may fail.

[Read the setup guide](SETUP.md), including what to do when the password option is greyed out by iPhone Mirroring. You can also open it inside the app.

**Prerequisite:** Start with an unlocked session. In **System Settings > Lock Screen > "Require password after screen saver begins or display is turned off"**, select **Never** if the session must remain unlocked through display sleep. If this is not confirmed as Never (including a failed status check), `wake` prints a warning and continues. It cannot unlock an already locked session and never changes this setting itself.

The CLI neither reads nor modifies the `pmset displaysleep` timeout or any other system setting, requires no `sudo`, and leaves no continuous keep-awake assertion. The normal display timeout still applies during recording; keep each recording within that existing timeout. The app download includes the same CLI at `Screen Awake.app/Contents/MacOS/ScreenAwake`.

### GUI

Download the DMG and drag **Screen Awake** into **Applications**, then open it. You can also unzip the ZIP and open the app directly.

**Keep display awake** keeps the display on while you're away from the keyboard when explicitly enabled. It starts **off on every launch**, even if an older version saved it as on. Turn the switch off to return to the system's idle display sleep settings.

The **monitor icon** in the menu bar stays visible while the app runs. A sun inside the monitor means keep-awake is on. Click it to toggle keep-awake, reopen the window, open the setup guide or quit.

Closing the window leaves the app running. Its menu bar icon or Dock icon reopens it; **⌘Q** quits and releases its keep-awake request. Your language choice is remembered; the keep-awake switch is not restored on launch.

The **Setup guide** button explains the optional password setting and opens the relevant System Settings pane without changing it.

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

Run `zsh scripts/check.sh` for isolated CLI checks (no live display or settings changes), and `zsh scripts/render-previews.sh` for bilingual light/dark/error/guide previews.

Bug reports and focused improvements are welcome. Please include your macOS version, chosen language and expected behavior when opening an issue.

[MIT license](LICENSE). Made by [Micky Yang](https://github.com/mickyyang-1407).
