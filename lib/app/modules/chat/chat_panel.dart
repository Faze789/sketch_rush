import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/enums/message_type.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/chat_message_model.dart';
import '../game/game_controller.dart';
import 'chat_controller.dart';

class ChatPanel extends StatelessWidget {
  const ChatPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final chatController = Get.find<ChatController>();
    final gameController = Get.find<GameController>();

    return Column(
      children: [
        // Message list
        Expanded(
          child: Obx(() => ListView.builder(
                controller: chatController.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: chatController.messages.length,
                itemBuilder: (context, index) {
                  return _MessageBubble(
                    message: chatController.messages[index],
                  );
                },
              )),
        ),

        // Input bar — SafeArea prevents overlap with system navigation buttons
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Obx(() {
              final isDrawer = gameController.isDrawer.value;
              final isLocked = chatController.isGuessLocked.value;

              return Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: chatController.textController,
                      enabled: !isDrawer && !isLocked,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: isDrawer
                            ? 'You are drawing...'
                            : isLocked
                                ? 'You guessed correctly!'
                                : 'Type your guess...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        isDense: true,
                      ),
                      onSubmitted: (value) => _submitGuess(
                        chatController,
                        gameController,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: isDrawer || isLocked
                        ? null
                        : () => _submitGuess(chatController, gameController),
                    icon: const Icon(Icons.send_rounded),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _submitGuess(
    ChatController chatController,
    GameController gameController,
  ) {
    final text = chatController.textController.text.trim();
    if (text.isEmpty) return;
    if (!chatController.canGuess) return;

    chatController.recordGuessAttempt();
    chatController.textController.clear();
    gameController.submitGuess(text);
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessageModel message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case MessageType.system:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Center(
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.systemMessage,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        );

      case MessageType.correct:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.correctGuessMsg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.correctGuessMsg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

      case MessageType.closeGuess:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.closeGuessMsg.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.closeGuessMsg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );

      case MessageType.guess:
      case MessageType.chat:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: Colors.black87),
              children: [
                TextSpan(
                  text: '${message.playerName ?? 'Player'}: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: message.content),
              ],
            ),
          ),
        );
    }
  }
}
