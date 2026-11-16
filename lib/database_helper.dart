
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,

      // Bật khóa ngoại
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      onCreate: _createDB,

      // Cập nhật database cũ, không xóa dữ liệu
      onUpgrade: _upgradeDB,
    );
  }

  // Tạo database mới
  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        note TEXT,
        FOREIGN KEY (category_id)
          REFERENCES categories(id)
      )
    ''');

    // Danh mục chi tiêu
    await db.insert('categories', {
      'name': 'Ăn uống',
      'type': 'expense'
    });

    await db.insert('categories', {
      'name': 'Đi lại',
      'type': 'expense'
    });

    // Danh mục thu nhập
    await db.insert('categories', {
      'name': 'Lương',
      'type': 'income'
    });
  }

  // Nâng cấp database phiên bản 1 lên 2
  Future<void> _upgradeDB(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      // Thêm cột ghi chú
      await db.execute(
          'ALTER TABLE transactions ADD COLUMN note TEXT'
      );

      // Sửa tên danh mục
      await db.update(
        'categories',
        {'name': 'Đi lại'},
        where: 'name = ?',
        whereArgs: ['Di chuyển'],
      );

      // Sửa loại danh mục Lương
      await db.update(
        'categories',
        {'type': 'income'},
        where: 'name = ?',
        whereArgs: ['Lương'],
      );
    }
  }

  // Thêm giao dịch
  Future<int> insertTransaction(
      Map<String, dynamic> row
      ) async {
    final db = await database;
    return await db.insert('transactions', row);
  }

  // Lấy danh sách giao dịch
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await database;

    return await db.query(
      'transactions',
      orderBy: 'id DESC',
    );
  }

  // Lấy danh sách danh mục
  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;

    return await db.query(
      'categories',
      orderBy: 'id ASC',
    );
  }

  // Xóa giao dịch
  Future<int> deleteTransaction(int id) async {
    final db = await database;

    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Cập nhật giao dịch
  Future<int> updateTransaction(
      Map<String, dynamic> row
      ) async {
    final db = await database;
    final id = row['id'] as int;

    return await db.update(
      'transactions',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Đóng database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

// Lấy ID danh mục, nếu chưa có thì tạo mới
  Future<int> getOrCreateCategoryId({
    required String name,
    required String type,
  }) async {
    final db = await database;

    final result = await db.query(
      'categories',
      columns: ['id'],
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }

    return await db.insert('categories', {
      'name': name,
      'type': type,
    });
  }

}

