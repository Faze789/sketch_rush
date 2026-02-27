import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/game_constants.dart';
import '../lobby_controller.dart';

class CreateRoomDialog extends GetView<LobbyController> {
  const CreateRoomDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(text: 'SketchRush Room');
    final maxPlayers = GameConstants.defaultMaxPlayers.obs;
    final totalRounds = GameConstants.defaultTotalRounds.obs;
    final turnDuration = GameConstants.defaultTurnDuration.obs;
    final difficulty = 'medium'.obs;
    final isPublic = true.obs;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Create Room',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 20),

            // Room name
            TextField(
              controller: nameController,
              maxLength: 30,
              decoration: const InputDecoration(
                labelText: 'Room Name',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),

            // Max players
            Obx(() => _buildSlider(
                  context: context,
                  label: 'Max Players',
                  value: maxPlayers.value.toDouble(),
                  min: GameConstants.minPlayers.toDouble(),
                  max: GameConstants.maxPlayers.toDouble(),
                  divisions: GameConstants.maxPlayers - GameConstants.minPlayers,
                  displayValue: '${maxPlayers.value}',
                  onChanged: (v) => maxPlayers.value = v.round(),
                )),
            const SizedBox(height: 8),

            // Rounds
            Obx(() => _buildSlider(
                  context: context,
                  label: 'Rounds',
                  value: totalRounds.value.toDouble(),
                  min: GameConstants.minRounds.toDouble(),
                  max: GameConstants.maxRounds.toDouble(),
                  divisions: GameConstants.maxRounds - GameConstants.minRounds,
                  displayValue: '${totalRounds.value}',
                  onChanged: (v) => totalRounds.value = v.round(),
                )),
            const SizedBox(height: 8),

            // Turn duration
            Obx(() => _buildSlider(
                  context: context,
                  label: 'Turn Duration',
                  value: turnDuration.value.toDouble(),
                  min: GameConstants.minTurnDuration.toDouble(),
                  max: GameConstants.maxTurnDuration.toDouble(),
                  divisions: (GameConstants.maxTurnDuration -
                          GameConstants.minTurnDuration) ~/
                      10,
                  displayValue: '${turnDuration.value}s',
                  onChanged: (v) => turnDuration.value = (v / 10).round() * 10,
                )),
            const SizedBox(height: 12),

            // Difficulty
            Obx(() => Row(
                  children: [
                    Text('Difficulty: ',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Easy'),
                      selected: difficulty.value == 'easy',
                      onSelected: (_) => difficulty.value = 'easy',
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Medium'),
                      selected: difficulty.value == 'medium',
                      onSelected: (_) => difficulty.value = 'medium',
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Hard'),
                      selected: difficulty.value == 'hard',
                      onSelected: (_) => difficulty.value = 'hard',
                    ),
                  ],
                )),
            const SizedBox(height: 12),

            // Public toggle
            Obx(() => SwitchListTile(
                  title: const Text('Public Room'),
                  subtitle: Text(
                    isPublic.value
                        ? 'Anyone can join from the lobby'
                        : 'Only accessible via room code',
                  ),
                  value: isPublic.value,
                  onChanged: (v) => isPublic.value = v,
                  contentPadding: EdgeInsets.zero,
                )),
            const SizedBox(height: 20),

            // Create button
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isCreating.value
                        ? null
                        : () {
                            Get.back();
                            controller.createRoom(
                              roomName: nameController.text.trim().isEmpty
                                  ? 'SketchRush Room'
                                  : nameController.text.trim(),
                              maxPlayers: maxPlayers.value,
                              totalRounds: totalRounds.value,
                              turnDuration: turnDuration.value,
                              difficulty: difficulty.value,
                              isPublic: isPublic.value,
                            );
                          },
                    child: controller.isCreating.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Create Room'),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 40,
          child: Text(
            displayValue,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
