import '../database/db_helper.dart';
import '../models/task_model.dart';

class TaskRepository {
  const TaskRepository({required this.dbHelper});

  final DbHelper dbHelper;

  Future<List<TaskModel>> fetchTasks() => dbHelper.fetchTasks();

  Future<TaskModel> insertTask(TaskModel task) async {
    final int id = await dbHelper.insertTask(task);
    return task.copyWith(id: id);
  }

  Future<void> updateTask(TaskModel task) async {
    await dbHelper.updateTask(task);
  }

  Future<void> deleteTask(int id) async {
    await dbHelper.deleteTask(id);
  }
}
