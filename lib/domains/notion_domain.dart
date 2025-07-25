import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/notion_model.dart';

class NotionDomain {
  static final _client = SupabaseConfig.client;
  static const String _tableName = 'notion';

  static Future<Map<String, dynamic>> getAllNotions() async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .select("*")
          .order('created_ad', ascending: false);
      final notions = response
          .map((json) => NotionModel.fromJson(json))
          .toList();
      return {'success': true, 'notions': notions, 'count': notions.length};
    } catch (e) {
      print("Error get all notion : $e ");
      return {'success': false};
    }
  }

  static Future<Map<String, dynamic>> getRecentNotions({
    int limit = 10,
    int? villageId,
  }) async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from(_tableName)
          .select("*")
          .eq('village_id', villageId!)
          .order('created_at', ascending: false)
          .limit(limit);
      final notions = response
          .map((json) => NotionModel.fromJson(json))
          .toList();
      return {'success': true, 'notions': notions, 'count': notions.length};
    } catch (e) {
      print("error getRecenNotion : ${e}");
      return {'success': false};
    }
  }
}
