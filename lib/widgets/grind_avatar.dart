import 'dart:convert';

import 'package:flutter/material.dart';

class GrindAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final String name;

  const GrindAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.name = "?",
  });

  @override
  Widget build(BuildContext context) {
    final String url = imageUrl ?? "";

    return CircleAvatar(
      radius: radius,
      backgroundColor: url.isEmpty ? _getAvatarColor(name) : Colors.white10,
      backgroundImage: _getImageProvider(url),
      child: url.isEmpty
          ? Text(
              _getInitial(name),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            )
          : null,
    );
  }

  ImageProvider? _getImageProvider(String url) {
    if (url.isEmpty) return null;
    if (url.startsWith('http')) {
      return NetworkImage(url);
    } else {
      try {
        return MemoryImage(base64Decode(url));
      } catch (e) {
        return null;
      }
    }
  }

  String _getInitial(String name) {
    if (name.isEmpty || name == "?") return "?";
    return name[0].toUpperCase();
  }

  Color _getAvatarColor(String name) {
    final List<Color> palette = [
      const Color(0xFF8E2DE2),
      const Color(0xFF00D2FF),
      const Color(0xFFED4264),
      const Color(0xFFF37335),
      const Color(0xFF00B09B),
      const Color(0xFF4A00E0),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }
}
