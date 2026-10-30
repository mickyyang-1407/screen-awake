import Foundation

struct ScheduleText {
    let language: AppLanguage
    private var zh: Bool { language.resolved == .traditionalChinese }
    var title: String { zh ? "排程" : "Schedule" }
    var subtitle: String { zh ? "讓螢幕跟著你的作息。" : "A rhythm for your display." }
    var modes: [String] { zh ? ["每日時段", "倒數計時"] : ["Daily", "Countdown"] }
    var preset: String { zh ? "預設時段" : "Preset" }
    var presets: [String] { zh ? ["早班 · 08:00–17:00", "日間 · 09:00–18:00", "夜間 · 20:00–08:00", "自訂"] : ["Early · 08:00–17:00", "Day · 09:00–18:00", "Night · 20:00–08:00", "Custom"] }
    var dailyEnabled: String { zh ? "啟用每日排程" : "Enable daily schedule" }
    var wake: String { zh ? "Wake 喚醒螢幕" : "Wake display" }
    var dim: String { zh ? "Dim 關閉螢幕" : "Dim display" }
    var hold: String { zh ? "Wake 後保持常亮，直到 Dim 或手動關閉" : "Keep awake after Wake, until Dim or turned off" }
    var save: String { zh ? "儲存每日排程" : "Save daily schedule" }
    var saved: String { zh ? "已儲存" : "Saved" }
    var invalidDaily: String { zh ? "請選擇動作，並設定不同的時間。" : "Choose an action and use different times." }
    var quickTimer: String { zh ? "快速選擇" : "Quick timer" }
    var duration: String { zh ? "倒數時間" : "Duration" }
    var minutes: String { zh ? "分鐘" : "minutes" }
    var action: String { zh ? "時間到時" : "When time is up" }
    var startTimer: String { zh ? "開始倒數" : "Start countdown" }
    var cancelTimer: String { zh ? "取消倒數" : "Cancel countdown" }
    var replaceTimer: String { zh ? "重新開始倒數" : "Restart countdown" }
    var timerIdle: String { zh ? "尚未設定倒數。可自訂 1–1440 分鐘。" : "No countdown. Choose 1–1440 minutes." }
    var invalidMinutes: String { zh ? "請輸入 1–1440 的整數分鐘。" : "Enter a whole number from 1 to 1440." }
    var next: String { zh ? "下一次執行" : "UP NEXT" }
    var none: String { zh ? "目前沒有排程" : "Nothing scheduled" }
    var footnote: String { zh ? "請讓 App 保持執行；關閉視窗仍可運作。Mac 睡眠或關機時可能錯過排程，過期動作不會補執行。時間依目前時區。" : "Keep the app running; closing its window is fine. Mac sleep or shutdown can miss schedules. Expired actions are skipped. Times follow your current time zone." }
    var missed: String { zh ? "已略過過期動作。" : "An expired action was skipped." }
    var menuTitle: String { zh ? "排程…" : "Schedule…" }
    var activeButton: String { zh ? "排程 · 已啟用" : "Schedule · Active" }
    func event(_ event: ScheduledEvent?) -> String {
        guard let event else { return none }
        return "\(event.action.rawValue.capitalized) · \(date(event.date))"
    }
    func countdown(_ countdown: CountdownSchedule?) -> String {
        guard let countdown else { return timerIdle }
        return "\(countdown.action.rawValue.capitalized) · \(date(countdown.deadline))"
    }
    private func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: zh ? "zh_TW" : "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
