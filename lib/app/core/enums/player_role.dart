enum PlayerRole {
  drawer,
  guesser,
  spectator;

  static PlayerRole fromString(String value) {
    return PlayerRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlayerRole.guesser,
    );
  }
}
