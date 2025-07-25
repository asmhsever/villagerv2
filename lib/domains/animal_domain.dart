import 'package:fullproject/models/animal_model.dart';
import 'package:fullproject/config/supabase_config.dart';

class AnimalDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'animal';

  static Future<List<AnimalModel>> getAll() async {
    final res = await _client.from(_table).select().order('animal_id');
    return res.map<AnimalModel>((json) => AnimalModel.fromJson(json)).toList();
  }

  static Future<void> create({
    required int houseId,
    required String type,
    required String name,
    String? img,
  }) async {
    await _client.from(_table).insert({
      'house_id': houseId,
      'type': type,
      'name': name,
      'img': img,
    });
  }

  static Future<void> update({
    required int animalId,
    required String type,
    required String name,
    String? img,
  }) async {
    await _client
        .from(_table)
        .update({'type': type, 'name': name, 'img': img})
        .eq('animal_id', animalId);
  }

  static Future<void> delete(int animalId) async {
    await _client.from(_table).delete().eq('animal_id', animalId);
  }
}
