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
}
