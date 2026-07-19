import 'package:flutter/material.dart';
import 'package:nexus/features/deliverables/presentation/screens/tasks_screen.dart';
import 'package:nexus/features/meetings/presentation/screens/schedule_screen.dart';

class WorkspaceScreen extends StatelessWidget {
  const WorkspaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.surface,
            child: TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              indicatorWeight: 3,
              labelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontFamily: 'Kameron',
              ),
              unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                fontFamily: 'Kameron',
              ),
              tabs: const [
                Tab(text: 'Deliverables'),
                Tab(text: 'Schedule'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [
                TasksScreen(),
                ScheduleScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
