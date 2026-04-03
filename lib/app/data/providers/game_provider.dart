import 'dart:async';
import 'dart:convert';
import 'supabase_provider.dart';

class GameProvider {
  Future<Map<String, dynamic>> invokeGameEngine({
    required String action,
    required String roomId,
    required String playerId,
    Map<String, dynamic>? params,
  }) async {
    final body = {
      'action': action,
      'room_id': roomId,
      'player_id': playerId,
      ...?params,
    };

    final response = await SupabaseProvider.functions
        .invoke('game-engine', body: body)
        .timeout(const Duration(seconds: 15));

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } on FormatException catch (e) {
        return {'error': 'Invalid JSON response: ${e.message}'};
      }
    }
    return {'error': 'Unexpected response type: ${data.runtimeType}'};
  }

  Future<Map<String, dynamic>> startGame({
    required String roomId,
    required String playerId,
  }) {
    return invokeGameEngine(
      action: 'start_game',
      roomId: roomId,
      playerId: playerId,
    );
  }

  Future<Map<String, dynamic>> selectWord({
    required String roomId,
    required String playerId,
    required String word,
  }) {
    return invokeGameEngine(
      action: 'select_word',
      roomId: roomId,
      playerId: playerId,
      params: {'word': word},
    );
  }

  Future<Map<String, dynamic>> submitGuess({
    required String roomId,
    required String playerId,
    required String guess,
  }) {
    return invokeGameEngine(
      action: 'submit_guess',
      roomId: roomId,
      playerId: playerId,
      params: {'guess': guess},
    );
  }

  Future<Map<String, dynamic>> requestHint({
    required String roomId,
    required String playerId,
  }) {
    return invokeGameEngine(
      action: 'request_hint',
      roomId: roomId,
      playerId: playerId,
    );
  }

  Future<Map<String, dynamic>> endTurn({
    required String roomId,
    required String playerId,
  }) {
    return invokeGameEngine(
      action: 'end_turn',
      roomId: roomId,
      playerId: playerId,
    );
  }

  Future<Map<String, dynamic>> skipTurn({
    required String roomId,
    required String playerId,
  }) {
    return invokeGameEngine(
      action: 'skip_turn',
      roomId: roomId,
      playerId: playerId,
    );
  }

  Future<Map<String, dynamic>> playAgain({
    required String roomId,
    required String playerId,
  }) {
    return invokeGameEngine(
      action: 'play_again',
      roomId: roomId,
      playerId: playerId,
    );
  }

  Future<Map<String, dynamic>?> getCurrentTurn(String roomId) async {
    final result = await SupabaseProvider.from('game_turns')
        .select()
        .eq('room_id', roomId)
        .isFilter('ended_at', null)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return result;
  }
}
