import 'package:fullproject/models/vehicle_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/image_service.dart';

class VehicleDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'vehicle';

  static Future<List<VehicleModel>> getAll() async {
    final res = await _client.from(_table).select().order('vehicle_id');
    return res
        .map<VehicleModel>((json) => VehicleModel.fromJson(json))
        .toList();
  }

  static Future<List<VehicleModel>> getByHouse({required int houseId}) async {
    try {
      final res = await _client.from(_table).select().eq('house_id', houseId);

      return res
          .map<VehicleModel>((json) => VehicleModel.fromJson(json))
          .toList();
    } catch (e) {
      // Log the error for debugging
      print('Error fetching vehicles for house $houseId: $e');

      return [];
    }
  }

  static Future<VehicleModel?> create({
    required int houseId,
    required String brand,
    required String model,
    required String number,

    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // 1. สร้าง vehicle ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
        'house_id': houseId,
        'brand': brand,
        'model': model,
        'number': number,
        'img': null,
      })
          .select()
          .single();

      final createdVehicle = VehicleModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null && createdVehicle.vehicleId != 0) {
        final imageUrl = await SupabaseImage().uploadImage(
          bucketPath: "vehicle",
          imgName: "vehicle",
          imageFile: imageFile,
          tableName: "vehicle",
          rowName: "vehicle_id",
          rowImgName: "img",
          rowKey: createdVehicle.vehicleId,
        );

        // 3. อัปเดต vehicle ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_table)
              .update({'img': imageUrl})
              .eq('vehicle_id', createdVehicle.vehicleId);

          // Return vehicle ที่มี imageUrl
          return VehicleModel(
            vehicleId: createdVehicle.vehicleId,
            houseId: createdVehicle.houseId,
            brand: createdVehicle.brand,
            model: createdVehicle.model,
            number: createdVehicle.number,
            img: imageUrl,
          );
        }
      }

      return createdVehicle;
    } catch (e) {
      print('Error creating vehicle: $e');
      return null;
    }
  }

  static Future<void> update({
    required int vehicleId,
    required String brand,
    required String model,
    required String number,
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
          tableName: "vehicle",
          rowName: "vehicle_id",
          rowImgName: "img",
          rowKey: vehicleId,
          bucketPath: "vehicle",
          imgName: "vehicle",
        );
      }
      // ถ้า imageFile เป็น null และ removeImage เป็น false = ไม่แก้ไขรูป

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'brand': brand,
        'model': model,
        'number': number,
      };

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client.from(_table).update(updateData).eq('vehicle_id', vehicleId);
    } catch (e) {
      print('Error updating vehicle: $e');
      throw Exception('Failed to update vehicle: $e');
    }
  }

  static Future<void> delete(int vehicleId) async {
    try {
      await _client.from(_table).delete().eq('vehicle_id', vehicleId);
    } catch (e) {
      print('Error deleting vehicle: $e');
      throw Exception('Failed to delete vehicle: $e');
    }
  }
}
