import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/village_model.dart';
import 'package:fullproject/services/image_service.dart';

class VillageDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'village';

  // Create - เพิ่มหมู่บ้านใหม่
  static Future<VillageModel?> create({
    required int provinceId,
    required String name,
    required String address,
    required String salePhone,
    required String zipCode,
    dynamic logoImageFile, // รองรับทั้ง File และ Uint8List สำหรับ logo
    String? ruleImgs,
  }) async {
    try {
      // 1. สร้าง village ก่อน (ยังไม่มี logo)
      final response = await _client
          .from(_tableName)
          .insert({
            'province_id': provinceId,
            'name': name,
            'address': address,
            'sale_phone': salePhone,
            'zip_code': zipCode,
            'rule_imgs': ruleImgs,
            'logo_img': null,
          })
          .select()
          .single();

      final createdVillage = VillageModel.fromJson(response);

      // 2. อัปโหลดรูป logo (ถ้ามี)
      if (logoImageFile != null && createdVillage.villageId != 0) {
        final logoUrl = await SupabaseImage().uploadImage(
          bucketPath: "village",
          imgName: "village_logo",
          imageFile: logoImageFile,
          tableName: "village",
          rowName: "village_id",
          rowImgName: "logo_img",
          rowKey: createdVillage.villageId,
        );

        // 3. อัปเดต village ด้วย logoUrl
        if (logoUrl != null) {
          await _client
              .from(_tableName)
              .update({'logo_img': logoUrl})
              .eq('village_id', createdVillage.villageId);

          // Return village ที่มี logoUrl
          return VillageModel(
            villageId: createdVillage.villageId,
            provinceId: createdVillage.provinceId,
            name: createdVillage.name,
            address: createdVillage.address,
            salePhone: createdVillage.salePhone,
            zipCode: createdVillage.zipCode,
            logoImg: logoUrl,
            ruleImgs: createdVillage.ruleImgs,
          );
        }
      }

      return createdVillage;
    } catch (e) {
      print('Error creating village: $e');
      return null;
    }
  }

  // Update - อัปเดตข้อมูลหมู่บ้าน
  static Future<VillageModel?> update({
    required int villageId,
    required int provinceId,
    required String name,
    required String address,
    required String salePhone,
    required String zipCode,
    String? ruleImgs,
    dynamic logoImageFile, // รองรับทั้ง File และ Uint8List สำหรับ logo
    bool removeLogo = false, // flag สำหรับลบ logo
  }) async {
    try {
      String? finalLogoUrl;

      if (removeLogo) {
        // ลบรูป logo
        finalLogoUrl = null;
      } else if (logoImageFile != null) {
        // อัปโหลด logo ใหม่
        finalLogoUrl = await SupabaseImage().uploadImage(
          imageFile: logoImageFile,
          tableName: "village",
          rowName: "village_id",
          rowImgName: "logo_img",
          rowKey: villageId,
          bucketPath: "village",
          imgName: "village_logo",
        );
      }
      // ถ้า logoImageFile เป็น null และ removeLogo เป็น false = ไม่แก้ไข logo

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'province_id': provinceId,
        'name': name,
        'address': address,
        'sale_phone': salePhone,
        'zip_code': zipCode,
        'rule_imgs': ruleImgs,
      };

      // เพิ่ม logo_img field เฉพาะเมื่อต้องการเปลี่ยน logo
      if (removeLogo || logoImageFile != null) {
        updateData['logo_img'] = finalLogoUrl;
      }

      final response = await _client
          .from(_tableName)
          .update(updateData)
          .eq('village_id', villageId)
          .select()
          .single();

      return VillageModel.fromJson(response);
    } catch (e) {
      print('Error updating village: $e');
      return null;
    }
  }

  // Delete - ลบหมู่บ้าน
  static Future<bool> delete(int villageId) async {
    try {
      // 1. ดึงข้อมูล village เพื่อเช็ค logoImg ก่อน
      final response = await _client
          .from(_tableName)
          .select('logo_img')
          .eq('village_id', villageId)
          .single();

      final logoUrl = response['logo_img'] as String?;

      // 2. ลบรูป logo ออกจาก storage ก่อน (ถ้ามี)
      if (logoUrl != null && logoUrl.isNotEmpty) {
        await SupabaseImage().deleteImage(
          bucketPath: "village",
          imageUrl: logoUrl,
        );
      }

      // 3. ลบข้อมูล village จากฐานข้อมูล
      await _client.from(_tableName).delete().eq('village_id', villageId);

      return true;
    } catch (e) {
      print('Error deleting village: $e');
      return false;
    }
  }

  // Read - ดึงข้อมูลหมู่บ้านทั้งหมด
  static Future<List<VillageModel>> getAllVillages() async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .order('village_id', ascending: true);

      return (response as List)
          .map((json) => VillageModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching villages: $e');
      return [];
    }
  }

  // Read - ดึงข้อมูลหมู่บ้านตาม ID
  static Future<VillageModel?> getVillageById(int villageId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('village_id', villageId)
          .single();

      return VillageModel.fromJson(response);
    } catch (e) {
      print('Error fetching village by ID: $e');
      return null;
    }
  }

  // Read - ดึงข้อมูลหมู่บ้านตาม Province ID
  static Future<List<VillageModel>> getVillagesByProvinceId(
    int provinceId,
  ) async {
    try {
      final response = await _client
          .from(_tableName)
          .select()
          .eq('province_id', provinceId)
          .order('village_id', ascending: true);

      return (response as List)
          .map((json) => VillageModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching villages by province ID: $e');
      return [];
    }
  }

  // Realtime - Stream ข้อมูลหมู่บ้าน
  static Stream<List<VillageModel>> watchVillages() {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['village_id'])
        .order('village_id', ascending: true)
        .map(
          (data) => data.map((json) => VillageModel.fromJson(json)).toList(),
        );
  }

  // Realtime - Stream ข้อมูลหมู่บ้านตาม Province ID
  static Stream<List<VillageModel>> watchVillagesByProvince(int provinceId) {
    return _client
        .from(_tableName)
        .stream(primaryKey: ['village_id'])
        .eq('province_id', provinceId)
        .order('village_id', ascending: true)
        .map(
          (data) => data.map((json) => VillageModel.fromJson(json)).toList(),
        );
  }
}
