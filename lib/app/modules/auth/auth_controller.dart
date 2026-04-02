import 'dart:async';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import '../../data/providers/auth_provider.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
  final AuthProvider _authProvider = Get.find<AuthProvider>();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxString displayName = ''.obs;
  final RxInt avatarIndex = 0.obs;
  final RxString avatarColor = '#6C5CE7'.obs;
  final RxBool isLoading = false.obs;
  final RxBool isAuthenticated = false.obs;

  StreamSubscription<AuthState>? _authSub;

  String? get userId => currentUser.value?.id;

  @override
  void onInit() {
    super.onInit();
    _listenAuthState();
    _restorePreferences();
  }

  void _listenAuthState() {
    // Set initial state synchronously from current session
    currentUser.value = _authProvider.currentUser;
    isAuthenticated.value = _authProvider.isAuthenticated;
    _subscribeAuth();
  }

  void _subscribeAuth() {
    _authSub?.cancel();
    _authSub = _authProvider.authStateChanges.listen((authState) {
      currentUser.value = authState.session?.user;
      isAuthenticated.value = authState.session?.user != null;
    }, onError: (_) {});
  }

  /// Re-sync auth state from the current Supabase session.
  /// Called on hot restart via splash to handle stale stream subscriptions
  /// (web hot restart creates a new Supabase client, invalidating old streams).
  void refreshAuthState() {
    currentUser.value = _authProvider.currentUser;
    isAuthenticated.value = _authProvider.isAuthenticated;
    _subscribeAuth();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  Future<void> _restorePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    displayName.value = prefs.getString(AppConstants.keyDisplayName) ?? '';
    avatarIndex.value = prefs.getInt(AppConstants.keyAvatarIndex) ?? 0;
    avatarColor.value =
        prefs.getString(AppConstants.keyAvatarColor) ?? '#6C5CE7';
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyDisplayName, displayName.value);
    await prefs.setInt(AppConstants.keyAvatarIndex, avatarIndex.value);
    await prefs.setString(AppConstants.keyAvatarColor, avatarColor.value);
  }

  // --- Input Validation ---

  /// Returns null if valid, or an error message string.
  String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!GetUtils.isEmail(email.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirm != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? validateDisplayName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Display name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (name.trim().length > 20) {
      return 'Name must be 20 characters or less';
    }
    return null;
  }

  // --- Anonymous Sign In ---

  Future<bool> signInAnonymously({
    required String name,
    int? avatar,
    String? color,
  }) async {
    try {
      isLoading.value = true;
      displayName.value = name;
      if (avatar != null) avatarIndex.value = avatar;
      if (color != null) avatarColor.value = color;

      await _authProvider.signInAnonymously(name);
      await _savePreferences();

      // Update player profile with avatar info
      await _authProvider.updatePlayerProfile(
        displayName: name,
        avatarIndex: avatarIndex.value,
        avatarColor: avatarColor.value,
      );

      return true;
    } catch (e) {
      Get.snackbar('Error', 'Failed to sign in: ${e.toString()}');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Email/Password Sign Up ---

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    int? avatar,
    String? color,
  }) async {
    try {
      isLoading.value = true;
      displayName.value = name;
      if (avatar != null) avatarIndex.value = avatar;
      if (color != null) avatarColor.value = color;

      final response = await _authProvider.signUpWithEmail(
        email: email.trim(),
        password: password,
        displayName: name,
      );

      if (response.user == null) {
        Get.snackbar('Error', 'Sign up failed. Please try again.');
        return false;
      }

      await _savePreferences();

      // Create player profile
      await _authProvider.ensurePlayerProfile(
        displayName: name,
        avatarIndex: avatarIndex.value,
        avatarColor: avatarColor.value,
      );

      return true;
    } on AuthException catch (e) {
      Get.snackbar('Sign Up Failed', e.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Email/Password Sign In ---

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final response = await _authProvider.signInWithEmail(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        Get.snackbar('Error', 'Sign in failed. Please try again.');
        return false;
      }

      // Restore display name from user metadata
      final metadata = response.user!.userMetadata;
      final name = metadata?['display_name'] as String? ?? '';
      if (name.isNotEmpty) {
        displayName.value = name;
      }

      await _savePreferences();

      // Ensure player profile exists (first login on new device)
      if (displayName.value.isNotEmpty) {
        await _authProvider.ensurePlayerProfile(
          displayName: displayName.value,
          avatarIndex: avatarIndex.value,
          avatarColor: avatarColor.value,
        );
      }

      return true;
    } on AuthException catch (e) {
      Get.snackbar('Sign In Failed', e.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Forgot Password ---

  Future<bool> resetPassword(String email) async {
    try {
      isLoading.value = true;
      await _authProvider.resetPassword(email.trim());
      return true;
    } on AuthException catch (e) {
      Get.snackbar('Error', e.message);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to send reset email.');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // --- Profile Update ---

  Future<void> updateProfile({String? name, int? avatar, String? color}) async {
    try {
      if (name != null) displayName.value = name;
      if (avatar != null) avatarIndex.value = avatar;
      if (color != null) avatarColor.value = color;

      await _authProvider.updatePlayerProfile(
        displayName: displayName.value,
        avatarIndex: avatarIndex.value,
        avatarColor: avatarColor.value,
      );
      await _savePreferences();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: ${e.toString()}');
    }
  }

  // --- Sign Out ---

  Future<void> signOut() async {
    await _authProvider.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    displayName.value = '';
    Get.offAllNamed(AppRoutes.auth);
  }

  /// Check if session is valid and navigate accordingly
  Future<void> checkSessionAndNavigate() async {
    if (isAuthenticated.value && displayName.value.isNotEmpty) {
      Get.offAllNamed(AppRoutes.lobby);
    } else {
      Get.offAllNamed(AppRoutes.auth);
    }
  }
}
