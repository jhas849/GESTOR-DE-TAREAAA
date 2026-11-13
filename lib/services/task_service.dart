import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

abstract interface class TaskRepository {
  Stream<List<Task>> watchTasks(String userId);
  Future<void> createTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> setCompleted(Task task, bool isCompleted);
  Future<void> deleteTask(Task task);
}

class TaskService implements TaskRepository {
  TaskService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _tasksFor(String userId) =>
      _firestore.collection('users').doc(userId).collection('tasks');

  @override
  Stream<List<Task>> watchTasks(String userId) => _tasksFor(userId)
      .orderBy('dueDate')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Task.fromFirestore).toList());

  @override
  Future<void> createTask(Task task) async {
    final document = _tasksFor(task.userId).doc();
    await document.set(task.toFirestore());
  }

  @override
  Future<void> updateTask(Task task) =>
      _tasksFor(task.userId).doc(task.id).update(task.toFirestore());

  @override
  Future<void> setCompleted(Task task, bool isCompleted) =>
      _tasksFor(task.userId).doc(task.id).update({'isCompleted': isCompleted});

  @override
  Future<void> deleteTask(Task task) =>
      _tasksFor(task.userId).doc(task.id).delete();
}
