// lib/services/bill_service.dart
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/bill_model.dart';

class BillService {
  final String table = 'bill';

  Future<List<BillModel>> getAllBills() async {
    final response = await SupabaseConfig.client.from(table).select();
    return (response as List).map((e) => BillModel.fromJson(e)).toList();
  }

  Future<void> addBill(BillModel bill) async {
    await SupabaseConfig.client.from(table).insert(bill.toJson());
  }

  Future<void> updateBill(BillModel bill) async {
    await SupabaseConfig.client.from(table).update(bill.toJson()).eq('bill_id', bill.billId);
  }

  Future<void> deleteBill(int id) async {
    await SupabaseConfig.client.from(table).delete().eq('bill_id', id);
  }
}