enum GamePhase {
  wordSelection,
  drawing,
  turnReveal,
  roundScores,
  gameOver;

  String get dbValue {
    switch (this) {
      case GamePhase.wordSelection:
        return 'word_selection';
      case GamePhase.drawing:
        return 'drawing';
      case GamePhase.turnReveal:
        return 'turn_reveal';
      case GamePhase.roundScores:
        return 'round_scores';
      case GamePhase.gameOver:
        return 'game_over';
    }
  }

  static GamePhase fromString(String? value) {
    switch (value) {
      case 'word_selection':
        return GamePhase.wordSelection;
      case 'drawing':
        return GamePhase.drawing;
      case 'turn_reveal':
        return GamePhase.turnReveal;
      case 'round_scores':
        return GamePhase.roundScores;
      case 'game_over':
        return GamePhase.gameOver;
      default:
        return GamePhase.wordSelection;
    }
  }
}
