import 'package:flutter/material.dart';
import 'package:nexus/features/deliverables/presentation/screens/tasks_screen.dart';
import 'package:nexus/features/meetings/presentation/screens/schedule_screen.dart';
import 'package:skeletonizer/skeletonizer.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  bool _isLoading = false; // Set to true when fetching real data from backend

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
          Expanded(
            child: Skeletonizer(
              enabled: _isLoading,
              child: const TabBarView(
                children: [
                  TasksScreen(),
                  ScheduleScreen(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
