// providers/database_helper.dart
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite_common/sqlite_api.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    if (_database != null) return _database!;

    // Initialize FFI for non-web platforms
    if (!kIsWeb) {
      sqfliteFfiInit();
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;
    DatabaseFactory databaseFactory;

    if (kIsWeb) {
      // Web platform (use in-memory DB for now)
      databaseFactory = databaseFactoryFfi; // fallback since no sqflite_web here
      path = inMemoryDatabasePath;
    } else {
      // Desktop/mobile platforms
      databaseFactory = databaseFactoryFfi;
      path = join(await databaseFactory.getDatabasesPath(), 'focus_timer.db');
    }

    print('Database path: $path');

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');

    // Create sessions table
    await db.execute('''
      CREATE TABLE sessions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionName TEXT NOT NULL,
        duration INTEGER NOT NULL,
        date TEXT NOT NULL
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');

    // Insert default categories
    await db.insert('categories', {'name': 'Work'});
    await db.insert('categories', {'name': 'Study'});
    await db.insert('categories', {'name': 'Reading'});
    await db.insert('categories', {'name': 'Coding'});

    print('Database tables created successfully');
  }

  // Session methods
  Future<int> insertSession(Map<String, dynamic> session) async {
    try {
      Database db = await database;
      print('Inserting session: $session');
      final id = await db.insert('sessions', session);
      print('Session inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting session: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      Database db = await database;
      final sessions = await db.query('sessions', orderBy: 'date DESC');
      print('Retrieved ${sessions.length} sessions from database');
      return sessions;
    } catch (e) {
      print('Error getting sessions: $e');
      rethrow;
    }
  }

  Future<int> deleteSession(int id) async {
    try {
      Database db = await database;
      print('Deleting session with ID: $id');
      final result = await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
      print('Deleted $result session(s)');
      return result;
    } catch (e) {
      print('Error deleting session: $e');
      rethrow;
    }
  }

  // Category methods
  Future<int> insertCategory(String name) async {
    try {
      Database db = await database;
      print('Inserting category: $name');
      final id = await db.insert('categories', {'name': name});
      print('Category inserted with ID: $id');
      return id;
    } catch (e) {
      print('Error inserting category: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      Database db = await database;
      final categories = await db.query('categories', orderBy: 'name');
      print('Retrieved ${categories.length} categories from database');
      return categories;
    } catch (e) {
      print('Error getting categories: $e');
      rethrow;
    }
  }

  Future<int> deleteCategory(String name) async {
    try {
      Database db = await database;
      print('Deleting category: $name');
      final result = await db.delete('categories', where: 'name = ?', whereArgs: [name]);
      print('Deleted $result category(ies)');
      return result;
    } catch (e) {
      print('Error deleting category: $e');
      rethrow;
    }
  }

  // Statistics methods
  Future<List<Map<String, dynamic>>> getSessionsByDateRange(DateTime start, DateTime end) async {
    try {
      Database db = await database;
      final sessions = await db.query(
        'sessions',
        where: 'date BETWEEN ? AND ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
      );
      print('Retrieved ${sessions.length} sessions for date range: $start to $end');
      return sessions;
    } catch (e) {
      print('Error getting sessions by date range: $e');
      rethrow;
    }
  }

  // Debug method to print all data
  Future<void> debugPrintAllData() async {
    try {
      Database db = await database;

      // Print all sessions
      final sessions = await db.query('sessions');
      print('=== ALL SESSIONS ===');
      for (var session in sessions) {
        print('Session: $session');
      }

      // Print all categories
      final categories = await db.query('categories');
      print('=== ALL CATEGORIES ===');
      for (var category in categories) {
        print('Category: $category');
      }
    } catch (e) {
      print('Error debugging data: $e');
    }
  }

  Future<void> close() async {
    try {
      Database db = await database;
      await db.close();
      print('Database closed');
    } catch (e) {
      print('Error closing database: $e');
    }
  }
}
