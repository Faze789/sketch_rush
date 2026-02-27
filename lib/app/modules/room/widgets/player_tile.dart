import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/room_player_model.dart';
import '../../../widgets/avatar_widget.dart';

class PlayerTile extends StatelessWidget {
  final RoomPlayerModel player;
  final bool isHost;
  final bool isMe;

  const PlayerTile({
    super.key,
    required this.player,
    this.isHost = false,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: AvatarWidget(
          index: player.avatarIndex,
          color: player.avatarColor,
          size: 44,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                player.displayName,
                style: TextStyle(
                  fontWeight: isMe ? FontWeight.w700 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isMe) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
            if (isHost) ...[
              const SizedBox(width: 6),
              const Icon(Icons.star, size: 18, color: AppColors.warning),
            ],
          ],
        ),
        trailing: isHost
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.correct.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Host',
                  style: TextStyle(
                    color: AppColors.correct,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              )
            : Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Joined',
                  style: TextStyle(
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
      ),
    );
  }
}
