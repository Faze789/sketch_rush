import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/avatar_widget.dart';
import 'auth_controller.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = TextEditingController(
      text: controller.displayName.value,
    );
    final selectedAvatar = controller.avatarIndex.value.obs;
    final selectedColor = controller.avatarColor.value.obs;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    'SketchRush',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Draw, Guess, Win!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 40),

                  // Avatar selection
                  Obx(() => AvatarWidget(
                        index: selectedAvatar.value,
                        color: selectedColor.value,
                        size: 80,
                      )),
                  const SizedBox(height: 16),

                  // Color picker row
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemCount: AppConstants.defaultAvatarColors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final color = AppConstants.defaultAvatarColors[index];
                        return Obx(() => GestureDetector(
                              onTap: () => selectedColor.value = color,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(
                                    int.parse(color.replaceFirst('#', '0xFF')),
                                  ),
                                  shape: BoxShape.circle,
                                  border: selectedColor.value == color
                                      ? Border.all(
                                          color: Colors.white, width: 3)
                                      : null,
                                  boxShadow: selectedColor.value == color
                                      ? [
                                          BoxShadow(
                                            color: Color(int.parse(color
                                                    .replaceFirst(
                                                        '#', '0xFF')))
                                                .withValues(alpha: 0.5),
                                            blurRadius: 8,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            ));
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name input
                  TextField(
                    controller: nameController,
                    maxLength: 20,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Play button
                  Obx(() => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () async {
                                  final name = nameController.text.trim();
                                  if (name.isEmpty) {
                                    Get.snackbar(
                                        'Oops', 'Please enter a display name');
                                    return;
                                  }
                                  final success =
                                      await controller.signInAnonymously(
                                    name: name,
                                    avatar: selectedAvatar.value,
                                    color: selectedColor.value,
                                  );
                                  if (success) {
                                    Get.offAllNamed(AppRoutes.lobby);
                                  }
                                },
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text('Let\'s Play!'),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
