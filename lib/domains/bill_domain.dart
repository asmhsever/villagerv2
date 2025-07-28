import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/config/supabase_config.dart';

class BillDomain {
  final _client = SupabaseConfig.client;
  final String _table = 'bill';

  // 🟢 READ

  /// ดึงบิลทั้งหมดในระบบ
  Future<List<BillModel>> getAll() async {
    final response = await _client.from(_table).select();
    return (response as List).map((e) => BillModel.fromJson(e)).toList();
  }

  /// ดึงบิลเฉพาะของบ้านในหมู่บ้านนั้น ๆ
  Future<List<BillModel>> getByVillage(int villageId) async {
    final houseResponse = await _client
        .from('house')
        .select('house_id')
        .eq('village_id', villageId);

    final houseIds = (houseResponse as List)
        .map((e) => e['house_id'] as int)
        .toList();

    if (houseIds.isEmpty) return [];

    final billResponse = await _client
        .from(_table)
        .select()
        .inFilter('house_id', houseIds);

    return (billResponse as List)
        .map((e) => BillModel.fromJson(e))
        .toList();
  }

  // 🟡 CREATE

  Future<void> create(BillModel bill) async {
    await _client.from(_table).insert(bill.toJson());
  }

  // 🟠 UPDATE

  Future<void> update(BillModel bill) async {
    await _client
        .from(_table)
        .update(bill.toJson())
        .eq('bill_id', bill.billId);
  }

  // 🔴 DELETE

  Future<void> delete(int billId) async {
    await _client.from(_table).delete().eq('bill_id', billId);
  }
}
