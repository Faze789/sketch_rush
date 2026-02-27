import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/enums/game_phase.dart';
import '../../core/theme/app_colors.dart';
import '../chat/chat_panel.dart';
import 'game_controller.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/game_over_screen.dart';
import 'widgets/timer_widget.dart';
import 'widgets/tool_bar.dart';
import 'widgets/turn_scoreboard.dart';
import 'widgets/word_hint_display.dart';
import 'widgets/word_selection_overlay.dart';

class GameView extends GetView<GameController> {
  const GameView({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showLeaveDialog(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Obx(() => Text(
                'Round ${controller.currentRound.value}/${controller.totalRounds.value}',
              )),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showLeaveDialog(context),
          ),
          actions: [
            // Timer
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: TimerWidget(),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            if (isWide) {
              return _buildWideLayout(context);
            } else {
              return _buildNarrowLayout(context);
            }
          },
        ),
      ),
    );
  }

  /// Desktop/tablet: canvas left, chat right
  Widget _buildWideLayout(BuildContext context) {
    return Stack(
      children: [
        Row(
          children: [
            // Canvas area
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Header: drawer name + word hint
                  _buildGameHeader(),
                  // Canvas
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: DrawingCanvas(),
                    ),
                  ),
                  // Toolbar
                  const Padding(
                    padding: EdgeInsets.only(left: 12, right: 12, bottom: 12),
                    child: ToolBar(),
                  ),
                ],
              ),
            ),
            // Chat panel
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Column(
                children: [
                  // Players list header
                  _buildPlayersBar(),
                  // Chat
                  const Expanded(child: ChatPanel()),
                ],
              ),
            ),
          ],
        ),
        // Overlays
        _buildOverlays(),
      ],
    );
  }

  /// Mobile: canvas top, chat bottom
  Widget _buildNarrowLayout(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            // Header
            _buildGameHeader(),
            // Canvas
            const Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: DrawingCanvas(),
              ),
            ),
            // Toolbar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ToolBar(),
            ),
            // Players bar
            _buildPlayersBar(),
            // Chat
            const Expanded(
              flex: 2,
              child: ChatPanel(),
            ),
          ],
        ),
        _buildOverlays(),
      ],
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: AppColors.primary.withValues(alpha: 0.03),
      child: Row(
        children: [
          Obx(() {
            if (controller.isDrawer.value) {
              return const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.brush, size: 16, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text(
                    'Draw!',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ],
              );
            } else {
              return Flexible(
                flex: 0,
                child: Text(
                  '${controller.currentDrawerName.value.isNotEmpty ? controller.currentDrawerName.value : 'Someone'} is drawing',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }
          }),
          const SizedBox(width: 8),
          const Expanded(child: WordHintDisplay()),
        ],
      ),
    );
  }

  Widget _buildPlayersBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Obx(() {
        final sorted = List.of(controller.players)
          ..sort((a, b) => b.score.compareTo(a.score));

        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: sorted.length,
          separatorBuilder: (_, _) => const SizedBox(width: 4),
          itemBuilder: (context, index) {
            final player = sorted[index];
            final isDrawer =
                player.playerId == controller.currentDrawerId.value;
            final hasGuessed = player.hasGuessed;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDrawer
                    ? AppColors.accent.withValues(alpha: 0.1)
                    : hasGuessed
                        ? AppColors.correct.withValues(alpha: 0.1)
                        : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDrawer)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child:
                          Icon(Icons.brush, size: 14, color: AppColors.accent),
                    ),
                  if (hasGuessed)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle,
                          size: 14, color: AppColors.correct),
                    ),
                  Text(
                    player.displayName,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${player.score}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildOverlays() {
    return Obx(() {
      switch (controller.phase.value) {
        case GamePhase.wordSelection:
          if (controller.isDrawer.value &&
              controller.wordChoices.isNotEmpty) {
            return const WordSelectionOverlay();
          }
          return const SizedBox.shrink();
        case GamePhase.turnReveal:
        case GamePhase.roundScores:
          return const TurnScoreboard();
        case GamePhase.gameOver:
          return const GameOverScreen();
        case GamePhase.drawing:
          return const SizedBox.shrink();
      }
    });
  }

  void _showLeaveDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave Game?'),
        content:
            const Text('You will lose your progress if you leave the game.'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.leaveGame();
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.wrong)),
          ),
        ],
      ),
    );
  }
}
