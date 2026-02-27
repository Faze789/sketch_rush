import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../drawing_controller.dart';
import '../game_controller.dart';

class ToolBar extends StatelessWidget {
  const ToolBar({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DrawingController>();
    final gameController = Get.find<GameController>();

    return Obx(() {
      final isDrawer = gameController.isDrawer.value;
      final isEnabled = controller.isEnabled.value;
      // Touch phase observable so Obx rebuilds on phase changes
      gameController.phase.value;
      // Show toolbar when player is drawer and in a drawable phase
      if (!isDrawer && !isEnabled) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Color palette
            SizedBox(
              height: 32,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: AppColors.drawingPalette.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, index) {
                  final color = AppColors.drawingPalette[index];
                  return Obx(() => GestureDetector(
                        onTap: () => controller.setColor(color),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: controller.selectedColor.value == color &&
                                    !controller.isEraser.value &&
                                    !controller.isFillMode.value
                                ? Border.all(color: AppColors.primary, width: 3)
                                : Border.all(
                                    color: Colors.grey.shade300, width: 1),
                          ),
                        ),
                      ));
                },
              ),
            ),
            const SizedBox(height: 8),

            // Tools row (scrollable for narrow screens)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pen tool
                  Obx(() => _toolButton(
                        icon: Icons.edit,
                        isActive: !controller.isEraser.value &&
                            !controller.isFillMode.value,
                        onTap: () {
                          controller.isEraser.value = false;
                          controller.isFillMode.value = false;
                        },
                        tooltip: 'Pen',
                      )),

                  // Fill tool
                  Obx(() => _toolButton(
                        icon: Icons.format_color_fill,
                        isActive: controller.isFillMode.value,
                        onTap: controller.toggleFillMode,
                        tooltip: 'Fill',
                      )),

                  const SizedBox(width: 4),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  const SizedBox(width: 4),

                  // Brush sizes
                  ...AppColors.brushSizes.map((size) => Obx(() => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: GestureDetector(
                          onTap: () => controller.setStrokeWidth(size),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: controller.strokeWidth.value == size &&
                                      !controller.isEraser.value &&
                                      !controller.isFillMode.value
                                  ? AppColors.primary.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Container(
                                width: size.clamp(4.0, 20.0),
                                height: size.clamp(4.0, 20.0),
                                decoration: BoxDecoration(
                                  color: controller.selectedColor.value,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ))),

                  const SizedBox(width: 4),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  const SizedBox(width: 4),

                  // Eraser
                  Obx(() => _toolButton(
                        icon: Icons.auto_fix_high,
                        isActive: controller.isEraser.value,
                        onTap: controller.toggleEraser,
                        tooltip: 'Eraser',
                      )),

                  // Undo
                  _toolButton(
                    icon: Icons.undo,
                    onTap: controller.undo,
                    tooltip: 'Undo',
                  ),

                  // Redo
                  _toolButton(
                    icon: Icons.redo,
                    onTap: controller.redo,
                    tooltip: 'Redo',
                  ),

                  // Clear
                  _toolButton(
                    icon: Icons.delete_outline,
                    onTap: controller.clearCanvas,
                    tooltip: 'Clear',
                    color: AppColors.wrong,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _toolButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
    bool isActive = false,
    Color? color,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? (isActive ? AppColors.primary : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}
