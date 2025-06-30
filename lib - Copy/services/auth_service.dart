
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    return await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  User? get currentUser => supabase.auth.currentUser;
}
Future<String?> getRole() async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  final response = await Supabase.instance.client
      .from('users')
      .select('role')
      .eq('id', uid)
      .single();
  return response['role'] as String?;
}

