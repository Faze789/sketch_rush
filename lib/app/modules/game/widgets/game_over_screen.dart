import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../widgets/avatar_widget.dart';
import '../game_controller.dart';

class GameOverScreen extends StatelessWidget {
  const GameOverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GameController>();

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events, size: 56, color: AppColors.warning),
              const SizedBox(height: 12),
              Text(
                'Game Over!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 24),

              // Podium
              Obx(() {
                final sorted = List.of(controller.players)
                  ..sort((a, b) {
                    final roundCmp = b.roundsWon.compareTo(a.roundsWon);
                    if (roundCmp != 0) return roundCmp;
                    return b.score.compareTo(a.score);
                  });

                return Column(
                  children: sorted.asMap().entries.map((entry) {
                    final rank = entry.key + 1;
                    final player = entry.value;
                    final isMe = player.playerId == controller.playerId;
                    final isWinner = rank == 1;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isWinner
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : isMe
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: isWinner
                            ? Border.all(
                                color:
                                    AppColors.warning.withValues(alpha: 0.4))
                            : isMe
                                ? Border.all(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.3))
                                : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 28,
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: isWinner
                                    ? AppColors.warning
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                          AvatarWidget(
                            index: player.avatarIndex,
                            color: player.avatarColor,
                            size: 36,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                if (isMe)
                                  const Text(
                                    'You',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${player.roundsWon} round${player.roundsWon == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${player.score} pts',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                  color: isWinner
                                      ? AppColors.warning
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.leaveGame,
                      child: const Text('Leave'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => ElevatedButton(
                          onPressed: controller.isHost.value
                              ? controller.playAgain
                              : null,
                          child: Text(controller.isHost.value
                              ? 'Play Again'
                              : 'Waiting for host...'),
                        )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
