# 競品 UI/UX 研究筆記 — ISBN Manager（原生 SwiftUI）

日期：2026-08-05
用途：作為「20 次一次一個 UI 部分改善」的依據。改善後仍保留使用者指定的紫色主色與統計語意色。

## 競品清單與其 UI 強項

### Goodreads
- 書架(shelf)式分類：currently-reading / read / want-to-read，等同我們的 status + filter chip。
- 列表列：封面縮圖 + 書名/作者 + **列內進度條(percent)**，一列可讀完整閱讀狀態。
- 封面在 UI 中是主要視覺元素，縮圖尺寸大且一致。

### BookBuddy / Libib（iOS 書目管理）
- **封面導向**：預設大封面縮圖，列表列縮圖統一、間距一致(8dp 韻律)。
- **列表/網格切換**：Libib 有 grid/list 切換，瀏覽量大時用網格。
- 頂部有**內嵌搜尋列**（不是只有 toolbar 按鈕），常駐可打字。
- 空狀態：給**明確 CTA**（去掃描/去新增）+ 友善文案，不是空白。

### Book Track / StoryGraph（統計/追蹤）
- **視覺化**：圓環/長條進度圖、年度目標、連續天數，色彩語意明確（讀完綠/進行中橘/未讀灰）。
- 閱讀進度用**滑桿 + 百分比**，回饋即時。

### Calibre（桌面，參考）
- 中繼資料豐富、欄位完整；移動 app 不沿用其密度。

## 對照我們的 app（原生 SwiftUI，紫色主色，統計語意色保留）

已具備：封面縮圖、status chip、filter chip（含 wishlist）、列內進度條、統計(目標/連續天數)、掃描、tags、lexile、相似書、逐來源進度、EAN fallback、a11y 標籤、44pt 觸控。

可改善（競品啟發、一次一個、外科式、低風險）：
1. 列表列封面縮圖統一加大 + 間距 8dp 韻律（BookBuddy/Libib）。
2. 列表列閱讀中列內顯示百分比文字（Goodreads）。
3. 空狀態加明確 CTA（去掃描/去新增）+ 更友善文案（ux empty-state 規則）。
4. 統計完成度卡片加視覺化（圓環/長條，語意色保留）（Book Track）。
5. 設定頁區塊間距/分隔線 8dp 一致（pro-rules spacing）。
6. 全部 icon-only 按鈕 a11y label + ≥44pt 稽核補齊（pro-rules a11y/touch）。
7. 暗色模式對比稽核：卡片/文字/邊框兩模式皆可辨（pro-rules dark contrast）。
8. 載入/空/錯誤三態回饋模式一致化（pro-rules feedback）。
9. 列表底部安全區 inset，內容不被 tab/固定列遮蔽（pro-rules safe-area）。
10. 封面 placeholder 統一（書 icon + 圓角矩形，兩模式皆可辨）。
11. 搜尋入口：內嵌搜尋列 vs 現 toolbar 按鈕（評估，BookBuddy）。
12. 網格/列表切換（評估，Libib）。
13. 閱讀進度滑桿 + 百分比回饋即時（Book Track）。
14. 狀態 badge 顏色與 filter chip 語意一致。
15. 導航標題/返回一致性（pro-rules nav）。
16. 表單必填欄錯誤就近提示（pro-rules forms）。
17. 掃描器 torch 狀態可視 + 掃描中回饋（已部分）。
18. FAB/新增入口一致性與觸控大小。
19. 封面縮圖載入 placeholder/error 處理。
20. 統計「本年 vs 累計」或簡單長條圖（Book Track，評估）。

## 執行原則
- 一次只改一個 UI 部分（run），每 run 記錄 file:line + 競品依據 + 驗證。
- 每 run 後 build + 測試必須過，失敗則修回或記錄並跳過。
- 保留紫色主色與統計語意色，不改動這些。
