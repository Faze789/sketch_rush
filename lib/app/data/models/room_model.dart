import '../../core/enums/game_phase.dart';
import '../../core/enums/room_status.dart';

class RoomModel {
  final String id;
  final String roomCode;
  final String hostId;
  final String roomName;
  final int maxPlayers;
  final int totalRounds;
  final int turnDuration;
  final int wordCount;
  final String difficulty;
  final bool isPublic;
  final List<String> customWords;
  final int hintInterval;
  final RoomStatus status;
  final GamePhase? currentPhase;
  final int currentRound;
  final int currentTurn;
  final String? currentDrawerId;
  final DateTime? gameStartedAt;
  final DateTime? gameEndedAt;
  final DateTime createdAt;

  // Joined fields
  final String? hostName;
  final int? currentPlayers;

  RoomModel({
    required this.id,
    required this.roomCode,
    required this.hostId,
    required this.roomName,
    this.maxPlayers = 8,
    this.totalRounds = 3,
    this.turnDuration = 80,
    this.wordCount = 3,
    this.difficulty = 'medium',
    this.isPublic = true,
    this.customWords = const [],
    this.hintInterval = 15,
    this.status = RoomStatus.waiting,
    this.currentPhase,
    this.currentRound = 0,
    this.currentTurn = 0,
    this.currentDrawerId,
    this.gameStartedAt,
    this.gameEndedAt,
    DateTime? createdAt,
    this.hostName,
    this.currentPlayers,
  }) : createdAt = createdAt ?? DateTime.now();

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String? ?? '',
      roomCode: json['room_code'] as String? ?? '',
      hostId: json['host_id'] as String? ?? '',
      roomName: json['room_name'] as String? ?? 'SketchRush Room',
      maxPlayers: json['max_players'] as int? ?? 8,
      totalRounds: json['total_rounds'] as int? ?? 3,
      turnDuration: json['turn_duration'] as int? ?? 80,
      wordCount: json['word_count'] as int? ?? 3,
      difficulty: json['difficulty'] as String? ?? 'medium',
      isPublic: json['is_public'] as bool? ?? true,
      customWords: (json['custom_words'] as List?)?.cast<String>() ?? [],
      hintInterval: json['hint_interval'] as int? ?? 15,
      status: RoomStatus.fromString(json['status'] as String? ?? 'waiting'),
      currentPhase: json['current_phase'] != null
          ? GamePhase.fromString(json['current_phase'] as String?)
          : null,
      currentRound: json['current_round'] as int? ?? 0,
      currentTurn: json['current_turn'] as int? ?? 0,
      currentDrawerId: json['current_drawer_id'] as String?,
      gameStartedAt: json['game_started_at'] != null
          ? DateTime.parse(json['game_started_at'] as String)
          : null,
      gameEndedAt: json['game_ended_at'] != null
          ? DateTime.parse(json['game_ended_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      hostName: json['host_name'] as String?,
      currentPlayers: json['current_players'] as int?,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'host_id': hostId,
      'room_name': roomName,
      'max_players': maxPlayers,
      'total_rounds': totalRounds,
      'turn_duration': turnDuration,
      'word_count': wordCount,
      'difficulty': difficulty,
      'is_public': isPublic,
      'custom_words': customWords,
      'hint_interval': hintInterval,
    };
  }

  RoomModel copyWith({
    RoomStatus? status,
    GamePhase? currentPhase,
    int? currentRound,
    int? currentTurn,
    String? currentDrawerId,
    int? currentPlayers,
  }) {
    return RoomModel(
      id: id,
      roomCode: roomCode,
      hostId: hostId,
      roomName: roomName,
      maxPlayers: maxPlayers,
      totalRounds: totalRounds,
      turnDuration: turnDuration,
      wordCount: wordCount,
      difficulty: difficulty,
      isPublic: isPublic,
      customWords: customWords,
      hintInterval: hintInterval,
      status: status ?? this.status,
      currentPhase: currentPhase ?? this.currentPhase,
      currentRound: currentRound ?? this.currentRound,
      currentTurn: currentTurn ?? this.currentTurn,
      currentDrawerId: currentDrawerId ?? this.currentDrawerId,
      gameStartedAt: gameStartedAt,
      gameEndedAt: gameEndedAt,
      createdAt: createdAt,
      hostName: hostName,
      currentPlayers: currentPlayers ?? this.currentPlayers,
    );
  }
}
