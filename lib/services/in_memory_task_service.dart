import 'dart:async';

import '../models/task.dart';
import 'task_service.dart';

class InMemoryTaskService implements TaskRepository {
  InMemoryTaskService()
      : _tasksByUser = {
          'demo-user': [
            Task(
              id: 'demo-task-1',
              title: 'Preparar entrega final',
              description: 'Revisar el informe y las pruebas del proyecto.',
              category: 'Estudio',
              dueDate: DateTime.now().add(const Duration(days: 1)),
              isCompleted: false,
              userId: 'demo-user',
            ),
            Task(
              id: 'demo-task-2',
              title: 'Organizar pendientes de la semana',
              description: 'Agrupar tareas por categoria y prioridad.',
              category: 'Personal',
              dueDate: DateTime.now().add(const Duration(days: 3)),
              isCompleted: true,
              userId: 'demo-user',
            ),
          ],
        };

  final Map<String, List<Task>> _tasksByUser;
  final Map<String, StreamController<List<Task>>> _controllers = {};
  int _nextId = 0;

  StreamController<List<Task>> _controllerFor(String userId) =>
      _controllers.putIfAbsent(
        userId,
        () => StreamController<List<Task>>.broadcast(),
      );

  void _publish(String userId) {
    _controllers[userId]?.add(List.unmodifiable(_tasksByUser[userId] ?? []));
  }

  @override
  Stream<List<Task>> watchTasks(String userId) =>
      Stream<List<Task>>.multi((sink) {
        final controller = _controllerFor(userId);
        sink.add(List.unmodifiable(_tasksByUser.putIfAbsent(userId, () => [])));
        final subscription = controller.stream.listen(
          sink.add,
          onError: (Object error, StackTrace stackTrace) =>
              sink.addError(error, stackTrace),
        );
        sink.onCancel = subscription.cancel;
      });

  @override
  Future<void> createTask(Task task) async {
    _nextId++;
    final created = Task(
      id: 'local-task-$_nextId',
      title: task.title,
      description: task.description,
      category: task.category,
      dueDate: task.dueDate,
      isCompleted: task.isCompleted,
      userId: task.userId,
    );
    _tasksByUser.putIfAbsent(task.userId, () => []).add(created);
    _publish(task.userId);
  }

  @override
  Future<void> updateTask(Task task) async {
    final tasks = _tasksByUser[task.userId] ?? [];
    final index = tasks.indexWhere((item) => item.id == task.id);
    if (index == -1) throw StateError('La tarea ya no existe.');
    tasks[index] = task;
    _publish(task.userId);
  }

  @override
  Future<void> setCompleted(Task task, bool isCompleted) =>
      updateTask(task.copyWith(isCompleted: isCompleted));

  @override
  Future<void> deleteTask(Task task) async {
    _tasksByUser[task.userId]?.removeWhere((item) => item.id == task.id);
    _publish(task.userId);
  }
}
