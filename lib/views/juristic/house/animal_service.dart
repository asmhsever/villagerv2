// lib/views/juristic/house/animal_service.dart

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'animal_model.dart';
import 'package:image_picker/image_picker.dart';


class AnimalService {
  final _client = Supabase.instance.client;

  Future<List<Animal>> getAnimalsByHouse(int houseId) async {
    final res = await _client
        .from('animal')
        .select()
        .eq('house_id', houseId);
    return List<Map<String, dynamic>>.from(res)
        .map((e) => Animal.fromMap(e))
        .toList();
  }

  Future<Animal?> insertAnimal(Animal animal, File imageFile) async {
    final inserted = await _client
        .from('animal')
        .insert(animal.toInsertMap())
        .select()
        .maybeSingle();
    if (inserted == null) return null;

    final newId = inserted['animal_id'];
    final ext = imageFile.path.split('.').last;
    await _client.storage
        .from('animal-images')
        .uploadBinary('$newId.$ext', await imageFile.readAsBytes(), fileOptions: const FileOptions(upsert: true));

    return Animal.fromMap(inserted);
  }

  Future<void> updateAnimal(Animal animal) async {
    await _client
        .from('animal')
        .update(animal.toMap())
        .eq('animal_id', animal.animalId);
  }

  Future<void> updateAnimalWithImage({
    required int animalId,
    required int houseId,
    required String name,
    required String type,
    XFile? imageFile,
  }) async {
    await _client.from('animal').update({
      'house_id': houseId,
      'name': name,
      'type': type,
    }).eq('animal_id', animalId);

    if (imageFile != null) {
      final ext = imageFile.path.split('.').last;
      await _client.storage
          .from('animal-images')
          .uploadBinary('$animalId.$ext', await imageFile.readAsBytes(), fileOptions: const FileOptions(upsert: true));
    }
  }

  Future<void> deleteAnimal(int animalId) async {
    await _client
        .from('animal')
        .delete()
        .eq('animal_id', animalId);
  }
}
