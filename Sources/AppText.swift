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

struct AppText {
    let language: AppLanguage
    private var chinese: Bool { language == .traditionalChinese }
    var productName: String { chinese ? "螢幕常亮" : "Screen Awake" }
    var eyebrow: String { chinese ? "顯示器控制" : "Display control" }
    var switchTitle: String { chinese ? "保持螢幕開啟" : "Keep display awake" }
    var switchHelp: String { chinese ? "關閉後，螢幕可依系統的閒置設定關閉。" : "Turn off to let the display follow the system idle setting." }
    var languageLabel: String { chinese ? "語言" : "Language" }
    var languageHelp: String { chinese ? "立即切換介面語言，不影響螢幕狀態。" : "Change the interface language without changing the display state." }
    var systemOption: String { chinese ? "跟隨系統" : "System" }
    var footer: String { chinese ? "關閉視窗後仍會運作。按 ⌘Q 結束。\n手動睡眠與鎖定仍由系統控制。" : "Keeps running when the window closes. ⌘Q quits.\nManual sleep and lock remain under system control." }
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
