// lib/domains/success_complaint_domain.dart
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/success_complaint_model.dart';
import 'package:fullproject/services/image_service.dart';

class SuccessComplaintDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'success_complaint';

  // Create - เพิ่มการดำเนินการเสร็จสิ้น
  static Future<SuccessComplaintModel?> create({
    required int lawId,
    required int complaintId,
    required String description,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // 1. สร้าง success_complaint ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_tableName)
          .insert({
        'law_id': lawId,
        'complaint_id': complaintId,
        'description': description,
        'success_at': DateTime.now().toIso8601String(), // ใช้ success_at ที่ถูกต้อง
        'img': null,
      })
          .select()
          .single();

      final createdSuccess = SuccessComplaintModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null &&
          createdSuccess.id != null &&
          createdSuccess.id != 0) {
        final imageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "success_complaint",
          rowName: "id",
          rowImgName: "img",
          rowKey: createdSuccess.id!,
        );

        // 3. อัปเดต success_complaint ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_tableName)
              .update({'img': imageUrl})
              .eq('id', createdSuccess.id!);

          // Return success_complaint ที่มี imageUrl
          return SuccessComplaintModel(
            id: createdSuccess.id,
            lawId: createdSuccess.lawId,
            complaintId: createdSuccess.complaintId,
            description: createdSuccess.description,
            img: imageUrl,
            successAt: createdSuccess.successAt,
          );
        }
      }

      return createdSuccess;
    } catch (e) {
      print('Error creating success complaint: $e');
      return null;
    }
  }

  // Read - ดึงข้อมูลการดำเนินการเสร็จสิ้นทั้งหมด
  static Future<List<SuccessComplaintModel>> getAll() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('success_at', ascending: false);

      return response
          .map<SuccessComplaintModel>((json) => SuccessComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all success complaints: $e');
      return [];
    }
  }

  // Read - ดึงข้อมูลตาม complaint_id
  static Future<SuccessComplaintModel?> getByComplaintId(int complaintId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('complaint_id', complaintId)
          .maybeSingle();

      if (response == null) return null;
      return SuccessComplaintModel.fromJson(response);
    } catch (e) {
      print('Error getting success complaint by complaint ID: $e');
      return null;
    }
  }

  // Read - ดึงข้อมูลตาม law_id (นิติกรคนนั้น)
  static Future<List<SuccessComplaintModel>> getByLawId(int lawId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('law_id', lawId)
          .order('success_at', ascending: false);

      return response
          .map<SuccessComplaintModel>((json) => SuccessComplaintModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting success complaints by law ID: $e');
      return [];
    }
  }

  // Read - ดึงข้อมูลตาม ID
  static Future<SuccessComplaintModel?> getById(int id) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('id', id)
          .single();

      return SuccessComplaintModel.fromJson(response);
    } catch (e) {
      print('Error getting success complaint by ID: $e');
      return null;
    }
  }

  // Update - อัพเดทข้อมูลการดำเนินการ
  static Future<bool> update({
    required int id,
    required String description,
    dynamic imageFile,
    bool removeImage = false,
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
          tableName: "success_complaint",
          rowName: "id",
          rowImgName: "img",
          rowKey: id,
        );
      }

      final Map<String, dynamic> updateData = {
        'description': description,
      };

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client
          .from(_tableName)
          .update(updateData)
          .eq('id', id);

      return true;
    } catch (e) {
      print('Error updating success complaint: $e');
      return false;
    }
  }

  // Delete - ลบข้อมูลการดำเนินการ
  static Future<bool> delete(int id) async {
    try {
      await _client.from(_tableName).delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting success complaint: $e');
      return false;
    }
  }

  // Utility - เช็คว่าคำร้องนี้มีการดำเนินการเสร็จสิ้นแล้วหรือไม่
  static Future<bool> isComplaintResolved(int complaintId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('id')
          .eq('complaint_id', complaintId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking complaint resolution: $e');
      return false;
    }
  }

  // Utility - สถิติการดำเนินการของนิติกร
  static Future<Map<String, dynamic>> getLawStats(int lawId) async {
    try {
      final allSuccess = await _client
          .from(_tableName)
          .select('success_at')
          .eq('law_id', lawId);

      int totalResolved = allSuccess.length;

      // นับตามเดือน
      final now = DateTime.now();
      final thisMonth = allSuccess.where((s) {
        try {
          final successDate = DateTime.parse(s['success_at']); // ใช้ success_at ที่ถูกต้อง
          return successDate.year == now.year && successDate.month == now.month;
        } catch (e) {
          return false;
        }
      }).length;

      // นับตามสัปดาห์
      final weekAgo = now.subtract(const Duration(days: 7));
      final thisWeek = allSuccess.where((s) {
        try {
          final successDate = DateTime.parse(s['success_at']); // ใช้ success_at ที่ถูกต้อง
          return successDate.isAfter(weekAgo);
        } catch (e) {
          return false;
        }
      }).length;

      return {
        'total_resolved': totalResolved,
        'this_month': thisMonth,
        'this_week': thisWeek,
      };
    } catch (e) {
      print('Error getting law stats: $e');
      return {
        'total_resolved': 0,
        'this_month': 0,
        'this_week': 0,
      };
    }
  }
}