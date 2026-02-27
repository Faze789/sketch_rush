import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../modules/auth/auth_controller.dart';
import '../../widgets/avatar_widget.dart';
import 'lobby_controller.dart';
import 'widgets/room_card.dart';
import 'widgets/create_room_dialog.dart';
import 'widgets/join_room_dialog.dart';

class LobbyView extends GetView<LobbyController> {
  const LobbyView({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SketchRush'),
        actions: [
          Obx(() => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showProfileMenu(context, authController),
                  child: AvatarWidget(
                    index: authController.avatarIndex.value,
                    color: authController.avatarColor.value,
                    size: 36,
                  ),
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const CreateRoomDialog(),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Room'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => const JoinRoomDialog(),
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Join Room'),
                  ),
                ),
              ],
            ),
          ),

          // Public rooms header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Public Rooms',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: controller.fetchPublicRooms,
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),

          // Room list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.publicRooms.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.meeting_room_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No public rooms available',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create one to get started!',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: controller.fetchPublicRooms,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: controller.publicRooms.length,
                  itemBuilder: (context, index) {
                    final room = controller.publicRooms[index];
                    return RoomCard(
                      room: room,
                      onJoin: () => controller.joinRoom(room),
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context, AuthController auth) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Obx(() => AvatarWidget(
                  index: auth.avatarIndex.value,
                  color: auth.avatarColor.value,
                  size: 64,
                )),
            const SizedBox(height: 12),
            Obx(() => Text(
                  auth.displayName.value,
                  style: Theme.of(context).textTheme.titleLarge,
                )),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Get.back();
                auth.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
