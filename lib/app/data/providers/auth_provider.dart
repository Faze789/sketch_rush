import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_provider.dart';

class AuthProvider {
  Future<AuthResponse> signInAnonymously(String displayName) async {
    return await SupabaseProvider.auth.signInAnonymously(
      data: {'display_name': displayName},
    );
  }

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
}
