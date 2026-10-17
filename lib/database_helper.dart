import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper{
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expense_manager.db');
    return _database!;
  }
    Future<Database> _initDB(String filePath) async{
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version:1,
      onCreate: _createDB,
    );
  }
  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE categories(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    type TEXT NOT NULL)''');


    await db.execute('''
  CREATE TABLE transactions(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  type TEXT NOT NULL,
  category_id INTEGER,
  FOREIGN KEY (category_id) REFERENCES categories(id)
  )
  ''');
    await db.insert('categories', {'name': 'Ăn uống', 'type': 'expense'});
    await db.insert('categories', {'name': 'Di chuyển', 'type': 'expense'});
    await db.insert('categories', {'name': 'Lương', 'type': 'expense'});
  }
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('transactions', row);
  }
  Future<List<Map<String, dynamic>>> getTransactions() async {
    final db = await instance.database;
    return await db.query('transactions', orderBy: 'id DESC');
    }
  Future<int> deleteTransaction(int id) async{
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<int> updateTransaction(Map<String,dynamic> row) async{
    final db = await instance.database;
    int id = row['id'];
    return await db.update('transactions', row, where: 'id =?', whereArgs: [id]);
  }
  Future close() async{
    final db = await instance.database;
    db.close();
  }
}