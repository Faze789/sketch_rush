import '../../core/enums/player_role.dart';

class RoomPlayerModel {
  final String id;
  final String roomId;
  final String playerId;
  final String displayName;
  final int avatarIndex;
  final String avatarColor;
  final int score;
  final int turnOrder;
  final PlayerRole currentRole;
  final bool hasGuessed;
  final bool isConnected;
  final bool isReady;
  final int correctGuesses;
  final int drawingsDone;
  final int roundsWon;
  final DateTime joinedAt;
  final DateTime? leftAt;

  RoomPlayerModel({
    required this.id,
    required this.roomId,
    required this.playerId,
    required this.displayName,
    this.avatarIndex = 0,
    this.avatarColor = '#6C5CE7',
    this.score = 0,
    this.turnOrder = 0,
    this.currentRole = PlayerRole.guesser,
    this.hasGuessed = false,
    this.isConnected = true,
    this.isReady = false,
    this.correctGuesses = 0,
    this.drawingsDone = 0,
    this.roundsWon = 0,
    DateTime? joinedAt,
    this.leftAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory RoomPlayerModel.fromJson(Map<String, dynamic> json) {
    return RoomPlayerModel(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      playerId: json['player_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Player',
      avatarIndex: json['avatar_index'] as int? ?? 0,
      avatarColor: json['avatar_color'] as String? ?? '#6C5CE7',
      score: json['score'] as int? ?? 0,
      turnOrder: json['turn_order'] as int? ?? 0,
      currentRole: PlayerRole.fromString(json['role'] as String? ?? 'guesser'),
      hasGuessed: json['has_guessed'] as bool? ?? false,
      isConnected: json['is_connected'] as bool? ?? true,
      isReady: json['is_ready'] as bool? ?? false,
      correctGuesses: json['correct_guesses'] as int? ?? 0,
      drawingsDone: json['drawings_done'] as int? ?? 0,
      roundsWon: json['rounds_won'] as int? ?? 0,
      joinedAt: DateTime.tryParse(json['joined_at'] as String? ?? '') ??
          DateTime.now(),
      leftAt: DateTime.tryParse(json['left_at'] as String? ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'player_id': playerId,
      'display_name': displayName,
      'avatar_index': avatarIndex,
      'avatar_color': avatarColor,
    };
  }

  RoomPlayerModel copyWith({
    int? score,
    int? roundsWon,
    PlayerRole? currentRole,
    bool? hasGuessed,
    bool? isConnected,
    bool? isReady,
  }) {
    return RoomPlayerModel(
      id: id,
      roomId: roomId,
      playerId: playerId,
      displayName: displayName,
      avatarIndex: avatarIndex,
      avatarColor: avatarColor,
      score: score ?? this.score,
      turnOrder: turnOrder,
      currentRole: currentRole ?? this.currentRole,
      hasGuessed: hasGuessed ?? this.hasGuessed,
      isConnected: isConnected ?? this.isConnected,
      isReady: isReady ?? this.isReady,
      correctGuesses: correctGuesses,
      drawingsDone: drawingsDone,
      roundsWon: roundsWon ?? this.roundsWon,
      joinedAt: joinedAt,
      leftAt: leftAt,
    );
  }
}
