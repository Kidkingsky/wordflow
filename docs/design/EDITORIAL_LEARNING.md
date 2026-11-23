# WordFlow — Editorial Learning（視覺設計提案 v1）

> 狀態：**設計原型／待審核**，非正式 App 的 UI、非已上線 IPA。
> 
> Base：`fix/review-flow-widget-layout`，版號仍為 WordFlow v0.3.1 (Build 4)。本提案未修改既有 Flutter、WidgetKit、字庫、學習演算法及 SideStore 流程。

## 目標

以 WordFlow 已有的英文字庫、朗讀、收藏與間隔複習為內容，先完成「今天 → 單字詳情 → 翻卡複習」的統一設計。降低 AI 模板感：不重複堆疊大圓角卡、不在所有標籤使用全大寫字距、不以多種彩色漸層遮蓋學習內容。

參照 [Hallmark](https://github.com/nutlope/hallmark) 的設計觀念，**不是**將 CSS 直接轉成 Flutter 或宣稱原型通過完整 Hallmark linter。

## 視覺規格

| Token | HEX | 用途 |
| --- | --- | --- |
| paper | `#F6F3EE` | 暖白閱讀底 |
| card | `#FFFEFC` | 內容表面 |
| ink | `#292535` | 主標題與英文內容 |
| muted | `#776F7D` | 次要中文及說明 |
| rule | `#E3DDD7` | 分隔線 |
| plum | `#624D79` | WordFlow 品牌色、主要操作 |
| plum deep | `#483659` | 品牌深色 |
| plum wash | `#EEE7F2` | 選取狀態 |
| sage | `#E1E8DB` | 完成與正向訊息 |
| rose | `#F1E1D7` | 需要複習的輔助訊息 |

- 英文展示：有襯線特徵的大字，保留英文字母辨識度。原型採系統可用的 Georgia／Iowan／Cambria fallback；正式 iOS 端可評估系統 New York。
- 中文操作：iPhone 系統繁中字體（PingFang TC fallback）。正文至少 13–16pt，重要解釋 17–21pt。
- 層級：一個主要視覺焦點／畫面；次要資訊以分隔線與留白，不以多重外框承載。
- 主要動作最小觸控高度 44pt；次要動作與收藏、發音可清楚區分。
- 深色模式與 Reduce Motion 需要獨立驗收，不得直接把色碼照搬至所有亮度。

## 三個核心畫面

### 1. 今日首頁（`lib/ui/pages/home_page.dart`）

先看今日學習重點，再看進度與主題。主要單字使用一塊有層次的品牌卡；例句和翻譯保持在一起。進度縮成簡短的一列，完成目標是有真實行為的按鈕，避免無效「漂亮數字」。

### 2. 單字詳情（`lib/ui/widgets/learning_card.dart`）

英文 headword 最大；中文詞義次之；詞性／CEFR 作為簡短資訊。發音與收藏不與內容混排。例句有足夠閱讀留白；字族內容可折疊，勿在第一屏展開所有標籤。

### 3. 間隔複習（`lib/ui/pages/review_page.dart`）

先展示英文，讓使用者心裡作答；按「翻開答案」後才顯示繁中與例句，接著選「還不熟／記住了」。保留原本錯題排到本輪後面的邏輯、複習時間與本機紀錄，不以畫面上的示範進度替換正式演算法。

## 其他畫面與 Widget 延伸

- 探索：字典式列表、搜尋與主題篩選，不在 1,500 筆內容上重複厚重卡片。
- 設定：保留 A2/B1、聲音挑選、語速、Live Activity 啟停及實際版號。
- 原生 WidgetKit：待 App 主畫面視覺確認後，再用 SwiftUI tokens 實現同一品牌語言；鎖定畫面仍需遵守 iOS accessory Widget/Live Activity 限制。
- 主 App 的使用者學習資料、TTS、收藏、WidgetKit extension signing 路徑都必須保留。

## 交付與驗收

可互動原型：[`docs/design/wordflow-editorial-preview.html`](wordflow-editorial-preview.html)。

原型使用已存在於 WordFlow 的英文字詞與例句；「2/5」等進度僅為設計示例，不會保存真實資料。現階段無 Firebase、無新增帳號、無後端。

已以 Chromium 手機視窗 393×852 檢查：首頁 → 詳情 → 複習翻答案 → 記住 → 探索搜尋 → 設定；未出現 JavaScript 頁面錯誤，也沒有水平溢出。此檢查**不代表** Flutter 原生畫面或 IPA 實機已經通過。

實作下一階段：
1. 建立 Flutter 設計 tokens 與文字樣式，並保留既有資料模型。
2. 先按原型完成首頁、單字詳情與複習三個畫面；維持既有事件 handler。
3. 執行 Flutter analyze/test、iOS unsigned build，簽署前在 SideStore 上以新 Bundle 版本測試升級，確保本機收藏未遺失。
4. 最後再對齊 WidgetKit，做亮/暗模式、中文字長、狹窄螢幕與 VoiceOver 驗收。
