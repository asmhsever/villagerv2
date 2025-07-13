// lib/views/juristic/house/car_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'car_model.dart';

class CarService {
  final _client = Supabase.instance.client;

  Future<List<Car>> getCarsByHouse(int houseId) async {
    final res = await _client
        .from('car')
        .select()
        .eq('house_id', houseId);
    return List<Map<String, dynamic>>.from(res)
        .map((e) => Car.fromMap(e))
        .toList();
  }

  Future<Car?> insertCar(Car car, File imageFile) async {
    final inserted = await _client
        .from('car')
        .insert(car.toInsertMap())
        .select()
        .maybeSingle();
    if (inserted == null) return null;

    final newId = inserted['car_id'];
    final ext = imageFile.path.split('.').last;
    await _client.storage
        .from('car-images')
        .uploadBinary('$newId.$ext', await imageFile.readAsBytes(), fileOptions: const FileOptions(upsert: true));

    return Car.fromMap(inserted);
  }

  Future<void> updateCar(Car car) async {
    await _client
        .from('car')
        .update(car.toMap())
        .eq('car_id', car.carId);
  }

  Future<void> updateCarWithImage({
    required int carId,
    required int houseId,
    required String brand,
    required String model,
    required String number,
    File? imageFile,
  }) async {
    await _client.from('car').update({
      'house_id': houseId,
      'brand': brand,
      'model': model,
      'number': number,
    }).eq('car_id', carId);

    if (imageFile != null) {
      final ext = imageFile.path.split('.').last;
      await _client.storage
          .from('car-images')
          .uploadBinary('$carId.$ext', await imageFile.readAsBytes(), fileOptions: const FileOptions(upsert: true));
    }
  }

  Future<void> deleteCar(int carId) async {
    await _client
        .from('car')
        .delete()
        .eq('car_id', carId);
  }
}
