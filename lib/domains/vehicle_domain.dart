import 'package:fullproject/models/vehicle_model.dart';
import 'package:fullproject/config/supabase_config.dart';

class VehicleDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'vehicle';

  static Future<List<VehicleModel>> getAll() async {
    final res = await _client.from(_table).select().order('vehicle_id');
    return res
        .map<VehicleModel>((json) => VehicleModel.fromJson(json))
        .toList();
  }

  static Future<List<VehicleModel>> getByHouse({required int houseId}) async {
    try {
      final res = await _client.from(_table).select().eq('house_id', houseId);

      return res
          .map<VehicleModel>((json) => VehicleModel.fromJson(json))
          .toList();
    } catch (e) {
      // Log the error for debugging
      print('Error fetching vehicles for house $houseId: $e');

      return [];
    }
  }

  static Future<void> create({
    required int houseId,
    required String brand,
    required String model,
    required String number,
    String? img,
  }) async {
    await _client.from(_table).insert({
      'house_id': houseId,
      'brand': brand,
      'model': model,
      'number': number,
      'img': img,
    });
  }

  static Future<void> update({
    required int vehicleId,
    required String brand,
    required String model,
    required String number,
    String? img,
  }) async {
    await _client
        .from(_table)
        .update({'brand': brand, 'model': model, 'number': number, 'img': img})
        .eq('vehicle_id', vehicleId);
  }

  static Future<void> delete(int vehicleId) async {
    await _client.from(_table).delete().eq('vehicle_id', vehicleId);
  }
}
