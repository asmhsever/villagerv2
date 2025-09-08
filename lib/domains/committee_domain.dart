import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/committee_model.dart';
import 'package:fullproject/services/image_service.dart';

class CommitteeDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'committee';

  // Get all committees
  static Future<List<CommitteeModel>> getAll() async {
    try {
      final res = await _client.from(_table).select().order('committee_id');
      return res
          .map<CommitteeModel>((json) => CommitteeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching all committees: $e');
      return [];
    }
  }

  // Get committees by village
  static Future<List<CommitteeModel>> getByVillage({
    required int villageId,
  }) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .order('committee_id');

      return res
          .map<CommitteeModel>((json) => CommitteeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching committees for village $villageId: $e');
      return [];
    }
  }

  // Get committees by house
  static Future<List<CommitteeModel>> getByHouse({required int houseId}) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('house_id', houseId)
          .order('committee_id');

      return res
          .map<CommitteeModel>((json) => CommitteeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching committees for house $houseId: $e');
      return [];
    }
  }

  // Get committee by ID
  static Future<CommitteeModel?> getById({required int committeeId}) async {
    try {
      final res = await _client
          .from(_table)
          .select()
          .eq('committee_id', committeeId)
          .single();

      return CommitteeModel.fromJson(res);
    } catch (e) {
      print('Error fetching committee with ID $committeeId: $e');
      return null;
    }
  }

  // Create new committee
  static Future<CommitteeModel?> create({
    required int villageId,
    required int houseId,
    required String firstName,
    required String lastName,
    required String phone,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
  }) async {
    try {
      // Validation
      if (firstName.trim().isEmpty)
        throw ArgumentError('First name cannot be empty');
      if (lastName.trim().isEmpty)
        throw ArgumentError('Last name cannot be empty');
      if (phone.trim().isEmpty) throw ArgumentError('Phone cannot be empty');

      // 1. สร้าง committee ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
            'village_id': villageId,
            'house_id': houseId,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'phone': phone.trim(),
            'img': null,
          })
          .select()
          .single();

      final createdCommittee = CommitteeModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (imageFile != null && createdCommittee.committeeId != null) {
        final imageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "committee",
          rowName: "committee_id",
          rowImgName: "img",
          rowKey: createdCommittee.committeeId!,
          bucketPath: "committee",
          imgName: "committee",
        );

        // 3. อัปเดต committee ด้วย imageUrl
        if (imageUrl != null) {
          await _client
              .from(_table)
              .update({'img': imageUrl})
              .eq('committee_id', createdCommittee.committeeId!);

          // Return committee ที่มี imageUrl
          return CommitteeModel(
            villageId: createdCommittee.villageId,
            houseId: createdCommittee.houseId,
            committeeId: createdCommittee.committeeId,
            firstName: createdCommittee.firstName,
            lastName: createdCommittee.lastName,
            phone: createdCommittee.phone,
            img: imageUrl,
          );
        }
      }

      return createdCommittee;
    } catch (e) {
      print('Error creating committee: $e');
      throw Exception('Failed to create committee: $e');
    }
  }

  // Update committee
  static Future<void> update({
    required int committeeId,
    required String firstName,
    required String lastName,
    required String phone,
    int? villageId,
    int? houseId,
    dynamic imageFile, // รองรับทั้ง File และ Uint8List
    bool removeImage = false,
  }) async {
    try {
      // Validation
      if (committeeId <= 0)
        throw ArgumentError('Committee ID must be positive');
      if (firstName.trim().isEmpty)
        throw ArgumentError('First name cannot be empty');
      if (lastName.trim().isEmpty)
        throw ArgumentError('Last name cannot be empty');
      if (phone.trim().isEmpty) throw ArgumentError('Phone cannot be empty');

      String? finalImageUrl;

      if (removeImage) {
        finalImageUrl = null;
      } else if (imageFile != null) {
        finalImageUrl = await SupabaseImage().uploadImage(
          imageFile: imageFile,
          tableName: "committee",
          rowName: "committee_id",
          rowImgName: "img",
          rowKey: committeeId,
          bucketPath: "committee",
          imgName: "committee",
        );
      }

      final Map<String, dynamic> updateData = {
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone': phone.trim(),
      };

      // เพิ่ม villageId และ houseId ถ้ามีการส่งมา
      if (villageId != null) updateData['village_id'] = villageId;
      if (houseId != null) updateData['house_id'] = houseId;

      // เพิ่ม img field เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeImage || imageFile != null) {
        updateData['img'] = finalImageUrl;
      }

      await _client
          .from(_table)
          .update(updateData)
          .eq('committee_id', committeeId);
    } catch (e) {
      print('Error updating committee: $e');
      throw Exception('Failed to update committee: $e');
    }
  }

  // Delete committee
  static Future<void> delete(int committeeId) async {
    try {
      // Validation
      if (committeeId <= 0)
        throw ArgumentError('Committee ID must be positive');

      // 1. ดึงข้อมูล committee เพื่อเช็ค imageUrl ก่อน
      final response = await _client
          .from(_table)
          .select('img')
          .eq('committee_id', committeeId)
          .single();

      final imageUrl = response['img'] as String?;

      // 2. ลบรูปภาพออกจาก storage ก่อน (ถ้ามี)
      if (imageUrl != null && imageUrl.isNotEmpty) {
        await SupabaseImage().deleteImage(
          bucketPath: "committee",
          imageUrl: imageUrl,
        );
      }

      // 3. ลบข้อมูล committee จากฐานข้อมูล
      await _client.from(_table).delete().eq('committee_id', committeeId);
    } catch (e) {
      print('Error deleting committee: $e');
      throw Exception('Failed to delete committee: $e');
    }
  }

  // Search committees by name
  static Future<List<CommitteeModel>> searchByName({
    required String searchTerm,
  }) async {
    try {
      if (searchTerm.trim().isEmpty) return [];

      final res = await _client
          .from(_table)
          .select()
          .or(
            'first_name.ilike.%${searchTerm.trim()}%,last_name.ilike.%${searchTerm.trim()}%',
          )
          .order('committee_id');

      return res
          .map<CommitteeModel>((json) => CommitteeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching committees: $e');
      return [];
    }
  }

  // Get committees with pagination
  static Future<List<CommitteeModel>> getPaginated({
    required int offset,
    required int limit,
    int? villageId,
  }) async {
    try {
      var query = _client.from(_table).select();

      if (villageId != null) {
        query = query.eq('village_id', villageId);
      }

      final res = await query
          .range(offset, offset + limit - 1)
          .order('committee_id');

      return res
          .map<CommitteeModel>((json) => CommitteeModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching paginated committees: $e');
      return [];
    }
  }

  // ตรวจสอบว่า house_id มี committee หรือไม่
  static Future<bool> hasCommitteeByHouseId(int houseId) async {
    try {
      final committee = await getByHouse(houseId: houseId);
      return committee != null;
    } catch (e) {
      throw Exception('Failed to check committee for house $houseId: $e');
    }
  }
}
