import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas/models/task.dart';

void main() {
  final dueDate = DateTime(2026, 11, 13, 9, 30);
  final task = Task(
    id: 'task-1',
    title: 'Entregar informe',
    description: 'Revisar el documento final',
    category: 'Estudio',
    dueDate: dueDate,
    isCompleted: false,
    userId: 'user-1',
  );

  test('serializa los campos con tipos Firestore', () {
    final data = task.toFirestore();

    expect(data['title'], 'Entregar informe');
    expect(data['description'], 'Revisar el documento final');
    expect(data['category'], 'Estudio');
    expect(data['dueDate'], Timestamp.fromDate(dueDate));
    expect(data['isCompleted'], isFalse);
    expect(data['userId'], 'user-1');
  });

  test('copyWith cambia el estado sin alterar otros datos', () {
    final completed = task.copyWith(isCompleted: true);

    expect(completed.isCompleted, isTrue);
    expect(completed.title, task.title);
    expect(completed.userId, task.userId);
    expect(completed.dueDate, task.dueDate);
  });
}
