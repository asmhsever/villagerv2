import 'package:fullproject/models/house_model.dart';
import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    switch (user.role) {
      case 'admin':
        await prefs.setInt('user_id', user.userId);
        await prefs.setString('role', user.role);
        await prefs.setBool('is_logged_in', true);
        await prefs.setString('username', user.username);
        break;
      case 'law':
        await prefs.setInt('user_id', user.userId);
        await prefs.setString('role', user.role);
        await prefs.setBool('is_logged_in', true);
        final response = await _client
            .from('law')
            .select('*')
            .eq('user_id', user.userId)
            .maybeSingle();
        if (response != null) {
          final model = LawModel.fromJson(response);
          await prefs.setInt('law_id', model.lawId);
          await prefs.setInt('village_id', model.villageId);
          await prefs.setString('first_name', model.firstName ?? '');
        }
        //lawid villageid userid? first_name
        break;
      case 'house':
        await prefs.setInt('user_id', user.userId);
        await prefs.setString('role', user.role);
        await prefs.setBool('is_logged_in', true);
        final response = await _client
            .from('house')
            .select('*')
            .eq('user_id', user.userId)
            .maybeSingle();
        if (response != null) {
          final model = HouseModel.fromJson(response);
          await prefs.setInt('house_id', model.houseId);
          await prefs.setInt('village_id', model.villageId);
          await prefs.setString('owner', model.owner ?? '');
          await prefs.setString('house_number', model.houseNumber ?? '');
        }
        break;
      default:
        break;
    }
  }

  // Check if user is logged in
  static Future<Map<String, dynamic>> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role');
    final isLogin = prefs.getBool('is_logged_in') ?? false;
    return {'role': role, 'is_logged_in': isLogin};
  }

  // Get current user
  static Future<dynamic> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    if (isLoggedIn) {
      final userId = prefs.getInt('user_id');
      final username = prefs.getString('username');
      final role = prefs.getString('role');

      switch (role) {
        case 'admin':
          return UserModel(
            userId: userId ?? 0,
            username: username ?? "",
            password: "password",
            role: role ?? "",
          );
          break;
        case 'law':
          final villageId = prefs.getInt('village_id');
          final lawId = prefs.getInt('law_id');
          final firstName = prefs.getString('first_name');
          return LawModel(
            lawId: lawId ?? 0,
            villageId: villageId ?? 0,
            userId: userId ?? 0,
            firstName: firstName ?? "",
          );
          break;
        case 'house':
          final villageId = prefs.getInt('village_id');
          final houseId = prefs.getInt('house_id');
          final owner = prefs.getString('owner');
          final houseNumber = prefs.getString('house_number');
          return HouseModel(
            houseId: houseId ?? 0,
            villageId: villageId ?? 0,
            userId: userId ?? 0,
            owner: owner ?? "",
            houseNumber: houseNumber ?? "",
          );
          break;
        default:
          break;
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
