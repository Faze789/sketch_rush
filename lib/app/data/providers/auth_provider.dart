import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

class AuthProvider {
  // --- Anonymous Auth ---

  Future<AuthResponse> signInAnonymously(String displayName) async {
    return await SupabaseProvider.auth.signInAnonymously(
      data: {'display_name': displayName},
    );
  }

  // --- Email/Password Auth ---

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await SupabaseProvider.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': displayName},
    );
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await SupabaseProvider.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> resetPassword(String email) async {
    await SupabaseProvider.auth.resetPasswordForEmail(email);
  }

  // --- Session & User ---

  User? get currentUser => SupabaseProvider.auth.currentUser;

  String? get currentUserId => currentUser?.id;

  Session? get currentSession => SupabaseProvider.auth.currentSession;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      SupabaseProvider.auth.onAuthStateChange;

  Future<void> signOut() async {
    await SupabaseProvider.auth.signOut();
  }

  Future<UserResponse> updateUserMetadata(Map<String, dynamic> data) async {
    return await SupabaseProvider.auth.updateUser(
      UserAttributes(data: data),
    );
  }

  Future<void> updatePlayerProfile({
    required String displayName,
    int? avatarIndex,
    String? avatarColor,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final updates = <String, dynamic>{
      'display_name': displayName,
    };
    if (avatarIndex != null) updates['avatar_index'] = avatarIndex;
    if (avatarColor != null) updates['avatar_color'] = avatarColor;

    await SupabaseProvider.from('players').update(updates).eq('id', userId);
  }

  /// Ensure a player row exists for the authenticated user.
  /// Called after sign-up or first email sign-in.
  Future<void> ensurePlayerProfile({
    required String displayName,
    int avatarIndex = 0,
    String avatarColor = '#6C5CE7',
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    await SupabaseProvider.from('players').upsert({
      'id': userId,
      'display_name': displayName,
      'avatar_index': avatarIndex,
      'avatar_color': avatarColor,
    });
  }
}
