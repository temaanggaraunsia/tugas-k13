import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

class ApiService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'app_database.db'),
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT
          )
        ''');
        db.execute('''
          CREATE TABLE reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT,
            title TEXT,
            rating INTEGER,
            comment TEXT,
            photo TEXT,
            FOREIGN KEY (username) REFERENCES users (username)
          )
        ''');
      },
      version: 1,
    );
  }

  Future<bool> registerUser(String username, String password) async {
    try {
      final db = await database;
      await db.insert(
        'users',
        {'username': username, 'password': password},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      return true;
    } catch (e) {
      print('Error in registerUser: $e');
      return false;
    }
  }

  Future<bool> checkUsernameExists(String username) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error in checkUsernameExists: $e');
      return false;
    }
  }

  Future<bool> loginUser(String username, String password) async {
    try {
      final db = await database;
      final result = await db.query(
        'users',
        where: 'username = ? AND password = ?',
        whereArgs: [username, password],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error in loginUser: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReviews(String username) async {
    try {
      final db = await database;
      return await db.query(
        'reviews',
        where: 'username = ?',
        whereArgs: [username],
      );
    } catch (e) {
      print('Error in getReviews: $e');
      return [];
    }
  }

  Future<bool> addReview(String username, String title, int rating,
      String comment, String? photo) async {
    try {
      // Validasi data
      if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty) {
        print('Invalid data for addReview');
        return false;
      }

      if (photo != null && !File(photo).existsSync()) {
        print('Photo file not found: $photo');
        return false;
      }

      final db = await database;
      await db.insert(
        'reviews',
        {
          'username': username,
          'title': title,
          'rating': rating,
          'comment': comment,
          'photo': photo,
        },
      );
      return true;
    } catch (e) {
      print('Error in addReview: $e');
      return false;
    }
  }

  Future<bool> updateReview(
      int id, String title, int rating, String comment, String? photo) async {
    try {
      // Validasi data
      if (title.isEmpty || rating < 1 || rating > 10 || comment.isEmpty) {
        print('Invalid data for updateReview');
        return false;
      }

      if (photo != null && !File(photo).existsSync()) {
        print('Photo file not found: $photo');
        return false;
      }

      final db = await database;
      final rowsUpdated = await db.update(
        'reviews',
        {
          'title': title,
          'rating': rating,
          'comment': comment,
          'photo': photo,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return rowsUpdated > 0;
    } catch (e) {
      print('Error in updateReview: $e');
      return false;
    }
  }

  Future<bool> deleteReview(int id) async {
    try {
      final db = await database;
      final rowsDeleted = await db.delete(
        'reviews',
        where: 'id = ?',
        whereArgs: [id],
      );
      return rowsDeleted > 0;
    } catch (e) {
      print('Error in deleteReview: $e');
      return false;
    }
  }
}
