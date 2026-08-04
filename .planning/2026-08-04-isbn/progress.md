# Progress Log

## Session: 2026-08-04

### Phase 1: Requirements & Discovery
- **Status:** complete
- Actions taken:
  - 診斷查書語系問題（來源覆蓋+API key，非編碼）
  - 實測 Google Books(429/空)、Open Library(503/空)、Jike(需key)、Wikidata/LOC(零星)
  - GitHub 研究：BambooIsbn 停止開放、NLCISBNPlugin(Calibre)、excpu/ISBN-API(台灣書404)
  - 競品研究（iTunes API）：CLZ/iCollect/Bookshelf/Book Tracker/Reading List/Bookmory/Goodreads
  - 安裝 app 到實機 Daniel iPhone 17（team NKY2898W74，已簽名+安裝+啟動成功）
- Files created/modified:
  - .planning/2026-08-04-isbn/task_plan.md, findings.md, progress.md

### Phase 2: 查書可靠度（已實作一部分）
- **Status:** complete
- Actions taken:
  - 已實作：Google Books/Jike API key、平行查詢、Wikidata+LOC 來源（commit 5855f32）
  - 新增本地 isbn_cache 表（saveCachedBook/cachedBook），查詢前讀快取、成功後寫入
  - 新增 retryFetch：429/503 等待 1.5s 重試一次，6 個來源皆套用
  - NCL 評估：多欄位表單+AJAX，測試 ISBN 回 0 筆，不整合（保留備援連結）
  - NLCISBNPlugin 評估：Calibre 外掛、中國國圖 OPAC 刮取，非 API，不整合
  - 新增 testIsbnCacheRoundTrip（cache 寫讀回）
- Files created/modified:
  - ApiSource.swift, ISBNService.swift, SettingsView.swift, LocalizedTables.swift
  - Database.swift（isbn_cache 表 + 方法）、DatabaseMigrationTests.swift

### Phase 3: 閱讀目標 + 連續天數
- **Status:** complete
- Actions taken:
  - 新增 reading_log/settings 表、recordReading/currentStreak/bestStreak/setSetting/getSetting/finishedBooksThisYear
  - BookStore 標記已讀時 recordReading
  - StatisticsView 新增 goalsCard（年度目標輸入、進度、目前/最佳連續天數）
  - 修正 calendarDay 實例方法→自由函式 dayBefore、Date(dayKey:) 非 optional 綁定
  - 新增 testReadingStreakAndGoal，13 測試全過
- Files created/modified:
  - Database.swift, BookStore.swift, StatisticsView.swift, Localized.swift, LocalizedTables.swift, DatabaseMigrationTests.swift

### Phase 4: 願望清單 TBR + 標籤
- **Status:** complete
- Actions taken:
  - BookEditView 閱讀狀態 picker 新增「想讀」(wishlist)
  - BookListView 新增 wishlist 篩選 chip、filteredBooks 分支、狀態徽章支援（紫色）
  - BookRow 顯示標籤
  - 新增 filter_wishlist 三語系鍵；13 測試全過
- Files created/modified:
  - BookEditView.swift, BookListView.swift, LocalizedTables.swift

### Phase 6（部分）: 本地 AI 相似書籍推薦
- **Status:** complete
- Actions taken:
  - Database.similarBooks(to:)：依作者/標籤重疊、排除自己與同 isbn
  - BookEditView 新增「相似書籍」推薦區塊
  - 新增 similar_title 三語系鍵、testSimilarBooksRecommendation，14 測試全過
- Files created/modified:
  - Database.swift, BookEditView.swift, LocalizedTables.swift, DatabaseMigrationTests.swift

## Test Results
| Test | Input | Expected | Actual | Status |
|------|-------|----------|--------|--------|
| 單元測試(13) | xcodebuild test | 全過 | 全過 | ✓ |
| 建置 | xcodebuild build | 成功 | 成功 | ✓ |
| 實機安裝+啟動 | devicectl install+launch | 成功 | 成功 | ✓ |

## Error Log
| Timestamp | Error | Attempt | Resolution |
|-----------|-------|---------|------------|
| 2026-08-04 | apply_patch 長內容截斷 | 1 | 拆成小 patch |
| 2026-08-04 | 測試 progress DEFAULT 0 致 0.0 | 1 | 改無預設值為 NULL |
| 2026-08-04 | 簽名缺 development team | 1 | 用 team NKY2898W74 自動簽名 |
| 2026-08-05 | calendarDay 實例方法當自由函式 | 1 | 改自由函式 dayBefore |
| 2026-08-05 | Date(dayKey:) optional 綁定錯誤 | 1 | 改為非 optional let |

## 5-Question Reboot Check
| Question | Answer |
|----------|--------|
| Where am I? | Phase 5（iCloud 同步）+ Phase 6 估價 |
| Where am I going? | Phase 5-8 |
| What's the goal? | 可靠度+功能補完+commit/push+實機安裝 |
| What have I learned? | findings.md |
| What have I done? | 本檔案 |
