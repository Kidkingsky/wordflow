# WordFlow 詞彙來源與授權

本次擴充採用以下開放資料及工具。新增內容為英文字詞及其精簡繁體中文釋義，轉換後離線打包於原生 App 與 WidgetKit Extension。

- **imfiiish/wordlists**（MIT）：A2/B1 字詞選擇與程度參考。https://github.com/imfiiish/wordlists
  - Copyright (c) 2026 imfiiish
  - 該專案的 CEFR 程度編目參考 Oxford 3000；WordFlow 並非 Oxford 官方教材，英文字詞選擇也不構成官方認證。
- **ECDICT**（MIT）：英中詞義與詞性參考。https://github.com/skywind3000/ECDICT
  - Copyright (c) 2025 Linwei
- **OpenCC**（Apache-2.0）：只用於開發時將新增詞義轉換為臺灣常用繁體字。https://github.com/BYVoid/OpenCC
  - 轉換字典及工具原始碼並未隨 App 重新分發，請參考上游授權 https://github.com/BYVoid/OpenCC/blob/master/LICENSE

MIT 授權全文保留於 `third_party/licenses/`。原本 WordFlow 的 72 筆人工撰寫教材不變。

**內容品質範圍**：新增的 1,452 個詞條為自動選取、轉換及格式化的精簡詞義資料，不代表逐條人工校對，部分多義字只列常見意義之一。新增詞條的雙語例句目前留空；既有 72 筆保留完整例句。若發現用字不精確，可於 WordFlow GitHub 回報。

## v0.5.0 循序學習課程

新增的 `assets/content/course_content.json` 是 WordFlow 以日常溝通目標自編的情境課程，並非任何出版商教材的重製。以 A2/B1 為大致學習難度，部分基礎詞彙跨級重複運用；原詞庫的詞彙程度標籤仍保留。新增 24 課（96 個單字、48 個詞句），所有課內詞條皆有雙語例句。既有詞條以原 ID 合併，原有人工撰寫例句與收藏／複習紀錄不變。新增 55 個獨立單字、34 句新詞句，既有自動詞條中有 22 個補上例句。合併後 1,555 單字、58 詞句；其餘字典資料仍是補充查詢資料，未宣稱逐條人工校訂。自編內容尚待實際教學回饋與校訂。

### 句型與延伸單字

48 個核心詞句的句型結構、使用時機、文法提醒、重點搭配與 144 組跨情境雙語例句為 WordFlow 自編（非出版商教材）。另從例句中整理 54 個新字和 9 個舊字的語境釋義與例句，合計字庫 1,609 字、58 句。程度為教學安排參考，非官方認證；內容仍可依學習回饋修訂。
