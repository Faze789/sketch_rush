class PlayerModel {
  final String id;
  final String displayName;
  final int avatarIndex;
  final String avatarColor;
  final int gamesPlayed;
  final int gamesWon;
  final int totalScore;
  final int bestScore;
  final DateTime createdAt;

  PlayerModel({
    required this.id,
    required this.displayName,
    this.avatarIndex = 0,
    this.avatarColor = '#6C5CE7',
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.totalScore = 0,
    this.bestScore = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory PlayerModel.fromJson(Map<String, dynamic> json) {
    return PlayerModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? 'Player',
      avatarIndex: json['avatar_index'] as int? ?? 0,
      avatarColor: json['avatar_color'] as String? ?? '#6C5CE7',
      gamesPlayed: json['games_played'] as int? ?? 0,
      gamesWon: json['games_won'] as int? ?? 0,
      totalScore: json['total_score'] as int? ?? 0,
      bestScore: json['best_score'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_index': avatarIndex,
      'avatar_color': avatarColor,
    };
  }

  PlayerModel copyWith({
    String? displayName,
    int? avatarIndex,
    String? avatarColor,
  }) {
    return PlayerModel(
      id: id,
      displayName: displayName ?? this.displayName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      avatarColor: avatarColor ?? this.avatarColor,
      gamesPlayed: gamesPlayed,
      gamesWon: gamesWon,
      totalScore: totalScore,
      bestScore: bestScore,
      createdAt: createdAt,
    );
  }
}
