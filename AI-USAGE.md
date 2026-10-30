# Use Screen Awake with an AI assistant

[繁體中文](AI-USAGE.zh-Hant.md) · [Main guide](README.md)

An AI assistant with permission to run local commands on your Mac can call Screen Awake before work that needs the display. A chat without local command access cannot execute it. Screen Awake itself does not connect to an AI service.

You can paste the following into a task, or add it to that project's existing AI instructions after replacing the app path. Linking this page helps an assistant read the instructions; it does not automatically configure every assistant.

For a new installation, use the [complete Claude Code installation prompt (Traditional Chinese)](CLAUDE-CODE-INSTALL.zh-Hant.md).

## Copy this to your assistant

```text
Screen Awake is installed on this Mac. For work that needs the display,
use its CLI to wake the display if needed before starting.

First check these app locations, without scanning other disks:
/Applications/Screen Awake.app
~/Applications/Screen Awake.app
~/Desktop/Screen Awake.app
~/Desktop/螢幕常亮.app

The executable inside the app is Contents/MacOS/ScreenAwake.
Use the actual path you find, quoted as one argument. If it is not in
these locations, ask me where I installed it.

Run `status` to read the display-off password requirement, then `wake`
when needed. `status` does not tell you whether the Mac is unlocked.
A successful `wake` means the request was accepted; check the display
with an available observation tool before claiming it is ready.
If observation is unavailable, report only that wake was requested.

Run `dim` only when I ask to turn the display off, or when my task
explicitly includes turning it off after completion. Finish the work first.

Wake is a one-time display wake. It cannot unlock the Mac or wake a
sleeping/powered-off computer. If authentication is needed, ask me to
unlock it myself. Leave password and system security settings unchanged.
```

For one task, you can shorten that to: “Use Screen Awake to wake the display before starting this screen-based task. Do not call Dim afterwards.” Include the installed app path the first time.

## Commands

With the standard Applications installation:

```sh
AWAKE='/Applications/Screen Awake.app/Contents/MacOS/ScreenAwake'
"$AWAKE" status
"$AWAKE" wake
```

If you put the app on your Desktop instead, replace the first line with the actual name:

```sh
AWAKE="$HOME/Desktop/螢幕常亮.app/Contents/MacOS/ScreenAwake"
```

| Command | Meaning |
| --- | --- |
| `status` | Reads the display-off password requirement. Does not report current display power or whether the session is unlocked. |
| `wake` | Requests display wake, waits for its two-second user-activity assertion to end, then exits. Existing idle timeouts still apply. |
| `dim` | Requests display sleep. Use after the user's work has finished and only when requested. |

The CLI works without the GUI app running. Continuous keep-awake and schedules require the GUI app to remain running. If its keep-awake switch is on, turn that switch off before using CLI `dim`; the GUI Dim button releases its own request automatically.

## Can the assistant set a schedule?

In version 1.4.0, schedules are configured through the GUI. An assistant with macOS app-control tools can do this on your behalf; it is not limited to human clicks. Give it the times and actions you want, then have it open **Schedule**, fill **Daily** or **Countdown**, save/start, and verify the displayed next action.

An assistant with terminal access alone can use `wake`, `dim` and `status`, but there is no schedule CLI command in this version. It should not invent one or write the app's private preferences to simulate configuration. If it cannot operate Mac apps, use the schedule page yourself.

Do not choose another person's daily times without their instructions. Keep the GUI app running for saved schedules to execute; closing its window is fine.

## What the assistant can expect

- **Only the display is off:** the assistant can request a wake while the Mac and its command tools are still running.
- **The session is locked:** the display can light up, but you must unlock the Mac yourself. The optional [password setup](SETUP.md) concerns display-off authentication; it does not cancel an explicit lock by you or another app.
- **The whole Mac is asleep or powered off:** this CLI cannot wake it. Configure any separate system wake behavior yourself if needed.

Wake does not keep the display on permanently. For a long task, enable the GUI keep-awake switch or use a daily Wake schedule with **Keep awake after Wake**. This is separate from waking the display once.

If a computer-use tool locks the Mac again, stop and ask the user to unlock it. Do not disable that tool's lock protection or treat a successful wake request as proof that authentication was bypassed.
