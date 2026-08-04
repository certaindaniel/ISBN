# Findings & Decisions

## Requirements
- 提升查書可靠度：本地快取、NCL 來源、429/503 重試、評估 NLCISBNPlugin
- 補完未實作：閱讀目標/連續天數、願望清單 TBR、iCloud 同步、書本估價、AI 推薦
- 全部建置+測試過、commit+push、安裝實機

## Research Findings
- **查書語系診斷**：非編碼問題，是來源覆蓋+API key。中文/台灣書在 Google Books(需key) 與 Open Library(覆蓋差) 常查不到。
- **Google Books**：免 key 會撞每日額度(429)，回空。需 API key（設定頁可填）。
- **Open Library**：免 key 但中文/台灣覆蓋差；實測 2026-08 時 503 掛掉。
- **Jike**：需 apikey，文件說不再發放新 key → 不可用。
- **BambooIsbn(竹簡,503星)**：已停止對外開放(法律因素)，推薦改用 NLCISBNPlugin。
- **NLCISBNPlugin**：Calibre 外掛，走中國國家圖書館 OPAC(網頁刮取)，偏中國書，非乾淨 API。
- **excpu/ISBN-API**：免 key，但實測台灣書回 404、服務不穩。
- **Wikidata SPARQL**：免 key 免費，但對特定 ISBN 覆蓋零星（1984 查無）。
- **Library of Congress**：免 key，但 US 出版覆蓋、ISBN 覆蓋零星。
- **競品(App Store 實測)**：CLZ Books(訂閱$1.99/mo,$19.99/yr)、iCollect Books(教室/跨平台同步)、Bookshelf(社交/願望清單/AI)、Book Tracker(閱讀目標/統計)、Reading List(iCloud同步)、Bookmory(閱讀日誌/計時/月曆)、Goodreads(社群巨頭743K評量)。
- **本 app 差異化**：財務/利潤追蹤、Lexile、繁體台灣在地化、一次性買斷。
- **競品都有但本 app 缺**：iCloud 同步、閱讀進度/目標/連續天數、願望清單 TBR、標籤、估價、AI、社交。

## Technical Decisions
| Decision | Rationale |
|----------|-----------|
| 平行查詢+免 key 來源(Wikidata/LOC)已實作 | 可靠度+速度 |
| Google Books/Jike API key 設定已實作 | 解決額度/需key |
| 本地查詢快取放 SQLite | 免額度、重掃秒回 |
| NCL 台灣國圖做最後備援(HTML刮取) | 台灣書最權威 |
| NLCISBNPlugin 僅評估不整合 | 中國書、Calibre外掛、非API |
| iCloud 同步最後做 | 需 entitlement，風險高 |

## Issues Encountered
| Issue | Resolution |
|-------|------------|
| Google Books 免 key 429 額度 | 設定頁加 API key |
| Jike 需 key 且不再發放 | 標記 requiresKey，需 key 才能用 |
| Open Library 503 不穩 | 平行查詢+更多來源兜底 |
| 簽名缺 team | 用 NKY2898W74 自動簽名 |

## Resources
- iTunes Search API: https://itunes.apple.com/search?term=...&entity=software
- Google Books API: https://www.googleapis.com/books/v1/volumes?q=isbn:{isbn}&key={key}
- Open Library: https://openlibrary.org/api/books?bibkeys=ISBN:{isbn}&format=json
- Jike: https://api.jike.xyz/situ/book/isbn/{isbn}?apikey={key}
- Wikidata SPARQL: https://query.wikidata.org/sparql
- Library of Congress: https://www.loc.gov/search/?q=isbn:{isbn}&fo=json
- NLCISBNPlugin: https://github.com/DoiiarX/NLCISBNPlugin
- 台灣國圖: https://isbn.ncl.edu.tw/NEW_ISBNNet/main_DisplayResults.php?Pact=DisplayAll4Simple&isbn=
- 實機安裝: team NKY2898W74, Daniel iPhone 17 (65E56DBE...)

## Visual/Browser Findings
- 無多媒體內容需記錄
