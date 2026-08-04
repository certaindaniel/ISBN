# Task Plan: ISBN App 可靠度提升 + 功能補完

## Goal
完成 ISBN 書籍管理 App 的查書可靠度提升（本地快取、NLC 來源、429/503 重試、評估 NLCISBNPlugin），並補完先前未實作的功能（閱讀目標/連續天數、願望清單 TBR、iCloud 同步、書本估價、AI 推薦），全部建置+測試通過，commit + push，並安裝到實機。

## Current Phase
Phase 5（iCloud 同步）

## Phases

### Phase 1: Requirements & Discovery
- [x] 理解使用者意圖（可靠度 + 補完未實作 + 安裝實機）
- [x] 確認既有狀態（lookup 診斷、GitHub 來源研究、競品研究）
- [x] 記錄 findings 到 findings.md
- **Status:** complete

### Phase 2: 查書可靠度
- [x] 本地查詢快取（SQLite 存成功查詢，重掃秒回）
- [x] 429/503 退避重試
- [x] 台灣國家圖書館（NCL）評估 → 複雜表單+AJAX、測試 ISBN 回 0 筆，不整合
- [x] 評估 NLCISBNPlugin → Calibre 外掛、中國國圖 OPAC 刮取，非 API，不整合
- **Status:** complete

### Phase 3: 閱讀目標 + 連續天數
- [x] DB 存閱讀目標（settings 表 reading_goal_year）
- [x] reading_log 每日記錄 + currentStreak/bestStreak
- [x] 統計頁顯示目標進度與連續天數
- **Status:** complete

### Phase 4: 願望清單 TBR + 標籤
- [x] 新增 wishlist 狀態（編輯 picker）與列表「想讀」篩選
- [x] 標籤輸入（已實作）+ 列表標籤顯示
- [x] 狀態徽章支援想讀（紫色）
- **Status:** complete

### Phase 5: iCloud 同步
- [ ] CloudKit/entitlement 設定
- [ ] 書籍資料同步與衝突處理
- **Status:** pending

### Phase 6: 書本估價 + AI 推薦
- [ ] 市場估價來源整合（無可靠免 key 來源，待評估）
- [x] AI/推薦功能（本地相似書籍：依標籤/作者）
- **Status:** in_progress

### Phase 7: 測試與驗證
- [ ] 建置成功
- [ ] 單元測試全過
- [ ] 安裝到實機
- **Status:** pending

### Phase 8: Delivery
- [ ] commit + push
- [ ] 向使用者報告
- **Status:** pending

## Key Questions
1. 哪個免 key 來源對台灣書最可靠？→ Google Books(需key) 最佳；NCL 網頁刮取可當備援
2. iCloud 同步是否可行？→ 需 entitlement + CloudKit，風險高，最後做
3. 書本估價/AI 來源？→ 需評估免 key 選項

## Decisions Made
| Decision | Rationale |
|----------|-----------|
| 本地查詢快取放 SQLite | 既有 DB 基礎，免額度、重掃秒回 |
| NCL 做最後備援（HTML 刮取） | 台灣書最權威但無乾淨 API |
| 平行查詢 + 免 key 來源（已實作） | 提升可靠度與速度 |
| iCloud 同步最後做 | 需 entitlement，風險高 |

## Errors Encountered
| Error | Attempt | Resolution |
|-------|---------|------------|
| apply_patch 長內容被截斷 | 2 | 拆成小 patch |
| 測試 progress DEFAULT 0 致 0.0 | 1 | 改為無預設值，NULL |

## Notes
- 更新 phase 狀態；決策前重讀計畫；記錄所有錯誤
- 每完成一段就更新 progress.md 並 commit
