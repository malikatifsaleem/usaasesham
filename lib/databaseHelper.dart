
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as pathh;

class DatabaseHelper {
  static DatabaseHelper? _databaseHelper;
  static Database? _database;

  String favoriteTable = 'favorite_table';
  String colId = 'id';
  String colContent = 'content';

  DatabaseHelper._createInstance();

  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper._createInstance();
    }
    return _databaseHelper!;
  }
  Future<bool> isFavoriteInDatabase(String content) async {
    Database db = await this.database;
    var result = await db.query(favoriteTable, where: '$colContent = ?', whereArgs: [content]);
    return result.isNotEmpty;
  }
  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database!;
  }

  Future<Database> initializeDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = pathh.join(databasesPath, 'favorites.db'); // Using join here

    var notesDatabase = await openDatabase(path, version: 1, onCreate: _createDb);
    return notesDatabase;
  }

  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE $favoriteTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colContent TEXT)');
  }

  Future<int> insertFavorite(String content) async {
    Database db = await this.database;
    var result = await db.insert(favoriteTable, {colContent: content});
    return result;
  }
  Future<int> removeFavorite(String content) async {
    Database db = await this.database;
    return await db.delete(
      favoriteTable,
      where: '$colContent = ?',
      whereArgs: [content],
    );
  }

  Future<List<Map<String, dynamic>>> getFavoriteMapList() async {
    Database db = await this.database;
    var result = await db.query(favoriteTable);
    return result;
  }
  Stream<bool> isFavoriteInDatabaseStream(String content) async* {
    while (true) {
      yield await isFavoriteInDatabase(content);
      await Future.delayed(Duration(seconds: 1)); // Adjust as needed
    }
  }
  Future<List<String>> getFavoriteList() async {
    var favoriteMapList = await getFavoriteMapList();
    List<String> favoriteList = [];
    for (int i = 0; i < favoriteMapList.length; i++) {
      favoriteList.add(favoriteMapList[i][colContent]);
    }
    return favoriteList;
  }
}

