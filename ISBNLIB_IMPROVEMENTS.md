# 參考 isbnlib 的改進

本應用參考 Python 的 [isbnlib](https://github.com/xlcnd/isbnlib) 套件的設計，實現了以下功能改進：

## 🎯 新增的功能

### 1. **Wikipedia API 來源** (ApiSource.wikipedia)
- 新增 Wikipedia 作為第四個查詢來源
- 預設關閉（穩定度較低）
- 可在設定頁切換啟用
- 用於補充文獻和參考資訊

```dart
ApiSourceInfo(
  id: ApiSource.wikipedia,
  displayName: 'Wikipedia',
  description: '維基百科參考書籍資訊，補充文獻數據。',
  enabledByDefault: false,
  requiresKey: false,
  baseUrl: 'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=',
)
```

### 2. **嚴格的 ISBN 驗證** (isValidIsbn10/13)
參考 isbnlib 實現了正確的檢查碼驗證：

#### ISBN-10 驗證
```dart
static bool isValidIsbn10(String isbn) {
  // 格式: 9個數字 + 1個數字或 X
  // 檢查碼計算: sum = (d₁×10 + d₂×9 + ... + d₉×2) mod 11
  // 檢查碼為 (11 - sum) mod 11，若為 10 則用 X
}
```

#### ISBN-13 驗證
```dart
static bool isValidIsbn13(String isbn) {
  // 格式: 13個數字
  // 檢查碼計算: sum = (d₁×1 + d₂×3 + ... + d₁₂×3) mod 10
  // 檢查碼為 (10 - sum) mod 10
}
```

### 3. **ISBN 文字提取** (extractIsbnFromText)
類似 isbnlib 的 `get_isbnlike` 功能，可從文字中自動提取 ISBN：

```dart
static List<String> extractIsbnFromText(String text)
```

支援的格式：
- `ISBN 978-0-446-31078-9` → `9780446310789`
- `ISBN 978 0 446 31078 9` → `9780446310789`
- `978-0-446-31078-9` → `9780446310789`
- `ISBN: 0-446-31078-3` → `0446310783`

## 📊 現有 API 來源對比

| 來源 | 啟用預設 | 需要 API Key | 覆蓋範圍 | 說明 |
|-----|--------|-----------|--------|------|
| Google Books | ✅ | ❌ | 國際書籍 | 覆蓋面廣，含中文書 |
| Open Library | ✅ | ❌ | 國際書籍 | 完全免費開放 |
| Wikipedia | ❌ | ❌ | 參考文獻 | 補充文獻數據 |
| 中文第三方 API | ❌ | ❌ | 中文書籍 | 社群維護，穩定度較低 |

## 🔄 多來源策略

應用依序嘗試啟用的來源，如第一個來源找不到資料就自動換下一個：

```
1️⃣ Google Books (預設啟用)
   ↓ 找不到
2️⃣ Open Library (預設啟用)
   ↓ 找不到
3️⃣ Wikipedia (可啟用)
   ↓ 找不到
4️⃣ 中文第三方 API (可啟用)
   ↓ 全部找不到
❌ 提示使用者前往手動查詢網頁
```

## 💡 使用方式

### 掃描或輸入 ISBN
1. 在掃描頁輸入 ISBN（支援帶文字或符號的輸入）
2. 應用自動提取純 ISBN 碼
3. 依序查詢已啟用的來源

### 調整查詢來源
1. 進入設定頁面
2. 開啟/關閉各個 API 來源
3. 查詢順序即為列表順序

### 查詢失敗時
1. 頁面顯示 SnackBar 錯誤提示
2. 前往設定頁「常用查詢網頁」區塊
3. 點擊相應書店或圖書館進行手動查詢

## 🛠 技術細節

### ISBN-10 檢查碼範例
```
ISBN-10: 0-446-31078-3

計算:
sum = 0×10 + 4×9 + 4×8 + 6×7 + 3×6 + 1×5 + 0×4 + 7×3 + 8×2
    = 0 + 36 + 32 + 42 + 18 + 5 + 0 + 21 + 16 = 170

checksum = (11 - (170 mod 11)) mod 11
         = (11 - 5) mod 11 = 6

實際提供的檢查碼: 3 ✗ (不匹配)
```

### ISBN-13 檢查碼範例
```
ISBN-13: 978-0-446-31078-9

計算:
sum = 9×1 + 7×3 + 8×1 + 0×3 + 4×1 + 4×3 + 6×1 + 3×3 + 1×1 + 0×3 + 7×1 + 8×3
    = 9 + 21 + 8 + 0 + 4 + 12 + 6 + 9 + 1 + 0 + 7 + 24 = 101

checksum = (10 - (101 mod 10)) mod 10
         = (10 - 1) mod 10 = 9 ✓

實際提供的檢查碼: 9 ✓ (匹配)
```

## 📚 參考資源

- [isbnlib GitHub](https://github.com/xlcnd/isbnlib)
- [ISBN 國際標準](https://en.wikipedia.org/wiki/International_Standard_Book_Number)
- [Google Books API](https://developers.google.com/books)
- [Open Library API](https://openlibrary.org/dev/docs/api)
- [Wikipedia Search API](https://en.wikipedia.org/w/api.php)
