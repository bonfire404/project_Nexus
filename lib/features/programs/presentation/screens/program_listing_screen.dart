import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nexus/core/enums/user_role.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/features/programs/domain/entities/program.dart';
import 'package:nexus/features/programs/data/repositories/program_firestore_repository.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProgramListingScreen extends StatefulWidget {
  final AuthController? authController;

  const ProgramListingScreen({super.key, this.authController});

  @override
  State<ProgramListingScreen> createState() => _ProgramListingScreenState();
}

class _ProgramListingScreenState extends State<ProgramListingScreen> {
  final ProgramFirestoreRepository _repository = ProgramFirestoreRepository();
  StreamSubscription<List<Program>>? _programsSubscription;
  List<Program> _programs = [];
  bool _isLoading = true;

  bool get _isAdmin => widget.authController?.selectedRole == UserRole.administrator;

  @override
  void initState() {
    super.initState();
    _subscribeToPrograms();
  }

  void _subscribeToPrograms() {
    _programsSubscription = _repository.streamPrograms().listen(
      (programs) {
        if (mounted) {
          setState(() {
            _programs = programs;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _programsSubscription?.cancel();
    super.dispose();
  }

  void _showCreateProgramSheet() {
    final theme = Theme.of(context);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String duration = '12 Weeks';
    String level = 'Intermediate';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
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
                    'Create New Program',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: 'Kameron',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Program Title',
                      hintText: 'e.g. Full-Stack Web Engineering',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Program Description',
                      hintText: 'Describe program goals and deliverables...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: duration,
                          decoration: const InputDecoration(labelText: 'Duration'),
                          items: ['4 Weeks', '8 Weeks', '12 Weeks', '16 Weeks']
                              .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => duration = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: level,
                          decoration: const InputDecoration(labelText: 'Level'),
                          items: ['Beginner', 'Intermediate', 'Advanced']
                              .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setSheetState(() => level = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final desc = descController.text.trim();
                        if (title.isEmpty) return;

                        Navigator.pop(ctx);
                        try {
                          await _repository.addProgram(Program(
                            id: '',
                            title: title,
                            description: desc.isNotEmpty ? desc : 'Comprehensive career program.',
                            imageUrl: '',
                            duration: duration,
                            level: level,
                          ));
                          if (mounted) {
                            showGlassSnackbar(
                              context,
                              'Program created successfully!',
                              type: SnackbarType.success,
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            showGlassSnackbar(
                              context,
                              'Error creating program: $e',
                              type: SnackbarType.error,
                            );
                          }
                        }
                      },
                      child: const Text('Create Program'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Programs'),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'Create Program',
                onPressed: _showCreateProgramSheet,
              ),
            ),
        ],
      ),
      body: Skeletonizer(
        enabled: _isLoading,
        child: _programs.isEmpty && !_isLoading
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_open,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No career development programs available.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
                itemCount: _programs.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final program = _programs[index];
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
      ),
    );
  }
}
