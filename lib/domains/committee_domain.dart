import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/committee_model.dart';

class CommitteeDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'committee';

  // ดึงข้อมูล committee ทั้งหมด
  static Future<List<CommitteeModel>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('committee_id');

      return (response as List)
          .map((data) => CommitteeModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch committees: $e');
    }
  }

  // ดึงข้อมูล committee ตาม village_id
  static Future<List<CommitteeModel>> getByVillageId(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .order('committee_id');

      return (response as List)
          .map((data) => CommitteeModel.fromJson(data))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch committees for village $villageId: $e');
    }
  }

  // ดึงข้อมูล committee ตาม committee_id
  static Future<CommitteeModel?> getById(int committeeId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('committee_id', committeeId)
          .maybeSingle();

      if (response == null) return null;
      return CommitteeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch committee $committeeId: $e');
    }
  }

  // ดึงข้อมูล committee ตาม house_id
  static Future<CommitteeModel?> getByHouseId(int houseId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('house_id', houseId)
          .maybeSingle();

      if (response == null) return null;
      return CommitteeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch committee for house $houseId: $e');
    }
  }

  // เพิ่มข้อมูล committee ใหม่
  static Future<CommitteeModel> create(CommitteeModel committee) async {
    try {
      final response = await _client
          .from(_table)
          .insert(committee.toJson())
          .select()
          .single();

      return CommitteeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create committee: $e');
    }
  }

  // อัปเดตข้อมูล committee
  static Future<CommitteeModel> update(
    int committeeId,
    CommitteeModel committee,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .update(committee.toJson())
          .eq('committee_id', committeeId)
          .select()
          .single();

      return CommitteeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update committee $committeeId: $e');
    }
  }

  // ลบข้อมูล committee
  static Future<void> delete(int committeeId) async {
    try {
      await _client.from(_table).delete().eq('committee_id', committeeId);
    } catch (e) {
      throw Exception('Failed to delete committee $committeeId: $e');
    }
  }

  // ตรวจสอบว่า house_id มี committee หรือไม่
  static Future<bool> hasCommitteeByHouseId(int houseId) async {
    try {
      final committee = await getByHouseId(houseId);
      return committee != null;
    } catch (e) {
      throw Exception('Failed to check committee for house $houseId: $e');
    }
  }
}
