import '../../core/enums/message_type.dart';

class ChatMessageModel {
  final String? id;
  final String? playerId;
  final String? playerName;
  final MessageType type;
  final String content;
  final bool isCorrect;
  final int scoreAwarded;
  final DateTime createdAt;

  ChatMessageModel({
    this.id,
    this.playerId,
    this.playerName,
    required this.type,
    required this.content,
    this.isCorrect = false,
    this.scoreAwarded = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String?,
      playerId: json['player_id'] as String?,
      playerName: json['player_name'] as String?,
      type: MessageType.fromString(json['message_type'] as String?),
      content: json['content'] as String? ?? '',
      isCorrect: json['is_correct'] as bool? ?? false,
      scoreAwarded: json['score_awarded'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  factory ChatMessageModel.system(String content) {
    return ChatMessageModel(type: MessageType.system, content: content);
  }

  factory ChatMessageModel.correctGuess(String playerName, int score) {
    return ChatMessageModel(
      type: MessageType.correct,
      playerName: playerName,
      content: '$playerName guessed the word! (+$score)',
      isCorrect: true,
      scoreAwarded: score,
    );
  }

  factory ChatMessageModel.closeGuess(String playerName) {
    return ChatMessageModel(
      type: MessageType.closeGuess,
      playerName: playerName,
      content: '$playerName is close!',
    );
  }
}
