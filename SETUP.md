# Screen Awake user guide

[繁體中文](SETUP.zh-Hant.md) · [Download for macOS](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.dmg)

## Three steps after downloading

1. Download the DMG, drag **Screen Awake** into **Applications**, then open the app.
2. Click **Copy instructions for AI** in the main window or menu bar. Paste into **Claude Code** or an AI with command access on this Mac.
3. Ask for an action or a time: **“Keep my screen on”** or **“Dim in 30 minutes.”**

The copied text includes the installed path and asks the AI to read the app's built-in guide. No code, plug-in or GUI automation is needed. This workflow requires **1.5.1 or later**. A chat without local command tools cannot control this Mac.

## Your AI can set schedules directly

You do not have to fill in the app's schedule form. After pasting the instructions, try:

| Ask your AI | Result |
| --- | --- |
| Keep my screen on | Wake now and keep the display on while the app runs. |
| Wake my display | Wake once; the existing idle timeout still applies. |
| Dim in 30 minutes | Start a 30-minute Dim countdown, replacing the previous countdown. |
| Wake at 9 AM and Dim at 6 PM every day | Save and enable daily 09:00 Wake / 18:00 Dim, keeping awake after Wake. |
| Wake at 8 PM and Dim at 8 AM every day | Save an overnight daily schedule. |
| Disable the daily schedule | Disable daily times; leave the countdown and current keep-awake state unchanged. |
| Cancel the countdown | Cancel the countdown; leave the daily schedule and current keep-awake state unchanged. |
| Tell me the next Wake or Dim time | Read the saved settings and next action. |

After setting a schedule, ask the AI to **read back the saved times, actions and next execution time**. You can also inspect or change them in the app's **Schedule** window; both use the same settings. Say “Turn off keep-awake” to return to the system idle behavior. To stop both types of schedule, say “Disable the daily schedule and cancel the countdown.”

**Keep the app running.** Closing windows is fine; ⌘Q stops execution. Times follow this Mac's current time zone. Reopening resumes future events only; expired actions are skipped. New schedules start the app in the background if needed, but saving does not immediately wake or dim the display. New installations have no enabled schedules.

## Can the AI wake a dark display?

**Yes, if the Mac and the AI's local command tools are still running.** The AI can request a one-time Wake. Ask it to enable keep-awake if you want the display to stay on afterwards.

Wake cannot unlock a locked Mac or wake a sleeping/powered-off computer. Handle passwords and Touch ID yourself. A successful command means the request was accepted; it does not prove that the Mac is unlocked or that the display stays on/off.

## Optional: return without a password

**Keep-awake, AI controls and schedules work without changing password settings.** Follow the steps below only if you want to return after display sleep without authentication. This changes the display-off password requirement; it does not remove your account password. Decide and change the setting yourself.

### 1. If the password option is greyed out

If Lock Screen says “Password immediately required when iPhone Mirroring is set to automatically authenticate.”:

1. Open **iPhone Mirroring** on your Mac.
2. Choose **iPhone Mirroring → Settings…** from the menu bar.
3. Select **Ask every time**.
4. Complete any authentication prompt yourself.

This makes iPhone Mirroring ask you to authenticate before mirroring. Skip this section if the Lock Screen password option is already editable.

### 2. Set the display-off requirement to Never

1. Open ** → System Settings → Lock Screen**.
2. Find **Require password after screen saver begins or display is turned off**.
3. Select **Never**.
4. Complete any password or confirmation prompt yourself.

While set to Never, others may be able to use this Mac. Leave your account password, FileVault and automatic login unchanged. Device management policies may also prevent changing the option.

### 3. Check the return to the desktop yourself

1. Unlock your Mac and return to the normal desktop, then open Screen Awake.
2. Click **Dim**.
3. Wake with Space or the mouse and confirm that you return directly without Touch ID or a password.
4. Turn **Keep display awake** back on if you want the display to stay on afterwards.

Check this yourself. A successful command or a visible display wake alone does not prove that authentication was unnecessary. If authentication is still required, check whether you or another app issued a separate explicit lock; Never does not cancel such a lock.

## Use the app

- **Keep display awake ON** prevents idle display sleep while the app runs, including with the window closed.
- **OFF** releases this app’s request and follows the existing system timeout; it does not immediately turn off the display. Other apps may still keep it awake.
- **Wake** wakes the display once without enabling continuous keep-awake. **Dim** releases this app’s keep-awake request, then requests display sleep. Both actions are in the main window and menu bar; the system password setting still applies.
- The switch starts off on every launch. Your language and saved schedules are remembered; a future scheduled action may enable keep-awake again.
- **Setup guide** opens these instructions inside the app, with a button to open Lock Screen settings.
- **⌘Q** quits and releases the app’s request.

For an AI assistant, click **Copy instructions for AI** in the app and paste the result. It includes the exact local path. See [AI usage](AI-USAGE.md); local command access is required.

## Wake → record → dim

Start from an unlocked desktop. Finish recording before requesting display sleep:

```sh
AWAKE='/Applications/Screen Awake.app/Contents/MacOS/ScreenAwake'
"$AWAKE" status
"$AWAKE" wake
# Run your recording command here and wait for completion.
"$AWAKE" dim
```

Source builds also provide `./build/ScreenAwake`. Wake ends its user-activity assertion after two seconds and leaves no continuous keep-awake process. The existing system idle timeout applies during recording. For longer recordings, use `awake on`; `dim` releases the running app’s own keep-awake request before requesting sleep.

`dim` requests sleep for all displays. It does not sleep the computer, change brightness, or write system timeouts. A rejected request returns nonzero with an explanation. User input or another app can wake the display again immediately.

Never controls the password requirement after idle/display sleep. An explicit lock by you or another app still requires unlocking; Never does not cancel it. A restarted or logged-out Mac may also require authentication. The CLI cannot unlock an already locked Mac.

## Restore protection

Return to the same Lock Screen option and choose **Immediately**. You can also restore your previous iPhone Mirroring authentication choice.

Apple documentation: [iPhone Mirroring](https://support.apple.com/120421) · [Lock Screen settings](https://support.apple.com/guide/mac-help/mh11784/mac)
