import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/user_model.dart';

class UserDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'users';

  static Future<Map<String, dynamic>> create({
    required String usernmae,
    required String password,
    required String role,
    required int villageId,
  }) async {
    try {
      if (usernmae.trim().isEmpty ||
          password.trim().isEmpty ||
          role.trim().isEmpty ||
          villageId.isNaN) {
        return {'success': false, 'message': 'ข้อมูลไม่ครบ'};
      }
      final existing = await _client
          .from(_tableName)
          .select('user_id')
          .eq('usernmae', usernmae.trim())
          .maybeSingle();
      if (existing != null) {
        return {'success': false, 'message': 'มีชื่อนี้แล้ว'};
      }

      final List<Map<String, dynamic>> response =
          await _client.from(_tableName).insert({
            'username': usernmae.trim(),
            'password': password.trim(),
            'role': role.trim(),
            'village_id': villageId,
          }).select();

      if (response.isNotEmpty) {
        return {'success': true, 'message': 'สร้างผู้ใช้สำเร็จ'};
      } else {
        return {'success': false, 'message': 'ไม่สามารถสร้างผู้ใช้ได้'};
      }
    } catch (e) {
      print("Error create user : $e");
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการสร้างผู้ใช้: ${e.toString()}',
      };
    }
  }

  // Read - ดึงข้อมูลผู้ใช้ตาม userId
  static Future<UserModel?> getByUserId(int userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }

  // Read - ดึงข้อมูลผู้ใช้ทั้งหมด
  static Future<List<UserModel>> getAll() async {
    try {
      final response = await _client.from(_tableName).select().order('user_id');

      return response
          .map<UserModel>((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all users: $e');
      return [];
    }
  }

  // Read - ดึงข้อมูลผู้ใช้ตาม villageId
  static Future<List<UserModel>> getByVillageId(int villageId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId);

      return response
          .map<UserModel>((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching users by village ID: $e');
      return [];
    }
  }

  // Update - อัปเดตข้อมูลผู้ใช้
  static Future<Map<String, dynamic>> update({
    required int userId,
    required String username,
    required String password,
    required String role,
    required int villageId,
  }) async {
    try {
      if (username.trim().isEmpty ||
          password.trim().isEmpty ||
          role.trim().isEmpty ||
          villageId.isNaN) {
        return {'success': false, 'message': 'ข้อมูลไม่ครบ'};
      }

      // ตรวจสอบว่า username ซ้ำกับคนอื่นหรือไม่ (ยกเว้นตัวเอง)
      final existing = await _client
          .from(_tableName)
          .select('user_id')
          .eq('username', username.trim())
          .neq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        return {'success': false, 'message': 'มีชื่อผู้ใช้นี้แล้ว'};
      }

      final response = await _client
          .from(_tableName)
          .update({
            'username': username.trim(),
            'password': password.trim(),
            'role': role.trim(),
            'village_id': villageId,
          })
          .eq('user_id', userId)
          .select();

      if (response.isNotEmpty) {
        return {'success': true, 'message': 'อัปเดตผู้ใช้สำเร็จ'};
      } else {
        return {'success': false, 'message': 'ไม่พบผู้ใช้ที่ต้องการอัปเดต'};
      }
    } catch (e) {
      print("Error updating user: $e");
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการอัปเดตผู้ใช้: ${e.toString()}',
      };
    }
  }

  // Delete - ลบผู้ใช้
  static Future<Map<String, dynamic>> delete(int userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
          .select();

      if (response.isNotEmpty) {
        return {'success': true, 'message': 'ลบผู้ใช้สำเร็จ'};
      } else {
        return {'success': false, 'message': 'ไม่พบผู้ใช้ที่ต้องการลบ'};
      }
    } catch (e) {
      print("Error deleting user: $e");
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการลบผู้ใช้: ${e.toString()}',
      };
    }
  }

  // Login - ตรวจสอบการเข้าสู่ระบบ
  static Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return {'success': false, 'message': 'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน'};
      }

      final response = await _client
          .from(_tableName)
          .select()
          .eq('username', username.trim())
          .eq('password', password.trim())
          .maybeSingle();

      if (response != null) {
        final user = UserModel.fromJson(response);
        return {'success': true, 'message': 'เข้าสู่ระบบสำเร็จ', 'user': user};
      } else {
        return {
          'success': false,
          'message': 'ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง',
        };
      }
    } catch (e) {
      print("Error login: $e");
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเข้าสู่ระบบ: ${e.toString()}',
      };
    }
  }
}
