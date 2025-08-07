import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/bill_model.dart';

class BillDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'bill';

  // Create - เพิ่มบิลใหม่
  static Future<BillModel?> create({required BillModel bill}) async {
    try {
      final response = await _client
          .from(_table)
          .insert(bill.toJson())
          .select()
          .single();

      return BillModel.fromJson(response);
    } catch (e) {
      print('Error creating bill: $e');
      return null;
    }
  }

  // Read - อ่านบิลทั้งหมดในระบบ (Admin only)
  static Future<List<BillModel>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('bill_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all bills: $e');
      return [];
    }
  }

  // Read - อ่านบิลทั้งหมดในหมู่บ้าน
  static Future<List<BillModel>> getAllInVillage({
    required int villageId,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select('*, house!inner(village_id)')
          .eq('house.village_id', villageId);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting bills in village: $e');
      return [];
    }
  }

  // Read - อ่านบิลทั้งหมดของบ้าน
  static Future<List<BillModel>> getAllInHouse({required int houseId}) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('house_id', houseId)
          .order('bill_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting bills in house: $e');
      return [];
    }
  }

  // Read - อ่านบิลตาม ID
  static Future<BillModel?> getById(int billId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('bill_id', billId)
          .single();

      return BillModel.fromJson(response);
    } catch (e) {
      print('Error getting bill by ID: $e');
      return null;
    }
  }

  // Read - อ่านบิลที่ยังไม่จ่ายในหมู่บ้าน
  static Future<List<BillModel>> getUnpaidInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('paid_status', 0)
          .order('due_date', ascending: true);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting unpaid bills in village: $e');
      return [];
    }
  }

  // Read - อ่านบิลที่ยังไม่จ่ายของบ้าน
  static Future<List<BillModel>> getUnpaidInHouse({
    required int houseId,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('house_id', houseId)
          .eq('paid_status', 0)
          .order('due_date', ascending: true);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting unpaid bills in house: $e');
      return [];
    }
  }

  // Read - อ่านบิลที่จ่ายแล้วในหมู่บ้าน
  static Future<List<BillModel>> getPaidInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('paid_status', 1)
          .order('paid_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting paid bills in village: $e');
      return [];
    }
  }

  // Read - อ่านบิลที่จ่ายแล้วของบ้าน
  static Future<List<BillModel>> getPaidInHouse({required int houseId}) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('house_id', houseId)
          .eq('paid_status', 1)
          .order('paid_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting paid bills in house: $e');
      return [];
    }
  }

  // Read - อ่านบิลตามประเภทบริการในหมู่บ้าน
  static Future<List<BillModel>> getByServiceInVillage(
    int villageId,
    int service,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('service', service)
          .order('bill_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting bills by service in village: $e');
      return [];
    }
  }

  // Read - อ่านบิลตามประเภทบริการของบ้าน
  static Future<List<BillModel>> getByServiceInHouse(
    int villageId,
    int houseId,
    int service,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('house_id', houseId)
          .eq('service', service)
          .order('bill_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting bills by service in house: $e');
      return [];
    }
  }

  // Read - อ่านบิลที่ครบกำหนดในหมู่บ้าน
  static Future<List<BillModel>> getOverdueInVillage(int villageId) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('paid_status', 0)
          .lt('due_date', today)
          .order('due_date', ascending: true);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting overdue bills in village: $e');
      return [];
    }
  }

  // Read - อ่านบิลที่ครบกำหนดของบ้าน
  static Future<List<BillModel>> getOverdueInHouse(
    int villageId,
    int houseId,
  ) async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('house_id', houseId)
          .eq('paid_status', 0)
          .lt('due_date', today)
          .order('due_date', ascending: true);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting overdue bills in house: $e');
      return [];
    }
  }

  // Update - อัพเดทบิล
  static Future<BillModel?> update({
    required int billId,
    required BillModel updatedBill,
  }) async {
    try {
      final response = await _client
          .from(_table)
          .update(updatedBill.toJson())
          .eq('bill_id', billId)
          .select()
          .single();

      return BillModel.fromJson(response);
    } catch (e) {
      print('Error updating bill: $e');
      return null;
    }
  }

  // Update - อัพเดทสถานะการจ่ายเงิน
  static Future<bool> updatePaymentStatus({
    required int billId,
    required int paidStatus,
    String? paidDate,
    String? paidMethod,
    String? referenceNo,
    String? paidImg,
  }) async {
    try {
      final updateData = {
        'paid_status': paidStatus,
        if (paidDate != null) 'paid_date': paidDate,
        if (paidMethod != null) 'paid_method': paidMethod,
        if (referenceNo != null) 'reference_no': referenceNo,
        if (paidImg != null) 'paid_img': paidImg,
      };

      await _client.from(_table).update(updateData).eq('bill_id', billId);

      return true;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // Delete - ลบบิล
  static Future<bool> delete(int billId) async {
    try {
      await _client.from(_table).delete().eq('bill_id', billId);

      return true;
    } catch (e) {
      print('Error deleting bill: $e');
      return false;
    }
  }

  // Utility - นับจำนวนบิลที่ยังไม่จ่ายในหมู่บ้าน
  static Future<int> countUnpaidInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('bill_id')
          .eq('village_id', villageId)
          .eq('paid_status', 0);

      return response.length;
    } catch (e) {
      print('Error counting unpaid bills in village: $e');
      return 0;
    }
  }

  // Utility - นับจำนวนบิลที่ยังไม่จ่ายของบ้าน
  static Future<int> countUnpaidInHouse(int villageId, int houseId) async {
    try {
      final response = await _client
          .from(_table)
          .select('bill_id')
          .eq('village_id', villageId)
          .eq('house_id', houseId)
          .eq('paid_status', 0);

      return response.length;
    } catch (e) {
      print('Error counting unpaid bills in house: $e');
      return 0;
    }
  }

  // Utility - คำนวณยอดรวมที่ยังไม่จ่ายในหมู่บ้าน
  static Future<double> getTotalUnpaidInVillage(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select('amount')
          .eq('village_id', villageId)
          .eq('paid_status', 0);

      double total = 0;
      for (var item in response) {
        total += (item['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Error calculating total unpaid in village: $e');
      return 0;
    }
  }

  // Utility - คำนวณยอดรวมที่ยังไม่จ่ายของบ้าน
  static Future<double> getTotalUnpaidInHouse(
    int villageId,
    int houseId,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select('amount')
          .eq('village_id', villageId)
          .eq('house_id', houseId)
          .eq('paid_status', 0);

      double total = 0;
      for (var item in response) {
        total += (item['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Error calculating total unpaid in house: $e');
      return 0;
    }
  }

  // Utility - สถิติการจ่ายเงินของบ้าน
  static Future<Map<String, dynamic>> getHousePaymentStats(
    int villageId,
    int houseId,
  ) async {
    try {
      final allBills = await _client
          .from(_table)
          .select('paid_status, amount')
          .eq('village_id', villageId)
          .eq('house_id', houseId);

      int totalBills = allBills.length;
      int paidBills = allBills.where((bill) => bill['paid_status'] == 1).length;
      int unpaidBills = totalBills - paidBills;

      double totalAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;

      for (var bill in allBills) {
        double amount = (bill['amount'] ?? 0).toDouble();
        totalAmount += amount;

        if (bill['paid_status'] == 1) {
          paidAmount += amount;
        } else {
          unpaidAmount += amount;
        }
      }

      return {
        'total_bills': totalBills,
        'paid_bills': paidBills,
        'unpaid_bills': unpaidBills,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'unpaid_amount': unpaidAmount,
        'payment_rate': totalBills > 0 ? (paidBills / totalBills * 100) : 0,
      };
    } catch (e) {
      print('Error getting house payment stats: $e');
      return {};
    }
  }

  // Utility - สถิติการจ่ายเงินของหมู่บ้าน
  static Future<Map<String, dynamic>> getVillagePaymentStats(
    int villageId,
  ) async {
    try {
      final allBills = await _client
          .from(_table)
          .select('paid_status, amount')
          .eq('village_id', villageId);

      int totalBills = allBills.length;
      int paidBills = allBills.where((bill) => bill['paid_status'] == 1).length;
      int unpaidBills = totalBills - paidBills;

      double totalAmount = 0;
      double paidAmount = 0;
      double unpaidAmount = 0;

      for (var bill in allBills) {
        double amount = (bill['amount'] ?? 0).toDouble();
        totalAmount += amount;

        if (bill['paid_status'] == 1) {
          paidAmount += amount;
        } else {
          unpaidAmount += amount;
        }
      }

      return {
        'total_bills': totalBills,
        'paid_bills': paidBills,
        'unpaid_bills': unpaidBills,
        'total_amount': totalAmount,
        'paid_amount': paidAmount,
        'unpaid_amount': unpaidAmount,
        'payment_rate': totalBills > 0 ? (paidBills / totalBills * 100) : 0,
      };
    } catch (e) {
      print('Error getting village payment stats: $e');
      return {};
    }
  }
}
