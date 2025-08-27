// lib/domains/committee_domain.dart
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/committee_model.dart';

class CommitteeDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'committee';

  // ====== Queries ======
  static Future<List<CommitteeModel>> getAll() async {
    try {
      final response = await _client.from(_table).select().order('committee_id');
      return (response as List).map((data) => CommitteeModel.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch committees: $e');
    }
  }

  static Future<List<CommitteeModel>> getByVillageId(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .order('committee_id');
      return (response as List).map((data) => CommitteeModel.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch committees for village $villageId: $e');
    }
  }

  static Future<CommitteeModel?> getById(int committeeId) async {
    try {
      final response = await _client.from(_table).select().eq('committee_id', committeeId).maybeSingle();
      if (response == null) return null;
      return CommitteeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch committee $committeeId: $e');
    }
  }

  static Future<CommitteeModel?> getByHouseId(int houseId) async {
    try {
      final response = await _client.from(_table).select().eq('house_id', houseId).maybeSingle();
      if (response == null) return null;
      return CommitteeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch committee for house $houseId: $e');
    }
  }

  // ====== Helpers ======
  /// หาเลข `committee_id` ถัดไปจากค่าปัจจุบัน (เริ่มที่ 1 หากยังไม่มีข้อมูล)
  static Future<int> _getNextCommitteeId() async {
    try {
      final row = await _client
          .from(_table)
          .select('committee_id')
          .order('committee_id', ascending: false)
          .limit(1)
          .maybeSingle();
      final last = (row == null) ? 0 : (row['committee_id'] as int? ?? 0);
      return last + 1;
    } catch (_) {
      // ถ้า select ล้มเหลวให้เริ่มที่ 1 เพื่อไม่บล็อคการสร้าง
      return 1;
    }
  }

  // ====== Mutations ======
  /// สร้างคณะกรรมการใหม่ — ถ้าไม่ได้ส่ง committee_id มา จะเติมให้อัตโนมัติ
  static Future<CommitteeModel> create(CommitteeModel committee) async {
    try {
      final payload = committee.toJson();

      // ถ้า model ไม่ได้ใส่หรือเป็น null ให้เติมอัตโนมัติ
      if (!payload.containsKey('committee_id') || payload['committee_id'] == null) {
        payload['committee_id'] = await _getNextCommitteeId();
      }

      final response = await _client.from(_table).insert(payload).select().single();
      return CommitteeModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create committee: $e');
    }
  }

  static Future<CommitteeModel> update(int committeeId, CommitteeModel committee) async {
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

  static Future<void> delete(int committeeId) async {
    try {
      await _client.from(_table).delete().eq('committee_id', committeeId);
    } catch (e) {
      throw Exception('Failed to delete committee $committeeId: $e');
    }
  }

  static Future<bool> hasCommitteeByHouseId(int houseId) async {
    try {
      final committee = await getByHouseId(houseId);
      return committee != null;
    } catch (e) {
      throw Exception('Failed to check committee for house $houseId: $e');
    }
  }
}
