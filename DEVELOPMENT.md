# 開發與測試指南

## 本地開發設置

### 環境配置

#### macOS 環境變數
```bash
# 設定開發環境
export FLUTTER_ROOT=~/development/flutter
export PATH="$FLUTTER_ROOT/bin:$PATH"

# 驗證安裝
flutter doctor
```

#### iOS 開發
```bash
# 安裝 CocoaPods
sudo gem install cocoapods

# 驗證 Xcode
xcode-select --install

# 確保 iOS deployment target ≥ 12.0
```

#### Android 開發
```bash
# 設定 Android SDK 路徑
export ANDROID_HOME=~/Library/Android/sdk
export PATH="$ANDROID_HOME/tools:$PATH"

# 驗證 Android SDK
flutter doctor -v
```

## 測試指南

### 單元測試

測試書籍模型序列化：

```bash
flutter test test/models/book_test.dart
```

測試 ISBN 驗證和格式化：

```bash
flutter test test/services/isbn_service_test.dart
```

### 集成測試

進行掃描流程集成測試：

```bash
flutter test integration_test/scanner_test.dart
```

測試書籍管理完整流程：

```bash
flutter test integration_test/book_management_test.dart
```

### 運行所有測試

```bash
flutter test
```

## 模擬器測試

### iOS 模擬器

```bash
# 啟動 iPhone SE 模擬器
open -a Simulator

# 或使用 Flutter 命令列
flutter emulators --launch apple_ios_simulator

# 在模擬器上運行
flutter run -d ios
```

### Android 模擬器

```bash
# 啟動 Android 模擬器
flutter emulators --launch <emulator_name>

# 列出可用模擬器
flutter emulators

# 在模擬器上運行
flutter run -d <device_id>
```

## 測試 ISBN 掃描

### 使用 Barcode Scanner App

1. 在實機上使用第三方條碼掃描應用測試 ISBN
2. 記下有效的 ISBN-10 和 ISBN-13 號碼
3. 在應用中測試掃描

### 測試 ISBN

常用測試 ISBN：

- **ISBN-10**: `0140328721` (1984 - George Orwell)
- **ISBN-13**: `9780140328721` (1984)
- **ISBN-13**: `9781491927281` (Learning JavaScript)
- **ISBN-13**: `9781449355739` (Programming Rust)

### 離線測試

編輯 `lib/services/isbn_service.dart` 進行模擬測試：

```dart
// 添加測試模式
static const bool _testMode = false;

static Future<Book?> searchByIsbn(String isbn) async {
  if (_testMode) {
    return _createMockBook(isbn);
  }
  // 正常流程...
}

static Book _createMockBook(String isbn) {
  return Book(
    isbn: isbn,
    title: '測試書籍',
    author: '測試作者',
    publisher: '測試出版社',
    purchasePrice: 100.0,
    purchaseDate: DateTime.now(),
  );
}
```

### API 配置

應用已預設使用 **Open Library API**（完全免費）。無需額外配置，開箱即用！

### 啟用調試信息

```bash
flutter run -v  # 詳細日誌
```

### 使用 DevTools

```bash
flutter pub global activate devtools
devtools

# 在另一個終端運行應用
flutter run
# 然後在 DevTools 中連接
```

### 資料庫檢查

查看本地資料庫內容：

```bash
# 連接到 Android 設備
adb shell

# 進入應用資料目錄
cd /data/data/com.example.isbn_book_manager/databases

# 使用 sqlite3 查看
sqlite3 isbn_books.db
sqlite> .tables
sqlite> SELECT * FROM books;
```

## 性能測試

### 監控 FPS

```bash
flutter run --profile
# 在應用運行時按 P 鍵顯示 FPS
```

### 記憶體檢查

```bash
flutter run --profile

# 使用 DevTools 查看記憶體使用
# 或在 logcat 中監控
adb logcat | grep "memory"
```

## 準備發布

### iOS 發布準備

```bash
# 更新版本信息（在 Info.plist 中）
# 更新 build number

# 打包
flutter build ios --release

# 上傳到 App Store Connect
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -derivedDataPath ios/build archive -archivePath ios/build/Runner.xcarchive
```

### Android 發布準備

```bash
# 生成密鑰
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key

# 建立 key.properties 配置
cat > android/key.properties << EOF
storePassword=<password>
keyPassword=<password>
keyAlias=key
storeFile=/Users/daniel.lu/key.jks
EOF

# 打包 APK
flutter build apk --release

# 打包 App Bundle
flutter build appbundle --release
```

## 常見問題

### 掃描器崩潰

**症狀**：應用在掃描器打開時崩潰

**解決**：
1. 檢查相機權限配置
2. 在物理設備上測試（模擬器不支持完整相機功能）
3. 更新 `mobile_scanner` 套件

### API 查詢超時

**症狀**：ISBN 查詢時超時

**解決**：
1. 檢查網路連接
2. 增加超時時間（在 `isbn_service.dart` 中）
3. Open Library 伺服器暫時無法訪問時稍後重試

### 資料庫鎖定

**症狀**：無法寫入資料庫

**解決**：
1. 清除應用快取
2. 卸載並重新安裝應用
3. 檢查檔案權限

## 參考資源

- [Flutter 開發文件](https://flutter.dev/docs)
- [Dart 文件](https://dart.dev/guides)
- [mobile_scanner 文件](https://pub.dev/packages/mobile_scanner)
- [SQLite 文件](https://www.sqlite.org/docs.html)
- [Google Books API 文件](https://developers.google.com/books)
- [Open Library API 文件](https://openlibrary.org/developers/api)
