import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';

/// Intern's weekly task/deliverable tracker — toggleable and submittable.
class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Map<String, dynamic>> _tasks = [
    {'title': 'Weekly Progress Report', 'due': 'Jul 18, 2026', 'done': true},
    {'title': 'UI Wireframe Submission', 'due': 'Jul 20, 2026', 'done': false},
    {'title': 'Code Review: Sprint 3', 'due': 'Jul 22, 2026', 'done': false},
    {'title': 'Team Retrospective Notes', 'due': 'Jul 24, 2026', 'done': false},
  ];

  int get _completedCount => _tasks.where((t) => t['done'] == true).length;

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['done'] = !(_tasks[index]['done'] as bool);
    });
    final name = _tasks[index]['title'];
    final done = _tasks[index]['done'] as bool;
    showGlassSnackbar(context, done ? '"$name" marked complete' : '"$name" marked incomplete', type: done ? SnackbarType.success : SnackbarType.warning);
  }

  void _submitTask(int index) {
    final name = _tasks[index]['title'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Submit: $name',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontFamily: 'Kameron',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  showGlassSnackbar(context, 'File attachment coming soon');
                },
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Attach File'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _tasks[index]['done'] = true;
                    });
                    showGlassSnackbar(context, '"$name" submitted successfully', type: SnackbarType.success);
                  },
                  child: const Text('Submit'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deliverables',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Kameron',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // Progress indicator
          Row(
            children: [
              Text(
                '$_completedCount of ${_tasks.length} completed',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _completedCount / _tasks.length,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.secondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              itemCount: _tasks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                final isDone = task['done'] as bool;

                return GestureDetector(
                  onTap: () => _toggleTask(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDone
                            ? theme.colorScheme.secondary.withValues(alpha: 0.3)
                            : theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isDone
                                ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                                : theme.colorScheme.outline.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isDone ? Icons.check : Icons.radio_button_unchecked,
                            size: 16,
                            color: isDone
                                ? theme.colorScheme.secondary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'] as String,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: isDone
                                      ? theme.colorScheme.onSurfaceVariant
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Due ${task['due']}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDone)
                          TextButton(
                            onPressed: () => _submitTask(index),
                            child: const Text('Submit'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
