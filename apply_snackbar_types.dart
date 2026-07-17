import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;
    
    // discover_screen.dart
    content = content.replaceAll(
      "showGlassSnackbar(context, saved ? 'Bookmarked \"\$name\"' : 'Removed bookmark');",
      "showGlassSnackbar(context, saved ? 'Bookmarked \"\$name\"' : 'Removed bookmark', type: saved ? SnackbarType.success : SnackbarType.warning);"
    );
    content = content.replaceAll(
      "showGlassSnackbar(context, 'Application submitted for \"\${program['title']}\"');",
      "showGlassSnackbar(context, 'Application submitted for \"\${program['title']}\"', type: SnackbarType.success);"
    );
    
    // applications_screen.dart
    content = content.replaceAll(
      "showGlassSnackbar(context, 'Withdrew application for \"\${app['program']}\"');",
      "showGlassSnackbar(context, 'Withdrew application for \"\${app['program']}\"', type: SnackbarType.warning);"
    );
    
    // schedule_screen.dart
    content = content.replaceAll(
      "showGlassSnackbar(context, 'Joining \"\${meeting['title']}\"...');",
      "showGlassSnackbar(context, 'Joining \"\${meeting['title']}\"...', type: SnackbarType.success);"
    );
    
    // tasks_screen.dart
    content = content.replaceAll(
      "showGlassSnackbar(context, done ? '\"\$name\" marked complete' : '\"\$name\" marked incomplete');",
      "showGlassSnackbar(context, done ? '\"\$name\" marked complete' : '\"\$name\" marked incomplete', type: done ? SnackbarType.success : SnackbarType.warning);"
    );
    content = content.replaceAll(
      "showGlassSnackbar(context, '\"\$name\" submitted successfully');",
      "showGlassSnackbar(context, '\"\$name\" submitted successfully', type: SnackbarType.success);"
    );
    
    // users_screen.dart
    content = content.replaceAll(
      "showGlassSnackbar(context, 'Message sent to \${user['name']}');",
      "showGlassSnackbar(context, 'Message sent to \${user['name']}', type: SnackbarType.success);"
    );
    
    // programs_management_screen.dart
    content = content.replaceAll(
      "showGlassSnackbar(context, '\"\$name\" created as draft');",
      "showGlassSnackbar(context, '\"\$name\" created as draft', type: SnackbarType.success);"
    );
    content = content.replaceAll(
      "showGlassSnackbar(context, 'Editing \"\${program['title']}\"');",
      "showGlassSnackbar(context, 'Editing \"\${program['title']}\"', type: SnackbarType.warning);"
    );
    
    // fix the context bug I just made in settings_screen.dart
    content = content.replaceAll("_showSnack(context, 'Message sent'", "_showSnack('Message sent'");
    
    if (content != original) {
      file.writeAsStringSync(content);
      print("Updated ${file.path}");
    }
  }
}
