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
