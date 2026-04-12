import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_constants.dart';
import '../models/task_model.dart';

class DbHelper {
  DbHelper._();

  static final DbHelper instance = DbHelper._();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String databasePath = await getDatabasesPath();
    final String filePath = path.join(databasePath, AppConstants.databaseName);

    return openDatabase(
      filePath,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${AppConstants.taskTableName} (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            isCompleted INTEGER NOT NULL,
            dueDate TEXT,
            reminderTime TEXT,
            createdAt TEXT NOT NULL,
            taskKind TEXT NOT NULL DEFAULT 'one_time',
            subtasksData TEXT NOT NULL DEFAULT '[]',
            progressLogData TEXT NOT NULL DEFAULT '[]'
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE ${AppConstants.taskTableName} ADD COLUMN taskKind TEXT NOT NULL DEFAULT 'one_time'",
          );
          await db.execute(
            "ALTER TABLE ${AppConstants.taskTableName} ADD COLUMN subtasksData TEXT NOT NULL DEFAULT '[]'",
          );
          await db.execute(
            "ALTER TABLE ${AppConstants.taskTableName} ADD COLUMN progressLogData TEXT NOT NULL DEFAULT '[]'",
          );
        }
      },
    );
  }

  Future<int> insertTask(TaskModel task) async {
    final Database db = await database;
    final Map<String, dynamic> values = task.toMap()..remove('id');
    return db.insert(AppConstants.taskTableName, values);
  }

  Future<int> updateTask(TaskModel task) async {
    final Database db = await database;
    return db.update(
      AppConstants.taskTableName,
      task.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: <Object?>[task.id],
    );
  }

  Future<int> deleteTask(int id) async {
    final Database db = await database;
    return db.delete(
      AppConstants.taskTableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  Future<List<TaskModel>> fetchTasks() async {
    final Database db = await database;
    final List<Map<String, dynamic>> rows = await db.query(
      AppConstants.taskTableName,
      orderBy: 'createdAt DESC',
    );

    return rows.map(TaskModel.fromMap).toList(growable: false);
  }
}
