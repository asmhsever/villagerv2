import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/funds_model.dart';
import 'package:fullproject/services/image_service.dart';

class FundDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'funds';

  // Create - เพิ่มรายการกองทุนใหม่
  static Future<FundModel?> create({
    required int villageId,
    required String type, // income, outcome
    required double amount,
    required String description,
    dynamic receiptImageFile, // รูปใบเสร็จ (File หรือ Uint8List)
    dynamic approvImageFile, // รูปอนุมัติ (File หรือ Uint8List)
  }) async {
    try {
      // 1. สร้าง fund ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
            'village_id': villageId,
            'type': type,
            'amount': amount,
            'description': description,
            'created_at': DateTime.now().toIso8601String(),
            'receipt_img': null,
            'approv_img': null,
          })
          .select()
          .single();

      final createdFund = FundModel.fromJson(response);

      String? receiptImageUrl;
      String? approvImageUrl;

      // 2. อัปโหลดรูปภาพ (ถ้ามี)
      if (createdFund.fundId != null && createdFund.fundId != 0) {
        // อัปโหลดรูปใบเสร็จ
        if (receiptImageFile != null) {
          receiptImageUrl = await SupabaseImage().uploadImage(
            imageFile: receiptImageFile,

            tableName: "funds",
            rowName: "fund_id",
            rowImgName: "receipt_img",
            rowKey: createdFund.fundId!,
            bucketPath: "funds/receipt",
            imgName: "receipt",
          );
        }

        // อัปโหลดรูปอนุมัติ
        if (approvImageFile != null) {
          approvImageUrl = await SupabaseImage().uploadImage(
            imageFile: approvImageFile,
            tableName: "funds",
            rowName: "fund_id",
            rowImgName: "approv_img",
            rowKey: createdFund.fundId!,
            bucketPath: "funds/approv",
            imgName: "approv}",
          );
        }

        // 3. อัปเดต fund ด้วย imageUrls
        if (receiptImageUrl != null || approvImageUrl != null) {
          final updateData = <String, dynamic>{};
          if (receiptImageUrl != null)
            updateData['receipt_img'] = receiptImageUrl;
          if (approvImageUrl != null) updateData['approv_img'] = approvImageUrl;

          await _client
              .from(_table)
              .update(updateData)
              .eq('fund_id', createdFund.fundId);

          // Return fund ที่มี imageUrls
          return FundModel(
            fundId: createdFund.fundId,
            villageId: createdFund.villageId,
            type: createdFund.type,
            amount: createdFund.amount,
            description: createdFund.description,
            createdAt: createdFund.createdAt,
            receiptImg: receiptImageUrl,
            approvImg: approvImageUrl,
          );
        }
      }

      return createdFund;
    } catch (e) {
      print('Error creating fund: $e');
      return null;
    }
  }

  // Update - อัพเดทรายการกองทุน
  static Future<void> update({
    required int fundId,
    required int villageId,
    required String type,
    required double amount,
    required String description,
    dynamic receiptImageFile, // รูปใบเสร็จใหม่ (File หรือ Uint8List)
    dynamic approvImageFile, // รูปอนุมัติใหม่ (File หรือ Uint8List)
    bool removeReceiptImage = false, // flag สำหรับลบรูปใบเสร็จ
    bool removeApprovImage = false, // flag สำหรับลบรูปอนุมัติ
  }) async {
    try {
      String? finalReceiptImageUrl;
      String? finalApprovImageUrl;

      // จัดการรูปใบเสร็จ
      if (removeReceiptImage) {
        finalReceiptImageUrl = null;
      } else if (receiptImageFile != null) {
        finalReceiptImageUrl = await SupabaseImage().uploadImage(
          imageFile: receiptImageFile,
          tableName: "funds",
          rowName: "fund_id",
          rowImgName: "receipt_img",
          rowKey: fundId,
          bucketPath: "funds/receipt",
          imgName: "receipt",
        );
      }

      // จัดการรูปอนุมัติ
      if (removeApprovImage) {
        finalApprovImageUrl = null;
      } else if (approvImageFile != null) {
        finalApprovImageUrl = await SupabaseImage().uploadImage(
          imageFile: approvImageFile,
          tableName: "funds",
          rowName: "fund_id",
          rowImgName: "approv_img",
          rowKey: fundId,
          bucketPath: "funds/approv",
          imgName: "approv",
        );
      }

      // อัปเดตข้อมูล
      final Map<String, dynamic> updateData = {
        'village_id': villageId,
        'type': type,
        'amount': amount,
        'description': description,
      };

      // เพิ่ม image fields เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeReceiptImage || receiptImageFile != null) {
        updateData['receipt_img'] = finalReceiptImageUrl;
      }

      if (removeApprovImage || approvImageFile != null) {
        updateData['approv_img'] = finalApprovImageUrl;
      }

      await _client.from(_table).update(updateData).eq('fund_id', fundId);
    } catch (e) {
      print('Error updating fund: $e');
      throw Exception('Failed to update fund: $e');
    }
  }

  // Delete - ลบรายการกองทุน
  static Future<void> delete(int fundId) async {
    try {
      // 1. ดึงข้อมูล fund เพื่อเช็ค imageUrls ก่อน
      final response = await _client
          .from(_table)
          .select('receipt_img, approv_img')
          .eq('fund_id', fundId)
          .single();

      final receiptImageUrl = response['receipt_img'] as String?;
      final approvImageUrl = response['approv_img'] as String?;

      // 2. ลบรูปภาพออกจาก storage ก่อน (ถ้ามี)
      if (receiptImageUrl != null && receiptImageUrl.isNotEmpty) {
        await SupabaseImage().deleteImage(
          bucketPath: "funds/receipt",
          imageUrl: receiptImageUrl,
        );
      }

      if (approvImageUrl != null && approvImageUrl.isNotEmpty) {
        await SupabaseImage().deleteImage(
          bucketPath: "funds/approv",
          imageUrl: approvImageUrl,
        );
      }

      // 3. ลบข้อมูล fund จากฐานข้อมูล
      await _client.from(_table).delete().eq('fund_id', fundId);
    } catch (e) {
      print('Error deleting fund: $e');
      throw Exception('Failed to delete fund: $e');
    }
  }

  // Read - อ่านรายการกองทุนทั้งหมด
  static Future<List<FundModel>> getAll() async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FundModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting all funds: $e');
      return [];
    }
  }

  // Read - อ่านรายการกองทุนตาม village_id
  static Future<List<FundModel>> getByVillageId(int villageId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((json) => FundModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting funds by village: $e');
      return [];
    }
  }

  // Read - อ่านรายการกองทุนตามประเภท (income/outcome)
  static Future<List<FundModel>> getByType(String type) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('type', type)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FundModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting funds by type: $e');
      return [];
    }
  }

  // Read - อ่านรายการกองทุนตาม village_id และประเภท
  static Future<List<FundModel>> getByVillageAndType(
    int villageId,
    String type,
  ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('village_id', villageId)
          .eq('type', type)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FundModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting funds by village and type: $e');
      return [];
    }
  }

  // Read - อ่านรายการกองทุนเดี่ยวตาม fund_id
  static Future<FundModel?> getById(int fundId) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('fund_id', fundId)
          .single();

      return FundModel.fromJson(response);
    } catch (e) {
      print('Error getting fund by id: $e');
      return null;
    }
  }

  // คำนวณยอดรวมตาม village_id
  static Future<Map<String, double>> getVillageSummary(int villageId) async {
    try {
      final funds = await getByVillageId(villageId);

      double totalIncome = 0;
      double totalOutcome = 0;

      for (var fund in funds) {
        if (fund.type == 'income') {
          totalIncome += fund.amount;
        } else if (fund.type == 'outcome') {
          totalOutcome += fund.amount;
        }
      }

      return {
        'total_income': totalIncome,
        'total_outcome': totalOutcome,
        'balance': totalIncome - totalOutcome,
      };
    } catch (e) {
      print('Error calculating village summary: $e');
      return {'total_income': 0.0, 'total_outcome': 0.0, 'balance': 0.0};
    }
  }

  // ค้นหารายการกองทุนจากคำอธิบาย
  static Future<List<FundModel>> searchByDescription(
    String searchText, {
    int? villageId,
  }) async {
    try {
      var query = _client.from(_table).select();

      if (villageId != null) {
        query = query.eq('village_id', villageId);
      }

      final response = await query
          .ilike('description', '%$searchText%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FundModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error searching funds: $e');
      return [];
    }
  }
}
