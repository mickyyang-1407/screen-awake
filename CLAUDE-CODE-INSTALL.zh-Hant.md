# Claude Code 安裝範本

一般使用者只要[下載 App](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.dmg)、打開、按 **複製給 AI** 即可。[三步使用說明](AI-USAGE.zh-Hant.md)。

想連下載安裝也交給 Claude Code，可以貼這段：

```text
請在這台 Mac 安裝官方 Screen Awake 螢幕常亮：
https://github.com/mickyyang-1407/screen-awake/releases/latest

從同一個正式 Release 下載 universal ZIP 與 SHA256SUMS.txt，比對雜湊，確認 App 簽章有效且 Gatekeeper 接受，再安裝到 ~/Applications。保留既有版本與設定；遇到衝突或驗證失敗就回報，不覆寫或繞過保護。支援 macOS 14 以上。

打開 App，執行其中 Contents/MacOS/ScreenAwake 的 agent-help，依本機說明使用喚醒、常亮與排程。沒有指定時間就不要新增排程，也不要為了驗收關閉我的螢幕。密碼、Touch ID 與安全設定由我處理。

完成後回報實際安裝路徑、版本、驗證結果，以及可以直接使用的指令。若你沒有這台 Mac 的本機指令權限，請明確說明尚未安裝。
```

這段會讓 Claude Code 實際下載並安裝 App；貼上前請確認安裝位置與允許範圍。
