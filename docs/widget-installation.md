# WordFlow iPhone 主畫面與鎖定畫面小工具

## 功能
- 使用 Apple 原生 WidgetKit + SwiftUI，而不是 Safari 網頁捷徑。
- **主畫面**：小／中／大尺寸的主題彩色漸層卡片，顯示英文單字和繁體中文；原有詞條若有例句，中／大尺寸也能顯示。
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
- 每次從所選 A2/B1、主題中選出 4 個不重複詞條，顯示英文和繁體中文。點卡片可開啟 App；畫面中的書籤圖示目前僅為裝飾，不提供獨立收藏互動。
- Apple 規定 Live Activity 最多進行 8 小時，結束後鎖定畫面可能繼續顯示最多 4 小時；不是永久鎖定畫面小工具。到期後需手動再次開啟。
- Live Activity 透過 Flutter MethodChannel 呼叫 ActivityKit，原生介面在 WidgetKit extension。
- 這次 iOS 專案由 CI 即時產生，Ruby 腳本會產生兼容 UIScene 的 AppDelegate、添加共用 ActivityAttributes、原生 MethodChannel，以及主 App 的 NSSupportsLiveActivities。
- 完成編譯只證明 IPA 包含擴充功能；SideStore 能否簽署與實機啟用仍需 iPhone 驗證。切勿先移除舊 App。
