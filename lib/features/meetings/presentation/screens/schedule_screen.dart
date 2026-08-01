import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nexus/core/utils/snackbar_utils.dart';

/// Intern's meeting schedule — interactive agenda with live Firestore sync and join actions.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final defaultMeetings = [
      {
        'title': 'Daily Stand-up',
        'time': '9:00 AM',
        'date': 'Today',
        'type': 'Team',
        'link': 'https://meet.google.com/nexus-standup',
        'description': 'Quick sync to share progress and blockers.',
      },
      {
        'title': 'Mentor Check-in',
        'time': '2:00 PM',
        'date': 'Today',
        'type': '1-on-1',
        'link': 'https://meet.google.com/nexus-mentor',
        'description': 'Weekly check-in with your assigned mentor.',
      },
      {
        'title': 'Sprint Review',
        'time': '10:00 AM',
        'date': 'Jul 19',
        'type': 'Team',
        'link': '',
        'description': 'Review completed work and demo features from this sprint.',
      },
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meetings')
          .snapshots(),
      builder: (context, snapshot) {
        List<Map<String, dynamic>> combinedMeetings = [...defaultMeetings];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final liveMeetings = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'title': data['title'] as String? ?? 'Scheduled Session',
              'time': data['time'] as String? ?? '6:00 PM',
              'date': data['date'] as String? ?? 'Upcoming',
              'type': data['type'] as String? ?? 'Team',
              'link': data['link'] as String? ?? '',
              'description': data['description'] as String? ?? 'Scheduled live session.',
            };
          }).toList();

          combinedMeetings = [...liveMeetings, ...defaultMeetings];
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Schedule',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: 'Kameron',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Live Data Sync',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: combinedMeetings.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final meeting = combinedMeetings[index];
                    final linkStr = (meeting['link'] as String? ?? '').trim();
                    final hasLink = linkStr.isNotEmpty;

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
                            SizedBox(
                              width: 62,
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
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (hasLink)
                              ElevatedButton(
                                onPressed: () {
                                  showGlassSnackbar(
                                    context,
                                    'Opening meeting link...',
                                    type: SnackbarType.info,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text('Join'),
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
      },
    );
  }

  void _showMeetingDetail(
    BuildContext context,
    Map<String, dynamic> meeting,
    ThemeData theme,
  ) {
    final linkStr = (meeting['link'] as String? ?? '').trim();
    final hasLink = linkStr.isNotEmpty;

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
                    showGlassSnackbar(context, 'Reminder set for "${meeting['title']}"', type: SnackbarType.info);
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
