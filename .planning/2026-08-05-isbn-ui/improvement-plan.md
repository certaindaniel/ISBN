# ISBN Manager UI 改善計畫 — 20 次一次一個部分

日期：2026-08-05
來源：競品研究（competitor-research.md）+ ui-ux-pro-max pro-rules。
原則：一次只改一個 UI 部分；外科式低風險；保留紫色主色與統計語意色；每 run 後 build+test 必須過；每 run 記錄到 run-log.md。
專案根：/Users/daniel.lu/GitProject/Daniel/ISBN，原生 SwiftUI 在 ios/ISBNManager/Views/*.swift。

## 驗證命令（每 run 用）
cd /Users/daniel.lu/GitProject/Daniel/ISBN/ios && xcodebuild -project ISBNManager.xcodeproj -scheme ISBNManager -destination 'platform=iOS Simulator,id=74AB1F0E-D484-420B-AC5F-BAA88151B545' -derivedDataPath /tmp/dd_run build
再跑 test：同上加 test。必須 BUILD SUCCEEDED + TEST SUCCEEDED(17)。

## Run 清單（每 run = 一個 UI 部分；若某項不適合/會破壞，記錄原因並跳過，仍算一次）
1. BookListView BookRow 封面縮圖統一加大 + 列間距 8dp 韻律（BookBuddy/Libib 封面導向）。
2. BookListView 閱讀中列內顯示百分比文字（Goodreads 列內進度）。
3. BookListView 空狀態加明確 CTA（去掃描/去新增）+ 友善文案（ux empty-state）。
4. StatisticsView 完成度卡片加視覺化圓環/長條（語意色保留）（Book Track）。
5. SettingsView 區塊間距/分隔 8dp 一致（pro-rules spacing）。
6. 全部 icon-only 按鈕 a11y label + ≥44pt 稽核補齊（pro-rules a11y/touch）。
7. 暗色模式對比稽核：卡片/文字/邊框兩模式皆可辨（pro-rules dark contrast）。
8. 載入/空/錯誤三態回饋模式一致化（pro-rules feedback）。
9. BookListView 列表底部安全區 inset，內容不被固定列遮蔽（pro-rules safe-area）。
10. 封面 placeholder 統一（書 icon + 圓角矩形，兩模式可辨）。
11. 搜尋入口評估：BookList 內嵌搜尋列 vs toolbar（BookBuddy）。若可行加內嵌搜尋列，否則記錄評估跳過。
12. 網格/列表切換評估（Libib）。若可行加，否則記錄評估跳過。
13. BookEdit 閱讀進度滑桿 + 百分比回饋即時（Book Track）。
14. 狀態 badge 顏色與 filter chip 語意一致（Goodreads shelf）。
15. 導航標題/返回一致性稽核（pro-rules nav）。
16. BookEdit 必填欄錯誤就近提示（pro-rules forms）。
17. Scanner torch 狀態可視化（亮/暗）+ 掃描回饋（已部分，補齊）。
18. FAB/新增入口一致性與觸控大小稽核（BookBuddy）。
19. 封面縮圖載入 placeholder/error 處理（AsyncImage）。
20. 統計「本年 vs 累計」或簡單長條圖評估（Book Track）。

## 執行方式
依序執行 run 1..20。每 run：
- 讀取目標檔案確認現況。
- 做單一外科式修改。
- build + test 驗證（失敗→修回或記錄並跳過）。
- 在 run-log.md 追加一列：run 編號、改了哪、file:line、競品依據、build/test 結果。
全部完成後在 run-log.md 寫總結。
不 commit（留 working tree + 記錄給使用者驗收）。
