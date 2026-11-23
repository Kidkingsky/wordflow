# WordFlow — 每日英文（Flutter iOS / Android）

 > **專案狀態：v0.2 原始碼起點**。本專案在沒有 Flutter SDK 與 Xcode 的環境下產生；尚未經過實際 `flutter analyze`、`flutter test`、iOS / Android 編譯。附有雲端 CI 供第一次驗證。**目前不是已簽署、可直接安裝的 iPhone App。**

## ✅ iPhone 現在先試用（不需要 Windows）

**GitHub 專案：** https://github.com/Kidkingsky/wordflow

首次需在 GitHub → **Settings → Pages**，設定 **Deploy from a branch → main → /(root) → Save**。
GitHub Pages 完成部署後，在 iPhone Safari 開啟 https://kidkingsky.github.io/wordflow/ ，按分享 → 加入主畫面。
此版本是可操作的手機瀏覽器預覽，**不是已簽署的原生 IPA**。

## iOS 主畫面與鎖定畫面 Widget

已新增原生 WidgetKit 的每日單字、每日詞句小工具，支援 iPhone 主畫面和鎖定畫面，可自選 A2／B1 與主題，離線按日輪替。詳見 [Widget 安裝、簽署與驗證說明](docs/widget-installation.md)。

## 第一版包含什麼？

- **每日推薦**：單字卡＋實用詞句卡，同一天固定推薦，隔日輪換。
- **72 筆內建內容**：48 個單字、24 個實用詞句，A2 / B1，旅遊／生活／健身／工作四個主題。
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

- `docs/index.html` is a **mobile browser preview** with the same 72 lesson items as Flutter. Its native implementation is still `lib/`.
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
