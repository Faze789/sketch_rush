import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../game_controller.dart';

class TurnScoreboard extends StatelessWidget {
  const TurnScoreboard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'The word was:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 8),
              Obx(() => Text(
                    controller.revealedWord.value,
                    style:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 2,
                            ),
                  )),
              const SizedBox(height: 20),

              // Player scores
              Obx(() {
                final sorted = List.of(controller.players)
                  ..sort((a, b) => b.score.compareTo(a.score));

                return Column(
                  children: sorted.map((player) {
                    final isMe = player.playerId == controller.playerId;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppColors.primary.withValues(alpha: 0.08)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: isMe
                            ? Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.displayName,
                              style: TextStyle(
                                fontWeight:
                                    isMe ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${player.score}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
