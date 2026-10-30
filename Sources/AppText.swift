import Foundation

enum AppLanguage: String, CaseIterable {
    case system
    case english = "en"
    case traditionalChinese = "zh-Hant"

    var resolved: AppLanguage {
        guard self == .system else { return self }
        let preferred = Bundle.preferredLocalizations(from: ["en", "zh-Hant"],
                                                      forPreferences: Locale.preferredLanguages).first ?? "en"
        return preferred.hasPrefix("zh") ? .traditionalChinese : .english
    }
}

struct PowerError {
    let enabling: Bool
    let code: Int32
}

nonisolated enum DisplayAction: String, Sendable, Codable {
    case wake, dim
}

enum DisplayActionState {
    case idle
    case running(DisplayAction)
    case finished(DisplayAction, Int32)

    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }
    var isFailure: Bool {
        if case .finished(_, let code) = self { return code != 0 }
        return false
    }
}

struct AppText {
    let language: AppLanguage
    private var chinese: Bool { language == .traditionalChinese }
    var productName: String { chinese ? "螢幕常亮" : "Screen Awake" }
    var eyebrow: String { chinese ? "顯示器控制" : "Display control" }
    var switchTitle: String { chinese ? "保持螢幕開啟" : "Keep display awake" }
    var switchHelp: String { chinese ? "關閉後，螢幕可依系統的閒置設定關閉。" : "Turn off to let the display follow the system idle setting." }
    var sessionNote: String { chinese ? "只在本次開啟期間生效" : "For this session only" }
    var guideTitle: String { chinese ? "螢幕常亮使用教學" : "Use Screen Awake" }
    var guideSubtitle: String { chinese ? "AI 操作、排程與選用免密碼設定" : "AI controls, schedules and optional password setup" }
    var copyAITitle: String { chinese ? "複製給 AI" : "Copy instructions for AI" }
    var copyAIHelp: String { chinese ? "貼給可執行本機指令的 AI，即可使用喚醒、常亮與排程。" : "Paste into an AI with local command access to use wake, keep-awake and schedules." }
    var aiCopied: String { chinese ? "已複製 · 貼給 AI 即可" : "Copied · Paste into your AI" }
    var guideButton: String { chinese ? "設定教學" : "Setup guide" }
    var openSettings: String { chinese ? "打開鎖定畫面設定" : "Open Lock Screen settings" }
    var done: String { chinese ? "完成" : "Done" }
    var helpMenu: String { chinese ? "輔助說明" : "Help" }
    var menuBarControls: String { chinese ? "選單列控制項" : "Menu Bar Controls" }
    var wakeTitle: String { chinese ? "Wake 喚醒螢幕" : "Wake" }
    var dimTitle: String { chinese ? "Dim 關閉螢幕" : "Dim" }
    var wakeHelp: String { chinese ? "送出一次喚醒要求，不會開啟持續常亮，也無法解鎖已鎖定的 Mac。" : "Wake the display once. Does not enable keep-awake or unlock a locked Mac." }
    var dimHelp: String { chinese ? "先關閉本 App 的常亮，再送出關閉螢幕要求。密碼要求仍依系統設定。" : "Turn off this app’s keep-awake request, then sleep the display. The system password setting still applies." }
    func actionMessage(_ state: DisplayActionState) -> String {
        switch state {
        case .idle: return ""
        case .running(let action):
            if chinese { return action == .wake ? "正在喚醒螢幕…" : "正在關閉螢幕…" }
            return action == .wake ? "Waking the display…" : "Turning the display off…"
        case .finished(let action, let code):
            if code != 0 {
                return chinese ? "\(action.rawValue.capitalized) 無法完成（\(code)）。請查看設定教學。" : "\(action.rawValue.capitalized) failed (\(code)). See Setup guide."
            }
            if chinese { return action == .wake ? "已送出喚醒要求。" : "已送出關屏要求。移動滑鼠可喚醒。" }
            return action == .wake ? "Display wake requested." : "Display sleep requested. Move the mouse to wake it."
        }
    }
    var guideIntro: String { chinese ? "安裝後，直接用開關和按鈕，也能把喚醒、常亮與排程交給 AI。一般使用不需要更改密碼設定。" : "Use the switches yourself, or let your AI control wake, keep-awake and schedules. Normal use needs no password-setting changes." }
    var guideAIHeading: String { chinese ? "三步交給 AI" : "Three steps with your AI" }
    var guideAISteps: [(String, String)] {
        if chinese { return [
            ("在主視窗按「複製給 AI」", "把複製的文字貼給 Claude Code 或可執行這台 Mac 本機指令的 AI。文字已帶入安裝路徑，AI 會讀取 App 內建說明；不需要外掛或操作畫面的工具。"),
            ("直接說你要的動作或時間", "例如：「幫我保持亮屏」、「半小時後關屏」、「每天早上九點亮屏、下午六點關屏」。AI 可以直接儲存每日排程與啟動倒數，不必由你手動填寫。只想喚醒一次，就說「幫我喚醒螢幕」。"),
            ("請 AI 確認結果，並讓 App 繼續執行", "AI 應讀回排程與下一次動作。要停止時可說「停用每日排程」或「取消倒數」；兩者分開控制。關閉視窗仍有效，⌘Q 結束 App 就停止；重開只恢復未來事件，過期不補執行。時間依 Mac 目前時區。")
        ] }
        return [
            ("Click Copy instructions for AI in the main window", "Paste into Claude Code or an AI with command access on this Mac. The text includes the installed path and points to the app's built-in guide. No plug-in or GUI automation is needed."),
            ("Ask for an action or a time", "Try “Keep my screen on”, “Dim in 30 minutes”, or “Wake at 9 AM and Dim at 6 PM every day”. Your AI can save daily schedules and start countdowns directly. For a one-time wake, say “Wake my display”."),
            ("Check the result and keep the app running", "Ask your AI to read back the saved schedule and next action. “Disable the daily schedule” and “Cancel the countdown” control them separately. Closing windows is fine; ⌘Q stops execution. Reopening resumes future events only. Times follow this Mac's current time zone.")
        ]
    }
    var guideAILimits: String { chinese ? "螢幕已暗、但 Mac 仍在運作且 AI 可以執行本機指令時，AI 也能送出 Wake。Wake 只喚醒一次，常亮才會持續保持開啟；兩者都無法解鎖 Mac，或喚醒整台睡眠／關機中的電腦。純聊天網頁沒有本機工具，無法直接操作。" : "If only the display is off and the Mac and local AI tools are still running, your AI can request Wake. Wake is one-time; keep-awake holds the display on. Neither unlocks the Mac or wakes a sleeping/powered-off computer. A chat without local tools cannot control this Mac." }
    var guideSecurityHeading: String { chinese ? "選用：關屏後直接回桌面" : "Optional: return without a password" }
    var guideSecurityIntro: String { chinese ? "只有希望關屏後喚醒時不再要求認證，才需要以下設定。由你親自決定與變更；AI 不會代改安全設定。" : "Use the following setup only if you want to return after display sleep without authentication. Decide and change these settings yourself; the AI does not change them for you." }
    var guideSteps: [(String, String)] {
        if chinese { return [
            ("如果選項是灰色，先處理 iPhone 鏡像輸出", "在 Mac 開啟「iPhone 鏡像輸出」。從上方選單選 iPhone 鏡像輸出 → 設定，將認證方式改為「每次都詢問」（Ask every time）。選項原本可修改，就跳到下一步。"),
            ("將關閉螢幕後要求密碼，設為「永不」", "打開 系統設定 → 鎖定畫面。找到「螢幕保護程式開始或顯示器關閉後要求輸入密碼」（Require password after screen saver begins or display is turned off），選「永不」（Never）。若系統要求密碼或確認，請自行完成。"),
            ("用滑鼠或空白鍵，確認能直接回桌面", "先自行解鎖回到桌面，開啟本 App 並按 Dim。只用滑鼠或空白鍵喚醒，確認不需要密碼或 Touch ID；若要繼續亮屏，再開啟常亮。"),
            ("完成錄影後，可以改回「立即」", "這只調整螢幕關閉後的密碼要求，不會刪除帳號密碼。選 Never 期間，旁人也可能直接使用這台 Mac。完成後可回到同一選項，改回 Immediately。")
        ] }
        return [
            ("If the option is greyed out, check iPhone Mirroring", "Open iPhone Mirroring on your Mac. Choose iPhone Mirroring → Settings from the menu bar and select Ask every time. If the password option is already editable, skip this step."),
            ("Set the display-off password requirement to Never", "Open System Settings → Lock Screen. Find “Require password after screen saver begins or display is turned off” and choose Never. Complete any password or confirmation prompt yourself."),
            ("Check with the mouse or space bar", "Unlock your Mac yourself, open this app and click Dim. Wake with the mouse or space bar and confirm you return to the desktop without a password or Touch ID. Turn keep-awake back on if needed."),
            ("Restore Immediately when recording is finished", "This changes the password requirement after display sleep; it does not remove your account password. While set to Never, others may be able to use this Mac. Return to the same option and choose Immediately when finished.")
        ]
    }
    var guideFootnote: String { chinese ? "Never 不會取消手動或其他程式送出的「立即鎖定」；這些情況仍需自行解鎖。若選項是灰色，可能受裝置管理政策限制。" : "Never does not cancel an explicit lock by you or another app; unlock those sessions yourself. Device management policies may also prevent changing this setting." }
    var languageLabel: String { chinese ? "語言" : "Language" }
    var languageHelp: String { chinese ? "立即切換介面語言，不影響螢幕狀態。" : "Change the interface language without changing the display state." }
    var systemOption: String { chinese ? "跟隨系統" : "System" }
    var footer: String { chinese ? "關閉視窗後仍會運作 · ⌘Q 結束\n每次啟動預設關閉常亮。" : "Runs with the window closed · ⌘Q quits\nKeep-awake starts off on every launch." }
    var showWindow: String { chinese ? "顯示視窗" : "Show Window" }
    var quit: String { chinese ? "結束螢幕常亮" : "Quit Screen Awake" }
    func state(_ enabled: Bool) -> String {
        if chinese { return enabled ? "保持螢幕開啟" : "依系統設定" }
        return enabled ? "Display stays on" : "System default"
    }
    func detail(_ enabled: Bool) -> String {
        if chinese { return enabled ? "螢幕不會因閒置而關閉。" : "允許螢幕依系統的閒置設定關閉。" }
        return enabled ? "Your display won’t turn off while idle." : "Your display follows the system idle setting."
    }
    func currentState(_ enabled: Bool) -> String {
        chinese ? "目前：\(state(enabled))" : "Current: \(state(enabled))"
    }
    func error(_ error: PowerError) -> String {
        if chinese {
            return "\(error.enabling ? "無法保持螢幕開啟" : "無法恢復系統設定")（\(error.code)）。請再試一次。"
        }
        return "\(error.enabling ? "Couldn’t keep the display awake" : "Couldn’t restore system default") (\(error.code)). Try again."
    }
}
