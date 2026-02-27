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
