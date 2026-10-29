# Screen Awake 螢幕常亮

用一個開關讓 Mac 螢幕保持開啟。關掉開關，就恢復原本的螢幕休眠設定。

[下載 macOS 版](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.dmg) · [ZIP 下載](https://github.com/mickyyang-1407/screen-awake/releases/latest/download/Screen-Awake-universal.zip) · [English](README.md)

macOS 14 以上 · Apple silicon 與 Intel · 繁體中文與英文 · MIT 授權

![螢幕常亮繁體中文介面](assets/screenshots/zh-light-on.png)

## 使用方式

下載 DMG，把 **Screen Awake** 拖進 **Applications** 後開啟。也可以解壓縮 ZIP，直接開啟 App。

啟用「保持螢幕開啟」，離開鍵盤後螢幕仍會維持開啟。關掉開關，便會依系統的閒置時間設定休眠。

關閉小視窗後仍會繼續運作。點選選單列或 Dock 圖示可重新開啟；按 **⌘Q** 結束 App，便會釋放它的亮屏要求。開關與語言選擇都會記住。

首次開啟會跟隨系統語言，也能透過語言選單切換繁體中文或英文，立即生效。

其他 App 也可能讓螢幕保持開啟。本工具只會釋放自己的要求；手動睡眠、鎖定、闔上筆電與 macOS 電源保護仍由系統控制。

## 保持簡單

- 使用 Swift 與 AppKit，沒有第三方執行環境或相依套件。
- 直接使用 macOS 電源管理 API，不模擬滑鼠移動，也不反覆掃描磁碟。
- 沒有帳號、分析追蹤或網路請求，不讀取文件或媒體；偏好設定留在自己的 Mac。

## 從原始碼建置

安裝含 Swift 6.2 以上版本的 Xcode 後執行：

```sh
git clone https://github.com/mickyyang-1407/screen-awake.git
cd screen-awake
zsh scripts/build.sh
open "build/Screen Awake.app"
```

建置使用 macOS 原生 SDK，產生同時支援 Apple silicon 與 Intel 的 App。本機建置採 ad-hoc 簽章，不需要憑證，也不會下載相依套件。

歡迎回報問題或提供範圍明確的改善。請附上 macOS 版本、介面語言及預期行為。

[MIT 授權](LICENSE)。由 [Micky Yang](https://github.com/mickyyang-1407) 製作。
