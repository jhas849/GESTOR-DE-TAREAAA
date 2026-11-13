import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas/models/task.dart';
import 'package:gestor_tareas/services/in_memory_task_service.dart';

void main() {
  test('emite tareas de demo y actualiza el stream con operaciones CRUD',
      () async {
    final service = InMemoryTaskService();
    final tasks = StreamIterator(service.watchTasks('demo-user'));

    expect(await tasks.moveNext(), isTrue);
    expect(tasks.current, hasLength(2));

    await service.createTask(
      Task(
        id: '',
        title: 'Tarea de prueba',
        description: '',
        category: 'Trabajo',
        dueDate: DateTime.now().add(const Duration(days: 1)),
        isCompleted: false,
        userId: 'demo-user',
      ),
    );
    expect(await tasks.moveNext(), isTrue);
    final created = tasks.current.singleWhere(
      (task) => task.title == 'Tarea de prueba',
    );

    await service.setCompleted(created, true);
    expect(await tasks.moveNext(), isTrue);
    expect(
      tasks.current.singleWhere((task) => task.id == created.id).isCompleted,
      isTrue,
    );

    await service.deleteTask(created);
    expect(await tasks.moveNext(), isTrue);
    expect(tasks.current, hasLength(2));
    await tasks.cancel();
  });
}
