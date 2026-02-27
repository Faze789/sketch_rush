import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../game_controller.dart';

class WordHintDisplay extends StatelessWidget {
  const WordHintDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Obx(() {
      final isDrawer = controller.isDrawer.value;
      final word = controller.currentWord.value;
      final hint = controller.wordHint.value;

      if (isDrawer && word.isNotEmpty) {
        // Drawer sees the full word
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              word,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
                color: AppColors.accent,
              ),
            ),
          ),
        );
      }

      if (hint.isEmpty) return const SizedBox.shrink();

      // Guesser sees the hint with blanks
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            hint,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
              color: Colors.black87,
            ),
          ),
        ),
      );
    });
  }
}
