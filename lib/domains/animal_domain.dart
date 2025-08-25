import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/image_service.dart';

class AnimalDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'animal';

  static Future<List<AnimalModel>> getAll() async {
    final res = await _client.from(_table).select().order('animal_id');
    return res.map<AnimalModel>((json) => AnimalModel.fromJson(json)).toList();
  }

  static Future<List<AnimalModel>> getByHouse({required int houseId}) async {
    try {
      final res = await _client.from(_table).select().eq('house_id', houseId);

      return res
          .map<AnimalModel>((json) => AnimalModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching animals for house $houseId: $e');

      return [];
    }
  }

  // Create new animal
  static Future<AnimalModel?> create({
    required int houseId,
    required String type,
    required String name,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // 1. สร้าง animal ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
        'house_id': houseId,
        'type': type,
        'name': name,
        'img': null,
      })
          .select()
          .single();

      final createdAnimal = AnimalModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null && createdAnimal.animalId != 0) {
        final imageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "animal",
          rowName: "animal_id",
          rowImgName: "img",
          rowKey: createdAnimal.animalId,
          bucketPath: "animal",
          imgName: "animal",
        );

        // 3. อัปเดต animal ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_table)
              .update({'img': imageUrl})
              .eq('animal_id', createdAnimal.animalId);

          // Return animal ที่มี imageUrl
          return AnimalModel(
            animalId: createdAnimal.animalId,
            houseId: createdAnimal.houseId,
            type: createdAnimal.type,
            name: createdAnimal.name,
            img: imageUrl,
          );
        }
      }

      return createdAnimal;
    } catch (e) {
      print('Error creating animal: $e');
      return null;
    }
  }

  // Update animal
  static Future<void> update({
    required int animalId,
    required String type,
    required String name,
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
          tableName: "animal",
          rowName: "animal_id",
          rowImgName: "img",
          rowKey: animalId,
          bucketPath: "animal",
          imgName: "animal",
        );
      }
      // ถ้า imageFile เป็น null และ removeImage เป็น false = ไม่แก้ไขรูป

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {'type': type, 'name': name};

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client.from(_table).update(updateData).eq('animal_id', animalId);
    } catch (e) {
      print('Error updating animal: $e');
      throw Exception('Failed to update animal: $e');
    }
  }

  // Get animal by ID
  static Future<AnimalModel?> getById({required int animalId}) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('animal_id', animalId)
          .single();

      return AnimalModel.fromJson(res);
    } catch (e) {
      print('Error fetching animal with ID $animalId: $e');
      return null;
    }
  }

  static Future<void> delete(int animalId) async {
    await _client.from(_table).delete().eq('animal_id', animalId);
  }
}
