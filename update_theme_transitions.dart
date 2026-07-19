import 'dart:io';

void main() {
  final file = File('lib/app/theme.dart');
  String content = file.readAsStringSync();
  
  if (content.contains('FadeSlidePageTransitionsBuilder')) {
    print('Already applied.');
    return;
  }
  
  // Add the class at the end
  content += '''

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }
}
''';

  // Insert into light theme
  content = content.replaceAll(
    'useMaterial3: true,',
    'useMaterial3: true,\n      pageTransitionsTheme: const PageTransitionsTheme(\n        builders: {\n          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),\n          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),\n          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),\n          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),\n        },\n      ),',
  );

  file.writeAsStringSync(content);
  print('Transitions added to theme.dart');
}
