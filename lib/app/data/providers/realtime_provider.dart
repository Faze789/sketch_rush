import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/supabase_constants.dart';
import 'supabase_provider.dart';

class RealtimeProvider {
  RealtimeChannel? _roomChannel;
  RealtimeChannel? _gameChannel;

  // --- Room Channel (Presence + Postgres Changes) ---

  RealtimeChannel setupRoomChannel({
    required String roomId,
    required Function(RealtimePresenceSyncPayload) onPresenceSync,
    required Function(RealtimePresenceJoinPayload) onPresenceJoin,
    required Function(RealtimePresenceLeavePayload) onPresenceLeave,
    Function(PostgresChangePayload)? onRoomUpdate,
    Function(PostgresChangePayload)? onPlayerInsert,
    Function(PostgresChangePayload)? onPlayerUpdate,
  }) {
    _roomChannel = SupabaseProvider.channel(
      SupabaseConstants.roomChannel(roomId),
    );

    _roomChannel!
        .onPresenceSync(onPresenceSync)
        .onPresenceJoin(onPresenceJoin)
        .onPresenceLeave(onPresenceLeave);

    if (onRoomUpdate != null) {
      _roomChannel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'game_rooms',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: roomId,
        ),
        callback: onRoomUpdate,
      );
    }

    if (onPlayerInsert != null) {
      _roomChannel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'room_players',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: onPlayerInsert,
      );
    }

    if (onPlayerUpdate != null) {
      _roomChannel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'room_players',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: onPlayerUpdate,
      );
    }

    return _roomChannel!;
  }

  Future<void> subscribeRoomChannel() async {
    if (_roomChannel == null) return;
    final completer = Completer<void>();
    _roomChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed &&
          !completer.isCompleted) {
        completer.complete();
      } else if (status == RealtimeSubscribeStatus.channelError &&
          !completer.isCompleted) {
        debugPrint('Room channel subscription error: $error');
        completer.complete();
      }
    });
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Room channel subscription timed out');
      },
    );
  }

  Future<void> trackPresence(Map<String, dynamic> data) async {
    await _roomChannel?.track(data);
  }

  Future<void> untrackPresence() async {
    await _roomChannel?.untrack();
  }

  // --- Game Channel (Broadcast only) ---

  RealtimeChannel setupGameChannel({
    required String roomId,
    required Map<String, Function(Map<String, dynamic>)> eventHandlers,
  }) {
    _gameChannel = SupabaseProvider.channel(
      SupabaseConstants.gameChannel(roomId),
    );

    for (final entry in eventHandlers.entries) {
      _gameChannel!.onBroadcast(
        event: entry.key,
        callback: (payload) {
          // Supabase Realtime wraps broadcast data inside a 'payload' key.
          // Unwrap if nested, otherwise use the map directly.
          final data = payload['payload'] is Map<String, dynamic>
              ? payload['payload'] as Map<String, dynamic>
              : payload;
          entry.value(data);
        },
      );
    }

    return _gameChannel!;
  }

  Future<void> subscribeGameChannel() async {
    if (_gameChannel == null) return;
    final completer = Completer<void>();
    _gameChannel!.subscribe((status, [error]) {
      if (status == RealtimeSubscribeStatus.subscribed &&
          !completer.isCompleted) {
        completer.complete();
      } else if (status == RealtimeSubscribeStatus.channelError &&
          !completer.isCompleted) {
        debugPrint('Game channel subscription error: $error');
        completer.complete();
      }
    });
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('Game channel subscription timed out');
      },
    );
  }

  Future<void> broadcast({
    required String event,
    required Map<String, dynamic> payload,
  }) async {
    if (_gameChannel == null) {
      debugPrint('Warning: broadcast("$event") called but game channel is null');
      return;
    }
    await _gameChannel!.sendBroadcastMessage(
      event: event,
      payload: payload,
    );
  }

  // --- Cleanup ---

  Future<void> disposeRoomChannel() async {
    if (_roomChannel != null) {
      await SupabaseProvider.removeChannel(_roomChannel!);
      _roomChannel = null;
    }
  }

  Future<void> disposeGameChannel() async {
    if (_gameChannel != null) {
      await SupabaseProvider.removeChannel(_gameChannel!);
      _gameChannel = null;
    }
  }

  Future<void> disposeAll() async {
    await disposeRoomChannel();
    await disposeGameChannel();
  }
}
