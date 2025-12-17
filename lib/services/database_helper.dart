import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/book.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'isbn_books.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
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
        status TEXT DEFAULT 'owned',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');
  }

  // 新增書籍
  Future<int> insertBook(Book book) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();

    return await db.insert(
      'books',
      {
        ...book.toMap(),
        'createdAt': now,
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 取得所有書籍
  Future<List<Book>> getAllBooks() async {
    final db = await database;
    final result = await db.query('books', orderBy: 'createdAt DESC');
    return result.map((map) => Book.fromMap(map)).toList();
  }

  // 依 ISBN 查詢書籍
  Future<Book?> getBookByISBN(String isbn) async {
    final db = await database;
    final result = await db.query(
      'books',
      where: 'isbn = ?',
      whereArgs: [isbn],
    );

    if (result.isEmpty) return null;
    return Book.fromMap(result.first);
  }

  // 更新書籍
  Future<int> updateBook(Book book) async {
    final db = await database;
    final updateData = book.toMap();
    // 過濾掉 null 值以避免 SQLite 型別錯誤
    updateData.removeWhere((key, value) => value == null);
    updateData['updatedAt'] = DateTime.now().toIso8601String();

    return await db.update(
      'books',
      updateData,
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  // 刪除書籍
  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete(
      'books',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 取得統計資訊
  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;

    final totalCount = await db.rawQuery('SELECT COUNT(*) as count FROM books');

    final soldCount = await db.rawQuery(
        'SELECT COUNT(*) as count FROM books WHERE status = ?', ['sold']);

    final totalSpent = await db
        .rawQuery('SELECT SUM(purchasePrice * quantity) as total FROM books');

    final totalEarned = await db.rawQuery(
        'SELECT SUM(salePrice * quantity) as total FROM books WHERE status = ? OR salePrice IS NOT NULL',
        ['sold']);

    return {
      'totalBooks': (totalCount.first['count'] as int?) ?? 0,
      'soldBooks': (soldCount.first['count'] as int?) ?? 0,
      'totalSpent': (totalSpent.first['total'] as num?)?.toDouble() ?? 0.0,
      'totalEarned': (totalEarned.first['total'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // 關閉資料庫
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
