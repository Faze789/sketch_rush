class GameConstants {
  GameConstants._();

  // Room defaults
  static const int defaultMaxPlayers = 8;
  static const int defaultTotalRounds = 3;
  static const int turnsPerPlayerPerRound = 3;
  static const int defaultTurnDuration = 80; // seconds
  static const int defaultWordCount = 3;
  static const int defaultHintInterval = 15; // seconds

  // Room limits
  static const int minPlayers = 2;
  static const int maxPlayers = 12;
  static const int minRounds = 1;
  static const int maxRounds = 10;
  static const int minTurnDuration = 30;
  static const int maxTurnDuration = 180;

  // Timing
  static const int wordSelectionTimeout = 15; // seconds
  static const int turnRevealDuration = 4; // seconds
  static const int roundScoresDuration = 6; // seconds
  static const int disconnectGracePeriod = 10; // seconds

  // Scoring — Guesser (range: 50–100, max 115 with first-guesser bonus)
  static const int guesserBaseScore = 50;
  static const int guesserMaxTimeBonus = 50;
  static const double guesserTimePower = 2.5; // steep curve for tight range
  static const double guesserHintPenalty = 0.10; // 10% reduction per hint
  static const int firstGuesserBonus = 15;

  // Scoring — Drawer (scaled average + all-guessed bonus)
  static const double drawerScalingFactor = 1.1;
  static const int drawerAllGuessedBonus = 20;
  static const int drawerMinPerGuesser = 10;
  static const int skipPenalty = -30;

  // Hints
  static const double firstHintAt = 0.50; // 50% time elapsed
  static const double secondHintAt = 0.75; // 75% time elapsed
  static const double firstHintRevealPercent = 0.25; // reveal 25% of letters
  static const double secondHintRevealPercent = 0.50; // reveal 50% of letters

  // Drawing sync
  static const int strokeBatchIntervalMs = 100; // 10 batches/sec
  static const int maxCanvasSnapshotBytes = 200000; // ~200KB safety limit

  // Rate limiting
  static const int maxGuessesPerWindow = 3;
  static const int guessWindowMs = 2000; // 2 seconds

  // Room code
  static const int roomCodeLength = 6;
}
