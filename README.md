# WordFlow — 每日英文（Flutter iOS / Android）

 > **專案狀態：持續開發中。** GitHub Actions 可透過 macOS runner 建立包含 WidgetKit Extension 的未簽署 iOS IPA，仍須使用 SideStore 等工具進行簽署與 iPhone 實機驗收。

## ✅ iPhone 現在先試用（不需要 Windows）

**GitHub 專案：** https://github.com/Kidkingsky/wordflow

首次需在 GitHub → **Settings → Pages**，設定 **Deploy from a branch → main → /(root) → Save**。
GitHub Pages 完成部署後，在 iPhone Safari 開啟 https://kidkingsky.github.io/wordflow/ ，按分享 → 加入主畫面。
此版本是可操作的手機瀏覽器預覽（仍為舊版 72 筆教材），**不是已簽署的原生 IPA**。

## 版本號與安裝識別

- 「我的」頁面底部會顯示實際安裝的 App 版本與 Build 編號，而非固定寫死的舊版本。
- **功能版本（`CFBundleShortVersionString`）**：以 `pubspec.yaml` 的 `0.5.0+10` 為基準，現在為 `0.5.0`，未來功能版本升級時需手動更新 `pubspec.yaml`。WidgetKit Extension 同步版本。
- **Build 編號（`CFBundleVersion`）**：每次 GitHub Actions iOS 編譯自動取 `pubspec.yaml` 的基本 build 值（目前 `9`）加上該工作流程的 `GITHUB_RUN_NUMBER`，不會再因連續合併 PR 而維持相同 Build。Flutter 主程式與 Widget Extension 使用同一 Build 編號。
- IPA 檔名自動帶入真實版本與 Build，例如 `WordFlow-v0.4.4-b45-unsigned.ipa`（僅為命名範例，實際數字以當次 Actions 為準）。這仍是未簽署 IPA，須透過 SideStore 簽署，包含 Widget Extension 才能在 iPhone 安裝。
- 四格鎖定畫面 Live Activity 需手動開啟，並非永久常駐 Widget。

## iOS 主畫面與鎖定畫面 Widget

已新增原生 WidgetKit 的每日單字、每日詞句小工具：主畫面支援小／中／大尺寸彩色單字卡，鎖定畫面支援符合系統限制的精簡單色版。可自選 A2／B1 與主題，離線每天輪替（不是每次解鎖換字）。詳見 [Widget 安裝、簽署與驗證說明](docs/widget-installation.md)。

## 第一版包含什麼？

- **每日推薦**：單字卡＋實用詞句卡，同一天固定推薦，隔日輪換。
- **1,613 筆原生 App 內建內容**：1,555 個單字、58 個實用詞句，24 課，A2 / B1，旅遊／生活／健身／工作四個主題。
- **英文朗讀**：使用 iOS / Android 的系統語音合成（TTS），可調整語速；並非真人錄音。
- **單字庫／詞句庫**：搜尋中文、英文及例句；依主題篩選及收藏。
- **間隔複習**：記住後分別隔 1、3、7、14、30、60 天複習；忘記則當日到期。
- **離線進度**：本機記錄收藏、程度與複習紀錄；不用帳號、Firebase 或 AI API。

> iOS WidgetKit Extension 的原始碼與 CI 打包檢查已加入；**尚待 CI 成功及 iPhone 實機簽署／安裝驗收**。推播、雲端同步、AI 生成句子、口說辨識與發音評分仍未完成。

## 目錄

```text
wordflow_flutter/
├── lib/                 Flutter App UI、模型、複習邏輯
├── assets/content/      可直接擴充的 JSON 教材
├── test/                推薦與複習邏輯測試
├── .github/workflows/   GitHub Actions Android + iOS（未簽署）自動檢查
├── codemagic.yaml       Codemagic 雲端 Mac：iOS 未簽署測試 + TestFlight 工作流程
└── pubspec.yaml         套件設定
```

> **重要：`android/` 與 `ios/` 原生專案資料夾尚未產生。** 這個 GitHub 上的原始碼包刻意只存放跨平台核心程式，在第一次執行 `flutter create` 或 CI 時生成原生平台檔案。

## A. 你有 Windows 電腦：先在本機跑 Android

安裝 [Flutter SDK](https://docs.flutter.dev/install) 與 VS Code（Flutter / Dart 擴充套件），開啟本專案資料夾並在終端執行：

```powershell
flutter doctor
flutter create --platforms=android --project-name wordflow --org com.kidkingsky .
flutter pub get
flutter analyze
flutter test
flutter run
```

`flutter run` 需要連上 Android 手機、模擬器或其他可用執行目標；若沒有 Android 裝置，先靠 GitHub Actions 驗證。Windows **不能**直接編譯 iOS App。`com.kidkingsky.wordflow` 是目前暫定的 bundle ID；如果已註冊其他 ID，務必先改成自己的版本並在 Apple Developer、Codemagic 全部保持一致。

## B. 沒有 Mac：先用 GitHub 同時驗證 Android / iOS

1. 在 GitHub 建立**新的** Repository，例如 `wordflow`，不要覆蓋別的專案。
2. 解壓縮這個專案，**上傳裡面的所有檔案**，要包含隱藏的 `.github/` 資料夾。
3. 打開 Repository 的 **Actions** 頁面，執行 `Flutter Android test build` 與 `Flutter iOS unsigned build check`。
4. 如果通過，Android 流程會提供 Android debug APK。iOS 流程只會產出 **未簽署** 的 `.app` 用於編譯驗證；**仍不能直接安裝到 iPhone**。GitHub Actions 的 Mac runner 可能產生額度使用量或計費，請以 GitHub 帳號設定為準。

## C. 沒有 Mac：Codemagic 雲端 Mac 驗證 iOS

1. 到 [Codemagic](https://codemagic.io/) 登入並連接你的 GitHub Repository。
2. 使用專案裡的 `codemagic.yaml`。
3. 選 `ios_unsigned`，讓 Codemagic 自動建立 iOS 原生資料夾、安裝依賴、執行測試、編譯 iOS `.app`。
4. **這個 `.app` 尚未簽署，不可以直接拿去安裝 iPhone。** 它只是先驗證 iOS 原生編譯沒有問題。

官方參考：[Flutter iOS](https://docs.flutter.dev/deployment/ios)、[Codemagic Code Signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/)。

## D. 要在 iPhone 裝 App：TestFlight

要把 Flutter App 安裝到 iPhone 使用，推薦正式走 TestFlight：

1. 加入 [Apple Developer Program](https://developer.apple.com/programs/)（費用以當時官方為準）。
2. 到 Apple Developer 註冊 Bundle ID `com.kidkingsky.wordflow`（若未被使用；與本專案設定一致），在 App Store Connect 建立 App 記錄。
3. 到 Codemagic 連接 App Store Connect API Key。**請只放在 Codemagic 的受保護環境變數，絕不提交到 GitHub。**
4. 在 Codemagic 產生或上傳 Apple Distribution Certificate 與 App Store Provisioning Profile；設定 `appstore_credentials` 變數群組，放入：
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_ISSUER_ID`
5. 選 `ios_testflight` workflow。這個工作流程建置、簽署 `.ipa`，並上傳 App Store Connect（**不會自動公開上架**）。
6. 等 Apple 處理完成後，在 App Store Connect 中將該 build 分配給 TestFlight 測試者，再從 iPhone 的 TestFlight 安裝。

Apple / Codemagic 的簽署設定、權限、帳號、Provisioning Profile 都是必要條件；使用 Codemagic 並不代表免 Apple 會員或免簽署。

> **Widget 注意**：已新增原生 SwiftUI WidgetKit Extension；不使用 App Groups 即可獨立輪換單字，但不會同步主 App 的個人進度。IPA 需簽署 App 及 Extension 才能在 iPhone 安裝。

## 資料與隱私

內建教材位於 `assets/content/content.json`，每筆格式：

```json
{
  "id": "w_travel_02",
  "kind": "word",
  "category": "travel",
  "level": "A2",
  "english": "reservation",
  "chinese": "預訂；訂位",
  "note": "名詞｜飯店、餐廳或交通的預約。",
  "example": "I have a reservation for two nights.",
  "exampleChinese": "我預訂了兩晚住宿。"
}
```

所有本機紀錄透過 `shared_preferences` 儲存。初版不提供資料同步或匯出備份；解除安裝後資料可能消失。App 沒有登入、沒有自動上傳學習紀錄。系統 TTS 音色與英文語音品質依裝置而異。

## 規劃中的 v0.2 / v0.3

- **v0.2**：iPhone Home Screen／Lock Screen Widget 程式碼已加入（仍待簽署實機驗收），每日通知、本機匯出尚未完成。
- **v0.3**：依錯題調整推薦、可更新教材內容、Android Widget、語音跟讀與 AI 對話（可選、需要 API 與後端成本）。

## 開發提醒

首次從這個原始碼套件執行 `flutter create` 時產生的 `ios/` / `android/` 資料夾，建議在能執行 Flutter 的開發環境生成後也提交到 GitHub，以利後續新增 Widget、設定 Bundle ID 和原生功能。正式簽署前先確認在 CI 上通過 `flutter analyze` 和 `flutter test`。

## E. iPhone-only first-look preview and SideStore unsigned IPA (added 2026-11-21)

### Preview without any computer

- `docs/index.html` is a **mobile browser preview** with the original 72 items. The native implementation in `lib/` uses 1,613 items and 24 ordered lessons. The web preview has not yet been migrated to the new catalog.
- In GitHub Settings → Pages, publish from `main` / `docs` to open `https://kidkingsky.github.io/wordflow/` **after** this repository exists and deployment completes.
- In iPhone Safari, choose **Share → Add to Home Screen** to launch the preview like an app. This is not an IPA and cannot create native lock-screen widgets.
- Its reviews and favorites use browser localStorage (not automatically shared with Flutter or other phones). Speech uses browser TTS.

### IPA build (no Mac required locally)

- `.github/workflows/ios-unsigned.yml` builds an **unsigned release .app** with bundled **WordFlowWidgets.appex**, then packages it into `WordFlow-unsigned.ipa`.
- This is an **unsigned IPA**, not a directly installable IPA. A compatible signing/installation tool must sign it for your Apple account and device. No Apple signing keys go to GitHub.
- To retrieve it after a successful build: Repository → **Actions** → **WordFlow iOS unsigned IPA for SideStore** → select successful run → **Artifacts** → download `WordFlow-iOS-unsigned-IPA-REQUIRES-SIGNING` ZIP → unpack and import the `.ipa` into your trusted signing tool.
- Device-only third-party installer **SideInstaller** currently *claims* to work on iOS 27 without a computer: https://github.com/FrizzleM/SideInstaller. It is independent of Apple and SideStore; its setup depends on third-party signing / Apple credentials and may fail. Verify the download source and consider account-security risk before entering any Apple login.
- Conventional **SideStore** still documents a computer-only initial installation process: https://docs.sidestore.io/docs/installation/prerequisites.
- Free personal-development signing expires in **7 days**, even if the installation tool can refresh it with minimal intervention.

### Current status

- The original non-Widget build previously succeeded; the updated WidgetKit build requires its own successful GitHub Actions run and a separate signed iPhone installation test.
- Repository `Kidkingsky/wordflow` has been created; Android/iOS Actions are configured. Enable GitHub Pages in Settings to publish the preview.


## 2026/11/23 原生版字庫與彩色 Widget 改版

- 原有 48 個單字與 24 句實用詞句全部保留；另外增加 1,452 個不重複的 A2/B1 英文單字，合計 1,500 單字（共 1,524 筆）。
- 新增詞彙搭配繁體中文常用義及詞性標籤。新增詞彙尚未逐筆編輯雙語例句，App 對沒有例句的詞條不顯示空白例句區；原有內容的例句完整保留。
- 主畫面 Widget 支援 Small / Medium / Large 彩色漸層卡片；鎖定畫面因 iOS 的顯示限制維持簡潔單色樣式。
- 每天依本機日期切換推薦單字，不會每次解鎖就變更；iOS 可能略微延遲 Widget 顯示更新。
- 單字參考 CEFR A2/B1 常用詞表，中英釋義參考 ECDICT，以 OpenCC 轉為繁體中文；詳見 [來源及授權](docs/vocabulary-sources.md)。
- **注意**：網頁預覽 `docs/index.html` 仍是 72 筆舊版教材，這次字庫與 Widget 改版針對 Flutter 原生 App 與 WidgetKit Extension。

## v0.5.0 — 24 課循序情境教材

- A2 基礎與 B1 進階各 12 課；生活、旅遊、健身、工作每個程度各 3 課。每課 4 個單字與 2 個情境詞句及雙語例句。
- App 首頁從第一課開始，可逐課完成、重選課程；本機儲存進度。完成課程與間隔複習的精熟紀錄分開。
- 保留 1,500 字與 24 句舊字庫；共用 ID 合併後共有 1,555 個單字及 58 句詞句，探索頁仍可搜尋完整字庫。
- Live Activity 啟動時顯示目前課程四字，切換課程後重新啟動。App Groups 可用時，Widget 接收目前課程首字及首句；無共用權限時仍依 Widget 自己的程度／主題與日期輪替有關聯的課程，不能保證與 App 個人進度一致。iPhone 實機同步仍需測試。
- 擴充教材時增加 `assets/content/course_content.json` 的條目及課程即可，CI 驗證引用、唯一 ID、例句和兩個 iOS bundle 是否一致，無固定上限。
