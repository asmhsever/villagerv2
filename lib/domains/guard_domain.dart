import 'package:fullproject/models/guard_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/image_service.dart';

class GuardDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'guard';

  static Future<List<GuardModel>> getAll() async {
    final res = await _client.from(_table).select().order('guard_id');
    return res.map<GuardModel>((json) => GuardModel.fromJson(json)).toList();
  }

  static Future<GuardModel?> create({
    required int villageId,
    required String firstName,
    required String lastName,
    required String phone,
    required String nickname,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // 1. สร้าง guard ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
            'village_id': villageId,
            'first_name': firstName,
            'last_name': lastName,
            'phone': phone,
            'nickname': nickname,
            'img': null,
          })
          .select()
          .single();

      final createdGuard = GuardModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null && createdGuard.guardId != 0) {
        final imageUrl = await SupabaseImage().uploadImage(
          bucketPath: "guard",
          imgName: "guard",
          imageFile: imageFile,
          tableName: "guard",
          rowName: "guard_id",
          rowImgName: "img",
          rowKey: createdGuard.guardId,
        );

        // 3. อัปเดต guard ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_table)
              .update({'img': imageUrl})
              .eq('guard_id', createdGuard.guardId);

          // Return guard ที่มี imageUrl
          return GuardModel(
            guardId: createdGuard.guardId,
            villageId: createdGuard.villageId,
            firstName: createdGuard.firstName,
            lastName: createdGuard.lastName,
            phone: createdGuard.phone,
            nickname: createdGuard.nickname,
            img: imageUrl,
          );
        }
      }

      return createdGuard;
    } catch (e) {
      print('Error creating guard: $e');
      return null;
    }
  }

  // Read - ดึงข้อมูลยามทั้งหมดตาม Village ID
  static Future<List<GuardModel>> getByVillageId(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId);

      return response
          .map<GuardModel>((json) => GuardModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching guards by village ID: $e');
      return []; // Return empty list instead of null
    }
  }

  static Future<void> update({
    required int guardId,
    required String firstName,
    required String lastName,
    required String phone,
    required String nickname,
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
          tableName: "guard",
          rowName: "guard_id",
          rowImgName: "img",
          rowKey: guardId,
          bucketPath: "guard",
          imgName: "guard",
        );
      }
      // ถ้า imageFile เป็น null และ removeImage เป็น false = ไม่แก้ไขรูป

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'nickname': nickname,
      };

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client.from(_table).update(updateData).eq('guard_id', guardId);
    } catch (e) {
      print('Error updating guard: $e');
      throw Exception('Failed to update guard: $e');
    }
  }

  static Future<void> delete(int guardId) async {
    try {
      // 1. ดึงข้อมูล guard เพื่อเช็ค imageUrl ก่อน
      final response = await _client
          .from(_table)
          .select('img')
          .eq('guard_id', guardId)
          .single();

      final imageUrl = response['img'] as String?;

      // 2. ลบรูปภาพออกจาก storage ก่อน (ถ้ามี)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await SupabaseImage().deleteImage(
          bucketPath: "guard",
          imageUrl: imageUrl,
        );
      }

      // 3. ลบข้อมูล guard จากฐานข้อมูล
      await _client.from(_table).delete().eq('guard_id', guardId);
    } catch (e) {
      print('Error deleting guard: $e');
      throw Exception('Failed to delete guard: $e');
    }
  }
}
