# 下載、打開、貼給 AI

[English](AI-USAGE.md) · [下載 App](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.dmg)

1. 安裝並打開螢幕常亮。
2. 按 **複製給 AI**，貼到 Claude Code 或有本機指令工具的 AI。
3. 直接告訴它你想做什麼：

> 幫我保持螢幕開啟。
>
> 半小時後關屏。
>
> 每天早上九點亮屏，下午六點關屏。

複製的文字會帶入實際安裝位置，請 AI 先讀取 App 內建的 `agent-help`。不需要長篇安裝 prompt、額外外掛或操作 App 畫面的工具。這些 AI 控制從 **1.5.0** 開始提供。

AI 需要這台 Mac 的本機指令權限；只有聊天能力的 AI 無法代為執行。

## 給 AI 的指令參考

以 App 內的 `agent-help` 為準。以下假設安裝在 Applications；實際路徑由「複製給 AI」帶入。

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

- `wake` 喚醒一次；`awake on` 喚醒並持續常亮；`awake off` 恢復原本的閒置設定。
- `dim` 先釋放執行中 App 的常亮要求，再請求關屏。只在使用者要求時執行。
- `schedule daily` 依序指定 Wake／Dim 時間，儲存並啟用；夜間跨日也可。任一時間可填 `off`，但至少保留一個動作。預設 Wake 後保持常亮；加 `--no-keep-awake` 可只喚醒一次。
- `schedule timer` 設定 1–1440 整數分鐘的倒數，動作為 `wake` 或 `dim`；會取代原倒數。
- `schedule off` 停用每日排程，保留倒數；`schedule cancel` 取消倒數，保留每日排程。兩者都不會改變目前常亮狀態。
- `schedule show` 回傳 JSON，包含 App 是否執行、常亮狀態、儲存的排程與下一次動作。`status` 只讀取關屏後的密碼要求。

設定新排程或開啟常亮時，App 若未執行會在背景開啟。讀取狀態、取消排程或關閉常亮，不會啟動已結束的 App。請檢查 JSON 的 `success`、回傳狀態及程序退出碼；逾時代表結果不確定，先讀取狀態再決定下一步，不要盲目重試。

## 使用邊界

App 必須持續執行才能保持常亮或執行排程；關閉視窗沒關係，退出 App 就停止。重開後只恢復未來事件，過期不補執行。時間依 Mac 目前時區。

Wake 可以點亮顯示器，但無法解鎖 Mac，也無法喚醒整台睡眠或關機中的電腦。密碼與 Touch ID 由使用者親自處理；[免密碼設定教學](SETUP.zh-Hant.md)是選用設定，不由 AI 代改。

若只有單次喚醒，之後仍遵循原本的閒置時間。不要把指令成功當成已解鎖或畫面會永久維持亮／暗；無法觀察時，只回報要求被接受。
