import '../models/room_model.dart';
import '../models/room_player_model.dart';
import 'supabase_provider.dart';

class RoomProvider {
  Future<List<Map<String, dynamic>>> listPublicRooms({
    int limit = 20,
    int offset = 0,
  }) async {
    final result = await SupabaseProvider.rpc<List<dynamic>>(
      'list_public_rooms',
      params: {'p_limit': limit, 'p_offset': offset},
    );
    return result.cast<Map<String, dynamic>>();
  }

  Future<RoomModel> createRoom(Map<String, dynamic> roomData) async {
    final result = await SupabaseProvider.from('game_rooms')
        .insert(roomData)
        .select()
        .single();
    return RoomModel.fromJson(result);
  }

  Future<Map<String, dynamic>> joinRoom({
    required String roomCode,
    required String playerId,
  }) async {
    final result = await SupabaseProvider.rpc<Map<String, dynamic>>(
      'join_room',
      params: {'p_room_code': roomCode, 'p_player_id': playerId},
    );
    return result;
  }

  Future<Map<String, dynamic>> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    final result = await SupabaseProvider.rpc<Map<String, dynamic>>(
      'leave_room',
      params: {'p_room_id': roomId, 'p_player_id': playerId},
    );
    return result;
  }

  Future<RoomModel?> getRoom(String roomId) async {
    final result = await SupabaseProvider.from('game_rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();
    if (result == null) return null;
    return RoomModel.fromJson(result);
  }

  Future<List<RoomPlayerModel>> getRoomPlayers(String roomId) async {
    final result = await SupabaseProvider.from('room_players')
        .select()
        .eq('room_id', roomId)
        .isFilter('left_at', null)
        .order('turn_order', ascending: true);
    return (result as List)
        .map((e) => RoomPlayerModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updatePlayerReady({
    required String roomPlayerId,
    required bool isReady,
  }) async {
    await SupabaseProvider.from('room_players')
        .update({'is_ready': isReady}).eq('id', roomPlayerId);
  }

  Future<void> updateRoomConfig(
    String roomId,
    Map<String, dynamic> config,
  ) async {
    await SupabaseProvider.from('game_rooms')
        .update(config)
        .eq('id', roomId);
  }
}
