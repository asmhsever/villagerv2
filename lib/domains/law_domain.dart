import 'package:fullproject/models/law_model.dart';
import 'package:fullproject/config/supabase_config.dart';

class LawDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'law';
  static const String _usersTableName = 'users';

  // ========== CRUD Operations ==========

  /// ดึงข้อมูล Law ตาม law_id
  static Future<LawModel?> getById(int lawId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .eq('law_id', lawId)
          .maybeSingle();

      if (response == null) return null;
      return LawModel.fromJson(response);
    } catch (e) {
      print('Error getting law by ID: $e');
      return null;
    }
  }

  /// ดึงข้อมูล Law ตาม user_id
  static Future<LawModel?> getByUserId(int userId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return LawModel.fromJson(response);
    } catch (e) {
      print('Error getting law by user ID: $e');
      return null;
    }
  }

  /// ดึงข้อมูล Law ทั้งหมดในหมู่บ้าน
  static Future<List<LawModel>> getAllByVillage(int villageId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .eq('village_id', villageId)
          .order('first_name', ascending: true);

      return response
          .map<LawModel>((json) => LawModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting laws by village: $e');
      return [];
    }
  }

  /// อัปเดตข้อมูลส่วนตัว
  static Future<LawModel?> update({
    required int lawId,
    required LawModel updatedLaw,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .update(updatedLaw.toJson())
          .eq('law_id', lawId)
          .select()
          .single();

      return LawModel.fromJson(response);
    } catch (e) {
      print('Error updating law: $e');
      return null;
    }
  }

  /// อัปเดตเฉพาะข้อมูลพื้นฐาน
  static Future<bool> updateBasicInfo({
    required int lawId,
    required String firstName,
    required String lastName,
    required String phone,
    required String address,
    DateTime? birthDate,
    String? gender,
  }) async {
    try {
      final updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'address': address,
        'birth_date': birthDate?.toIso8601String(),
        'gender': gender,
      };

      await _client
          .from(_tableName)
          .update(updateData)
          .eq('law_id', lawId);

      return true;
    } catch (e) {
      print('Error updating basic info: $e');
      return false;
    }
  }

  /// อัปเดตรูปโปรไฟล์
  static Future<bool> updateProfileImage({
    required int lawId,
    required String imageUrl,
  }) async {
    try {
      await _client
          .from(_tableName)
          .update({'img': imageUrl})
          .eq('law_id', lawId);

      return true;
    } catch (e) {
      print('Error updating profile image: $e');
      return false;
    }
  }

  // ========== Password Management ==========

  /// เปลี่ยนรหัสผ่าน
  static Future<bool> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // ตรวจสอบรหัสผ่านปัจจุบัน
      final isValidCurrent = await validateCurrentPassword(
        userId: userId,
        password: currentPassword,
      );

      if (!isValidCurrent) {
        throw Exception('รหัสผ่านปัจจุบันไม่ถูกต้อง');
      }

      // อัปเดตรหัสผ่านใหม่
      await _client
          .from(_usersTableName)
          .update({'password': newPassword})
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error changing password: $e');
      return false;
    }
  }

  /// ตรวจสอบรหัสผ่านปัจจุบัน
  static Future<bool> validateCurrentPassword({
    required int userId,
    required String password,
  }) async {
    try {
      final response = await _client
          .from(_usersTableName)
          .select('password')
          .eq('user_id', userId)
          .eq('password', password)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error validating password: $e');
      return false;
    }
  }

  /// อัปเดตเวลาเข้าสู่ระบบล่าสุด
  static Future<bool> updateLastLogin(int lawId) async {
    try {
      // Note: ต้องเพิ่มฟิลด์ last_login ในตาราง law ก่อน
      await _client
          .from(_tableName)
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('law_id', lawId);

      return true;
    } catch (e) {
      print('Error updating last login: $e');
      return false;
    }
  }

  // ========== Utility Functions ==========

  /// ตรวจสอบว่าข้อมูลครบหรือไม่
  static Future<Map<String, dynamic>> getProfileCompleteness(int lawId) async {
    try {
      final law = await getById(lawId);
      if (law == null) {
        return {'completed': false, 'percentage': 0, 'missing_fields': []};
      }

      List<String> missingFields = [];
      int totalFields = 7; // จำนวนฟิลด์ที่สำคัญ
      int completedFields = 0;

      // ตรวจสอบแต่ละฟิลด์
      if (law.firstName != null && law.firstName!.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('ชื่อจริง');
      }

      if (law.lastName != null && law.lastName!.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('นามสกุล');
      }

      if (law.phone != null && law.phone!.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('เบอร์โทร');
      }

      if (law.address != null && law.address!.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('ที่อยู่');
      }

      if (law.birthDate != null) {
        completedFields++;
      } else {
        missingFields.add('วันเกิด');
      }

      if (law.gender != null && law.gender!.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('เพศ');
      }

      if (law.img != null && law.img!.isNotEmpty) {
        completedFields++;
      } else {
        missingFields.add('รูปโปรไฟล์');
      }

      double percentage = (completedFields / totalFields * 100);

      return {
        'completed': completedFields == totalFields,
        'percentage': percentage.round(),
        'missing_fields': missingFields,
        'completed_fields': completedFields,
        'total_fields': totalFields,
      };
    } catch (e) {
      print('Error checking profile completeness: $e');
      return {'completed': false, 'percentage': 0, 'missing_fields': []};
    }
  }

  /// ดึงสรุปกิจกรรมล่าสุด
  static Future<Map<String, dynamic>> getActivitySummary(int lawId) async {
    try {
      // ดึงข้อมูลกิจกรรมจากตารางต่างๆ
      final notionCount = await _client
          .from('notion')
          .select('notion_id')
          .eq('law_id', lawId)
          .count();

      final recentNotions = await _client
          .from('notion')
          .select('header, created_at')
          .eq('law_id', lawId)
          .order('created_at', ascending: false)
          .limit(5);

      return {
        'total_notions': notionCount,
        'recent_notions': recentNotions,
        'last_active': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting activity summary: $e');
      return {};
    }
  }

  // ========== Create & Delete Operations ==========

  /// สร้าง Law ใหม่ (สำหรับ Admin)
  static Future<LawModel?> create({
    required int villageId,
    required int userId,
    required String firstName,
    required String lastName,
    required String phone,
    String? address,
    DateTime? birthDate,
    String? gender,
    String? img,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert({
        'village_id': villageId,
        'user_id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'address': address,
        'birth_date': birthDate?.toIso8601String(),
        'gender': gender,
        'img': img,
      })
          .select()
          .single();

      return LawModel.fromJson(response);
    } catch (e) {
      print('Error creating law: $e');
      return null;
    }
  }

  /// ลบ Law (สำหรับ Admin เท่านั้น)
  static Future<bool> delete(int lawId) async {
    try {
      await _client
          .from(_tableName)
          .delete()
          .eq('law_id', lawId);

      return true;
    } catch (e) {
      print('Error deleting law: $e');
      return false;
    }
  }

  // ========== Validation Helpers ==========

  /// ตรวจสอบว่าเบอร์โทรซ้ำหรือไม่
  static Future<bool> isPhoneExists(String phone, {int? excludeLawId}) async {
    try {
      var query = _client
          .from(_tableName)
          .select('law_id')
          .eq('phone', phone);

      if (excludeLawId != null) {
        query = query.neq('law_id', excludeLawId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking phone exists: $e');
      return false;
    }
  }

  /// ตรวจสอบว่า user_id ถูกใช้แล้วหรือไม่
  static Future<bool> isUserIdUsed(int userId, {int? excludeLawId}) async {
    try {
      var query = _client
          .from(_tableName)
          .select('law_id')
          .eq('user_id', userId);

      if (excludeLawId != null) {
        query = query.neq('law_id', excludeLawId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking user ID used: $e');
      return false;
    }
  }
}