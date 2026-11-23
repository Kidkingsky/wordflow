# WordFlow iPhone 主畫面與鎖定畫面小工具

## 功能
- 使用 Apple 原生 WidgetKit + SwiftUI，而不是 Safari 網頁捷徑。
- **主畫面**：小／中尺寸，顯示每日英文、中文意思；中尺寸附英文例句。
- **鎖定畫面**：單行與矩形；每日單字另有圓形小工具。
- 提供「每日單字」、「每日詞句」兩款 Widget。
- 長按 Widget 的「編輯 Widget」可選 A2／B1，以及全部、旅遊、生活、健身、工作。
- 72 筆離線教材依本機日期輪替，預先建立 14 天 WidgetKit Timeline。
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
