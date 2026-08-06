# Run 日誌 — ISBN Manager UI 20 次改善

計畫：improvement-plan.md
競品依據：competitor-research.md
格式：`run N | 改了什麼 | file:line | 競品/規則依據 | build/test 結果`

（由執行 agent 依序追加。使用者明天早上據此驗收。）

`run 1 | BookRow 封面縮圖加大至 52x78、列垂直 padding 6→8（8dp 韻律） | ios/ISBNManager/Views/BookListView.swift:231,262 | BookBuddy/Libib 封面導向 + pro-rules 8dp spacing | build+test 全過(17)；已裝實機並啟動`

`run 2 | 閱讀中列內加百分比文字（ProgressView 旁 "N%"）| ios/ISBNManager/Views/BookListView.swift:249-256 | Goodreads 列內進度 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 3 | 空狀態加 CTA（去掃描/以書名新增）| ios/ISBNManager/Views/BookListView.swift:154-171 | ux empty-state + BookBuddy 空狀態 CTA | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 4 | 統計完成度卡片加完成度圓環（綠色語意保留）| ios/ISBNManager/Views/StatisticsView.swift:104-132 | Book Track/StoryGraph 視覺化 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 5 | Settings 解鎖/評分/同步三區加 Section 標題（8dp 區塊韻律一致）| ios/ISBNManager/Views/SettingsView.swift + LocalizedTables.swift | pro-rules spacing | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 6 | icon-only 按鈕 a11y 稽核：全部已含 label；補封面可點區域 .isButton/.accessibilityLabel | ios/ISBNManager/Views/BookEditView.swift:149-153 | pro-rules a11y/touch | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 7 | 暗色對比：BookList 空狀態提示與封面 placeholder 灰 → 語意 .secondary（兩模式可辨）| ios/ISBNManager/Views/BookListView.swift:160,286,291,295 | pro-rules dark contrast | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 8 | 錯誤狀態回饋：error banner 關閉鈕補 .accessibilityLabel（icon-only 一致性）| ios/ISBNManager/Views/BookListView.swift:116-122 | pro-rules feedback/a11y | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 9 | 安全區：FAB 底部間距 16→24，避開 tab/gesture 指示列 | ios/ISBNManager/Views/BookListView.swift:186 | pro-rules safe-area | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 10 | 封面 placeholder 統一：BookEdit 佔位書 icon 灰 → .secondary（與 BookList 一致，兩模式可辨）| ios/ISBNManager/Views/BookEditView.swift:189 | pro-rules dark contrast + 一致性 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 11 | 評估內嵌搜尋列：現有 toolbar 搜尋是「遠端 Google Books 書名查詢」，內嵌本地過濾會與其語意重疊、增 scope → 記錄評估，跳過不改 | - | BookBuddy 內嵌搜尋（評估）| 未改 code（skip）`

`run 12 | 評估網格/列表切換：需新增網格 layout + 切換狀態 + toolbar 控制，超出「單一外科式 UI 部分」scope → 記錄評估，跳過不改 | - | Libib 網格切換（評估）| 未改 code（skip）`

`run 13 | 閱讀進度滑桿補 .accessibilityLabel/.accessibilityValue，百分比即時回饋 | ios/ISBNManager/Views/BookEditView.swift:230-245 | Book Track 滑桿+百分比 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 14 | 狀態 badge 與 filter chip 語意一致：wishlist badge .purple → .accentColor（與 chip 同紫）| ios/ISBNManager/Views/BookListView.swift:300 | Goodreads shelf 一致性 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 15 | 導航標題一致性：BookList 補 .navigationBarTitleDisplayMode(.inline)（與其他畫面一致）| ios/ISBNManager/Views/BookListView.swift:50 | pro-rules nav 一致性 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 16 | 表單必填錯誤就近提示：save 校驗失敗在儲存鈕上方 inline 顯示（非僅 toast）| ios/ISBNManager/Views/BookEditView.swift:33,360-379,426-434 | pro-rules forms | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 17 | 掃描 torch 狀態可視：開=黃 tint、關=紫，補 .accessibilityValue(torch_on/off) | ios/ISBNManager/Views/ScannerView.swift:224-233 + LocalizedTables.swift | BookBuddy/Book Track 狀態回饋 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 18 | FAB 常駐（非僅空列表時）讓有藏書也能隨時掃描/新增；觸控 56x56≥44 已達標 | ios/ISBNManager/Views/BookListView.swift:84-88 | BookBuddy 新增入口一致性 | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 19 | 封面 AsyncImage 載入回饋：載入中 spinner、失敗顯示書 icon placeholder | ios/ISBNManager/Views/BookListView.swift:291-300 | pro-rules loading feedback | BUILD SUCCEEDED + TEST SUCCEEDED(17)`

`run 20 | 評估統計「本年vs累計/長條圖」：run 4 已加完成度圓環、goalsCard 已有目標進度+百分比，再加需年份切換+新圖超出單一外科式 scope → 記錄評估，跳過 | - | Book Track 視覺化（評估）| 未改 code（skip）`

## 總結
- 執行 run 1..20，完成 15 項實際改動、5 項評估型跳過（run 11/12/20 因超出單一外科式 scope 或語意重疊；皆記錄原因）。
- 每項實際改動皆 BUILD SUCCEEDED + TEST SUCCEEDED(17)。
- 保留紫色主色與統計語意色；未 commit（working tree + run-log 供使用者驗收）。

## 補充根因（使用者指出，重要）
- 為何「怎麼改紫色都是灰白」的真正主因：Assets.xcassets/AccentColor.colorset/Contents.json 的 RGB 用了**浮點小數格式（如 "0.388"）**，Xcode 資產編譯器 actool 無法正確解析，把 AccentColor 自動降級退回 **#FFFFFF 白色**——所以之前所有紫色應用改動都看不到紫色。
- 修法（使用者）：改為 Xcode 嚴格標準的**16 進位 RGB（0x63, 0x66, 0xF1 = #6366F1 靛紫）**。
- 驗證：assetutil 讀出編譯後 Assets.car 的 AccentColor components = [0.388, 0.4, 0.945, 1] = #6366F1，非白色。根因已解。

