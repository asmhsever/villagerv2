import 'package:fullproject/models/guard_model.dart';
import 'package:fullproject/config/supabase_config.dart';

class GuardDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'guard';

  static Future<List<GuardModel>> getAll() async {
    final res = await _client.from(_table).select().order('guard_id');
    return res.map<GuardModel>((json) => GuardModel.fromJson(json)).toList();
  }

  static Future<void> create({
    required int villageId,
    required String firstName,
    required String lastName,
    required String phone,
    required String nickname,
    String? img,
  }) async {
    await _client.from(_table).insert({
      'village_id': villageId,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'nickname': nickname,
      'img': img,
    });
  }

  // Read - ดึงข้อมูลยามทั้งหมดตาม Village ID
  static Future<List<GuardModel>> getByVillageId(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId);

      return response
          .map<GuardModel>((json) => GuardModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching guards by village ID: $e');
      return []; // Return empty list instead of null
    }
  }

  static Future<void> update({
    required int guardId,
    required String firstName,
    required String lastName,
    required String phone,
    required String nickname,
    String? img,
  }) async {
    await _client
        .from(_table)
        .update({
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'nickname': nickname,
          'img': img,
        })
        .eq('guard_id', guardId);
  }

  static Future<void> delete(int guardId) async {
    await _client.from(_table).delete().eq('guard_id', guardId);
  }
}
