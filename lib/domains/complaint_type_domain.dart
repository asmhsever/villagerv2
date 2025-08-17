import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/complaint_type_model.dart';

class ComplaintTypeDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'type_complaint'; // แก้ชื่อตารางให้ถูกต้อง

  /// ดึงข้อมูลประเภทร้องเรียนทั้งหมด
  static Future<List<ComplaintTypeModel>> getAll() async {
    try {
      final response = await _client.from(_table).select('*').order('type_id');

      if (response == null) {
        throw Exception('No data returned from Supabase');
      }

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ComplaintTypeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error fetching complaint types: $e');
    }
  }

  /// ดึงข้อมูลประเภทร้องเรียนตาม ID
  static Future<ComplaintTypeModel?> getById(int typeId) async {
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('type_id', typeId)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      return ComplaintTypeModel.fromJson(response);
    } catch (e) {
      throw Exception('Error fetching complaint type by ID: $e');
    }
  }

  /// สร้างประเภทร้องเรียนใหม่
  static Future<bool> create(ComplaintTypeModel complaintType) async {
    try {
      final response = await _client
          .from(_table)
          .insert(complaintType.toJson())
          .select();

      return response != null && response.isNotEmpty;
    } catch (e) {
      throw Exception('Error creating complaint type: $e');
    }
  }

  /// อัพเดทข้อมูลประเภทร้องเรียน
  static Future<bool> update(
      int typeId,
      ComplaintTypeModel complaintType,
      ) async {
    try {
      final response = await _client
          .from(_table)
          .update(complaintType.toJson())
          .eq('type_id', typeId)
          .select();

      return response != null && response.isNotEmpty;
    } catch (e) {
      throw Exception('Error updating complaint type: $e');
    }
  }

  /// ลบประเภทร้องเรียน
  static Future<bool> delete(int typeId) async {
    try {
      final response = await _client
          .from(_table)
          .delete()
          .eq('type_id', typeId)
          .select();

      return response != null;
    } catch (e) {
      throw Exception('Error deleting complaint type: $e');
    }
  }

  /// ตรวจสอบว่าประเภทร้องเรียนมีอยู่หรือไม่
  static Future<bool> exists(int typeId) async {
    try {
      final complaintType = await getById(typeId);
      return complaintType != null;
    } catch (e) {
      return false;
    }
  }

  /// ค้นหาประเภทร้องเรียนตามชื่อ
  static Future<List<ComplaintTypeModel>> searchByName(String query) async {
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .ilike('type', '%$query%')
          .order('type_id');

      if (response == null) {
        return [];
      }

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ComplaintTypeModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error searching complaint types: $e');
    }
  }

  /// ตรวจสอบว่าชื่อประเภทร้องเรียนซ้ำหรือไม่
  static Future<bool> isTypeNameExists(
      String typeName, {
        int? excludeId,
      }) async {
    try {
      var query = _client
          .from(_table)
          .select('type_id')
          .ilike('type', typeName);

      if (excludeId != null) {
        query = query.neq('type_id', excludeId);
      }

      final response = await query.maybeSingle();
      return response != null;
    } catch (e) {
      throw Exception('Error checking complaint type name: $e');
    }
  }

  /// สำหรับ batch operations - สร้างหลายประเภทพร้อมกัน
  static Future<List<bool>> createMultiple(
      List<ComplaintTypeModel> complaintTypes,
      ) async {
    try {
      final List<Map<String, dynamic>> data = complaintTypes
          .map((type) => type.toJson())
          .toList();

      final response = await _client.from(_table).insert(data).select();

      if (response == null) {
        return List.generate(complaintTypes.length, (index) => false);
      }

      final List<dynamic> results = response as List<dynamic>;
      return List.generate(
        complaintTypes.length,
            (index) => index < results.length,
      );
    } catch (e) {
      throw Exception('Error creating multiple complaint types: $e');
    }
  }

  /// ดึงประเภทร้องเรียนแบบ active เท่านั้น (ถ้ามีฟิลด์ is_active)
  static Future<List<ComplaintTypeModel>> getActive() async {
    try {
      final response = await _client
          .from(_table)
          .select('*')
          .eq('is_active', true) // สมมติว่ามีฟิลด์ is_active
          .order('type_id');

      if (response == null) {
        // ถ้าไม่มีฟิลด์ is_active ให้ดึงทั้งหมด
        return await getAll();
      }

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => ComplaintTypeModel.fromJson(json)).toList();
    } catch (e) {
      // ถ้า error เพราะไม่มีฟิลด์ is_active ให้ดึงทั้งหมดแทน
      return await getAll();
    }
  }

  /// อัพเดทสถานะ active/inactive (ถ้ามีฟิลด์ is_active)
  static Future<bool> updateActiveStatus(int typeId, bool isActive) async {
    try {
      final response = await _client
          .from(_table)
          .update({'is_active': isActive})
          .eq('type_id', typeId)
          .select();

      return response != null && response.isNotEmpty;
    } catch (e) {
      throw Exception('Error updating complaint type status: $e');
    }
  }
}
