import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/enums/message_type.dart';
import '../../data/models/chat_message_model.dart';

class ChatController extends GetxController {
  final RxList<ChatMessageModel> messages = <ChatMessageModel>[].obs;
  final RxBool isGuessLocked = false.obs;
  final textController = TextEditingController();
  final scrollController = ScrollController();

  // Rate limiting
  final List<DateTime> _guessTimestamps = [];
  static const int _maxGuessesPerWindow = 3;
  static const int _windowMs = 2000;

  bool get canGuess {
    _guessTimestamps.removeWhere(
      (t) => DateTime.now().difference(t).inMilliseconds > _windowMs,
    );
    return _guessTimestamps.length < _maxGuessesPerWindow;
  }

  void addMessage(ChatMessageModel message) {
    messages.add(message);
    _scrollToBottom();
  }

  void addSystemMessage(String content) {
    addMessage(ChatMessageModel.system(content));
  }

  void addCorrectGuessMessage(String playerName, int score) {
    addMessage(ChatMessageModel.correctGuess(playerName, score));
  }

  void addCloseGuessMessage(String playerName) {
    addMessage(ChatMessageModel.closeGuess(playerName));
  }

  void addGuessMessage(String playerName, String text) {
    addMessage(ChatMessageModel(
      type: MessageType.guess,
      playerName: playerName,
      content: text,
    ));
  }

  void onRemoteMessage(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'chat';
    final name = data['player_name'] as String? ?? '';
    final content = data['content'] as String? ?? '';

    addMessage(ChatMessageModel(
      type: MessageType.fromString(type),
      playerName: name,
      content: content,
    ));
  }

  void clearMessages() {
    messages.clear();
  }

  void recordGuessAttempt() {
    _guessTimestamps.add(DateTime.now());
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
