import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/success_complaint_model.dart';
import 'package:fullproject/services/image_service.dart';

class SuccessComplaintDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'success_complaint';

  // ดึงข้อมูล success complaint ทั้งหมด
  static Future<List<SuccessComplaintModel>> getAll() async {
    try {
      final response = await _client.from(_table).select().order('id');

      return (response as List)
          .map((data) => SuccessComplaintModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch success complaints: $e');
    }
  }

  // ดึงข้อมูลตาม complaint_id
  static Future<List<SuccessComplaintModel>> getByComplaintId(
    int complaintId,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('complaint_id', complaintId)
          .order('id');

      return (response as List)
          .map((data) => SuccessComplaintModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception(
        'Failed to fetch success complaints for complaint $complaintId: $e',
      );
    }
  }

  // ดึงข้อมูลตาม law_id
  static Future<List<SuccessComplaintModel>> getByLawId(int lawId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('law_id', lawId)
          .order('id');

      return (response as List)
          .map((data) => SuccessComplaintModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch success complaints for law $lawId: $e');
    }
  }

  // ดึงข้อมูลตาม ID
  static Future<SuccessComplaintModel?> getById(int id) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return SuccessComplaintModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch success complaint $id: $e');
    }
  }

  // เพิ่มข้อมูลใหม่พร้อมรูปภาพ
  static Future<SuccessComplaintModel?> create({
    required int lawId,
    required int complaintId,
    required String description,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
    DateTime? successAt,
  }) async {
    try {
      // 1. สร้าง success complaint ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
            'law_id': lawId,
            'complaint_id': complaintId,
            'description': description,
            'img': null,
            'success_at': successAt?.toIso8601String(),
          })
          .select()
          .single();

      final createdSuccess = SuccessComplaintModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null && createdSuccess.id != null) {
        final imageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "success_complaint",
          rowName: "id",
          rowImgName: "img",
          rowKey: createdSuccess.id!,
          bucketPath: "success_complaint",
          imgName: "success_complaint",
        );

        // 3. อัปเดต success complaint ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_table)
              .update({'img': imageUrl})
              .eq('id', createdSuccess.id!);

          // Return success complaint ที่มี imageUrl
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

  // อัปเดตข้อมูลพร้อมจัดการรูปภาพ
  static Future<void> update({
    required int id,
    required int lawId,
    required int complaintId,
    required String description,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
    bool removeImage = false, // flag สำหรับลบรูป
    DateTime? successAt,
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
          bucketPath: "success_complaint",
          imgName: "success_complaint",
        );
      }
      // ถ้า imageFile เป็น null และ removeImage เป็น false = ไม่แก้ไขรูป

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'law_id': lawId,
        'complaint_id': complaintId,
        'description': description,
        'success_at': successAt?.toIso8601String(),
      };

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client.from(_table).update(updateData).eq('id', id);
    } catch (e) {
      print('Error updating success complaint: $e');
      throw Exception('Failed to update success complaint: $e');
    }
  }

  // ลบข้อมูล
  static Future<void> delete(int id) async {
    try {
      await _client.from(_table).delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete success complaint $id: $e');
    }
  }

  // อัปเดตสถานะเป็นเสร็จสิ้น
  static Future<void> markAsCompleted(int id) async {
    try {
      await _client
          .from(_table)
          .update({'success_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark success complaint $id as completed: $e');
    }
  }

  // อัปเดตสถานะเป็นกำลังดำเนินการ
  static Future<void> markAsPending(int id) async {
    try {
      await _client.from(_table).update({'success_at': null}).eq('id', id);
    } catch (e) {
      throw Exception('Failed to mark success complaint $id as pending: $e');
    }
  }

  // ดึงเฉพาะที่เสร็จสิ้นแล้ว
  static Future<List<SuccessComplaintModel>> getCompleted() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .not('success_at', 'is', null)
          .order('success_at', ascending: false);

      return (response as List)
          .map((data) => SuccessComplaintModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch completed success complaints: $e');
    }
  }

  // ดึงข้อมูลพร้อม join กับตารางอื่น
  static Future<List<Map<String, dynamic>>> getWithDetails() async {
    try {
      final response = await _client
          .from(_table)
          .select('''
            *,
            complaint:complaint_id(*),
            law:law_id(*)
          ''')
          .order('id');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch success complaints with details: $e');
    }
  }

  // Batch operations
  static Future<List<SuccessComplaintModel>> createMultiple(
    List<SuccessComplaintModel> successComplaints,
  ) async {
    try {
      final data = successComplaints.map((sc) => sc.toJson()).toList();
      final response = await _client.from(_table).insert(data).select();

      return (response as List)
          .map((data) => SuccessComplaintModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to create multiple success complaints: $e');
    }
  }

  // ลบหลายรายการตาม complaint_id
  static Future<void> deleteByComplaintId(int complaintId) async {
    try {
      await _client.from(_table).delete().eq('complaint_id', complaintId);
    } catch (e) {
      throw Exception(
        'Failed to delete success complaints for complaint $complaintId: $e',
      );
    }
  }

  // อัปโหลดรูปเพิ่มเติม
  static Future<String?> uploadAdditionalImage({
    required int id,
    required dynamic imageFile,
  }) async {
    try {
      final imageUrl = await SupabaseImage().uploadImage(
        imageFile: imageFile,
        tableName: "success_complaint",
        rowName: "id",
        rowImgName: "img",
        rowKey: id,
        bucketPath: "success_complaint",
        imgName: "success_complaint",
      );

      if (imageUrl != null) {
        await _client.from(_table).update({'img': imageUrl}).eq('id', id);
      }

      return imageUrl;
    } catch (e) {
      throw Exception('Failed to upload additional image: $e');
    }
  }
}
