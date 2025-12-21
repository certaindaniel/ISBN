# ISBN 書籍管理應用

支援 iOS、macOS 和 Android 平台的 Flutter 應用，用於掃描 ISBN、查詢書籍資訊、建檔管理和追蹤購售價格。

## 功能特性

### 📱 核心功能
- **ISBN 掃描**：使用手機攝像頭掃描書籍條碼
- **自動查詢**：透過 Open Library API（免費）查詢書籍資訊
- **書籍管理**：新增、編輯、刪除書籍記錄
- **價格追蹤**：記錄購買價格和售出價格
- **利潤計算**：自動計算單本和總體利潤
- **統計報告**：完整的銷售統計和效率分析

### 🎯 平台支援
- ✅ iOS 12.0+
- ✅ macOS 10.14+
- ✅ Android 5.0+

## 專案結構

```
isbn_book_manager/
├── lib/
│   ├── main.dart                 # 應用入口點
│   ├── models/
│   │   └── book.dart            # Book 數據模型
│   ├── services/
│   │   ├── database_helper.dart  # SQLite 資料庫操作
│   │   └── isbn_service.dart     # ISBN 查詢 API 整合
│   ├── providers/
│   │   └── book_provider.dart    # 狀態管理
│   └── screens/
│       ├── scanner_screen.dart   # 掃描頁面
│       ├── book_list_screen.dart # 書籍列表頁面
│       ├── book_edit_screen.dart # 編輯頁面
│       └── statistics_screen.dart # 統計頁面
├── pubspec.yaml                  # 依賴配置
└── README.md                      # 說明文件
```

## 安裝與配置

### 前置要求
- Flutter SDK 3.0.0 或更高版本
- iOS: Xcode 14+
- Android: Android Studio / SDK 21+
- macOS: 開發環境設定

### 步驟 1：複製並進入專案

```bash
cd isbn_book_manager
```

### 步驟 2：安裝依賴

```bash
flutter pub get
```

### 步驟 3：應用已配置為免費方案

應用預設使用 **Open Library API**（完全免費）：

✅ 無需 API 金鑰
✅ 涵蓋國際書籍
✅ 無請求配額限制

**開箱即用，無需額外配置！**

### 步驟 4：執行應用

#### iOS
```bash
flutter run -d ios
```

#### macOS
```bash
flutter run -d macos
```

#### Android
```bash
flutter run -d android
```

#### 連接特定設備
```bash
flutter devices  # 列出所有設備
flutter run -d <device_id>
```

## 使用指南

### 掃描新書籍

1. 在首頁點擊 **+** 按鈕開啟掃描器
2. 將書籍條碼放在掃描框內
3. 應用自動查詢書籍資訊（Open Library）
4. 編輯必要資訊（價格、描述等）
5. 點擊「保存書籍」

### 編輯書籍資訊

1. 在書籍列表中點擊書籍卡片
2. 修改購買價格、售出價格等資訊
3. 設定購買日期和售出日期
4. 點擊「保存書籍」

### 記錄售出

1. 編輯書籍資訊
2. 填入售出價格和日期
3. 點擊「保存書籍」
4. 應用自動計算利潤

### 查看統計

1. 底部導航欄切換到「統計」
2. 查看：
   - 書籍總數、已售出、持有數量
   - 總支出、總收入、總利潤
   - 銷售率和平均利潤

## API 整合

### Open Library API（預設免費方案）

完全免費，無需 API 金鑰，涵蓋國際書籍。

```
GET https://openlibrary.org/api/books\?bibkeys\=ISBN:9780140328721\&format\=json
```

**特性**：
- ✅ 完全免費
- ✅ 無 API 金鑰要求
- ✅ 支援 ISBN-10 和 ISBN-13
- ✅ 返回書名、作者、出版社、封面
- ✅ 無請求配額限制

### Google Books API（可選增強）

如需更詳細的書籍描述，可選擇配置（需 API 金鑰）。

## 資料庫架構

使用 SQLite 儲存本地資料，結構如下：

```sql
CREATE TABLE books(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  isbn TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  author TEXT NOT NULL,
  publisher TEXT NOT NULL,
  coverUrl TEXT,
  description TEXT,
  purchasePrice REAL NOT NULL,
  salePrice REAL,
  purchaseDate TEXT NOT NULL,
  saleDate TEXT,
  quantity INTEGER DEFAULT 1,
  status TEXT DEFAULT 'owned',  -- 'owned', 'sold'
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL
)
```

## 文件與引用

- [AI_PREFERENCES.md](AI_PREFERENCES.md) - 開發偏好設定
- [API_source.md](API_source.md) - ISBN API 資源列表
- [pubspec.yaml](pubspec.yaml) - 依賴套件

## 實作進度（2025-12-21）

- **已完成**
  - 產生 iOS / Android 應用程式圖示（來源：`assets/design/logo/proposal-1_bg_white.svg`），已將多尺寸 PNG 放入 `ios/Runner/Assets.xcassets/AppIcon.appiconset` 與 `android/app/src/main/res/mipmap-*`。
  - 在 `BookEditScreen` 新增離開前提示儲存（未儲存變更檢查、儲存／放棄／取消對話框）。
  - 在 `pubspec.yaml` 加入 `flutter_launcher_icons` 並執行 icon 生成流程；為了兼容，先將 SVG 轉出為 `assets/design/logo/app_icon.png`（使用 ImageMagick）。
  - 本地 `dart analyze` 與現有單元/Widget 測試已通過（測試輸出顯示 All tests passed）。

- **下一步建議**
  - 若要上架 iOS，可考慮在 `pubspec.yaml` 加入 `remove_alpha_ios: true` 以移除圖示 alpha 通道，避免 App Store 警告。
  - 推送上述變更到遠端（`git push`）並視需要建立 Release / Tag。
  - 將「離開前提示儲存」邏輯套用到其他編輯型 UI（例如掃描頁面的內嵌編輯對話框）。


## 主要依賴套件

| 套件 | 用途 | 版本 |
|------|------|------|
| mobile_scanner | 條碼掃描 | ^3.5.0 |
| http | HTTP 客戶端 | ^1.1.0 |
| sqflite | 本地資料庫 | ^2.3.0 |
| provider | 狀態管理 | ^6.1.0 |
| intl | 國際化日期 | ^0.19.0 |

完整清單見 [pubspec.yaml](pubspec.yaml)

## 疑難排解

### 掃描器無法開啟

**iOS：** 確認 `Info.plist` 中已設定攝像頭使用權限：
```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相機掃描書籍條碼</string>
```

**Android：** 確認 `AndroidManifest.xml` 中已設定相機權限：
```xml
<uses-permission android:name="android.permission.CAMERA" />
```

### API 無結果
1. 確認網路連線
2. Open Library 可能暫時無法連線，稍後再試

### 資料庫錯誤
1. 清除應用快取：`flutter clean`
2. 重新執行 `flutter run`
3. 刪除應用資料並重新安裝

## 開發建議

### 測試掃描功能
使用線上 ISBN 資料庫產生測試條碼，或掃描真實書籍進行測試。

### 效能最佳化
- 首次載入書籍時批量查詢
- 實現列表虛擬化以處理大量書籍
- 快取封面圖片

### 功能擴展建議
- 匯入/匯出書籍資料 (CSV/JSON)
- 支援多個書架分類
- 條形圖表統計
- 備份到雲端
- 掃描多本書籍批量新增

## 授權

本專案使用 MIT 授權。詳見 LICENSE 檔案。

## 貢獻指南

歡迎提交問題報告和功能需求！

## 聯絡與支援

如有問題或建議，請提交 Issue。

---

**最後更新**：2025-12-17
**應用版本**：1.0.0
**Flutter 版本**：3.0.0+
