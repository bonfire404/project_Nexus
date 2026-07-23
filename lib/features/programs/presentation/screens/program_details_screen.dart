import 'package:flutter/material.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';
import 'package:nexus/features/programs/data/repositories/program_repository_impl.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProgramDetailsScreen extends StatefulWidget {
  final String programId;

  const ProgramDetailsScreen({super.key, required this.programId});

  @override
  State<ProgramDetailsScreen> createState() => _ProgramDetailsScreenState();
}

class _ProgramDetailsScreenState extends State<ProgramDetailsScreen> {
  final ProgramRepositoryImpl _repository = ProgramRepositoryImpl();
  Program? _program;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProgram();
  }

  Future<void> _loadProgram() async {
    try {
      final program = await _repository.getProgramById(widget.programId);
      if (mounted) {
        setState(() {
          _program = program;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Program Details')),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    final displayProgram = _program ?? const Program(
      id: '',
      title: 'Loading Program...',
      description: 'This is a long placeholder description for the program detail screen to show the skeletonizer effect correctly.',
      imageUrl: '',
      duration: '0 Weeks',
      level: 'Beginner',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Program Details'),
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: SingleChildScrollView(
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
                      displayProgram.title,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _InfoChip(icon: Icons.timer_outlined, label: displayProgram.duration),
                        const SizedBox(width: 12),
                        _InfoChip(icon: Icons.bar_chart, label: displayProgram.level),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'About this program',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      displayProgram.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : () {
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
