import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:nexus/features/learning/data/repositories/learning_firestore_repository.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Intern's learning center — interactive categories and resources.
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen> {
  final LearningFirestoreRepository _repository = LearningFirestoreRepository();
  String? _selectedCategory;
  bool _isLoading = true;
  List<Map<String, String>> _resources = [];

  static final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Getting Started',
      'icon': HugeIcons.strokeRoundedBook01,
      'count': '3 guides',
    },
    {
      'title': 'Video Tutorials',
      'icon': HugeIcons.strokeRoundedVideo01,
      'count': '8 videos',
    },
    {
      'title': 'Templates & Documents',
      'icon': HugeIcons.strokeRoundedFile01,
      'count': '5 files',
    },
    {
      'title': 'FAQs',
      'icon': HugeIcons.strokeRoundedHelpCircle,
      'count': '12 questions',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadResources();
  }

  Future<void> _loadResources() async {
    try {
      final firestoreResources = await _repository.getResources();
      if (mounted) {
        setState(() {
          _resources = firestoreResources.map((r) => {
            'title': r['title'] as String? ?? 'Resource',
            'type': r['type'] as String? ?? 'PDF',
            'category': r['category'] as String? ?? 'Getting Started',
          }).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _resources = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, String>> get _filteredResources {
    if (_selectedCategory == null) return _resources;
    return _resources.where((r) => r['category'] == _selectedCategory).toList();
  }

  void _openResource(Map<String, String> resource) {
    showGlassSnackbar(context, 'Opening "${resource['title']}"');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resources = _filteredResources;

    return Skeletonizer(
      enabled: _isLoading,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory ?? 'Learning Center',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Kameron',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedCategory != null)
                  TextButton(
                    onPressed: () => setState(() => _selectedCategory = null),
                    child: const Text('Show All'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
  
            // Category grid
            if (_selectedCategory == null) ...[
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: _categories.map((cat) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['title'] as String),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          HugeIcon(
                            icon: cat['icon'] as List<List<dynamic>>,
                            size: 22,
                            color: theme.colorScheme.primary,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['title'] as String,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                cat['count'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),
            ],
  
            // Resources list
            Text(
              _selectedCategory != null ? 'Resources' : 'Recent Resources',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: resources.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final res = resources[index];
                  return GestureDetector(
                    onTap: () => _openResource(res),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedFile01,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              res['title']!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              res['type']!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
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
