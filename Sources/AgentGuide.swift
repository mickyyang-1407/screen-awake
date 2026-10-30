import Foundation

enum AgentGuide {
    static func quote(_ value: String) -> String { "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'" }

    static func invitation(language: AppLanguage, executable: String) -> String {
        let command = quote(executable) + " agent-help"
        if language.resolved == .traditionalChinese {
            return "我已安裝「螢幕常亮 Screen Awake」。請先執行以下唯讀指令，了解喚醒、常亮與排程用法，再依我的要求使用：\n\(command)\n需要密碼或 Touch ID 時，請讓我親自解鎖。"
        }
        return "I installed Screen Awake. First run this read-only command to learn how to wake the display, keep it awake and set schedules, then follow my requests:\n\(command)\nLet me unlock the Mac myself if authentication is needed."
    }

    static func help(executable: String) -> String {
        let cli = quote(executable)
        return """
        Screen Awake — local AI controls
        Use this exact executable path (no downloads or dependencies needed):
        \(cli)

        Commands:
          agent-help                         Read this guide; changes nothing.
          wake                               Wake the display once, not continuous keep-awake.
          dim                                Release this app's keep-awake, then request display sleep.
          status                             Read the display-off password requirement only.
          awake on                           Wake once and keep the display on while the app runs.
          awake off                          Release this app's continuous keep-awake.
          schedule show                      JSON: actual daily/countdown settings and next action.
          schedule daily HH:MM HH:MM          Daily Wake time, then Dim time; enable and save.
          schedule daily HH:MM HH:MM --no-keep-awake
                                             Daily Wake once instead of holding awake until Dim.
          schedule off                       Disable daily schedule; countdown unchanged.
          schedule timer MINUTES wake|dim    Start/replace countdown, 1–1440 whole minutes.
          schedule cancel                    Cancel countdown; daily schedule unchanged.

        Use 'off' in either daily time slot to omit that action; at least one must remain.
        Times use the Mac's current time zone. Overnight ranges work.
        Examples:
          \(cli) schedule daily 09:00 18:00
          \(cli) schedule daily 20:00 08:00
          \(cli) schedule daily off 23:00
          \(cli) schedule timer 30 dim
          \(cli) schedule show

        awake on and new schedules start the installed app in the background if needed.
        The app owns its power assertion and timer. No separate daemon or system wake setting.
        Closing windows is fine; quitting stops execution. Future schedules resume on reopening;
        expired actions are skipped. A new installation has no enabled schedules.
        'schedule show', cancellation and 'awake off' do not launch a stopped app.
        Keep-awake and schedule commands return JSON after the app acknowledges them (or a stopped app's saved
        cancellations are written). Check success and the returned state; on timeout the outcome
        is unknown, so inspect schedule show before retrying. Exit 0 means success, otherwise nonzero.
        Do not edit private preferences or create a separate cron/launchd job.

        Follow the user's requested times/actions; do not invent a schedule. Dim only when requested
        or explicitly included in the task. A Dim request returning success does not prove the
        displays stayed off. The normal idle timeout applies after a one-time Wake.
        Wake cannot unlock the Mac or wake a sleeping/powered-off computer. status reports a setting,
        not current lock/display state. Let the user handle authentication and security settings.
        """
    }
}
