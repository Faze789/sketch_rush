import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import 'room_controller.dart';
import 'widgets/player_tile.dart';

class RoomView extends GetView<RoomController> {
  const RoomView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.leaveRoom();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(controller.room.value?.roomName ?? 'Room')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: controller.leaveRoom,
          ),
          actions: [
            // Room code copy button
            Obx(() {
              final code = controller.room.value?.roomCode ?? '';
              return TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  Get.snackbar('Copied!', 'Room code $code copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2));
                },
                icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                label: Text(
                  code,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    fontSize: 16,
                  ),
                ),
              );
            }),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Room info banner
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Obx(() {
                  final room = controller.room.value;
                  if (room == null) return const SizedBox();
                  return Wrap(
                    spacing: 16,
                    children: [
                      _infoChip(Icons.loop, '${room.totalRounds} rounds'),
                      _infoChip(
                          Icons.timer_outlined, '${room.turnDuration}s turns'),
                      _infoChip(Icons.signal_cellular_alt, room.difficulty),
                      _infoChip(Icons.people,
                          '${controller.players.length}/${room.maxPlayers}'),
                    ],
                  );
                }),
              ),

              // Player list
              Expanded(
                child: Obx(() => ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: controller.players.length,
                      itemBuilder: (context, index) {
                        final player = controller.players[index];
                        return PlayerTile(
                          player: player,
                          isHost:
                              player.playerId == controller.room.value?.hostId,
                          isMe: player.playerId == controller.playerId,
                        );
                      },
                    )),
              ),

              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Obx(() {
                  final isHost = controller.isHost.value;
                  final hasEnoughPlayers = controller.players.length >= 2;
                  final isStarting = controller.isStarting.value;

                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isStarting
                          ? null
                          : isHost && hasEnoughPlayers
                              ? controller.startGame
                              : null,
                      child: isStarting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Starting game...'),
                              ],
                            )
                          : Text(
                              isHost
                                  ? hasEnoughPlayers
                                      ? 'Start Game'
                                      : 'Waiting for players... (${controller.players.length}/2 min)'
                                  : 'Waiting for host to start...',
                            ),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
