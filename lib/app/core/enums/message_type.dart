enum MessageType {
  guess,
  correct,
  closeGuess,
  system,
  chat;

  String get dbValue {
    switch (this) {
      case MessageType.guess:
        return 'guess';
      case MessageType.correct:
        return 'correct';
      case MessageType.closeGuess:
        return 'close_guess';
      case MessageType.system:
        return 'system';
      case MessageType.chat:
        return 'chat';
    }
  }

  static MessageType fromString(String? value) {
    switch (value) {
      case 'guess':
        return MessageType.guess;
      case 'correct':
        return MessageType.correct;
      case 'close_guess':
        return MessageType.closeGuess;
      case 'system':
        return MessageType.system;
      case 'chat':
        return MessageType.chat;
      default:
        return MessageType.guess;
    }
  }
}
