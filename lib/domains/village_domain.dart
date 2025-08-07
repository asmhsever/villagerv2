import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/village_model.dart';

class VillageDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'village';

  // Create - เพิ่มหมู่บ้านใหม่
  static Future<VillageModel?> createVillage(VillageModel village) async {
    try {
      final response = await _client
          .from(_tableName)
          .insert(village.toJson())
          .select()
          .single();

      return VillageModel.fromJson(response);
    } catch (e) {
      print('Error creating village: $e');
      return null;
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

  // Update - อัปเดตข้อมูลหมู่บ้าน
  static Future<VillageModel?> updateVillage(VillageModel village) async {
    try {
      final response = await _client
          .from(_tableName)
          .update(village.toJson())
          .eq('village_id', village.villageId)
          .select()
          .single();

      return VillageModel.fromJson(response);
    } catch (e) {
      print('Error updating village: $e');
      return null;
    }
  }

  // Delete - ลบหมู่บ้าน
  static Future<bool> deleteVillage(int villageId) async {
    try {
      await _client.from(_tableName).delete().eq('village_id', villageId);

      return true;
    } catch (e) {
      print('Error deleting village: $e');
      return false;
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

  // Bulk Operations - เพิ่มหลายรายการ
  static Future<List<VillageModel>> createVillagesBulk(
    List<VillageModel> villages,
  ) async {
    try {
      final data = villages.map((v) => v.toJson()).toList();
      final response = await _client.from(_tableName).insert(data).select();

      return (response as List)
          .map((json) => VillageModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error creating villages bulk: $e');
      return [];
    }
  }

  // Bulk Operations - อัปเดตหลายรายการ
  static Future<List<VillageModel>> updateVillagesBulk(
    List<VillageModel> villages,
  ) async {
    try {
      final List<VillageModel> updatedVillages = [];

      for (final village in villages) {
        final updated = await updateVillage(village);
        if (updated != null) {
          updatedVillages.add(updated);
        }
      }

      return updatedVillages;
    } catch (e) {
      print('Error updating villages bulk: $e');
      return [];
    }
  }
}
