import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// 初始化 sqflite 在測試環境的工廠。呼叫此函式以為全域 `openDatabase` 提供
/// 可運作的 `databaseFactory`。
void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
