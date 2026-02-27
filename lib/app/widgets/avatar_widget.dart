import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  final int index;
  final String color;
  final double size;
  final bool showBorder;

  const AvatarWidget({
    super.key,
    required this.index,
    this.color = '#6C5CE7',
    this.size = 48,
    this.showBorder = false,
  });

  static const _avatarIcons = [
    Icons.face,
    Icons.face_2,
    Icons.face_3,
    Icons.face_4,
    Icons.face_5,
    Icons.face_6,
    Icons.sentiment_satisfied_alt,
    Icons.sentiment_very_satisfied,
    Icons.mood,
    Icons.emoji_emotions,
    Icons.tag_faces,
    Icons.child_care,
  ];

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(int.parse(color.replaceFirst('#', '0xFF')));
    final iconIndex = index.clamp(0, _avatarIcons.length - 1);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: Colors.white, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        _avatarIcons[iconIndex],
        size: size * 0.55,
        color: Colors.white,
      ),
    );
  }
}
