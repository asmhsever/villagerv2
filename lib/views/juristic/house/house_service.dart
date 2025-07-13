// 📁 lib/views/juristic/house/house_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'house_model.dart';
import 'car_model.dart';
import 'animal_model.dart';
import 'villager_model.dart';

class HouseService {
  final _client = Supabase.instance.client;

  Future<List<House>> getByVillage(int villageId) async {
    final result = await _client
        .from('house')
        .select()
        .eq('village_id', villageId);

    return (result as List).map((e) => House.fromMap(e)).toList();
  }

  Future<House> getById(int houseId) async {
    final result = await _client
        .from('house')
        .select()
        .eq('house_id', houseId)
        .maybeSingle();

    return House.fromMap(result);
  }

  Future<List<Car>> getCars(int houseId) async {
    final result = await _client
        .from('car')
        .select()
        .eq('house_id', houseId);

    return (result as List).map((e) => Car.fromMap(e)).toList();
  }

  Future<List<Animal>> getAnimals(int houseId) async {
    final result = await _client
        .from('animal')
        .select()
        .eq('house_id', houseId);

    return (result as List).map((e) => Animal.fromMap(e)).toList();
  }

  Future<List<Villager>> getVillagers(int houseId) async {
    final result = await _client
        .from('villager')
        .select()
        .eq('house_id', houseId);

    return (result as List).map((e) => Villager.fromMap(e)).toList();
  }
}
