import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/auth/presentation/providers/auth_controller.dart';
import 'package:nexus/features/programs/data/repositories/application_firestore_repository.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Dedicated Applicant's view for tracking submitted program applications.
class ApplicationsScreen extends StatefulWidget {
  final AuthController? authController;

  const ApplicationsScreen({super.key, this.authController});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  final ApplicationFirestoreRepository _repository =
      ApplicationFirestoreRepository();
  String _filterStatus = 'All';
  bool _isLoading = true;
  List<Map<String, String>> _applications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final uid = widget.authController?.currentUser?.uid ?? 'guest_user';
      final userApps = await _repository.getUserApplications(uid);

      if (mounted) {
        setState(() {
          _applications = userApps
              .map(
                (a) => {
                  'id': a['id'] as String? ?? '',
                  'program': a['programName'] as String? ?? 'Program',
                  'date': 'Jul 2026',
                  'status': a['status'] as String? ?? 'Pending',
                  'org': a['organization'] as String? ?? 'Excelerate',
                },
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _applications = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, String>> get _filteredApps {
    if (_filterStatus == 'All') return _applications;
    return _applications.where((a) => a['status'] == _filterStatus).toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Accepted':
        return Icons.check_circle_outline;
      case 'Rejected':
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  void _showApplicationDetail(Map<String, String> app) {
    final theme = Theme.of(context);
    final color = _statusColor(app['status']!);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
              app['program']!,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              app['org']!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_statusIcon(app['status']!), color: color, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    app['status']!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Applied on ${app['date']}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (app['status'] == 'Pending')
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showGlassSnackbar(
                      context,
                      'Withdrew application for "${app['program']}"',
                      type: SnackbarType.warning,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Withdraw Application'),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Skeletonizer(
      enabled: _isLoading,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Applications',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track and manage your submitted program applications.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),

            // Status Filter Chips
            Wrap(
              spacing: 8,
              children: ['All', 'Pending', 'Accepted', 'Rejected'].map((label) {
                final isSelected = _filterStatus == label;
                return FilterChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _filterStatus = label),
                  selectedColor: theme.colorScheme.primary.withValues(
                    alpha: 0.1,
                  ),
                  checkmarkColor: theme.colorScheme.primary,
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.3)
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Applications List
            Expanded(
              child: _filteredApps.isEmpty
                  ? Center(
                      child: Text(
                        'No applications found.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filteredApps.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final app = _filteredApps[index];
                        final color = _statusColor(app['status']!);

                        return GestureDetector(
                          onTap: () => _showApplicationDetail(app),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _statusIcon(app['status']!),
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app['program']!,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Applied ${app['date']}',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    app['status']!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }
}
