import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';
import 'package:hugeicons/hugeicons.dart';

/// Applicant's program discovery screen — browse, search, and bookmark programs.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _programs = [
    {
      'title': 'Frontend Web Development',
      'org': 'TechCorp',
      'status': 'Open',
      'description': 'Learn modern frontend frameworks and build production-ready web applications.',
      'duration': '12 weeks',
      'bookmarked': false,
    },
    {
      'title': 'Data Science Internship',
      'org': 'DataSolve',
      'status': 'Closing Soon',
      'description': 'Hands-on experience with data analysis, machine learning, and visualization.',
      'duration': '8 weeks',
      'bookmarked': false,
    },
    {
      'title': 'Mobile App Development',
      'org': 'Nexus',
      'status': 'Open',
      'description': 'Build cross-platform mobile applications using Flutter and Dart.',
      'duration': '10 weeks',
      'bookmarked': true,
    },
    {
      'title': 'UX Design Program',
      'org': 'CreativeHub',
      'status': 'Open',
      'description': 'Master user research, wireframing, prototyping, and design systems.',
      'duration': '6 weeks',
      'bookmarked': false,
    },
  ];

  List<Map<String, dynamic>> get _filtered {
    if (_searchQuery.isEmpty) return _programs;
    final q = _searchQuery.toLowerCase();
    return _programs.where((p) {
      return (p['title'] as String).toLowerCase().contains(q) ||
          (p['org'] as String).toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleBookmark(int index) {
    setState(() {
      _programs[index]['bookmarked'] = !(_programs[index]['bookmarked'] as bool);
    });
    final name = _programs[index]['title'];
    final saved = _programs[index]['bookmarked'] as bool;
    showGlassSnackbar(context, saved ? 'Bookmarked "$name"' : 'Removed bookmark', type: saved ? SnackbarType.success : SnackbarType.warning);
  }

  void _showProgramDetail(Map<String, dynamic> program) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
              program['title'] as String,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              program['org'] as String,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _DetailChip(label: program['status'] as String, theme: theme),
                const SizedBox(width: 8),
                _DetailChip(label: program['duration'] as String, theme: theme),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              program['description'] as String,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  showGlassSnackbar(context, 'Application submitted for "${program['title']}"', type: SnackbarType.success);
                },
                child: const Text('Apply Now'),
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
    final results = _filtered;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Discover Programs',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Kameron',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search programs...',
              prefixIcon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${results.length} program${results.length == 1 ? '' : 's'} found',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: results.isEmpty
                ? Center(
                    child: Text(
                      'No programs match your search.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: results.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final program = results[index];
                      final realIndex = _programs.indexOf(program);
                      final isBookmarked = program['bookmarked'] as bool;

                      return GestureDetector(
                        onTap: () => _showProgramDetail(program),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      program['title'] as String,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: program['status'] == 'Open'
                                          ? Colors.green.withValues(alpha: 0.1)
                                          : Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      program['status'] as String,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: program['status'] == 'Open'
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${program['org']}  •  ${program['duration']}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isBookmarked
                                          ? Icons.bookmark
                                          : Icons.bookmark_border,
                                      size: 20,
                                      color: isBookmarked
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => _toggleBookmark(realIndex),
                                    tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark',
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showProgramDetail(program),
                                    icon: HugeIcon(
                                      icon: HugeIcons.strokeRoundedArrowRight01,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    label: const Text('View Details'),
                                  ),
                                ],
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

class _DetailChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _DetailChip({required this.label, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
