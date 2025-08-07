import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/house_model.dart';

class HouseDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'house';

  // Create - เพิ่มบ้านใหม่
  static Future<HouseModel?> create({required HouseModel house}) async {
    try {
      final response = await _client
          .from(_table)
          .insert(house.toJson())
          .select()
          .single();

      return HouseModel.fromJson(response);
    } catch (e) {
      print('Error creating house: $e');
      return null;
    }
  }

  // Read - อ่านบ้านทั้งหมดในระบบ (Admin only)
  static Future<List<HouseModel>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all houses: $e');
      return [];
    }
  }

  // Read - อ่านบ้านทั้งหมดในหมู่บ้าน
  static Future<List<HouseModel>> getAllInVillage({
    required int villageId,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting houses in village: $e');
      return [];
    }
  }

  // Read - อ่านบ้านตาม ID
  static Future<HouseModel?> getById(int houseId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('house_id', houseId)
          .single();

      return HouseModel.fromJson(response);
    } catch (e) {
      print('Error getting house by ID: $e');
      return null;
    }
  }

  // Read - อ่านบ้านตาม User ID
  static Future<List<HouseModel>> getByUserId(int userId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('user_id', userId)
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting houses by user ID: $e');
      return [];
    }
  }

  // Read - อ่านบ้านตามหมายเลขบ้าน
  static Future<HouseModel?> getByHouseNumber({
    required int villageId,
    required String houseNumber,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('house_number', houseNumber)
          .single();

      return HouseModel.fromJson(response);
    } catch (e) {
      print('Error getting house by number: $e');
      return null;
    }
  }

  // Read - อ่านบ้านตามสถานะ
  static Future<List<HouseModel>> getByStatus({
    required int villageId,
    required String status,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('status', status)
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting houses by status: $e');
      return [];
    }
  }

  // Read - อ่านบ้านตามประเภทความเป็นเจ้าของ
  static Future<List<HouseModel>> getByOwnershipType({
    required int villageId,
    required String ownershipType,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('ownership_type', ownershipType)
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting houses by ownership type: $e');
      return [];
    }
  }

  // Read - อ่านบ้านตามประเภทบ้าน
  static Future<List<HouseModel>> getByHouseType({
    required int villageId,
    required String houseType,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('house_type', houseType)
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting houses by house type: $e');
      return [];
    }
  }

  // Read - อ่านบ้านที่ใช้งานอยู่
  static Future<List<HouseModel>> getActiveHouses(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('usage_status', 'active')
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting active houses: $e');
      return [];
    }
  }

  // Read - อ่านบ้านที่ว่าง
  static Future<List<HouseModel>> getVacantHouses(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('status', 'vacant')
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting vacant houses: $e');
      return [];
    }
  }

  // Read - ค้นหาบ้านตามชื่อเจ้าของ
  static Future<List<HouseModel>> searchByOwner({
    required int villageId,
    required String ownerName,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .ilike('owner', '%$ownerName%')
          .order('house_number', ascending: true);

      return response
          .map<HouseModel>((json) => HouseModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching houses by owner: $e');
      return [];
    }
  }

  // Update - อัพเดทข้อมูลบ้าน
  static Future<HouseModel?> update({
    required int houseId,
    required HouseModel updatedHouse,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .update(updatedHouse.toJson())
          .eq('house_id', houseId)
          .select()
          .single();

      return HouseModel.fromJson(response);
    } catch (e) {
      print('Error updating house: $e');
      return null;
    }
  }

  // Update - อัพเดทสถานะบ้าน
  static Future<bool> updateStatus({
    required int houseId,
    required String status,
  }) async {
    try {
      await _client
          .from(_table)
          .update({'status': status})
          .eq('house_id', houseId);

      return true;
    } catch (e) {
      print('Error updating house status: $e');
      return false;
    }
  }

  // Update - อัพเดทข้อมูลเจ้าของ
  static Future<bool> updateOwner({
    required int houseId,
    required String owner,
    required String phone,
    int? userId,
  }) async {
    try {
      final updateData = {
        'owner': owner,
        'phone': phone,
        if (userId != null) 'user_id': userId,
      };

      await _client.from(_table).update(updateData).eq('house_id', houseId);

      return true;
    } catch (e) {
      print('Error updating house owner: $e');
      return false;
    }
  }

  // Update - อัพเดทรูปภาพบ้าน
  static Future<bool> updateImage({
    required int houseId,
    required String imageUrl,
  }) async {
    try {
      await _client
          .from(_table)
          .update({'img': imageUrl})
          .eq('house_id', houseId);

      return true;
    } catch (e) {
      print('Error updating house image: $e');
      return false;
    }
  }

  // Delete - ลบบ้าน
  static Future<bool> delete(int houseId) async {
    try {
      await _client.from(_table).delete().eq('house_id', houseId);

      return true;
    } catch (e) {
      print('Error deleting house: $e');
      return false;
    }
  }

  // Utility - นับจำนวนบ้านในหมู่บ้าน
  static Future<int> countHousesInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('house_id')
          .eq('village_id', villageId);

      return response.length;
    } catch (e) {
      print('Error counting houses in village: $e');
      return 0;
    }
  }

  // Utility - นับจำนวนบ้านตามสถานะ
  static Future<Map<String, int>> getHouseCountByStatus(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('status')
          .eq('village_id', villageId);

      Map<String, int> statusCount = {};
      for (var house in response) {
        String status = house['status'] ?? 'unknown';
        statusCount[status] = (statusCount[status] ?? 0) + 1;
      }

      return statusCount;
    } catch (e) {
      print('Error getting house count by status: $e');
      return {};
    }
  }

  // Utility - นับจำนวนบ้านตามประเภท
  static Future<Map<String, int>> getHouseCountByType(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('house_type')
          .eq('village_id', villageId);

      Map<String, int> typeCount = {};
      for (var house in response) {
        String type = house['house_type'] ?? 'unknown';
        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      return typeCount;
    } catch (e) {
      print('Error getting house count by type: $e');
      return {};
    }
  }

  // Utility - สถิติภาพรวมของหมู่บ้าน
  static Future<Map<String, dynamic>> getVillageStats(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('status, house_type, ownership_type, usage_status')
          .eq('village_id', villageId);

      int totalHouses = response.length;
      int ownedHouses = 0;
      int vacantHouses = 0;
      int activeHouses = 0;
      Map<String, int> typeCount = {};
      Map<String, int> ownershipCount = {};

      for (var house in response) {
        // นับสถานะ
        if (house['status'] == 'owned') ownedHouses++;
        if (house['status'] == 'vacant') vacantHouses++;
        if (house['usage_status'] == 'active') activeHouses++;

        // นับประเภทบ้าน
        String type = house['house_type'] ?? 'unknown';
        typeCount[type] = (typeCount[type] ?? 0) + 1;

        // นับประเภทความเป็นเจ้าของ
        String ownership = house['ownership_type'] ?? 'unknown';
        ownershipCount[ownership] = (ownershipCount[ownership] ?? 0) + 1;
      }

      return {
        'total_houses': totalHouses,
        'owned_houses': ownedHouses,
        'vacant_houses': vacantHouses,
        'active_houses': activeHouses,
        'occupancy_rate': totalHouses > 0
            ? (ownedHouses / totalHouses * 100)
            : 0,
        'house_types': typeCount,
        'ownership_types': ownershipCount,
      };
    } catch (e) {
      print('Error getting village stats: $e');
      return {};
    }
  }
}
