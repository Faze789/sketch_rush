class GameTurnModel {
  final String id;
  final String roomId;
  final int roundNumber;
  final int turnNumber;
  final String drawerId;
  final List<String> wordChoices;
  final String? chosenWord;
  final String? wordHint;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime? endedAt;
  final int guessersTotal;
  final int correctGuesses;
  final int drawerScore;
  final Map<String, dynamic> turnData;

  GameTurnModel({
    required this.id,
    required this.roomId,
    required this.roundNumber,
    required this.turnNumber,
    required this.drawerId,
    this.wordChoices = const [],
    this.chosenWord,
    this.wordHint,
    this.startedAt,
    this.endsAt,
    this.endedAt,
    this.guessersTotal = 0,
    this.correctGuesses = 0,
    this.drawerScore = 0,
    this.turnData = const {},
  });

  factory GameTurnModel.fromJson(Map<String, dynamic> json) {
    return GameTurnModel(
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      roundNumber: (json['round_number'] as num?)?.toInt() ?? 0,
      turnNumber: (json['turn_number'] as num?)?.toInt() ?? 0,
      drawerId: json['drawer_id'] as String? ?? '',
      wordChoices: (json['word_choices'] as List?)?.cast<String>() ?? [],
      chosenWord: json['chosen_word'] as String?,
      wordHint: json['word_hint'] as String?,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
      endsAt: json['ends_at'] != null
          ? DateTime.parse(json['ends_at'] as String)
          : null,
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : null,
      guessersTotal: json['guessers_total'] as int? ?? 0,
      correctGuesses: json['correct_guesses'] as int? ?? 0,
      drawerScore: json['drawer_score'] as int? ?? 0,
      turnData: json['turn_data'] as Map<String, dynamic>? ?? {},
    );
  }
}
