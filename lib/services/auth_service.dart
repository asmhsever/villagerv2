import 'package:fullproject/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fullproject/config/supabase_config.dart';

class AuthService {
  static final _client = SupabaseConfig.client;

  // Login method (username/password based)
  static Future<Map<String, dynamic>> login(
    String username,
    String password,
  ) async {
    try {
      // Query admin table directly with username and password
      print(username + password);
      final response = await _client
          .from('users')
          .select('*')
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();
      print(response);
      if (response != null) {
        final model = UserModel.fromJson(response);

        // Save login session
        await _saveLoginSession(model);

        return {
          'success': true,
          'role': response['role'],
          'message': 'เข้าสู่ระบบสำเร็จ',
        };
      } else {
        return {
          'success': false,
          'message': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'เกิดข้อผิดพลาด: ${e.toString()}'};
    }
  }

  // Save login session
  static Future<void> _saveLoginSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.userId);
    await prefs.setString('username', user.username);
    await prefs.setString('role', user.role);
    await prefs.setBool('is_logged_in', true);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Get current admin
  static Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

    if (isLoggedIn) {
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username');
      final role = prefs.getString('role');
      if (userId != null && username != null && role != null) {
        return UserModel(
          userId: userId,
          username: username,
          role: role,
          password: '', // Don't store password in session
        );
      }
    }
    return null;
  }

  // Get admin by ID
  static Future<UserModel?> getUserById(int userId) async {
    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return UserModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error getting admin: $e');
      return null;
    }
  }

  // Check if username exists
  static Future<bool> usernameExists(String username) async {
    try {
      final response = await _client
          .from('users')
          .select('user_id')
          .eq('username', username)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
