import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  
  // ScaffoldMessenger.of(context).showSnackBar( \n SnackBar( \n content: Text('xxx'), \n behavior: ... \n ), \n );
  final regex1 = RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content:\s*Text\((.*?)\),.*?\),\s*\);", dotAll: true);
  
  // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('xxx')));
  final regex2 = RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(const\s*SnackBar\(content:\s*Text\((.*?)\)\)\);");
  
  // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  final regex3 = RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(SnackBar\(content:\s*Text\((.*?)\)\)\);");

  // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('xxx'), behavior: SnackBarBehavior.floating));
  final regex4 = RegExp(r"ScaffoldMessenger\.of\(context\)\.showSnackBar\(const\s*SnackBar\(content:\s*Text\((.*?)\),\s*behavior:.*?\)\);");
  
  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;
    
    content = content.replaceAllMapped(regex1, (m) => "showGlassSnackbar(context, ${m.group(1)});");
    content = content.replaceAllMapped(regex2, (m) => "showGlassSnackbar(context, ${m.group(1)});");
    content = content.replaceAllMapped(regex3, (m) => "showGlassSnackbar(context, ${m.group(1)});");
    content = content.replaceAllMapped(regex4, (m) => "showGlassSnackbar(context, ${m.group(1)});");
    
    if (content != original) {
      if (!content.contains('snackbar_utils.dart')) {
        content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:nexus/core/utils/snackbar_utils.dart';");
      }
      file.writeAsStringSync(content);
      print("Updated ${file.path}");
    }
  }
}
