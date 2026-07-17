import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';

/// Intern's meeting schedule — interactive agenda with join and detail actions.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final meetings = [
      {
        'title': 'Daily Stand-up',
        'time': '9:00 AM',
        'date': 'Today',
        'type': 'Team',
        'link': true,
        'description': 'Quick sync to share progress and blockers.',
      },
      {
        'title': 'Mentor Check-in',
        'time': '2:00 PM',
        'date': 'Today',
        'type': '1-on-1',
        'link': true,
        'description': 'Weekly check-in with your assigned mentor.',
      },
      {
        'title': 'Sprint Review',
        'time': '10:00 AM',
        'date': 'Jul 19',
        'type': 'Team',
        'link': false,
        'description': 'Review completed work and demo features from this sprint.',
      },
      {
        'title': 'Workshop: API Design',
        'time': '3:00 PM',
        'date': 'Jul 21',
        'type': 'Learning',
        'link': false,
        'description': 'Learn best practices for designing RESTful APIs.',
      },
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Schedule',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Kameron',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: meetings.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final meeting = meetings[index];
                final hasLink = meeting['link'] as bool;

                return GestureDetector(
                  onTap: () => _showMeetingDetail(context, meeting, theme),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Time column
                        SizedBox(
                          width: 56,
                          child: Column(
                            children: [
                              Text(
                                meeting['date'] as String,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                meeting['time'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meeting['title'] as String,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  meeting['type'] as String,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasLink)
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () {
                                showGlassSnackbar(context, 
                                      'Joining "${meeting['title']}"...',
                                    );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Join'),
                            ),
                          )
                        else
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
    );
  }

  void _showMeetingDetail(
    BuildContext context,
    Map<String, dynamic> meeting,
    ThemeData theme,
  ) {
    final hasLink = meeting['link'] as bool;

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
              meeting['title'] as String,
              style: theme.textTheme.titleLarge?.copyWith(
                fontFamily: 'Kameron',
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  '${meeting['date']} at ${meeting['time']}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
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
                    meeting['type'] as String,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              meeting['description'] as String,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (hasLink)
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showGlassSnackbar(context, 'Joining "${meeting['title']}"...', type: SnackbarType.success);
                  },
                  child: const Text('Join Meeting'),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reminder set'),
                        duration: Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('Set Reminder'),
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
