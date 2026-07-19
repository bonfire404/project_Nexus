import 'package:flutter/material.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';
import 'package:nexus/features/programs/presentation/screens/program_listing_screen.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';

class ProgramDetailsScreen extends StatelessWidget {
  final String programId;

  const ProgramDetailsScreen({super.key, required this.programId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Find the program from dummy data (in a real app, this would come from a provider/repository)
    final program = ProgramListingScreen.dummyPrograms.firstWhere(
      (p) => p.id == programId,
      orElse: () => ProgramListingScreen.dummyPrograms.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 250,
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              child: const Icon(Icons.code, size: 80),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _InfoChip(icon: Icons.timer_outlined, label: program.duration),
                      const SizedBox(width: 12),
                      _InfoChip(icon: Icons.bar_chart, label: program.level),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'About this program',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    program.description + ' This comprehensive program is designed to take you from fundamentals to advanced concepts. You will work on real-world projects and gain practical experience that is highly valued in the industry.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        showGlassSnackbar(
                          context,
                          'Successfully applied to program!',
                          type: SnackbarType.success,
                        );
                      },
                      child: const Text('Enroll Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
