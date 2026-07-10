import 'package:flutter/material.dart';
import 'package:nexus/app/theme.dart';
import 'package:nexus/app/router.dart';

class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus',
      debugShowCheckedModeBanner: false,
      theme: NexusTheme.light,
      darkTheme: NexusTheme.dark,
      themeMode: ThemeMode.system,
      onGenerateRoute: NexusRouter.onGenerateRoute,
      initialRoute: NexusRouter.initial,
    );
  }
}
