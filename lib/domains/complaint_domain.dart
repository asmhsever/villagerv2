import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/complaint_model.dart';
import 'package:fullproject/services/image_service.dart';

class ComplaintDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'complaint';

  // Create - เพิ่มร้องเรียนใหม่
  static Future<ComplaintModel?> create({
    required int houseId,
    required int typeComplaint,
    required String header,
    required String description,
    required String level,
    required bool isPrivate,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // 1. สร้าง complaint ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_tableName)
          .insert({
        'house_id': houseId,
        'type_complaint': typeComplaint,
        'create_at': DateTime.now().toIso8601String(),
        'header': header,
        'description': description,
        'level': level,
        'private': isPrivate,
        'img': null,
        'status': null,
        'update_at': null,
      })
          .select()
          .single();

      final createdComplaint = ComplaintModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null &&
          createdComplaint.complaintId != null &&
          createdComplaint.complaintId != 0) {
        final imageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "complaint",
          rowName: "complaint_id",
          rowImgName: "img",
          rowKey: createdComplaint.complaintId!,
          bucketPath: "complaint",
          imgName: "complaint",
        );

        // 3. อัปเดต complaint ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_tableName)
              .update({'img': imageUrl})
              .eq('complaint_id', createdComplaint.complaintId!);

          // Return complaint ที่มี imageUrl
          return ComplaintModel(
            complaintId: createdComplaint.complaintId,
            houseId: createdComplaint.houseId,
            typeComplaint: createdComplaint.typeComplaint,
            createAt: createdComplaint.createAt,
            header: createdComplaint.header,
            description: createdComplaint.description,
            level: createdComplaint.level,
            isPrivate: createdComplaint.isPrivate,
            img: imageUrl,
            status: createdComplaint.status,
            updateAt: createdComplaint.updateAt,
          );
        }
      }

      return createdComplaint;
    } catch (e) {
      print('Error creating complaint: $e');
      return null;
    }
  }

  // Update - อัพเดทร้องเรียน
  static Future<void> update({
    required int complaintId,
    required int houseId,
    required int typeComplaint,
    required String header,
    required String description,
    required String level,
    required bool isPrivate,
    String? status,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
    bool removeImage = false, // flag สำหรับลบรูป
  }) async {
    try {
      String? finalImageUrl;

      if (removeImage) {
        // ลบรูปภาพ
        finalImageUrl = null;
      } else if (imageFile != null) {
        // อัปโหลดรูปใหม่
        finalImageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "complaint",
          rowName: "complaint_id",
          rowImgName: "img",
          rowKey: complaintId,
          bucketPath: "complaint",
          imgName: "complaint",
        );
      }
      // ถ้า imageFile เป็น null และ removeImage เป็น false = ไม่แก้ไขรูป

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'house_id': houseId,
        'type_complaint': typeComplaint,
        'header': header,
        'description': description,
        'level': level,
        'is_private': isPrivate,
        'status': status,
        'update_at': DateTime.now().toIso8601String(),
      };

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client
          .from(_tableName)
          .update(updateData)
          .eq('complaint_id', complaintId);
    } catch (e) {
      print('Error updating complaint: $e');
      throw Exception('Failed to update complaint: $e');
    }
  }

  // Read - อ่านร้องเรียนทั้งหมดในระบบ (Admin only)
  static Future<List<ComplaintModel>> getAll() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all complaints: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนทั้งหมดในหมู่บ้าน (เฉพาะที่ไม่ private)
  static Future<List<ComplaintModel>> getAllInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .eq('private', false)
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints in village: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนทั้งหมดของบ้าน
  static Future<List<ComplaintModel>> getAllInHouse(int houseId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('house_id', houseId)
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints in house: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนตาม ID
  static Future<ComplaintModel?> getById(int complaintId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('complaint_id', complaintId)
          .single();

      return ComplaintModel.fromJson(response);
    } catch (e) {
      print('Error getting complaint by ID: $e');
      return null;
    }
  }

  // Read - อ่านร้องเรียนตามประเภทในหมู่บ้าน
  static Future<List<ComplaintModel>> getByTypeInVillage(
      int villageId,
      int typeComplaint,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .eq('type_complaint', typeComplaint)
          .eq('private', false)
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints by type in village: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนตามประเภทของบ้าน
  static Future<List<ComplaintModel>> getByTypeInHouse(
      int villageId,
      int houseId,
      int typeComplaint,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .eq('house_id', houseId)
          .eq('type_complaint', typeComplaint)
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints by type in house: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนตามระดับความสำคัญในหมู่บ้าน
  static Future<List<ComplaintModel>> getByLevelInVillage(
      int villageId,
      int level,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .eq('level', level)
          .eq('private', false)
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints by level in village: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนตามระดับความสำคัญของบ้าน
  static Future<List<ComplaintModel>> getByLevelInHouse(
      int houseId,
      int level,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('house_id', houseId)
          .gte('level', level) // ระดับที่ระบุขึ้นไป
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints by level in house: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนตามสถานะในหมู่บ้าน
  static Future<List<ComplaintModel>> getByStatusInVillage(
      int villageId,
      String status,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .eq('status', status)
          .eq('private', false)
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints by status in village: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนตามสถานะของบ้าน
  static Future<List<ComplaintModel>> getByStatusInHouse(
      int villageId,
      int houseId,
      String status,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .eq('house_id', houseId)
          .eq('status', status)
          .order('create_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting complaints by status in house: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนที่รอดำเนินการในหมู่บ้าน
  static Future<List<ComplaintModel>> getPendingInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .or('status.in.(pending,in_progress),status.is.null')
          .eq('private', false)
          .order('level', ascending: false)
          .order('create_at', ascending: true);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting pending complaints in village: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนที่ยังไม่จ่ายของบ้าน
  static Future<List<ComplaintModel>> getPendingInHouse(int houseId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('house_id', houseId)
          .or('status.in.(pending,in_progress),status.is.null')
          .order('level', ascending: false)
          .order('create_at', ascending: true);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting pending complaints in house: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนที่เสร็จสิ้นแล้วในหมู่บ้าน
  static Future<List<ComplaintModel>> getResolvedInVillage(
      int villageId,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .eq('status', 'resolved')
          .eq('private', false)
          .order('update_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting resolved complaints in village: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนที่เสร็จสิ้นแล้วของบ้าน
  static Future<List<ComplaintModel>> getResolvedInHouse(int houseId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('house_id', houseId)
          .eq('status', 'resolved')
          .order('update_at', ascending: false);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting resolved complaints in house: $e');
      return [];
    }
  }

  // Read - อ่านร้องเรียนที่มีระดับความสำคัญสูงในหมู่บ้าน
  static Future<List<ComplaintModel>> getHighPriorityInVillage(
      int villageId,
      ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .gte('level', 3) // ระดับ 3 ขึ้นไป
          .eq('private', false)
          .order('level', ascending: false)
          .order('create_at', ascending: true);

      return response
          .map<ComplaintModel>((json) => ComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting high priority complaints in village: $e');
      return [];
    }
  }

  // Update - อัพเดทสถานะร้องเรียน
  static Future<bool> updateStatus({
    required int complaintId,
    required String status,
    String? updateAt,
  }) async {
    try {
      final updateData = {
        'status': status,
        'update_at': updateAt ?? DateTime.now().toIso8601String(),
      };

      await _client
          .from(_tableName)
          .update(updateData)
          .eq('complaint_id', complaintId);

      return true;
    } catch (e) {
      print('Error updating complaint status: $e');
      return false;
    }
  }

  // Update - อัพเดทระดับความสำคัญ
  static Future<bool> updateLevel({
    required int complaintId,
    required int level,
  }) async {
    try {
      await _client
          .from(_tableName)
          .update({
        'level': level,
        'update_at': DateTime.now().toIso8601String(),
      })
          .eq('complaint_id', complaintId);

      return true;
    } catch (e) {
      print('Error updating complaint level: $e');
      return false;
    }
  }

  // Delete - ลบร้องเรียน
  static Future<bool> delete(int complaintId) async {
    try {
      await _client.from(_tableName).delete().eq('complaint_id', complaintId);

      return true;
    } catch (e) {
      print('Error deleting complaint: $e');
      return false;
    }
  }

  // Utility - สถิติร้องเรียนของบ้าน
  static Future<Map<String, dynamic>> getHouseComplaintStats(
      int villageId,
      int houseId,
      ) async {
    try {
      final allComplaints = await _client
          .from(_tableName)
          .select('status, level, type_complaint')
          .eq('village_id', villageId)
          .eq('house_id', houseId);

      int totalComplaints = allComplaints.length;
      int pendingComplaints = allComplaints
          .where((c) => ['pending', 'in_progress', null].contains(c['status']))
          .length;
      int resolvedComplaints = allComplaints
          .where((c) => c['status'] == 'resolved')
          .length;
      int highPriorityComplaints = allComplaints
          .where((c) => (c['level'] ?? 0) >= 3)
          .length;

      // นับตามประเภท
      Map<int, int> typeCount = {};
      for (var complaint in allComplaints) {
        int type = complaint['type_complaint'] ?? 0;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      return {
        'total_complaints': totalComplaints,
        'pending_complaints': pendingComplaints,
        'resolved_complaints': resolvedComplaints,
        'high_priority_complaints': highPriorityComplaints,
        'resolution_rate': totalComplaints > 0
            ? (resolvedComplaints / totalComplaints * 100)
            : 0,
        'type_breakdown': typeCount,
      };
    } catch (e) {
      print('Error getting house complaint stats: $e');
      return {};
    }
  }

  // Utility - สถิติร้องเรียนของหมู่บ้าน
  static Future<Map<String, dynamic>> getVillageComplaintStats(
      int villageId,
      ) async {
    try {
      final allComplaints = await _client
          .from(_tableName)
          .select('status, level, type_complaint, house_id')
          .eq('village_id', villageId);

      int totalComplaints = allComplaints.length;
      int pendingComplaints = allComplaints
          .where((c) => ['pending', 'in_progress', null].contains(c['status']))
          .length;
      int resolvedComplaints = allComplaints
          .where((c) => c['status'] == 'resolved')
          .length;
      int highPriorityComplaints = allComplaints
          .where((c) => (c['level'] ?? 0) >= 3)
          .length;

      // นับตามประเภท
      Map<int, int> typeCount = {};
      // นับตามบ้าน
      Map<int, int> houseCount = {};

      for (var complaint in allComplaints) {
        int type = complaint['type_complaint'] ?? 0;
        int house = complaint['house_id'] ?? 0;
        typeCount[type] = (typeCount[type] ?? 0) + 1;
        houseCount[house] = (houseCount[house] ?? 0) + 1;
      }

      return {
        'total_complaints': totalComplaints,
        'pending_complaints': pendingComplaints,
        'resolved_complaints': resolvedComplaints,
        'high_priority_complaints': highPriorityComplaints,
        'resolution_rate': totalComplaints > 0
            ? (resolvedComplaints / totalComplaints * 100)
            : 0,
        'type_breakdown': typeCount,
        'house_breakdown': houseCount,
      };
    } catch (e) {
      print('Error getting village complaint stats: $e');
      return {};
    }
  }
}
