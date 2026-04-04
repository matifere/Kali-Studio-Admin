import 'dart:convert';
import 'package:flutter/material.dart';

class AvatarProvider {
  /// Returns a valid ImageProvider handling both standard URLs and raw base64 data URIs.
  static ImageProvider? fromUrl(String? avatarUrl) {
    if (avatarUrl == null || avatarUrl.isEmpty) return null;

    if (avatarUrl.startsWith('data:image')) {
      final commaIndex = avatarUrl.indexOf(',');
      if (commaIndex != -1) {
        final base64String = avatarUrl.substring(commaIndex + 1);
        return MemoryImage(base64Decode(base64String));
      } else {
        return MemoryImage(base64Decode(avatarUrl)); // Fallback
      }
    }
    
    return NetworkImage(avatarUrl);
  }
}
