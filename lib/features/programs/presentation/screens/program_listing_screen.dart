import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';

class ProgramListingScreen extends StatelessWidget {
  const ProgramListingScreen({super.key});

  static const List<Program> dummyPrograms = [
    Program(
      id: '1',
      title: 'Mobile App Development',
      description: 'Learn to build cross-platform apps with Flutter.',
      imageUrl: 'https://placeholder.com/150',
      duration: '12 Weeks',
      level: 'Intermediate',
    ),
    Program(
      id: '2',
      title: 'Data Science Bootcamp',
      description: 'Master data analysis and machine learning.',
      imageUrl: 'https://placeholder.com/150',
      duration: '16 Weeks',
      level: 'Advanced',
    ),
    Program(
      id: '3',
      title: 'UI/UX Design Essentials',
      description: 'Design beautiful and user-friendly interfaces.',
      imageUrl: 'https://placeholder.com/150',
      duration: '8 Weeks',
      level: 'Beginner',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Programs'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dummyPrograms.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final program = dummyPrograms[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                context.push('/programs/${program.id}');
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: theme.colorScheme.primaryContainer,
                    child: const Icon(Icons.code, size: 48),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.title,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, size: 16),
                            const SizedBox(width: 4),
                            Text(program.duration),
                            const SizedBox(width: 16),
                            const Icon(Icons.bar_chart, size: 16),
                            const SizedBox(width: 4),
                            Text(program.level),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
