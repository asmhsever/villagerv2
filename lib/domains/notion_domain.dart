import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/notion_model.dart';

class NotionDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'notion';

  // ✅ Get All
  static Future<Map<String, dynamic>> getAllNotions() async {
    try {
      final response = await _client
          .from(_tableName)
          .select("*")
          .order('created_at', ascending: false); // ✅ แก้ชื่อ field
      final notions = (response as List)
          .map((json) => NotionModel.fromJson(json))
          .toList();
      return {'success': true, 'notions': notions, 'count': notions.length};
    } catch (e) {
      print("Error get all notion : $e ");
      return {'success': false};
    }
  }

  // ✅ Get by village with limit
  static Future<Map<String, dynamic>> getRecentNotions({
    int limit = 10,
    required int villageId,
  }) async {
    try {
      final response = await _client
          .from(_tableName)
          .select("*")
          .eq('village_id', villageId)
          .order('created_at', ascending: false)
          .limit(limit);
      final notions = (response as List)
          .map((json) => NotionModel.fromJson(json))
          .toList();
      return {'success': true, 'notions': notions, 'count': notions.length};
    } catch (e) {
      print("error getRecentNotions : $e");
      return {'success': false};
    }
  }

  static Future<void> delete(int notionId) async {
    await _client.from(_tableName).delete().eq('notion_id', notionId);
  }

  static Future<List<NotionModel>> getByVillage(int villageId) async {
    try {
      final response = await _client
          .from(_tableName)
          .select('*')
          .eq('village_id', villageId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => NotionModel.fromJson(e))
          .toList();
    } catch (e) {
      print("Error in getByVillage: $e");
      return [];
    }
  }


  // ✅ Create
  Future<void> create(NotionModel notion) async {
    await _client.from(_tableName).insert(notion.toJson());
  }

  // ✅ Update
  Future<void> update(NotionModel notion) async {
    await _client
        .from(_tableName)
        .update(notion.toJson())
        .eq('notion_id', notion.notionId);
  }


}

