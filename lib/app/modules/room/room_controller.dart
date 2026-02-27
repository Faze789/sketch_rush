import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/enums/room_status.dart';
import '../../data/models/room_model.dart';
import '../../data/models/room_player_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/game_provider.dart';
import '../../data/providers/realtime_provider.dart';
import '../../data/providers/room_provider.dart';
import '../../routes/app_routes.dart';

class RoomController extends GetxController {
  final RoomProvider _roomProvider = Get.find<RoomProvider>();
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final RealtimeProvider _realtimeProvider = Get.find<RealtimeProvider>();
  final GameProvider _gameProvider = Get.find<GameProvider>();

  final Rx<RoomModel?> room = Rx<RoomModel?>(null);
  final RxList<RoomPlayerModel> players = <RoomPlayerModel>[].obs;
  final RxBool isHost = false.obs;
  final RxBool isLoading = false.obs;
  final RxBool isStarting = false.obs;

  // Polling fallback in case realtime INSERT event is missed
  Timer? _pollTimer;

  String get roomId => (Get.arguments as Map?)?['room_id'] as String? ?? '';
  String? get playerId => _authProvider.currentUserId;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> _initialize() async {
    if (roomId.isEmpty) {
      // Hot restart lost route arguments — defer navigation to avoid
      // calling setState/markNeedsBuild during the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.lobby);
      });
      return;
    }
    isLoading.value = true;
    await _fetchRoom();
    await _fetchPlayers();
    await _setupRealtime();
    _startPlayerPolling();
    isLoading.value = false;
  }

  Future<void> _fetchRoom() async {
    room.value = await _roomProvider.getRoom(roomId);
    isHost.value = room.value?.hostId == playerId;
  }

  Future<void> _fetchPlayers() async {
    players.value = await _roomProvider.getRoomPlayers(roomId);
    // Auto-start: host starts the game once 2+ players have joined
    _tryAutoStart();
  }

  void _tryAutoStart() {
    if (!isHost.value) return;
    if (isStarting.value) return;
    if (room.value?.status != RoomStatus.waiting) return;
    if (players.length < 2) return;
    startGame();
  }

  Future<void> _setupRealtime() async {
    _realtimeProvider.setupRoomChannel(
      roomId: roomId,
      onPresenceSync: (_) {},
      onPresenceJoin: (_) {},
      onPresenceLeave: (_) {},
      onRoomUpdate: _onRoomUpdate,
      onPlayerInsert: (_) => _fetchPlayers(),
      onPlayerUpdate: (_) => _fetchPlayers(),
    );
    await _realtimeProvider.subscribeRoomChannel();

    // Track presence
    if (playerId != null) {
      _realtimeProvider.trackPresence({
        'player_id': playerId,
        'online_at': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Poll for player changes every 3 seconds as a fallback in case
  /// the Postgres realtime INSERT event is missed.
  void _startPlayerPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (room.value?.status == RoomStatus.waiting) {
        _fetchPlayers();
      } else {
        // Stop polling once the game starts
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    });
  }

  void _onRoomUpdate(PostgresChangePayload payload) {
    final newData = payload.newRecord;
    // Guard: payload must have a valid room id
    if (newData.isEmpty || newData['id'] == null) return;

    room.value = RoomModel.fromJson(newData);
    isHost.value = room.value?.hostId == playerId;

    // Navigate to game when room status changes to playing
    if (room.value?.status == RoomStatus.playing) {
      Get.offNamed(AppRoutes.game, arguments: {'room_id': roomId});
    }
  }

  Future<void> startGame() async {
    if (!isHost.value) return;
    if (players.length < 2) return;
    final pid = playerId;
    if (pid == null) return;

    try {
      isStarting.value = true;
      await _gameProvider.startGame(
        roomId: roomId,
        playerId: pid,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to start game: ${e.toString()}');
    } finally {
      isStarting.value = false;
    }
  }

  Future<void> leaveRoom() async {
    final pid = playerId;
    if (pid == null) return;
    await _roomProvider.leaveRoom(roomId: roomId, playerId: pid);
    await _realtimeProvider.disposeRoomChannel();
    Get.offAllNamed(AppRoutes.lobby);
  }

  Future<void> updateRoomConfig(Map<String, dynamic> config) async {
    if (!isHost.value) return;
    await _roomProvider.updateRoomConfig(roomId, config);
  }

  @override
  void onClose() {
    _pollTimer?.cancel();
    _realtimeProvider.untrackPresence();
    _realtimeProvider.disposeRoomChannel();
    super.onClose();
  }
}
