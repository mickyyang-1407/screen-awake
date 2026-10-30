# Download, open, paste into your AI

[繁體中文](AI-USAGE.zh-Hant.md) · [Download](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.dmg)

1. Install and open Screen Awake.
2. Click **Copy instructions for AI** and paste into Claude Code or an AI with local command tools.
3. Just ask what you want:

> Keep my screen on.
>
> Dim the screen in half an hour.
>
> Wake at 9 AM and Dim at 6 PM every day.

The copied text includes your installation's exact path and asks the assistant to read the built-in `agent-help` guide. No long installation prompt, plug-in or GUI automation is needed. These controls require **1.5.0** or later.

The assistant needs command access on this Mac. A chat without local tools cannot execute commands.

## Command reference for assistants

Treat the installed app's `agent-help` as authoritative. This example assumes Applications; the Copy button supplies the actual local path.

```sh
AWAKE='/Applications/Screen Awake.app/Contents/MacOS/ScreenAwake'
"$AWAKE" agent-help
"$AWAKE" awake on
"$AWAKE" awake off
"$AWAKE" schedule daily 09:00 18:00
"$AWAKE" schedule timer 30 dim
"$AWAKE" schedule show
"$AWAKE" schedule off
"$AWAKE" schedule cancel
```

- `wake` wakes once; `awake on` wakes once and keeps the display on; `awake off` returns to the existing idle timeout.
- `dim` releases the running app's keep-awake request before requesting display sleep. Use only when the user requests it.
- `schedule daily` takes Wake time, then Dim time, saves and enables the schedule. Overnight ranges work. Either slot can be `off`, but at least one action is required. Wake holds awake by default; append `--no-keep-awake` for a one-time wake.
- `schedule timer` takes 1–1440 whole minutes and `wake` or `dim`; it replaces the existing countdown.
- `schedule off` disables daily scheduling and leaves the countdown. `schedule cancel` cancels the countdown and leaves daily scheduling. Neither changes the current keep-awake state.
- `schedule show` returns JSON with app-running/keep-awake state, saved settings and next action. `status` reads only the display-off password requirement.

New schedules and keep-awake start the app in the background if needed. Queries, cancellations and keep-awake off do not launch a stopped app. Check JSON `success`, the returned state and exit code. A timeout means the outcome is unknown: inspect state before deciding whether to retry.

## Limits

Keep the app running for assertions and schedules; closing windows is fine, quitting stops them. Reopening resumes future events only. Expired actions are skipped. Times follow the current Mac time zone.

Wake lights the display; it cannot unlock the Mac or wake a sleeping/powered-off computer. Let the user handle passwords and Touch ID. The optional [password setup](SETUP.md) remains their choice.

A one-time wake still follows the system idle timeout. A successful request does not prove the Mac is unlocked or the display stays on/off. If observation is unavailable, report only that the request was accepted.
