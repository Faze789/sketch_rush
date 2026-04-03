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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: const _AuthPages(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Manages switching between Login, Sign Up, and Forgot Password pages.
class _AuthPages extends StatefulWidget {
  const _AuthPages();

  @override
  State<_AuthPages> createState() => _AuthPagesState();
}

enum _AuthPage { login, signUp, forgotPassword }

class _AuthPagesState extends State<_AuthPages> {
  _AuthPage _currentPage = _AuthPage.login;

  void _navigateTo(_AuthPage page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: switch (_currentPage) {
        _AuthPage.login => _LoginPage(
            key: const ValueKey('login'),
            onSignUp: () => _navigateTo(_AuthPage.signUp),
            onForgotPassword: () => _navigateTo(_AuthPage.forgotPassword),
          ),
        _AuthPage.signUp => _SignUpPage(
            key: const ValueKey('signup'),
            onLogin: () => _navigateTo(_AuthPage.login),
          ),
        _AuthPage.forgotPassword => _ForgotPasswordPage(
            key: const ValueKey('forgot'),
            onBack: () => _navigateTo(_AuthPage.login),
          ),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN PAGE
// ─────────────────────────────────────────────────────────────────────────────

class _LoginPage extends StatefulWidget {
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;

  const _LoginPage({
    super.key,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Form(
      key: _formKey,
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

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: controller.validateEmail,
          ),
          const SizedBox(height: 16),

          // Password
          StatefulBuilder(
            builder: (context, setLocalState) => TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setLocalState(
                      () => _obscurePassword = !_obscurePassword,
                    );
                  },
                ),
              ),
              validator: controller.validatePassword,
              onFieldSubmitted: (_) => _handleLogin(controller),
            ),
          ),
          const SizedBox(height: 8),

          // Forgot Password link
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.onForgotPassword,
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sign In button
          Obx(() => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => _handleLogin(controller),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              )),
          const SizedBox(height: 16),

          // Divider
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),

          // Play as Guest button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _showGuestDialog(context, controller),
              icon: const Icon(Icons.person_outline),
              label: const Text('Play as Guest'),
            ),
          ),
          const SizedBox(height: 20),

          // Sign Up link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.grey[600]),
              ),
              GestureDetector(
                onTap: widget.onSignUp,
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(AuthController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.signInWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (success) {
      Get.offAllNamed(AppRoutes.lobby);
    }
  }

  void _showGuestDialog(BuildContext context, AuthController controller) {
    final nameCtrl = TextEditingController(text: controller.displayName.value);
    final selectedAvatar = controller.avatarIndex.value.obs;
    final selectedColor = controller.avatarColor.value.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Play as Guest',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            Obx(() => AvatarWidget(
                  index: selectedAvatar.value,
                  color: selectedColor.value,
                  size: 64,
                )),
            const SizedBox(height: 12),
            // Color picker
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
                            color: _parseHexColor(color),
                            shape: BoxShape.circle,
                            border: selectedColor.value == color
                                ? Border.all(color: Colors.white, width: 3)
                                : null,
                            boxShadow: selectedColor.value == color
                                ? [
                                    BoxShadow(
                                      color: _parseHexColor(color)
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
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_outline),
                counterText: '',
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            final name = nameCtrl.text.trim();
                            final nameError =
                                controller.validateDisplayName(name);
                            if (nameError != null) {
                              Get.snackbar('Oops', nameError);
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
                        : const Text("Let's Play!"),
                  ),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Color _parseHexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SIGN UP PAGE
// ─────────────────────────────────────────────────────────────────────────────

class _SignUpPage extends StatefulWidget {
  final VoidCallback onLogin;

  const _SignUpPage({super.key, required this.onLogin});

  @override
  State<_SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<_SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late final RxInt _selectedAvatar;
  late final RxString _selectedColor;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthController>();
    _selectedAvatar = auth.avatarIndex.value.obs;
    _selectedColor = auth.avatarColor.value.obs;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          Text(
            'Create Account',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Join the fun!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 28),

          // Avatar preview
          Obx(() => AvatarWidget(
                index: _selectedAvatar.value,
                color: _selectedColor.value,
                size: 72,
              )),
          const SizedBox(height: 12),

          // Avatar color picker
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: AppConstants.defaultAvatarColors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final color = AppConstants.defaultAvatarColors[index];
                return Obx(() => GestureDetector(
                      onTap: () => _selectedColor.value = color,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _parseHexColor(color),
                          shape: BoxShape.circle,
                          border: _selectedColor.value == color
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: _selectedColor.value == color
                              ? [
                                  BoxShadow(
                                    color: _parseHexColor(color)
                                        .withValues(alpha: 0.5),
                                    blurRadius: 6,
                                  )
                                ]
                              : null,
                        ),
                      ),
                    ));
              },
            ),
          ),
          const SizedBox(height: 24),

          // Display Name
          TextFormField(
            controller: _nameController,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'Choose a name',
              prefixIcon: Icon(Icons.person_outline),
              counterText: '',
            ),
            validator: controller.validateDisplayName,
          ),
          const SizedBox(height: 14),

          // Email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: controller.validateEmail,
          ),
          const SizedBox(height: 14),

          // Password
          StatefulBuilder(
            builder: (context, setLocalState) => TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'At least 6 characters',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setLocalState(
                      () => _obscurePassword = !_obscurePassword,
                    );
                  },
                ),
              ),
              validator: controller.validatePassword,
            ),
          ),
          const SizedBox(height: 14),

          // Confirm Password
          StatefulBuilder(
            builder: (context, setLocalState) => TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () {
                    setLocalState(
                      () => _obscureConfirm = !_obscureConfirm,
                    );
                  },
                ),
              ),
              validator: (value) => controller.validateConfirmPassword(
                _passwordController.text,
                value,
              ),
              onFieldSubmitted: (_) => _handleSignUp(controller),
            ),
          ),
          const SizedBox(height: 24),

          // Sign Up button
          Obx(() => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => _handleSignUp(controller),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Create Account'),
                ),
              )),
          const SizedBox(height: 20),

          // Back to login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: TextStyle(color: Colors.grey[600]),
              ),
              GestureDetector(
                onTap: widget.onLogin,
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignUp(AuthController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success = await controller.signUpWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      avatar: _selectedAvatar.value,
      color: _selectedColor.value,
    );
    if (success) {
      Get.offAllNamed(AppRoutes.lobby);
    }
  }

  static Color _parseHexColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD PAGE
// ─────────────────────────────────────────────────────────────────────────────

class _ForgotPasswordPage extends StatefulWidget {
  final VoidCallback onBack;

  const _ForgotPasswordPage({super.key, required this.onBack});

  @override
  State<_ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<_ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();

    if (_emailSent) {
      return _buildSuccessState(context);
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Forgot Password?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter your email and we'll send you a link to reset your password.",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Email input
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your registered email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: controller.validateEmail,
            onFieldSubmitted: (_) => _handleReset(controller),
          ),
          const SizedBox(height: 24),

          // Send Reset Link button
          Obx(() => SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () => _handleReset(controller),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Send Reset Link'),
                ),
              )),
          const SizedBox(height: 20),

          // Back to login
          TextButton.icon(
            onPressed: widget.onBack,
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.correct.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            size: 48,
            color: AppColors.correct,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          'We sent a password reset link to:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _emailController.text.trim(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Check your inbox and follow the link to reset your password.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.onBack,
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleReset(AuthController controller) async {
    if (!_formKey.currentState!.validate()) return;

    final success =
        await controller.resetPassword(_emailController.text.trim());
    if (success) {
      setState(() => _emailSent = true);
    }
  }
}
