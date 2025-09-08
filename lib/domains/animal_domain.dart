import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/image_service.dart';

class AnimalDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'animal';

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
    required String status,
    dynamic imageFile,
    bool removeImage = false,
  }) async {
    // Validation
    if (animalId <= 0) throw ArgumentError('Animal ID must be positive');
    if (type.trim().isEmpty) throw ArgumentError('Type cannot be empty');
    if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');

    try {
      String? finalImageUrl;

      if (removeImage) {
        // อาจเพิ่มการลบรูปเก่าจาก storage ด้วย
        finalImageUrl = null;
      } else if (imageFile != null) {
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

      final Map<String, dynamic> updateData = {
        'type': type.trim(), // trim whitespace
        'name': name.trim(),
        'status': status,
      };

      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      final response = await _client
          .from(_table)
          .update(updateData)
          .eq('animal_id', animalId);

      // Optional: ตรวจสอบผลลัพธ์
      // if (response.error != null) throw response.error!;
    } catch (e) {
      print('Error updating animal: $e');
      throw Exception('Failed to update animal: $e');
    }
  }

  static Future<void> delete(int animalId) async {
    try {
      // 1. ดึงข้อมูล vehicle เพื่อเช็ค imageUrl ก่อน
      final response = await _client
          .from(_table)
          .select('img')
          .eq('animal_id', animalId)
          .single();

      final imageUrl = response['img'] as String?;

      // 2. ลบรูปภาพออกจาก storage ก่อน (ถ้ามี)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await SupabaseImage().deleteImage(
          bucketPath: "animalId",
          imageUrl: imageUrl,
        );
      }

      // 3. ลบข้อมูล vehicle จากฐานข้อมูล
      await _client.from(_table).delete().eq('animal_id', animalId);
    } catch (e) {
      print('Error deleting vehicle: $e');
      throw Exception('Failed to delete vehicle: $e');
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
}
