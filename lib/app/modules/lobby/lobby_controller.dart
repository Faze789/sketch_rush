import 'package:get/get.dart';
import '../../core/enums/room_status.dart';
import '../../data/models/room_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/room_provider.dart';
import '../../routes/app_routes.dart';

class LobbyController extends GetxController {
  final RoomProvider _roomProvider = Get.find<RoomProvider>();
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  final RxList<RoomModel> publicRooms = <RoomModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isJoining = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPublicRooms();
  }

  Future<void> fetchPublicRooms() async {
    try {
      isLoading.value = true;
      final result = await _roomProvider.listPublicRooms();
      publicRooms.value = result.map((e) => RoomModel.fromJson(e)).toList();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load rooms: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createRoom({
    required String roomName,
    int maxPlayers = 8,
    int totalRounds = 3,
    int turnDuration = 80,
    int wordCount = 3,
    String difficulty = 'medium',
    bool isPublic = true,
  }) async {
    try {
      isCreating.value = true;
      final playerId = _authProvider.currentUserId;
      if (playerId == null) {
        Get.snackbar('Error', 'Not authenticated');
        return;
      }

      final room = await _roomProvider.createRoom({
        'host_id': playerId,
        'room_name': roomName,
        'max_players': maxPlayers,
        'total_rounds': totalRounds,
        'turn_duration': turnDuration,
        'word_count': wordCount,
        'difficulty': difficulty,
        'is_public': isPublic,
      });

      // Auto-join as host
      final joinResult = await _roomProvider.joinRoom(
        roomCode: room.roomCode,
        playerId: playerId,
      );

      if (joinResult['error'] != null) {
        Get.snackbar('Error', joinResult['error'].toString());
        return;
      }

      Get.toNamed(AppRoutes.room, arguments: {'room_id': room.id});
    } catch (e) {
      Get.snackbar('Error', 'Failed to create room: ${e.toString()}');
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> joinRoomByCode(String code) async {
    try {
      isJoining.value = true;
      final playerId = _authProvider.currentUserId;
      if (playerId == null) {
        Get.snackbar('Error', 'Not authenticated');
        return;
      }

      final result = await _roomProvider.joinRoom(
        roomCode: code.trim().toUpperCase(),
        playerId: playerId,
      );

      if (result['error'] != null) {
        Get.snackbar('Error', result['error'].toString());
        return;
      }

      final joinedRoomId = result['room_id'] as String?;
      if (joinedRoomId == null || joinedRoomId.isEmpty) {
        Get.snackbar('Error', 'Failed to join room');
        return;
      }

      // Check if the room is already playing (late join) — go straight to game
      final room = await _roomProvider.getRoom(joinedRoomId);
      if (room != null && room.status == RoomStatus.playing) {
        Get.offNamed(AppRoutes.game, arguments: {'room_id': joinedRoomId});
      } else {
        Get.toNamed(AppRoutes.room, arguments: {'room_id': joinedRoomId});
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to join room: ${e.toString()}');
    } finally {
      isJoining.value = false;
    }
  }

  Future<void> joinRoom(RoomModel room) async {
    await joinRoomByCode(room.roomCode);
  }
}
