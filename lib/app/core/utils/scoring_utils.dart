import 'dart:math';

import '../constants/game_constants.dart';

/// Client-side mirror of the server scoring formulas.
/// Authoritative scoring always happens server-side; these exist for
/// UI estimation / display purposes only.
class ScoringUtils {
  ScoringUtils._();

  /// Guesser score: power-based time decay + first-guesser bonus - hint penalty.
  ///
  /// Range: 50–100 (base), up to 115 with first-guesser bonus.
  ///
  /// Formula:
  ///   timeRatio  = clamp(remainingSec / totalSec, 0, 1)
  ///   timeFactor = pow(timeRatio, 2.5)
  ///   hintMult   = max(0, 1.0 - hintsRevealed × 0.10)
  ///   score      = round((50 + 50 × timeFactor) × hintMult + (isFirst ? 15 : 0))
  static int calculateGuesserScore({
    required double elapsedSeconds,
    required int totalSeconds,
    bool isFirstGuesser = false,
    int hintsRevealed = 0,
  }) {
    if (totalSeconds <= 0) return 0;

    final remaining = max(0.0, totalSeconds - elapsedSeconds);
    final timeRatio = (remaining / totalSeconds).clamp(0.0, 1.0);
    final timeFactor = pow(timeRatio, GameConstants.guesserTimePower);

    final hintMult = max(0.0,
        1.0 - hintsRevealed * GameConstants.guesserHintPenalty);

    var score = (GameConstants.guesserBaseScore +
            GameConstants.guesserMaxTimeBonus * timeFactor) *
        hintMult;

    if (isFirstGuesser) {
      score += GameConstants.firstGuesserBonus;
    }

    return max(0, score.round());
  }

  /// Drawer score: scaled average of guesser scores + all-guessed bonus.
  /// Minimum: correctCount × 10.
  /// Returns 0 if nobody guessed (anti-AFK).
  static int calculateDrawerScore({
    required int guesserScoresSum,
    required int correctGuesses,
    required int totalGuessers,
  }) {
    if (correctGuesses <= 0 || totalGuessers <= 0) return 0;

    var score = guesserScoresSum /
        totalGuessers *
        GameConstants.drawerScalingFactor;

    if (correctGuesses >= totalGuessers) {
      score += GameConstants.drawerAllGuessedBonus;
    }

    final minScore = correctGuesses * GameConstants.drawerMinPerGuesser;
    return max(minScore, score.round());
  }
}
