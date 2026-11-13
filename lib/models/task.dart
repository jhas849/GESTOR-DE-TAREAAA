import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dueDate,
    required this.isCompleted,
    required this.userId,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dueDate;
  final bool isCompleted;
  final String userId;

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data()!;
    final dueDate = data['dueDate'];

    return Task(
      id: snapshot.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: data['category'] as String? ?? 'Personal',
      dueDate: dueDate is Timestamp ? dueDate.toDate() : DateTime.now(),
      isCompleted: data['isCompleted'] as bool? ?? false,
      userId: data['userId'] as String? ?? '',
    );
  }

  Map<String, Object> toFirestore() => {
        'title': title,
        'description': description,
        'category': category,
        'dueDate': Timestamp.fromDate(dueDate),
        'isCompleted': isCompleted,
        'userId': userId,
      };

  Task copyWith({bool? isCompleted}) => Task(
        id: id,
        title: title,
        description: description,
        category: category,
        dueDate: dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        userId: userId,
      );
}
