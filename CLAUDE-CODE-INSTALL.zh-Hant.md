# Claude Code 下載安裝範本

[AI 使用說明](AI-USAGE.zh-Hant.md) · [English guide](AI-USAGE.md)

把下面整段貼給在目標 Mac 上執行的 Claude Code。這份範本安裝已驗證的 1.4.0 正式版；排程是否能由 AI 代設，取決於它是否具備 macOS App 操作工具。

```text
請在這台 Mac 下載、驗證並安裝「Screen Awake 螢幕常亮」，完成後打開 App。請實際執行，不只提供教學。

背景與範圍：
- 這是已完成的 macOS 原生工具，支援 Apple silicon／Intel、macOS 14 以上，介面有繁體中文。
- 本次目標版本為 1.4.0。安裝官方成品即可，不需要編譯、Homebrew、Xcode 或其他開發套件。
- 新安裝放在 ~/Applications/Screen Awake.app；下載與解壓縮只使用 ~/Downloads 內新建的本次工作資料夾。
- 保留既有 App、偏好設定與排程，不修改其他專案、全域 AI 指引或系統設定。

官方來源：
說明：https://github.com/mickyyang-1407/screen-awake/blob/main/AI-USAGE.zh-Hant.md
版本：https://github.com/mickyyang-1407/screen-awake/releases/tag/v1.4.0
ZIP：https://github.com/mickyyang-1407/screen-awake/releases/download/v1.4.0/Screen-Awake-universal.zip
校驗檔：https://github.com/mickyyang-1407/screen-awake/releases/download/v1.4.0/SHA256SUMS.txt
ZIP 預期 SHA-256：2ab34e4a09ce4ca98b78f972d2a46a7ff3769a8233af6ca21b001372a1dc1c05

安裝流程：
1. 先確認工具實際執行在我要安裝的 Mac，系統為 macOS 14 以上。有終端機權限就使用 macOS 內建工具；若目前只是雲端／Linux 環境或沒有本機權限，停止並說明，不能回報已安裝。
2. 只檢查 /Applications/Screen Awake.app 與 ~/Applications/Screen Awake.app 是否已有官方版本。先依第 4 步的條件驗證既有 App。若有有效的相同或更新版本，沿用、回報路徑並跳過第 3–5 步；若有較舊、來源不明或正在執行的衝突版本，先完成新下載包驗證，再說明衝突，暫停覆寫。
3. 下載上述 ZIP 與同版本校驗檔。比對 ZIP 的 SHA-256，必須同時符合校驗檔與此處預期值；不一致就停止。
4. 解壓縮後，用 codesign --verify --strict 驗證 App，並檢查簽章資訊：TeamIdentifier 必須是 RPNT54P79S，Identifier 必須是 com.mickyyang.screen-awake。再以 spctl --assess --type execute 確認 Gatekeeper 接受。任何驗證失敗都停止，不移除 quarantine 或關閉 Gatekeeper 來繞過。
5. 建立 ~/Applications（若不存在），用保留 bundle／延伸屬性的方式安裝 Screen Awake.app，例如 ditto；確認已安裝的版本是 1.4.0、簽章與 Gatekeeper 檢查仍通過。原始下載包先保留。
6. 執行 App 內建 CLI 的 --version、--help、status，記錄實際結果。執行檔位置是 App 內的 Contents/MacOS/ScreenAwake，路徑含空白時必須完整加引號。status 只讀取關屏後的密碼要求，無法判斷目前是否已解鎖。
7. 打開已驗證的 App。有可用的 Mac App 操作工具時，將介面切成繁體中文，確認主視窗有常亮開關、Wake、Dim、排程、設定教學。只有終端機時，打開 App 並清楚標示介面尚未驗證，不要假稱已看見。不要為此自行安裝 GUI 自動化工具。
8. 可以執行一次 wake，確認指令是否成功；成功只代表喚醒要求被接受。安裝驗收不執行 Dim，不主動關閉我的螢幕，也不擅自啟用常亮或每日排程。

排程：
- 1.4.0 的排程設定在 GUI，目前 CLI 只有 wake、dim、status 等顯示器操作，沒有 schedule 指令；若沿用更新版本，以該版本的 --help 確認實際支援內容。
- 如果我另外指定每日時間或倒數，且你有 Mac App 操作工具，就在「排程」頁代我設定：每日可套用早班／日間／夜間或自訂時間，選擇 Wake／Dim、是否在 Wake 後保持常亮，勾啟用並儲存；倒數則填分鐘與動作，再按開始倒數。完成後讀回下一次執行時間。
- 我還沒指定時間時，新安裝保持排程關閉；既有安裝保留原設定。只有終端機工具時，提供 App 內的點選步驟即可，不要杜撰指令或直接修改私有 UserDefaults。
- 排程需 App 保持執行，關閉視窗仍可運作；退出 App 就停止。睡眠／關機可能錯過排程，過期不補執行。

喚醒與密碼：
- 之後需要操作畫面時，可用已安裝的 CLI 執行 wake；它只喚醒一次，之後仍遵循原本的閒置時間。
- 只有我要求關屏，或任務明確包含完成後關屏時，才執行 dim。
- Wake 無法解鎖 Mac，也無法喚醒整台睡眠或關機中的電腦。若出現密碼、Touch ID 或系統授權，請讓我親自完成。
- 如果我希望關屏後不要求密碼，帶我看 App 的「設定教學」；說明 Lock Screen 的 Never，以及選項變灰時 iPhone Mirroring → Settings → Ask every time 的處理。Never 期間旁人也可能直接使用 Mac，是否變更由我決定，不代我修改。

完成與停止條件：
- 能獨立完成的步驟直接做；驗證失敗、既有版本衝突或同一錯誤重試兩次仍失敗，就停止並回報具體原因。
- 每個主要階段簡短回報實際進度。
- 最後用繁體中文列出：安裝路徑、版本、SHA-256／簽章／Gatekeeper 結果、App 是否已開啟、哪些 GUI 或排程操作實際驗證過，以及可直接複製的 wake 指令。清楚區分完成、未驗證與需要我操作的部分。
```

此範本會讓 Claude Code 實際操作這台電腦；貼上前請確認安裝位置與允許範圍符合使用者意願。
