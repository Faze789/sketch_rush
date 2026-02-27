import 'dart:math';

class HintUtils {
  HintUtils._();

  /// Generate a blank hint from a word: "cat" -> "_ _ _"
  static String generateBlankHint(String word) {
    return word.split('').map((c) => c == ' ' ? '  ' : '_').join(' ');
  }

  /// Reveal a percentage of letters in the word.
  /// Uses turnId as seed for deterministic letter selection.
  static String revealHint({
    required String word,
    required double revealPercent,
    required String seed,
  }) {
    final random = Random(seed.hashCode);
    final letters = word.split('');
    final totalLetters = letters.where((c) => c != ' ').length;
    final lettersToReveal = (totalLetters * revealPercent).ceil();

    // Build list of concealable indices (non-space characters)
    final indices = <int>[];
    for (var i = 0; i < letters.length; i++) {
      if (letters[i] != ' ') indices.add(i);
    }

    // Shuffle and pick indices to reveal
    indices.shuffle(random);
    final revealedIndices = indices.take(lettersToReveal).toSet();

    return letters.asMap().entries.map((entry) {
      if (entry.value == ' ') return '  ';
      if (revealedIndices.contains(entry.key)) return entry.value;
      return '_';
    }).join(' ');
  }

  /// Get the word length display: "cat" -> 3
  static int getWordLength(String word) {
    return word.replaceAll(' ', '').length;
  }
}
