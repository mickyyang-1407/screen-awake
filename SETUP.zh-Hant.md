# 螢幕暗掉後，不必再輸入密碼

這份教學調整的是「螢幕關閉後要求登入密碼」；不會刪除 Mac 帳號密碼。

**只用「保持螢幕開啟」開關，不需要改密碼設定。** 只有希望錄影腳本在螢幕關閉後，能直接喚醒畫面並繼續工作時，才需要以下步驟。

## 1. 如果選項是灰色，先調整 iPhone 鏡像輸出

如果鎖定畫面顯示「Password immediately required when iPhone Mirroring is set to automatically authenticate.」，請先：

1. 在 **Mac** 開啟 **iPhone Mirroring（iPhone 鏡像輸出）**。
2. 點螢幕最上方選單列的 **iPhone Mirroring → Settings…（設定）**。
3. 將認證方式選為 **Ask every time（每次都詢問）**。
4. 若出現密碼、Touch ID 或確認視窗，請親自完成。

這會讓下次使用 iPhone 鏡像輸出時先要求認證。選項原本就能修改，直接進行下一節。

## 2. 將關閉螢幕後要求密碼設為 Never

1. 點左上角 ** → System Settings（系統設定）**。
2. 在左側點 **Lock Screen（鎖定畫面）**。
3. 找到 **Require password after screen saver begins or display is turned off**（螢幕保護程式開始或顯示器關閉後要求輸入密碼）。
4. 將 **Immediately（立即）** 改為 **Never（永不）**。
5. 如果出現密碼或關閉螢幕鎖定的確認視窗，請自行閱讀並完成。

設定為 Never 期間，旁人可能直接使用這台 Mac。不要修改帳號密碼、FileVault 或自動登入。

若選項仍是灰色，可能受公司或裝置管理政策限制；請由管理者處理。

## 3. 親自確認可以直接回桌面

1. 先自行解鎖，回到正常桌面，開啟 Screen Awake。
2. 點 **Dim 關閉螢幕**。
3. 用空白鍵或滑鼠喚醒，確認能否直接回桌面、不需 Touch ID 或密碼。
4. 如果接下來要持續亮屏，再打開 **保持螢幕開啟**。

這一步請親自確認，不能只以腳本回傳成功或看到畫面醒來就判定通過。若仍要求認證，請分辨是否有手動鎖定或其他程式另外送出「立即鎖定」；Never 不會取消這種鎖定。

## 4. 使用 Screen Awake

- **保持螢幕開啟 ON**：螢幕不會因閒置而關閉。關閉視窗仍有效；按 ⌘Q 才會結束 App。
- **OFF**：釋放本 App 的常亮要求，恢復系統原本的閒置行為，不是立即關閉螢幕。其他 App 仍可能有自己的常亮要求。
- **Wake 喚醒螢幕**：送出一次喚醒要求，不會自動開啟持續常亮。
- **Dim 關閉螢幕**：先關閉本 App 的常亮，再請系統關閉螢幕。密碼要求依原本的系統設定。主視窗與選單列都有這兩個按鈕。
- 每次啟動都預設 OFF；只記住介面語言。
- 點 **設定教學** 可以在 App 內閱讀步驟，也能按按鈕打開 Lock Screen 設定。

## 5. 讓錄影腳本喚醒、錄完再關閉螢幕

第一次請在已解鎖的桌面測試，先結束螢幕錄影，再執行 `dim`：

```sh
# 已安裝的 App；依你的安裝位置調整。
AWAKE='/Applications/Screen Awake.app/Contents/MacOS/ScreenAwake'
"$AWAKE" status
"$AWAKE" wake
# 在此執行錄影，並等待錄影完成。
"$AWAKE" dim
```

從原始碼建置也能使用 `./build/ScreenAwake`。`wake` 的兩秒喚醒要求結束後，不留下持續常亮程序；錄影期間仍遵循系統原本的閒置時間。錄影超過該時間時，可先在 GUI 啟用常亮，錄完手動關閉後再執行 `dim`。

`dim` 請求關閉所有顯示器，不會讓整台 Mac 睡眠、修改亮度或改寫系統休眠時間。若 macOS 拒絕，CLI 會回傳非零狀態並列出原因。其他使用者輸入或 App 可能立刻重新喚醒螢幕。

Never 只調整閒置／關閉螢幕後的密碼要求。若你或其他程式另外送出「立即鎖定」指令，仍需要自行解鎖；Never 不會取消這種鎖定。重新啟動、登出後也仍可能需要登入密碼。CLI 無法解鎖已鎖定的 Mac。

## 6. 想恢復密碼保護

回到 **System Settings → Lock Screen**，把相同的密碼要求選項改回 **Immediately**。之後也可自行把 iPhone Mirroring 的認證方式改回原本選擇。

Apple 官方說明：[iPhone 鏡像輸出](https://support.apple.com/zh-tw/120421) · [鎖定畫面設定](https://support.apple.com/zh-tw/guide/mac-help/mh11784/mac)
