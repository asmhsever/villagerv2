import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/admin_model.dart';

class AdminDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'admin';

  // CREATE - สร้าง admin ใหม่
  static Future<Map<String, dynamic>> createAdmin({
    required String username,
    required String password,
  }) async {
    try {
      // ตรวจสอบข้อมูลที่รับเข้ามา
      if (username.trim().isEmpty || password.trim().isEmpty) {
        return {'success': false, 'message': 'กรุณากรอกชื่อผู้ใช้และรหัสผ่าน'};
      }

      // ตรวจสอบว่า username ซ้ำหรือไม่
      final existingAdmin = await _client
          .from(_tableName)
          .select('admin_id')
          .eq('username', username.trim())
          .maybeSingle();

      if (existingAdmin != null) {
        return {'success': false, 'message': 'ชื่อผู้ใช้นี้มีอยู่ในระบบแล้ว'};
      }

      // สร้าง admin ใหม่
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .insert({'username': username.trim(), 'password': password})
          .select();

      if (response.isNotEmpty) {
        final admin = AdminModel.fromJson(response.first);

        return {
          'success': true,
          'admin': admin,
          'message': 'สร้างผู้ดูแลระบบสำเร็จ',
        };
      } else {
        return {'success': false, 'message': 'ไม่สามารถสร้างผู้ดูแลระบบได้'};
      }
    } catch (e) {
      print('Error creating admin: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการสร้างผู้ดูแลระบบ: ${e.toString()}',
      };
    }
  }

  // READ - ดึงข้อมูล admin ทั้งหมด
  static Future<Map<String, dynamic>> getAllAdmins() async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .select('*')
          .order('admin_id', ascending: true);

      final admins = response.map((json) => AdminModel.fromJson(json)).toList();

      return {'success': true, 'admins': admins, 'count': admins.length};
    } catch (e) {
      print('Error getting all admins: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ดูแลระบบ: ${e.toString()}',
        'admins': <AdminModel>[],
        'count': 0,
      };
    }
  }

  // READ - ดึงข้อมูล admin ตาม ID
  static Future<Map<String, dynamic>> getAdminById(int adminId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .eq('admin_id', adminId)
          .maybeSingle();

      if (response != null) {
        final admin = AdminModel.fromJson(response);
        return {'success': true, 'admin': admin};
      } else {
        return {'success': false, 'message': 'ไม่พบผู้ดูแลระบบที่ระบุ'};
      }
    } catch (e) {
      print('Error getting admin by ID: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ดูแลระบบ: ${e.toString()}',
      };
    }
  }

  // READ - ดึงข้อมูล admin ตาม username
  static Future<Map<String, dynamic>> getAdminByUsername(
    String username,
  ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .eq('username', username)
          .maybeSingle();

      if (response != null) {
        final admin = AdminModel.fromJson(response);
        return {'success': true, 'admin': admin};
      } else {
        return {'success': false, 'message': 'ไม่พบผู้ดูแลระบบที่ระบุ'};
      }
    } catch (e) {
      print('Error getting admin by username: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ดูแลระบบ: ${e.toString()}',
      };
    }
  }

  // READ - ค้นหา admin ด้วย pagination
  static Future<Map<String, dynamic>> getAdminsWithPagination({
    int page = 1,
    int pageSize = 10,
    String? searchQuery,
  }) async {
    try {
      final offset = (page - 1) * pageSize;

      PostgrestFilterBuilder query = _client.from(_tableName).select('*');

      // เพิ่มการค้นหาถ้ามี searchQuery
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('username', '%$searchQuery%');
      }

      final List<Map<String, dynamic>> response = await query
          .range(offset, offset + pageSize - 1)
          .order('admin_id', ascending: true);

      final admins = response.map((json) => AdminModel.fromJson(json)).toList();

      // นับจำนวนทั้งหมด
      final countResponse = await _client
          .from(_tableName)
          .select('*')
          .count(CountOption.exact);

      final totalCount = countResponse.count ?? 0;
      final totalPages = (totalCount / pageSize).ceil();

      return {
        'success': true,
        'admins': admins,
        'currentPage': page,
        'pageSize': pageSize,
        'totalCount': totalCount,
        'totalPages': totalPages,
        'hasNextPage': page < totalPages,
        'hasPreviousPage': page > 1,
      };
    } catch (e) {
      print('Error getting admins with pagination: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการดึงข้อมูลผู้ดูแลระบบ: ${e.toString()}',
        'admins': <AdminModel>[],
        'currentPage': page,
        'pageSize': pageSize,
        'totalCount': 0,
        'totalPages': 0,
        'hasNextPage': false,
        'hasPreviousPage': false,
      };
    }
  }

  // UPDATE - อัปเดตข้อมูล admin
  static Future<Map<String, dynamic>> updateAdmin({
    required int adminId,
    String? username,
    String? password,
  }) async {
    try {
      // ตรวจสอบว่า admin มีอยู่จริงหรือไม่
      final existingAdmin = await _client
          .from(_tableName)
          .select('*')
          .eq('admin_id', adminId)
          .maybeSingle();

      if (existingAdmin == null) {
        return {
          'success': false,
          'message': 'ไม่พบผู้ดูแลระบบที่ต้องการอัปเดต',
        };
      }

      // เตรียมข้อมูลที่จะอัปเดต
      Map<String, dynamic> updateData = {};

      if (username != null && username.trim().isNotEmpty) {
        // ตรวจสอบว่า username ใหม่ซ้ำกับของอื่นหรือไม่
        final duplicateCheck = await _client
            .from(_tableName)
            .select('admin_id')
            .eq('username', username.trim())
            .neq('admin_id', adminId)
            .maybeSingle();

        if (duplicateCheck != null) {
          return {'success': false, 'message': 'ชื่อผู้ใช้นี้มีอยู่ในระบบแล้ว'};
        }
        updateData['username'] = username.trim();
      }

      if (password != null && password.isNotEmpty) {
        updateData['password'] = password;
      }

      if (updateData.isEmpty) {
        return {'success': false, 'message': 'ไม่มีข้อมูลที่จะอัปเดต'};
      }

      // อัปเดตข้อมูล
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .update(updateData)
          .eq('admin_id', adminId)
          .select();

      if (response.isNotEmpty) {
        final updatedAdmin = AdminModel.fromJson(response.first);

        return {
          'success': true,
          'admin': updatedAdmin,
          'message': 'อัปเดตข้อมูลผู้ดูแลระบบสำเร็จ',
        };
      } else {
        return {'success': false, 'message': 'ไม่สามารถอัปเดตข้อมูลได้'};
      }
    } catch (e) {
      print('Error updating admin: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการอัปเดตผู้ดูแลระบบ: ${e.toString()}',
      };
    }
  }

  // DELETE - ลบ admin
  static Future<Map<String, dynamic>> deleteAdmin(int adminId) async {
    try {
      // ตรวจสอบว่า admin มีอยู่จริงหรือไม่
      final existingAdmin = await _client
          .from(_tableName)
          .select('*')
          .eq('admin_id', adminId)
          .maybeSingle();

      if (existingAdmin == null) {
        return {'success': false, 'message': 'ไม่พบผู้ดูแลระบบที่ต้องการลบ'};
      }

      // ลบข้อมูล
      await _client.from(_tableName).delete().eq('admin_id', adminId);

      return {
        'success': true,
        'message': 'ลบผู้ดูแลระบบสำเร็จ',
        'deletedAdmin': AdminModel.fromJson(existingAdmin),
      };
    } catch (e) {
      print('Error deleting admin: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการลบผู้ดูแลระบบ: ${e.toString()}',
      };
    }
  }

  // UTILITY - ตรวจสอบว่า username มีอยู่หรือไม่
  static Future<bool> isUsernameExists(
    String username, {
    int? excludeAdminId,
  }) async {
    try {
      PostgrestFilterBuilder query = _client
          .from(_tableName)
          .select('admin_id')
          .eq('username', username);

      if (excludeAdminId != null) {
        query = query.neq('admin_id', excludeAdminId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      print('Error checking username existence: $e');
      return false;
    }
  }

  // UTILITY - เปลี่ยนรหัสผ่าน
  static Future<Map<String, dynamic>> changePassword({
    required int adminId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // ตรวจสอบรหัสผ่านปัจจุบัน
      final admin = await _client
          .from(_tableName)
          .select('*')
          .eq('admin_id', adminId)
          .eq('password', currentPassword)
          .maybeSingle();

      if (admin == null) {
        return {'success': false, 'message': 'รหัสผ่านปัจจุบันไม่ถูกต้อง'};
      }

      // อัปเดตรหัสผ่านใหม่
      final response = await _client
          .from(_tableName)
          .update({'password': newPassword})
          .eq('admin_id', adminId)
          .select()
          .single();

      final updatedAdmin = AdminModel.fromJson(response);

      return {
        'success': true,
        'admin': updatedAdmin,
        'message': 'เปลี่ยนรหัสผ่านสำเร็จ',
      };
    } catch (e) {
      print('Error changing password: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเปลี่ยนรหัสผ่าน: ${e.toString()}',
      };
    }
  }

  // UTILITY - นับจำนวน admin ทั้งหมด
  static Future<int> getTotalAdminCount() async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .count(CountOption.exact);

      return response.count ?? 0;
    } catch (e) {
      print('Error getting admin count: $e');
      return 0;
    }
  }
}
