// Các tiện ích chung cho ứng dụng (ImageProvider, GlobalNavigator).
import 'dart:convert';
import 'package:flutter/material.dart';

class Utils {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static ImageProvider getImageProvider(String? avatar) {
    if (avatar == null || avatar.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }

    if (avatar.startsWith('data:image')) {
      try {
        final base64Data = avatar.split(',').last;
        return MemoryImage(base64Decode(base64Data));
      } catch (e) {
        return const AssetImage('assets/images/default_avatar.png');
      }
    } else {
      return NetworkImage(avatar);
    }
  }
}
