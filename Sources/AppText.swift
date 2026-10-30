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

enum DisplayAction: String, Sendable {
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
    var guideTitle: String { chinese ? "螢幕暗掉後，不必輸入密碼" : "Wake without a password" }
    var guideSubtitle: String { chinese ? "錄影前的設定教學" : "A short setup guide for recording" }
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
    var guideIntro: String { chinese ? "常亮開關本身不需要這項設定。只有需要讓螢幕關閉後，仍能由腳本喚醒並繼續錄影時，才需要以下步驟。" : "The keep-awake switch works without this setup. Follow these steps only if a script needs to wake the display and resume recording after it turns off." }
    var guideSteps: [(String, String)] {
        if chinese { return [
            ("如果選項是灰色，先處理 iPhone 鏡像輸出", "在 Mac 開啟「iPhone 鏡像輸出」。從上方選單選 iPhone 鏡像輸出 → 設定，將認證方式改為「每次都詢問」（Ask every time）。選項原本可修改，就跳到下一步。"),
            ("將關閉螢幕後要求密碼，設為「永不」", "打開 系統設定 → 鎖定畫面。找到「螢幕保護程式開始或顯示器關閉後要求輸入密碼」（Require password after screen saver begins or display is turned off），選「永不」（Never）。若系統要求密碼或確認，請自行完成。"),
            ("完成錄影後，可以改回「立即」", "這只調整螢幕關閉後的密碼要求，不會刪除帳號密碼。選 Never 期間，旁人也可能直接使用這台 Mac。完成後可回到同一選項，改回 Immediately。")
        ] }
        return [
            ("If the option is greyed out, check iPhone Mirroring", "Open iPhone Mirroring on your Mac. Choose iPhone Mirroring → Settings from the menu bar and select Ask every time. If the password option is already editable, skip this step."),
            ("Set the display-off password requirement to Never", "Open System Settings → Lock Screen. Find “Require password after screen saver begins or display is turned off” and choose Never. Complete any password or confirmation prompt yourself."),
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
