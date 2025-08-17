import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/notion_model.dart';
import 'package:fullproject/services/image_service.dart';

class NotionDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'notion';

  static Future<Map<String, dynamic>> getAllNotions() async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .select("*")
          .order('created_ad', ascending: false);
      final notions = response
          .map((json) => NotionModel.fromJson(json))
          .toList();
      return {'success': true, 'notions': notions, 'count': notions.length};
    } catch (e) {
      print("Error get all notion : $e ");
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> getRecentNotions({
    int limit = 10,
    int? villageId,
  }) async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .select("*")
          .eq('village_id', villageId!)
          .order('created_at', ascending: false)
          .limit(limit);
      final notions = response
          .map((json) => NotionModel.fromJson(json))
          .toList();
      print(notions);
      return {'success': true, 'notions': notions, 'count': notions.length};
    } catch (e) {
      print("error getRecenNotion : ${e}");
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> getRecentNotionsFilter({
    int limit = 10,
    int? villageId,
    String? type,
  }) async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .select("*")
          .eq('village_id', villageId!)
          .eq('type', type!)
          .order('created_at', ascending: false)
          .limit(limit);
      final notions = response
          .map((json) => NotionModel.fromJson(json))
          .toList();
      print(notions);
      return {'success': true, 'notions': notions, 'count': notions.length};
    } catch (e) {
      print("error getRecenNotion : ${e}");
      return {'success': false};
    }
  }

  static Future<void> delete(int notionId) async {
    await _client.from(_tableName).delete().eq('notion_id', notionId);
  }

  static Future<List<NotionModel>> getByVillage(int villageId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .eq('village_id', villageId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => NotionModel.fromJson(e)).toList();
    } catch (e) {
      print("Error in getByVillage: $e");
      return [];
    }
  }

  // ✅ Create
  static Future<NotionModel?> create({
    required int lawId,
    required int villageId,
    required String? header,
    required String? description,
    required String? type,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // 1. สร้าง notion ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_tableName)
          .insert({
        'law_id': lawId,
        'village_id': villageId,
        'header': header,
        'description': description,
        'type': type,
        'create_date': DateTime.now().toIso8601String(),
        'img': null,
      })
          .select()
          .single();

      final createdNotion = NotionModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null && createdNotion.notionId != 0) {
        final imageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "notion",
          rowName: "notion_id",
          rowImgName: "img",
          rowKey: createdNotion.notionId,
        );

        // 3. อัปเดต notion ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_tableName)
              .update({'img': imageUrl})
              .eq('notion_id', createdNotion.notionId);

          // Return notion ที่มี imageUrl
          return NotionModel(
            notionId: createdNotion.notionId,
            lawId: createdNotion.lawId,
            villageId: createdNotion.villageId,
            header: createdNotion.header,
            description: createdNotion.description,
            createDate: createdNotion.createDate,
            img: imageUrl,
            type: createdNotion.type,
          );
        }
      }

      return createdNotion;
    } catch (e) {
      print('Error creating notion: $e');
      return null;
    }
  }

  // ✅ Update
  static Future<void> update({
    required int notionId,
    required int lawId,
    required int villageId,
    required String? header,
    required String? description,
    required String? type,
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
          tableName: "notion",
          rowName: "notion_id",
          rowImgName: "img",
          rowKey: notionId,
        );
      }
      // ถ้า imageFile เป็น null และ removeImage เป็น false = ไม่แก้ไขรูป

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'law_id': lawId,
        'village_id': villageId,
        'header': header,
        'description': description,
        'type': type,
      };

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client
          .from(_tableName)
          .update(updateData)
          .eq('notion_id', notionId);
    } catch (e) {
      print('Error updating notion: $e');
      throw Exception('Failed to update notion: $e');
    }
  }
}
