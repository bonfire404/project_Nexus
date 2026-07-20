import 'package:package_info_plus/package_info_plus.dart';

class AppVersion {
  static String currentVersion = '1.0.0';
  static String buildNumber = '1';
  
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    currentVersion = info.version;
    buildNumber = info.buildNumber;
  }

}
