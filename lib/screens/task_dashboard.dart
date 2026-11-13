import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../services/task_service.dart';

class TaskDashboard extends StatelessWidget {
  const TaskDashboard({
    required this.userId,
    required this.themeMode,
    required this.onToggleTheme,
    required this.taskRepository,
    this.onSignOut,
    this.demoMode = false,
    super.key,
  });

  final String userId;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final TaskRepository taskRepository;
  final VoidCallback? onSignOut;
  final bool demoMode;

  Future<void> _openForm(BuildContext context, {Task? task}) async {
    final result = await showDialog<Task>(
      context: context,
      builder: (_) => TaskFormDialog(userId: userId, task: task),
    );
    if (result == null || !context.mounted) return;

    try {
      if (task == null) {
        await taskRepository.createTask(result);
      } else {
        await taskRepository.updateTask(result);
      }
    } catch (error) {
      _showError(context, error);
    }
  }

  Future<void> _confirmDelete(BuildContext context, Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text('¿Quieres eliminar "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) return;

    try {
      await taskRepository.deleteTask(task);
    } catch (error) {
      _showError(context, error);
    }
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No se pudo completar la operacion: $error')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Mis tareas'),
            if (demoMode)
              Text(
                'DEMO LOCAL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: themeMode == ThemeMode.dark
                ? 'Cambiar a tema claro'
                : 'Cambiar a tema oscuro',
            onPressed: onToggleTheme,
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
          if (onSignOut != null)
            IconButton(
              tooltip: 'Cerrar sesion',
              onPressed: onSignOut,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Column(
        children: [
          if (demoMode)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 19,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Demo local: los cambios no se sincronizan con Firebase.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: taskRepository.watchTasks(userId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('No se pudieron cargar las tareas.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = snapshot.data ?? const <Task>[];
                final completedCount =
                    tasks.where((task) => task.isCompleted).length;
                final pendingCount = tasks.length - completedCount;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                  itemCount: tasks.isEmpty ? 2 : tasks.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return TaskOverview(
                        totalCount: tasks.length,
                        pendingCount: pendingCount,
                        completedCount: completedCount,
                      );
                    }
                    if (tasks.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 28),
                        child: Center(
                          child:
                              Text('Aun no hay tareas. Crea la primera con +.'),
                        ),
                      );
                    }

                    final task = tasks[index - 1];
                    return TaskCard(
                      task: task,
                      onChanged: (value) async {
                        try {
                          await taskRepository.setCompleted(
                              task, value ?? false);
                        } catch (error) {
                          if (context.mounted) _showError(context, error);
                        }
                      },
                      onEdit: () => _openForm(context, task: task),
                      onDelete: () => _confirmDelete(context, task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        tooltip: 'Crear tarea',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskOverview extends StatelessWidget {
  const TaskOverview({
    required this.totalCount,
    required this.pendingCount,
    required this.completedCount,
    super.key,
  });

  final int totalCount;
  final int pendingCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UN PASO A LA VEZ',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Organiza tu día',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$pendingCount pendientes · $completedCount completadas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.primary,
                  size: 27,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: colors.primary.withAlpha(28),
              color: colors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Task task;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme;
    final categoryColor = _categoryColor(task.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: categoryColor.withAlpha(58)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: ListTile(
          leading: Checkbox(value: task.isCompleted, onChanged: onChanged),
          title: Text(
            task.title,
            style: task.isCompleted
                ? textStyle.titleMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                  )
                : textStyle.titleMedium,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (task.description.isNotEmpty) Text(task.description),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: categoryColor),
                  const SizedBox(width: 6),
                  Text(task.category),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(DateFormat.yMMMd().format(task.dueDate)),
                  ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            tooltip: 'Opciones de tarea',
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Eliminar')),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) => switch (category) {
      'Personal' => const Color(0xFFB63D68),
      'Estudio' => const Color(0xFF4A70B5),
      'Trabajo' => const Color(0xFFB47A25),
      _ => const Color(0xFF287C72),
      };
}

class TaskFormDialog extends StatefulWidget {
  const TaskFormDialog({required this.userId, this.task, super.key});

  final String userId;
  final Task? task;

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  static const _categories = ['Personal', 'Estudio', 'Trabajo', 'Otro'];
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _dueDate;
  late String _category;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
    _dueDate =
        widget.task?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _category = widget.task?.category ?? _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (selected != null) setState(() => _dueDate = selected);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.task;
    Navigator.pop(
      context,
      Task(
        id: existing?.id ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        dueDate: _dueDate,
        isCompleted: existing?.isCompleted ?? false,
        userId: widget.userId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.task == null ? 'Nueva tarea' : 'Editar tarea'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                autofocus: true,
                maxLength: 80,
                decoration: const InputDecoration(labelText: 'Titulo'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Escribe un titulo.'
                    : null,
              ),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripcion'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: _categories
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _selectDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(DateFormat.yMMMd().format(_dueDate)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _save, child: const Text('Guardar')),
      ],
    );
  }
}
