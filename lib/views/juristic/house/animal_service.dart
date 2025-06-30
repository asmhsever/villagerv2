// 📁 lib/services/animal_service.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnimalService {
  final client = Supabase.instance.client;

  Future<void> addAnimalWithImage({
    required int houseId,
    required String name,
    required String type,
    required XFile imageFile,
  }) async {
    // Step 1: Insert new animal (img will be set to animal_id.jpg by trigger)
    final insertResponse = await client.from('animal').insert({
      'name': name,
      'type': type,
      'house_id': houseId,
    }).select('animal_id').single();

    final animalId = insertResponse['animal_id'];
    final fileExt = imageFile.path.split('.').last;
    final filename = '$animalId.$fileExt';
    final fileBytes = await imageFile.readAsBytes();

    // Step 2: Upload image to Supabase Storage
    await client.storage
        .from('animal-images')
        .uploadBinary(filename, fileBytes, fileOptions: const FileOptions(upsert: true));
  }

  Future<void> updateAnimalWithImage({
    required int animalId,
    required int houseId,
    required String name,
    required String type,
    XFile? imageFile, // optional update
  }) async {
    await client.from('animal').update({
      'name': name,
      'type': type,
      'house_id': houseId,
    }).eq('animal_id', animalId);

    if (imageFile != null) {
      final fileExt = imageFile.path.split('.').last;
      final filename = '$animalId.$fileExt';
      final fileBytes = await imageFile.readAsBytes();

      await client.storage
          .from('animal-images')
          .uploadBinary(filename, fileBytes, fileOptions: const FileOptions(upsert: true));
    }
  }
}
