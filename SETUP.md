# Wake without a password

The keep-awake switch works without changing your password settings. This setup is only for scripts that need to wake the display after it turns off and continue recording. It does not remove your account password.

## If the password option is greyed out

If Lock Screen says “Password immediately required when iPhone Mirroring is set to automatically authenticate.”:

1. Open **iPhone Mirroring** on your Mac.
2. Choose **iPhone Mirroring → Settings…** from the menu bar.
3. Select **Ask every time**.
4. Complete any authentication prompt yourself.

This makes iPhone Mirroring ask you to authenticate before mirroring. Skip this section if the Lock Screen password option is already editable.

## Set the display-off requirement to Never

1. Open ** → System Settings → Lock Screen**.
2. Find **Require password after screen saver begins or display is turned off**.
3. Select **Never**.
4. Complete any password or confirmation prompt yourself.

While set to Never, others may be able to use this Mac. Leave your account password, FileVault and automatic login unchanged. Device management policies may also prevent changing the option.

## Use the app

- **Keep display awake ON** prevents idle display sleep while the app runs, including with the window closed.
- **OFF** releases this app’s request and follows the existing system timeout; it does not immediately turn off the display. Other apps may still keep it awake.
- **Wake** wakes the display once without enabling continuous keep-awake. **Dim** releases this app’s keep-awake request, then requests display sleep. Both actions are in the main window and menu bar; the system password setting still applies.
- The switch starts off on every launch. Your language choice is remembered.
- **Setup guide** opens these instructions inside the app, with a button to open Lock Screen settings.
- **⌘Q** quits and releases the app’s request.

## Wake → record → dim

Start from an unlocked desktop. Finish recording before requesting display sleep:

```sh
AWAKE='/Applications/Screen Awake.app/Contents/MacOS/ScreenAwake'
"$AWAKE" status
"$AWAKE" wake
# Run your recording command here and wait for completion.
"$AWAKE" dim
```

Source builds also provide `./build/ScreenAwake`. Wake ends its user-activity assertion after two seconds and leaves no continuous keep-awake process. The existing system idle timeout applies during recording. For longer recordings, explicitly enable the GUI switch and turn it off after recording before calling `dim`.

`dim` requests sleep for all displays. It does not sleep the computer, change brightness, or write system timeouts. A rejected request returns nonzero with an explanation. User input or another app can wake the display again immediately.

Never controls the password requirement after idle/display sleep. An explicit lock by you or another app still requires unlocking; Never does not cancel it. A restarted or logged-out Mac may also require authentication. The CLI cannot unlock an already locked Mac.

## Restore protection

Return to the same Lock Screen option and choose **Immediately**. You can also restore your previous iPhone Mirroring authentication choice.

Apple documentation: [iPhone Mirroring](https://support.apple.com/120421) · [Lock Screen settings](https://support.apple.com/guide/mac-help/mh11784/mac)
