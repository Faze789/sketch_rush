import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import '../../core/constants/game_constants.dart';
import '../../core/constants/supabase_constants.dart';
import '../../core/enums/game_phase.dart';
import '../../core/enums/room_status.dart';
import '../../core/utils/hint_utils.dart';
import '../../data/models/room_model.dart';
import '../../data/models/room_player_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/game_provider.dart';
import '../../data/providers/realtime_provider.dart';
import '../../data/providers/room_provider.dart';
import '../../routes/app_routes.dart';
import '../chat/chat_controller.dart';
import 'drawing_controller.dart';

class GameController extends GetxController {
  final RoomProvider _roomProvider = Get.find<RoomProvider>();
  final AuthProvider _authProvider = Get.find<AuthProvider>();
  final RealtimeProvider _realtimeProvider = Get.find<RealtimeProvider>();
  final GameProvider _gameProvider = Get.find<GameProvider>();

  late final DrawingController drawingController;
  late final ChatController chatController;

  // Game state
  final Rx<GamePhase> phase = GamePhase.wordSelection.obs;
  final RxInt currentRound = 0.obs;
  final RxInt totalRounds = 3.obs;
  final RxInt currentTurnInRound = 0.obs;
  final RxString currentWord = ''.obs;
  final RxString wordHint = ''.obs;
  final RxInt wordLength = 0.obs;
  final RxList<String> wordChoices = <String>[].obs;
  final RxBool isDrawer = false.obs;

  // Timer
  final RxInt remainingSeconds = 0.obs;
  final RxInt totalTurnSeconds = 80.obs;
  Timer? _countdownTimer;
  DateTime? _turnEndsAt;

  // Hint flags
  bool _firstHintSent = false;
  bool _secondHintSent = false;

  // Word selection timer
  static const int wordSelectionDuration = GameConstants.wordSelectionTimeout;
  Timer? _wordSelectionTimer;
  final RxInt wordSelectionRemaining = 0.obs;
  bool _wordAlreadySelected = false;

  // Players & scores
  final RxList<RoomPlayerModel> players = <RoomPlayerModel>[].obs;
  final RxString currentDrawerId = ''.obs;
  final RxString currentDrawerName = ''.obs;
  final RxInt correctGuessCount = 0.obs;
  final RxBool hasGuessedCorrectly = false.obs;

  // Turn results
  final RxString revealedWord = ''.obs;
  final RxList<Map<String, dynamic>> turnScores = <Map<String, dynamic>>[].obs;

  // Broadcast recovery (handles at-most-once delivery failures)
  Timer? _recoveryTimer;

  // Room
  final Rx<RoomModel?> room = Rx<RoomModel?>(null);
  final RxBool isHost = false.obs;

  String get roomId => (Get.arguments as Map?)?['room_id'] as String? ?? '';
  String? get playerId => _authProvider.currentUserId;

  @override
  void onInit() {
    super.onInit();
    drawingController = Get.put(DrawingController());
    chatController = Get.put(ChatController());

    _initialize();
  }

  Future<void> _initialize() async {
    if (roomId.isEmpty) {
      // Hot restart lost route arguments — defer navigation to avoid
      // calling setState/markNeedsBuild during the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.lobby);
      });
      return;
    }
    try {
      await _fetchRoom();
      await _fetchPlayers();
      // Await channel subscription before proceeding to ensure broadcasts are received
      await _setupGameChannel();
      // Initialize state from DB in case we missed the turn_start broadcast
      await _initializeFromRoom();
    } catch (e) {
      debugPrint('GameController initialization error: $e');
      Get.snackbar('Error', 'Failed to join game. Please try again.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed(AppRoutes.lobby);
      });
    }
  }

  Future<void> _fetchRoom() async {
    room.value = await _roomProvider.getRoom(roomId);
    final r = room.value;
    if (r != null) {
      totalRounds.value = r.totalRounds;
      totalTurnSeconds.value = r.turnDuration;
      isHost.value = r.hostId == playerId;
    }
  }

  Future<void> _fetchPlayers() async {
    players.value = await _roomProvider.getRoomPlayers(roomId);
  }

  /// Initialize game state from DB when entering an in-progress game.
  /// Handles the race condition where turn_start broadcast fires
  /// before the client subscribes to the game channel.
  Future<void> _initializeFromRoom() async {
    final r = room.value;
    if (r == null || r.status != RoomStatus.playing) return;

    // If _onTurnStart already ran from broadcast, skip DB init
    if (currentRound.value > 0 && currentDrawerId.value.isNotEmpty) return;

    // Set round/turn from DB
    currentRound.value = r.currentRound;
    currentTurnInRound.value = r.currentTurn;

    // Set drawer
    if (r.currentDrawerId != null) {
      currentDrawerId.value = r.currentDrawerId ?? '';
      isDrawer.value = r.currentDrawerId == playerId;
      drawingController.isEnabled.value = isDrawer.value;

      // Find drawer name from players list
      final drawer = players.firstWhereOrNull(
        (p) => p.playerId == r.currentDrawerId,
      );
      if (drawer != null) {
        currentDrawerName.value = drawer.displayName;
      }
    }

    // Set phase from DB
    if (r.currentPhase != null) {
      phase.value = r.currentPhase ?? GamePhase.wordSelection;
    }

    // If we're the drawer in word_selection phase, fetch word choices and start timer
    if (isDrawer.value && r.currentPhase == GamePhase.wordSelection) {
      try {
        final turn = await _gameProvider.getCurrentTurn(roomId);
        if (turn != null) {
          final choices =
              (turn['word_choices'] as List?)?.cast<String>() ?? [];
          if (choices.isNotEmpty) {
            wordChoices.value = choices;
          }
        }
      } catch (_) {}
      _startWordSelectionTimer();
    } else if (!isDrawer.value && r.currentPhase == GamePhase.wordSelection) {
      // Guesser: show blank hint
      wordHint.value = HintUtils.generateBlankHint('?' * (r.currentTurn > 0 ? 5 : 0));
    }

    // If we're in drawing phase, fetch timer and hint info
    if (r.currentPhase == GamePhase.drawing) {
      try {
        final turn = await _gameProvider.getCurrentTurn(roomId);
        if (turn != null) {
          final endsAt = turn['ends_at'] as String?;
          final hint = turn['word_hint'] as String?;
          if (endsAt != null) {
            _turnEndsAt = DateTime.parse(endsAt);
            _startCountdown();
          }
          if (hint != null) {
            wordHint.value = hint;
          }
          if (isDrawer.value) {
            currentWord.value = turn['chosen_word'] as String? ?? '';
          }
        }
      } catch (_) {}
    }

    if (currentDrawerName.value.isNotEmpty) {
      chatController.addSystemMessage(
        '${currentDrawerName.value} is drawing!',
      );
    }
  }

  Future<void> _setupGameChannel() async {
    _realtimeProvider.setupGameChannel(
      roomId: roomId,
      eventHandlers: {
        SupabaseConstants.eventTurnStart: _onTurnStart,
        SupabaseConstants.eventWordSelected: _onWordSelected,
        SupabaseConstants.eventHintUpdate: _onHintUpdate,
        SupabaseConstants.eventCorrectGuess: _onCorrectGuess,
        SupabaseConstants.eventCloseGuess: _onCloseGuess,
        SupabaseConstants.eventWrongGuess: _onWrongGuess,
        SupabaseConstants.eventTurnEnd: _onTurnEnd,
        SupabaseConstants.eventRoundEnd: _onRoundEnd,
        SupabaseConstants.eventGameOver: _onGameOver,
        SupabaseConstants.eventGameReset: _onGameReset,
        SupabaseConstants.eventStrokeData: drawingController.onRemoteStrokeData,
        SupabaseConstants.eventStrokeUndo: drawingController.onRemoteStrokeUndo,
        SupabaseConstants.eventStrokeClear: drawingController.onRemoteStrokeClear,
        SupabaseConstants.eventCanvasRequest: drawingController.onCanvasRequest,
        SupabaseConstants.eventCanvasSnapshot: drawingController.onCanvasSnapshot,
        SupabaseConstants.eventChatMessage: chatController.onRemoteMessage,
      },
    );
    await _realtimeProvider.subscribeGameChannel();
  }

  // --- Event Handlers ---

  void _onTurnStart(Map<String, dynamic> data) {
    final drawerId = data['drawer_id'] as String? ?? '';
    final drawerName = data['drawer_name'] as String? ?? '';
    final round = (data['round'] as num?)?.toInt() ?? 1;
    final turn = (data['turn'] as num?)?.toInt() ?? 1;
    final wLength = (data['word_length'] as num?)?.toInt() ?? 0;
    final choices = (data['word_choices'] as List?)?.cast<String>() ?? [];

    // Ignore stale/duplicate turn_start for the same round+turn we're already in
    if (round == currentRound.value &&
        turn == currentTurnInRound.value &&
        (phase.value == GamePhase.drawing || _wordAlreadySelected)) {
      return;
    }

    // Ignore broadcasts with empty drawer_id (malformed)
    if (drawerId.isEmpty) {
      return;
    }

    currentDrawerId.value = drawerId;
    currentDrawerName.value = drawerName;
    currentRound.value = round;
    currentTurnInRound.value = turn;
    wordLength.value = wLength;
    correctGuessCount.value = 0;
    hasGuessedCorrectly.value = false;
    revealedWord.value = '';
    turnScores.clear();
    _firstHintSent = false;
    _secondHintSent = false;
    _wordAlreadySelected = false;
    _cancelRecovery();

    isDrawer.value = drawerId == playerId;
    drawingController.resetCanvas();
    drawingController.isEnabled.value = isDrawer.value;
    chatController.clearMessages();
    chatController.isGuessLocked.value = false;

    phase.value = GamePhase.wordSelection;

    if (isDrawer.value && choices.isNotEmpty) {
      wordChoices.value = choices;
    } else {
      wordChoices.clear();
      wordHint.value = HintUtils.generateBlankHint('?' * wLength);
    }

    _startWordSelectionTimer();

    chatController.addSystemMessage(
      '$drawerName is drawing!',
    );
  }

  void _onWordSelected(Map<String, dynamic> data) {
    _stopWordSelectionTimer();
    final wLength = (data['word_length'] as num?)?.toInt() ?? wordLength.value;
    final hint = data['hint'] as String? ?? '';
    final endsAt = data['ends_at'] as String?;

    wordLength.value = wLength;
    wordHint.value = hint;
    phase.value = GamePhase.drawing;
    wordChoices.clear();
    drawingController.isEnabled.value = isDrawer.value;

    if (isDrawer.value) {
      currentWord.value = data['word'] as String? ?? currentWord.value;
    }

    if (endsAt != null) {
      _turnEndsAt = DateTime.parse(endsAt);
    }
    _startCountdown();
  }

  void _onHintUpdate(Map<String, dynamic> data) {
    wordHint.value = data['hint'] as String? ?? wordHint.value;
  }

  void _onCorrectGuess(Map<String, dynamic> data) {
    final guesserId = data['player_id'] as String? ?? '';
    final name = data['display_name'] as String? ?? '';
    final score = (data['score'] as num?)?.toInt() ?? 0;

    correctGuessCount.value++;

    if (guesserId == playerId) {
      hasGuessedCorrectly.value = true;
      chatController.isGuessLocked.value = true;
    }

    // Update player score locally
    final idx = players.indexWhere((p) => p.playerId == guesserId);
    if (idx >= 0) {
      players[idx] = players[idx].copyWith(
        score: players[idx].score + score,
        hasGuessed: true,
      );
    }

    chatController.addCorrectGuessMessage(name, score);
  }

  void _onCloseGuess(Map<String, dynamic> data) {
    final name = data['display_name'] as String? ?? '';
    chatController.addCloseGuessMessage(name);
  }

  void _onWrongGuess(Map<String, dynamic> data) {
    final name = data['display_name'] as String? ?? '';
    final text = data['text'] as String? ?? '';
    chatController.addGuessMessage(name, text);
  }

  void _onTurnEnd(Map<String, dynamic> data) {
    _stopCountdown();
    phase.value = GamePhase.turnReveal;
    revealedWord.value = data['word'] as String? ?? '';
    currentWord.value = '';
    wordChoices.clear();
    isDrawer.value = false;
    drawingController.isEnabled.value = false;

    final scores = data['scores'] as List?;
    if (scores != null) {
      turnScores.value = scores.cast<Map<String, dynamic>>();

      // Sync local player scores from authoritative server data
      for (final scoreEntry in turnScores) {
        final pid = scoreEntry['player_id'] as String?;
        final serverScore = (scoreEntry['score'] as num?)?.toInt();
        if (pid == null || serverScore == null) continue;
        final idx = players.indexWhere((p) => p.playerId == pid);
        if (idx >= 0) {
          players[idx] = players[idx].copyWith(score: serverScore);
        }
      }
    }

    chatController.addSystemMessage(
      'The word was: ${revealedWord.value}',
    );

    // Schedule recovery in case next turn_start broadcast is missed
    _scheduleRecovery();
  }

  void _onRoundEnd(Map<String, dynamic> data) {
    phase.value = GamePhase.roundScores;
    final roundWinner = data['round_winner_id'] as String?;
    if (roundWinner != null) {
      final winnerPlayer = players.firstWhereOrNull(
        (p) => p.playerId == roundWinner,
      );
      if (winnerPlayer != null) {
        chatController.addSystemMessage(
          '${winnerPlayer.displayName} won this round!',
        );
      }
    }
    _fetchPlayers(); // Refresh scores and rounds_won from DB
  }

  void _onGameOver(Map<String, dynamic> data) {
    _stopCountdown();
    phase.value = GamePhase.gameOver;
    _fetchPlayers();

    final winnerName = data['winner_name'] as String? ?? 'Someone';
    chatController.addSystemMessage('Game Over! $winnerName wins!');
  }

  void _onGameReset(Map<String, dynamic> data) {
    _cancelRecovery();
    phase.value = GamePhase.wordSelection;
    currentRound.value = 0;
    currentTurnInRound.value = 0;
    currentWord.value = '';
    wordHint.value = '';
    correctGuessCount.value = 0;
    hasGuessedCorrectly.value = false;
    drawingController.resetCanvas();
    chatController.clearMessages();
    Get.offAllNamed(AppRoutes.room, arguments: {'room_id': roomId});
  }

  // --- Broadcast Recovery ---

  void _scheduleRecovery() {
    _cancelRecovery();
    _recoveryTimer = Timer(const Duration(seconds: 10), () {
      if (phase.value == GamePhase.turnReveal ||
          phase.value == GamePhase.roundScores) {
        // Should have received next turn_start by now — re-sync from DB
        _recoverFromMissedBroadcast();
      }
    });
  }

  void _cancelRecovery() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  Future<void> _recoverFromMissedBroadcast() async {
    await _fetchRoom();
    await _fetchPlayers();
    await _initializeFromRoom();
  }

  // --- Actions ---

  Future<void> selectWord(String word) async {
    if (!isDrawer.value || _wordAlreadySelected) return;
    final pid = playerId;
    if (pid == null) return;
    _wordAlreadySelected = true;
    _stopWordSelectionTimer();
    currentWord.value = word;
    phase.value = GamePhase.drawing;
    wordChoices.clear();
    drawingController.isEnabled.value = true;

    // Start local timer immediately (server will correct via broadcast)
    _turnEndsAt = DateTime.now().add(Duration(seconds: totalTurnSeconds.value));
    _startCountdown();
    try {
      await _gameProvider.selectWord(
        roomId: roomId,
        playerId: pid,
        word: word,
      );
    } catch (e) {
      // Rollback optimistic update on failure
      _wordAlreadySelected = false;
      currentWord.value = '';
      phase.value = GamePhase.wordSelection;
      drawingController.isEnabled.value = false;
      _stopCountdown();
      Get.snackbar('Error', 'Failed to select word. Please try again.');
    }
  }

  Future<void> skipTurn() async {
    if (!isDrawer.value || _wordAlreadySelected) return;
    final pid = playerId;
    if (pid == null) return;
    _wordAlreadySelected = true;
    try {
      await _gameProvider.skipTurn(
        roomId: roomId,
        playerId: pid,
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to skip turn');
    }
  }

  Future<void> submitGuess(String guess) async {
    if (isDrawer.value || hasGuessedCorrectly.value) return;
    if (guess.trim().isEmpty) return;
    final pid = playerId;
    if (pid == null) return;

    try {
      await _gameProvider.submitGuess(
        roomId: roomId,
        playerId: pid,
        guess: guess.trim(),
      );
    } catch (_) {
      // Silently fail — guess broadcast handles UI
    }
  }

  Future<void> requestHint() async {
    if (!isDrawer.value) return;
    final pid = playerId;
    if (pid == null) return;
    try {
      await _gameProvider.requestHint(roomId: roomId, playerId: pid);
    } catch (_) {}
  }

  Future<void> endTurn() async {
    final pid = playerId;
    if (pid == null) return;
    try {
      await _gameProvider.endTurn(roomId: roomId, playerId: pid);
    } catch (_) {}
  }

  Future<void> playAgain() async {
    if (!isHost.value) return;
    final pid = playerId;
    if (pid == null) return;
    try {
      await _gameProvider.playAgain(roomId: roomId, playerId: pid);
    } catch (e) {
      Get.snackbar('Error', 'Failed to restart');
    }
  }

  Future<void> leaveGame() async {
    final pid = playerId;
    if (pid == null) return;
    try {
      await _roomProvider.leaveRoom(roomId: roomId, playerId: pid);
    } catch (e) {
      debugPrint('Error leaving room: $e');
    }
    Get.offAllNamed(AppRoutes.lobby);
  }

  // --- Timer ---

  void _startCountdown() {
    _stopCountdown();
    _updateRemainingTime();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateRemainingTime(),
    );
  }

  void _updateRemainingTime() {
    if (_turnEndsAt == null) return;
    final diff = _turnEndsAt!.difference(DateTime.now()).inSeconds;
    remainingSeconds.value = diff.clamp(0, totalTurnSeconds.value);

    if (diff <= 0) {
      _stopCountdown();
      // Only the drawer triggers end_turn to avoid duplicate calls from all clients
      if (isDrawer.value) {
        endTurn();
      }
    }

    // Request hints at threshold times (drawer only)
    if (isDrawer.value && totalTurnSeconds.value > 0) {
      final elapsed = totalTurnSeconds.value - remainingSeconds.value;
      final ratio = elapsed / totalTurnSeconds.value;
      if (ratio >= GameConstants.firstHintAt && !_firstHintSent) {
        _firstHintSent = true;
        requestHint().catchError((_) {
          _firstHintSent = false;
        });
      } else if (ratio >= GameConstants.secondHintAt && !_secondHintSent) {
        _secondHintSent = true;
        requestHint().catchError((_) {
          _secondHintSent = false;
        });
      }
    }
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  // --- Word Selection Timer ---

  void _startWordSelectionTimer() {
    _stopWordSelectionTimer();
    wordSelectionRemaining.value = wordSelectionDuration;
    remainingSeconds.value = wordSelectionDuration;
    _wordSelectionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        wordSelectionRemaining.value--;
        remainingSeconds.value = wordSelectionRemaining.value;
        if (wordSelectionRemaining.value <= 0) {
          _stopWordSelectionTimer();
          // Skip turn if drawer didn't pick a word
          if (isDrawer.value) {
            skipTurn();
          }
        }
      },
    );
  }

  void _stopWordSelectionTimer() {
    _wordSelectionTimer?.cancel();
    _wordSelectionTimer = null;
    wordSelectionRemaining.value = 0;
  }

  @override
  void onClose() {
    _stopCountdown();
    _stopWordSelectionTimer();
    _cancelRecovery();
    _realtimeProvider.disposeGameChannel().catchError((_) {});
    super.onClose();
  }
}
