# ISBN 書籍管理應用 - 快速開始指南

## 🚀 5 分鐘快速開始

### 第 1 步：準備環境（2 分鐘）

```bash
# 確認 Flutter 已安裝
flutter --version

# 進入專案目錄
cd /Users/daniel.lu/GitProject/Daniel/ISBN

# 取得依賴
flutter pub get
```

### 第 2 步：選擇平台運行（2 分鐘）

#### 運行在 iOS 模擬器
```bash
flutter run -d ios
# 或打開 Xcode 並運行
open ios/Runner.xcworkspace
```

#### 運行在 Android 模擬器
```bash
flutter run
# 或指定設備
flutter run -d emulator-5554
```

#### 運行在 macOS
```bash
flutter run -d macos
```

### 第 3 步：測試應用（1 分鐘）

1. 應用啟動後進入「我的書籍」頁面
2. 點擊右下角 **+** 按鈕進入掃描器
3. 允許相機權限
4. 掃描任何書籍條碼（或使用 ISBN：`9780140328721`）
5. 填入購買價格並保存

---

## 📋 核心工作流程

### 工作流 1：新增書籍

```
掃描 ISBN
    ↓
自動查詢書籍資訊（Open Library / Google Books）
    ↓
編輯並補充價格、日期等
    ↓
保存到本地資料庫
    ↓
在列表中顯示
```

### 工作流 2：記錄售出

```
編輯現有書籍
    ↓
填入售出價格和日期
    ↓
應用自動計算利潤
    ↓
保存
    ↓
統計頁面自動更新
```

### 工作流 3：查看統計

```
底部導航切換到「統計」
    ↓
查看
  - 書籍數量統計
  - 金額統計（支出/收入/利潤）
  - 效率分析（銷售率、平均利潤）
```

---

## 🔧 快速配置

### 使用免費方案（推薦）

應用已預設配置為使用 **Open Library API**（完全免費）：

✅ 無需 API 金鑰
✅ 涵蓋國際書籍
✅ 支援 ISBN 查詢
✅ 無請求配額限制

**無需額外配置，開箱即用！**

### 可選：使用 Google Books API

如需更完整的書籍描述，可選擇配置 Google Books API（需 API 金鑰）：

1. 造訪 [Google Cloud Console](https://console.cloud.google.com/)
2. 建立新專案並啟用 **Google Books API**
3. 建立 **API 金鑰**
4. 編輯 `lib/services/isbn_service.dart` 第 8 行：

```dart
// 替換為您的 API 金鑰（可選）
static const String googleApiKey = 'YOUR_API_KEY_HERE';
```

注意：即使不配置 Google Books，應用仍可正常使用 Open Library API。

---

## 📱 平台特定設置

### iOS

**必要權限**已在 `ios/Runner/Info.plist` 中配置：

✅ 相機存取
✅ 照片庫存取

**測試**：
```bash
flutter run -d ios
# 或連接真機
flutter run -d <udid>
```

### Android

**必要權限**已在 `android/app/src/main/AndroidManifest.xml` 中配置：

✅ `CAMERA`
✅ `INTERNET`
✅ `READ_EXTERNAL_STORAGE`

**測試**：
```bash
flutter run
# 確認模擬器 API 等級 ≥ 21
```

### macOS

**相機支援**：macOS 10.14+

**測試**：
```bash
flutter run -d macos
```

---

## 🧪 簡單測試

### 測試掃描功能

**無實體書籍時**的替代方案：

1. 使用 QR 碼生成網站生成包含 ISBN 的條碼
2. 在應用中掃描
3. 或編輯 `lib/services/isbn_service.dart` 啟用測試模式

### 測試 API 查詢

```bash
# 終端測試 Open Library API
curl "https://openlibrary.org/api/books?bibkeys=ISBN:9780140328721&format=json"

# 終端測試 Google Books API
curl "https://www.googleapis.com/books/v1/volumes?q=isbn:9780140328721&key=YOUR_KEY"
```

### 測試 UI 組件

```bash
# 運行單元測試
flutter test test/models/book_test.dart

# 運行所有測試
flutter test
```

---

## 📂 檔案結構速查

```
lib/
├── main.dart                    # 應用主入點
├── models/book.dart             # 數據模型
├── services/
│   ├── isbn_service.dart       # ISBN 查詢邏輯
│   └── database_helper.dart     # 資料庫操作
├── providers/book_provider.dart # 狀態管理
└── screens/
    ├── scanner_screen.dart      # 掃描頁面
    ├── book_list_screen.dart    # 列表頁面
    ├── book_edit_screen.dart    # 編輯頁面
    └── statistics_screen.dart   # 統計頁面
```

---

## 🐛 常見問題速解

| 問題 | 解決方法 |
|------|--------|
| 相機無法開啟 | 檢查權限、使用實機、更新套件 |
| ISBN 無查詢結果 | 確認 ISBN 有效、檢查網路、查看日誌 |
| 應用崩潰 | 運行 `flutter clean && flutter pub get` |
| 資料庫錯誤 | 重新安裝應用、檢查存儲空間 |
| 模擬器性能慢 | 增加 RAM、使用 x86_64 架構、關閉背景應用 |

---

## 📚 下一步

### 功能測試清單

- [ ] 掃描功能測試
- [ ] Open Library API 查詢測試
- [ ] Google Books API 查詢測試（已配置 API Key）
- [ ] 書籍新增/編輯/刪除測試
- [ ] 價格記錄和利潤計算測試
- [ ] 統計數據準確性測試
- [ ] 跨平台相容性測試（iOS/Android/macOS）

### 推薦擴展功能

1. **批量匯入** - 支援 CSV/JSON 檔案
2. **資料備份** - 雲端同步（Firebase）
3. **分類管理** - 書架/標籤分類
4. **圖表統計** - 直觀的收益趨勢圖
5. **離線模式** - 無網路時的操作
6. **多語言** - 國際化支援

### 效能最佳化建議

1. 大量書籍時啟用分頁/虛擬列表
2. 圖片快取策略
3. 資料庫查詢最佳化
4. 定期清理過期資料

---

## 📞 需要幫助？

- 查看 [README.md](README.md) 了解完整功能說明
- 查看 [DEVELOPMENT.md](DEVELOPMENT.md) 了解開發和測試詳情
- 參考 [API_source.md](API_source.md) 了解 ISBN API 資源
- 檢查 [AI_PREFERENCES.md](AI_PREFERENCES.md) 了解開發規範

---

**祝您使用愉快！** 🎉
