# WordFlow iPhone 主畫面與鎖定畫面小工具

## 功能
- 使用 Apple 原生 WidgetKit + SwiftUI，而不是 Safari 網頁捷徑。
- **主畫面**：小／中／大尺寸的主題彩色漸層卡片，顯示英文、詞性（如名詞／動詞）和繁體中文；原有詞條若有例句，中／大尺寸也能顯示。
- **鎖定畫面**：單行與矩形；每日單字另有圓形小工具。
- 提供「每日單字」、「每日詞句」兩款 Widget。
- 長按 Widget 的「編輯 Widget」可選 A2／B1，以及全部、旅遊、生活、健身、工作。
- 1,524 筆離線教材（1,500 個單字、24 句詞句）依本機日期輪替，預先建立 14 天 WidgetKit Timeline。
- 點擊 Widget 可啟動 WordFlow。

## 加到 iPhone
1. 先安裝**包含 WordFlowWidgets.appex 的新版、已完整簽署的 IPA**，且首次開啟 WordFlow。
2. 主畫面長按空白 → 編輯 → 加入小工具 → 搜尋 WordFlow → 選每日單字／每日詞句及尺寸。
3. 鎖定畫面長按 → 自訂 → 鎖定畫面 → 點選時間下方的小工具區域 → 搜尋 WordFlow。
4. 長按已加入的 Widget → 編輯 Widget → 選程度及主題。

## CI／IPA 驗證
CI 透過 Flutter 產生暫時的 iOS 專案後執行 Ruby 腳本，在 Runner.xcodeproj 新增 SwiftUI WidgetKit target。若編譯成功，IPA 內應包含：
- Payload/Runner.app/PlugIns/WordFlowWidgets.appex
- 該 .appex 內的 content.json

GitHub Actions 會檢查兩者是否存在；但編譯成功**不代表**已成功簽署或已經在 iPhone 實際顯示。

此版本特意不使用 App Groups entitlement，降低免費個人簽署的限制；因此主 App 中的程度、主題與收藏**不會同步**到 Widget。請在各個 Widget 的編輯畫面自行設定。

**未簽署 IPA 必須分別簽署 Runner.app 與內含的 WordFlowWidgets.appex。**
SideStore/側載工具對包含 extension 的 IPA 支援程度可能不同，需要以實機安裝驗收。若使用 Apple Developer / TestFlight，需替主 App 與 extension 配好對應的 signing profile。


## 常見問題

- **會每次解鎖變不同單字嗎？** 不會。程式依照本機日曆日期每日選一個固定詞條。WidgetKit 使用預排 14 天的每日更新時間線，切換可能受系統排程略微延遲。
- **鎖定畫面能顯示大型彩色卡片嗎？** 不能。iPhone Lock Screen 的 accessory Widget 受系統尺寸與 vibrant（單色）渲染限制；彩色 Small / Medium / Large 卡片請加入「主畫面」。
- **更新 IPA 需要注意什麼？** 必須用 SideStore 再次簽署含 `WordFlowWidgets.appex` 的新 IPA。請勿先移除舊 App，以免本機收藏和複習紀錄遺失。
- **為什麼部分新單字沒有例句？** 新增的 1,452 個詞條目前提供雙語詞義與詞性，尚未逐條校對例句；原有 72 筆教材的雙語例句保留。


## 大型鎖定畫面四格單字（Live Activity）

- 這不是一般的 accessory Widget；是透過 ActivityKit 顯示在鎖定畫面下方的四格學習卡。
- 在 WordFlow App →「我的」→「鎖定畫面四格單字」→「開始今日四格單字」啟動。需允許 WordFlow 的「即時動態」。
- 每次從所選 A2/B1、主題中選出 4 個不重複詞條，顯示英文、詞性與繁體中文。點卡片可開啟 App，詞性標籤本身沒有獨立操作。
- Apple 規定 Live Activity 最多進行 8 小時，結束後鎖定畫面可能繼續顯示最多 4 小時；不是永久鎖定畫面小工具。到期後需手動再次開啟。
- Live Activity 透過 Flutter MethodChannel 呼叫 ActivityKit，原生介面在 WidgetKit extension。
- 這次 iOS 專案由 CI 即時產生，Ruby 腳本會產生兼容 UIScene 的 AppDelegate、添加共用 ActivityAttributes、原生 MethodChannel，以及主 App 的 NSSupportsLiveActivities。
- 完成編譯只證明 IPA 包含擴充功能；SideStore 能否簽署與實機啟用仍需 iPhone 驗證。切勿先移除舊 App。

## 版本與 Build 編號

- 版本統一由 `pubspec.yaml` 設定，例如 `0.3.0+3`。
- WordFlow「我的」頁面底部讀取已安裝 App 的版本，顯示 `v0.3.0 · Build 3`。
- iOS App 與 WidgetKit Extension 使用相同的版本號與 Build 編號，並在 GitHub Actions 中驗證一致。
- 新版 IPA 檔名將帶版本號，例如 `WordFlow-v0.3.0-b3-unsigned.ipa`；仍須透過 SideStore 簽署。
- 更新時請勿先移除舊 App，以免本機學習紀錄遺失。


## v0.4.1（Build 6）：鎖定畫面換下一字與詞句點字查詢

- 「每日單字」**鎖定畫面矩形 Widget** 右側新增 `↻` 按鈕：已學會時點選即可換下一字，不必等到隔天。iOS 仍可能延遲 Widget 畫面刷新。
- 目前由 WidgetKit extension 的 AppIntent 寫入自己的本機資料，不要求 App Groups entitlement；因此 **App 內的「我記住了」不會自動改變鎖定畫面 Widget**。圓形／單行 Widget 也沒有這個操作鈕。
- iOS 鎖定畫面「每日詞句」仍然每日輪換；不會因為按每日單字的箭頭而更換。
- WordFlow App 的「今日實用詞句」與「詞句詳情」內可直接點選英文單字；底部彈出繁體中文、原句及英語朗讀。
- 24 個原有詞句的中英例句常見詞形均有離線解釋（主字庫與 94 個補充詞形）；未知詞不會猜測。
- 詞句的複習卡在翻開答案後才開放點字查詢，以免提前洩漏答案。
- 不新增網路翻譯、帳號、學習資料 key 或額外 iOS 簽署權限。SideStore 更新請勿先刪除舊 App。

## v0.4.2（Build 7）：鎖定畫面換字操作修正

- **先使用 Face ID／密碼解鎖 iPhone，停留在鎖定畫面，才可執行互動 Widget 的按鈕。** Apple 系統禁止未通過驗證時執行 AppIntent，程式無法繞過。
- 調整矩形「每日單字」Widget：↻ 換字改為更大的獨立操作區，移除該矩形的整體「點擊開啟 App」連結，降低按鈕與整區導向的點擊衝突。
- 其他尺寸和每日詞句 Widget 的點擊開啟 App 行為保持原樣；未新增 App Groups entitlement。
- WidgetKit AppIntent 在擴充程序內更新本機輪替索引，更新時向 WidgetCenter 請求重新載入每日單字時間線。實際顯示仍須透過 Face ID 驗證並以 iPhone 實機確認。
- 若更新 IPA 後仍顯示舊按鈕樣式，可先從鎖定畫面移除**單字 Widget 本身**，再重新加入；**不要刪除 WordFlow App**，以免失去收藏和學習紀錄。
- 若完成解鎖仍無反應，須收集裝置系統版本、按鈕點擊是否打開 App 或完全無回應，以及實機 Console 日誌；雲端編譯通過不能證明 AppIntent 已在 iPhone 實際執行。


## v0.4.3（Build 8）App Groups / SideStore 實機驗證版（非正式版）

- 測試分支：`experiment/appgroup-widget-sync-b8`；此功能尚未合併 `main`。
- iOS Runner 與 WidgetKit extension 均透過 `CODE_SIGN_ENTITLEMENTS` **要求** 同一個 `group.com.kidkingsky.wordflow`。未簽署 IPA 會保留程式碼，但 SideStore 重新簽署時是否實際授權尚未知。
- 在 WordFlow「我的」→「鎖定畫面單字同步測試」查看 App 端共用容器能否存取。若不可用，顯示失敗原因，不會假稱同步成功。
- App 端可存取時，按「從 App 換下一個單字」，寫入詞條 ID 與遞增同步序號；同時要求 WidgetCenter 重新整理每日單字 Widget。
- **正確驗收**：鎖定畫面「每日單字」矩形 Widget 顯示和 App 完全相同的英文，以及「App 同步 #N」。若 Widget 顯示「尚未收到 App 同步」或仍是舊字，即使 App 顯示成功也不算通過。
- 測試版取消原本 Widget 的互動 ↻ 按鈕，改為點擊 Widget 開啟 App 並在 App 內切換。
- App 可按「恢復每日自動」清除測試選字，不會動到收藏與間隔複習紀錄。
- 如 SideStore 提示 App Group/Provisioning/Entitlement 不支援，不要刪除既有 WordFlow。可回報 SideStore 版本、完整錯誤和 iOS 版本；這是測試結果，不代表可以直接上線。
- **雲端 unsigned IPA 編譯通過只證明編譯成功，不代表 SideStore 能替 App 和 Widget 簽到需要的 App Groups 權限。**
