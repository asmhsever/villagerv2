// lib/views/juristic/house/villager_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'villager_model.dart';

class VillagerService {
  final _client = Supabase.instance.client;

  Future<List<Villager>> getByHouse(int houseId) async {
    final res = await _client
        .from('villager')
        .select()
        .eq('house_id', houseId);
    return List<Map<String, dynamic>>.from(res)
        .map((e) => Villager.fromMap(e))
        .toList();
  }

  Future<Villager?> insertVillager(Villager villager) async {
    final inserted = await _client
        .from('villager')
        .insert(villager.toInsertMap())
        .select()
        .maybeSingle();
    return inserted != null ? Villager.fromMap(inserted) : null;
  }

  Future<void> updateVillager(Villager villager) async {
    await _client
        .from('villager')
        .update(villager.toMap())
        .eq('villager_id', villager.villagerId);
  }

  Future<void> deleteVillager(int villagerId) async {
    await _client
        .from('villager')
        .delete()
        .eq('villager_id', villagerId);
  }
}
