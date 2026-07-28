import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

/// Zero-cost profile photo manager supporting custom uploaded user photos via Base64 in Firestore.
class AvatarUtils {
  AvatarUtils._();

  /// Pick custom user photo from gallery/camera and convert to compressed Base64 string ($0 Storage cost).
  static Future<String?> pickCustomPhoto({ImageSource source = ImageSource.gallery}) async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(
        source: source,
        maxWidth: 200,
        maxHeight: 200,
        imageQuality: 60,
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    } catch (_) {
      return null;
    }
  }

  /// Build avatar widget displaying custom uploaded Base64 photo, asset logo, network photo, or default profile icon.
  static Widget buildAvatarWidget(String? photoData, {double radius = 24, String? fallbackLetter}) {
    if (photoData != null && photoData.startsWith('assets/')) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(photoData),
        backgroundColor: Colors.transparent,
      );
    }

    if (photoData != null && (photoData.startsWith('http://') || photoData.startsWith('https://'))) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(photoData),
      );
    }

    if (photoData != null && photoData.startsWith('data:image')) {
      try {
        final base64Data = photoData.split(',').last;
        final bytes = base64Decode(base64Data);
        return CircleAvatar(
          radius: radius,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {}
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedUser,
        color: const Color(0xFF3B82F6),
        size: radius * 1.1,
      ),
    );
  }
}
