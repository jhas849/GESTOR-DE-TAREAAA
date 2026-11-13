import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gestor_tareas/models/task.dart';
import 'package:gestor_tareas/services/task_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CRUD se refleja en tiempo real en dos clientes', (tester) async {
    const projectId = 'demo-gestor-tareas';
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'fake-api-key',
        appId: '1:1234567890:android:integrationtest',
        messagingSenderId: '1234567890',
        projectId: projectId,
      ),
    );

    final auth = FirebaseAuth.instance;
    auth.useAuthEmulator(host, 9099);
    final userCredential = await auth.createUserWithEmailAndPassword(
      email: 'sync-${DateTime.now().microsecondsSinceEpoch}@example.test',
      password: 'test-password-123',
    );
    final userId = userCredential.user!.uid;

    final firestore = FirebaseFirestore.instance;
    firestore.useFirestoreEmulator(host, 8080);
    final service = TaskService(firestore: firestore);
    final clientA = StreamIterator(service.watchTasks(userId));
    final clientB = StreamIterator(service.watchTasks(userId));

    try {
      expect(await clientA.moveNext(), isTrue);
      expect(clientA.current, isEmpty);
      expect(await clientB.moveNext(), isTrue);
      expect(clientB.current, isEmpty);

      await service.createTask(
        Task(
          id: '',
          title: 'Probar sincronizacion',
          description: 'Verificar cambios remotos',
          category: 'Estudio',
          dueDate: DateTime.now().add(const Duration(days: 1)),
          isCompleted: false,
          userId: userId,
        ),
      );
      expect(await clientA.moveNext(), isTrue);
      expect(clientA.current.single.title, 'Probar sincronizacion');
      expect(await clientB.moveNext(), isTrue);
      final createdTask = clientB.current.single;
      expect(createdTask.title, 'Probar sincronizacion');

      await service.setCompleted(createdTask, true);
      expect(await clientA.moveNext(), isTrue);
      expect(clientA.current.single.isCompleted, isTrue);
      expect(await clientB.moveNext(), isTrue);
      expect(clientB.current.single.isCompleted, isTrue);

      await service.deleteTask(createdTask);
      expect(await clientA.moveNext(), isTrue);
      expect(clientA.current, isEmpty);
      expect(await clientB.moveNext(), isTrue);
      expect(clientB.current, isEmpty);
    } finally {
      await clientA.cancel();
      await clientB.cancel();
      await firestore
          .collection('users')
          .doc(userId)
          .delete()
          .catchError((_) {});
      await auth.signOut();
    }
  });
}
