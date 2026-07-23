import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';
import 'package:nexus/features/programs/data/repositories/program_repository_impl.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProgramListingScreen extends StatefulWidget {
  const ProgramListingScreen({super.key});

  @override
  State<ProgramListingScreen> createState() => _ProgramListingScreenState();
}

class _ProgramListingScreenState extends State<ProgramListingScreen> {
  final ProgramRepositoryImpl _repository = ProgramRepositoryImpl();
  List<Program> _programs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    try {
      final programs = await _repository.getPrograms();
      if (mounted) {
        setState(() {
          _programs = programs;
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

  // Fallback dummy data for Skeletonizer while loading
  static const List<Program> _skeletonPrograms = [
    Program(
      id: '0',
      title: 'Loading Program Title',
      description: 'This is a placeholder description for the loading state of the program listing.',
      imageUrl: '',
      duration: '0 Weeks',
      level: 'Beginner',
    ),
    Program(
      id: '0',
      title: 'Loading Program Title',
      description: 'This is a placeholder description for the loading state of the program listing.',
      imageUrl: '',
      duration: '0 Weeks',
      level: 'Beginner',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_errorMessage != null && !_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Available Programs')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_errorMessage'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _loadPrograms();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Programs'),
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _isLoading ? _skeletonPrograms.length : _programs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final program = _isLoading ? _skeletonPrograms[index] : _programs[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _isLoading ? null : () {
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
      ),
    );
  }
}
