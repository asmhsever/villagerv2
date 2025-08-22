import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/services/image_service.dart';

class BillDomain {
  static final _client = SupabaseConfig.client;
  static const String _table = 'bill';

  // Create - เพิ่มบิลใหม่
  static Future<BillModel?> create({
    required int houseId,
    required String billDate,
    required double amount,
    required int service,
    required String dueDate,
    String? referenceNo,
    String? paidMethod,
    String status = 'DRAFT',
    dynamic paidImageFile,
    dynamic billImageFile,
    dynamic receiptImageFile,
  }) async {
    try {
      // 1. สร้าง bill ก่อน (ยังไม่มีรูป)
      final response = await _client
          .from(_table)
          .insert({
        'house_id': houseId,
        'bill_date': billDate,
        'amount': amount,
        'paid_status': 0,
        'paid_date': null,
        'paid_method': paidMethod,
        'service': service,
        'due_date': dueDate,
        'reference_no': referenceNo,
        'status': status,
        'slip_img': null,
        'bill_img': null,
        'receipt_img': null,
      })
          .select()
          .single();

      final createdBill = BillModel.fromJson(response);

      // 2. อัปโหลดรูป (ถ้ามี)
      if (createdBill.billId != 0) {
        String? paidImageUrl;
        String? billImageUrl;
        String? receiptImageUrl;

        // อัปโหลดรูปหลักฐานการชำระ
        if (paidImageFile != null) {
          paidImageUrl = await SupabaseImage().uploadImage(
            imageFile: paidImageFile,
            tableName: "bill",
            rowName: "bill_id",
            rowImgName: "slip_img",
            rowKey: createdBill.billId,
            bucketPath: "bill/slip",
            imgName: "slip",
          );
        }

        // อัปโหลดรูปบิล
        if (billImageFile != null) {
          billImageUrl = await SupabaseImage().uploadImage(
            imageFile: billImageFile,
            tableName: "bill",
            rowName: "bill_id",
            rowImgName: "bill_img",
            rowKey: createdBill.billId,
            bucketPath: "bill/bill",
            imgName: "bill",
          );
        }

        // อัปโหลดรูปใบเสร็จ
        if (receiptImageFile != null) {
          receiptImageUrl = await SupabaseImage().uploadImage(
            imageFile: receiptImageFile,
            tableName: "bill",
            rowName: "bill_id",
            rowImgName: "receipt_img",
            rowKey: createdBill.billId,
            bucketPath: "bill/receipt",
            imgName: "receipt",
          );
        }

        // 3. อัปเดต bill ด้วย imageUrls (ถ้ามี)
        if (paidImageUrl != null ||
            billImageUrl != null ||
            receiptImageUrl != null) {
          final updateData = <String, dynamic>{};
          if (paidImageUrl != null) updateData['slip_img'] = paidImageUrl;
          if (billImageUrl != null) updateData['bill_img'] = billImageUrl;
          if (receiptImageUrl != null)
            updateData['receipt_img'] = receiptImageUrl;

          await _client
              .from(_table)
              .update(updateData)
              .eq('bill_id', createdBill.billId);

          // Return bill ที่มี imageUrls
          return BillModel(
            billId: createdBill.billId,
            houseId: createdBill.houseId,
            billDate: createdBill.billDate,
            amount: createdBill.amount,
            paidStatus: createdBill.paidStatus,
            paidDate: createdBill.paidDate,
            paidMethod: createdBill.paidMethod,
            service: createdBill.service,
            dueDate: createdBill.dueDate,
            referenceNo: createdBill.referenceNo,
            status: createdBill.status,
            slipImg: paidImageUrl ?? createdBill.slipImg,
            billImg: billImageUrl ?? createdBill.billImg,
            receiptImg: receiptImageUrl ?? createdBill.receiptImg,
            slipDate: createdBill.slipDate,
          );
        }
      }

      return createdBill;
    } catch (e) {
      print('Error creating bill: $e');
      return null;
    }
  }

  // Update - อัพเดทบิล (ปรับให้ตรงกับการใช้งานปัจจุบัน)
  static Future<bool> update({
    required int billId,
    int? houseId,
    String? billDate,
    double? amount,
    int? paidStatus,
    String? paidDate,
    String? paidMethod,
    int? service,
    String? dueDate,
    String? referenceNo,
    DateTime? slipDate, // รับ DateTime จากหน้าจ่ายบิล
    String? status,
    dynamic slipImageFile, // รูปสลิปการโอน (ใช้ในหน้าจ่ายบิล)
    dynamic billImageFile, // รูปบิล
    dynamic receiptImageFile, // รูปใบเสร็จ
    bool removeSlipImage = false,
    bool removeBillImage = false,
    bool removeReceiptImage = false,
  }) async {
    try {
      String? finalSlipImageUrl;
      String? finalBillImageUrl;
      String? finalReceiptImageUrl;

      // จัดการรูปสลิปการโอน
      if (removeSlipImage) {
        finalSlipImageUrl = null;
      } else if (slipImageFile != null) {
        finalSlipImageUrl = await SupabaseImage().uploadImage(
          imageFile: slipImageFile,
          tableName: "bill",
          rowName: "bill_id",
          rowImgName: "slip_img",
          rowKey: billId,
          bucketPath: "bill/slip",
          imgName: "slip",
        );
      }

      // จัดการรูปบิล
      if (removeBillImage) {
        finalBillImageUrl = null;
      } else if (billImageFile != null) {
        finalBillImageUrl = await SupabaseImage().uploadImage(
          imageFile: billImageFile,
          tableName: "bill",
          rowName: "bill_id",
          rowImgName: "bill_img",
          rowKey: billId,
          bucketPath: "bill/bill",
          imgName: "bill",
        );
      }

      // จัดการรูปใบเสร็จ
      if (removeReceiptImage) {
        finalReceiptImageUrl = null;
      } else if (receiptImageFile != null) {
        finalReceiptImageUrl = await SupabaseImage().uploadImage(
          imageFile: receiptImageFile,
          tableName: "bill",
          rowName: "bill_id",
          rowImgName: "receipt_img",
          rowKey: billId,
          bucketPath: "bill/receipt",
          imgName: "receipt",
        );
      }

      // เตรียมข้อมูลสำหรับอัปเดต
      final Map<String, dynamic> updateData = {};

      // เพิ่มข้อมูลทั่วไป (เฉพาะที่มีค่า)
      if (houseId != null) updateData['house_id'] = houseId;
      if (billDate != null) updateData['bill_date'] = billDate;
      if (amount != null) updateData['amount'] = amount;
      if (paidStatus != null) updateData['paid_status'] = paidStatus;
      if (paidDate != null) updateData['paid_date'] = paidDate;
      if (paidMethod != null) updateData['paid_method'] = paidMethod;
      if (service != null) updateData['service'] = service;
      if (dueDate != null) updateData['due_date'] = dueDate;
      if (referenceNo != null) updateData['reference_no'] = referenceNo;
      if (status != null) updateData['status'] = status;

      // จัดการ slipDate - แปลง DateTime เป็น ISO string
      if (slipDate != null) {
        updateData['slip_date'] = slipDate.toIso8601String();
      }

      // เพิ่ม image fields เฉพาะเมื่อต้องการเปลี่ยนรูป
      if (removeSlipImage || slipImageFile != null) {
        updateData['slip_img'] = finalSlipImageUrl;
      }
      if (removeBillImage || billImageFile != null) {
        updateData['bill_img'] = finalBillImageUrl;
      }
      if (removeReceiptImage || receiptImageFile != null) {
        updateData['receipt_img'] = finalReceiptImageUrl;
      }
      print(updateData);
      // อัปเดตข้อมูลในฐานข้อมูล
      await _client.from(_table).update(updateData).eq('bill_id', billId);

      return true;
    } catch (e) {
      print('Error updating bill: $e');
      return false;
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
          .eq('house.village_id', villageId)
          .order('bill_date', ascending: false);

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

  // Read - อ่านบิลตาม status ในหมู่บ้าน
  static Future<List<BillModel>> getByStatusInVillage(
      int villageId,
      String status,
      ) async {
    try {
      final response = await _client
          .from(_table)
          .select('*, house!inner(village_id)')
          .eq('house.village_id', villageId)
          .eq('status', status)
          .order('bill_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting bills by status in village: $e');
      return [];
    }
  }

  // Read - อ่านบิลตาม status ของบ้าน
  static Future<List<BillModel>> getByStatusInHouse(
      int houseId,
      String status,
      ) async {
    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('house_id', houseId)
          .eq('status', status)
          .order('bill_date', ascending: false);

      return response
          .map<BillModel>((json) => BillModel.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting bills by status in house: $e');
      return [];
    }
  }

  // Read - อ่านบิลที่ยังไม่จ่ายของบ้าน (paid_status = 0)
  static Future<List<BillModel>> getUnpaidByHouse({
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

  // Read - อ่านบิลที่จ่ายแล้วของบ้าน (paid_status = 1)
  static Future<List<BillModel>> getPaidByHouse({required int houseId}) async {
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

  // Update - อัพเดทสถานะการจ่ายเงิน (สำหรับ backward compatibility)
  static Future<bool> updatePaymentStatus({
    required int billId,
    required int paidStatus,
    String? status,
    String? paidDate,
    String? paidMethod,
    String? referenceNo,
    String? paidImg,
  }) async {
    try {
      final updateData = <String, dynamic>{'paid_status': paidStatus};

      if (status != null) updateData['status'] = status;
      if (paidDate != null) updateData['paid_date'] = paidDate;
      if (paidMethod != null) updateData['paid_method'] = paidMethod;
      if (referenceNo != null) updateData['reference_no'] = referenceNo;
      if (paidImg != null) updateData['slip_img'] = paidImg; // ใช้ slip_img

      await _client.from(_table).update(updateData).eq('bill_id', billId);

      return true;
    } catch (e) {
      print('Error updating payment status: $e');
      return false;
    }
  }

  // Update - อัพเดทสถานะเฉพาะ status
  static Future<bool> updateStatus({
    required int billId,
    required String status,
  }) async {
    try {
      await _client
          .from(_table)
          .update({'status': status})
          .eq('bill_id', billId);

      return true;
    } catch (e) {
      print('Error updating status: $e');
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

  // Utility - สถิติการจ่ายเงินของบ้าน
  static Future<Map<String, dynamic>> getHousePaymentStats(int houseId) async {
    try {
      final allBills = await _client
          .from(_table)
          .select('status, amount')
          .eq('house_id', houseId);

      int totalBills = allBills.length;
      int completedBills = allBills
          .where((bill) => bill['status'] == 'RECEIPT_SENT')
          .length;
      int pendingBills = allBills
          .where((bill) => bill['status'] == 'PENDING')
          .length;
      int rejectedBills = allBills
          .where((bill) => bill['status'] == 'REJECTED')
          .length;
      int underReviewBills = allBills
          .where((bill) => bill['status'] == 'UNDER_REVIEW')
          .length;
      int overdueBills = allBills
          .where((bill) => bill['status'] == 'OVERDUE')
          .length;

      double totalAmount = 0;
      double completedAmount = 0;
      double pendingAmount = 0;

      for (var bill in allBills) {
        double amount = (bill['amount'] ?? 0).toDouble();
        totalAmount += amount;

        String status = bill['status'] ?? '';
        if (status == 'RECEIPT_SENT') {
          completedAmount += amount;
        } else if (status == 'PENDING') {
          pendingAmount += amount;
        }
      }

      return {
        'total_bills': totalBills,
        'completed_bills': completedBills,
        'pending_bills': pendingBills,
        'rejected_bills': rejectedBills,
        'under_review_bills': underReviewBills,
        'overdue_bills': overdueBills,
        'total_amount': totalAmount,
        'completed_amount': completedAmount,
        'pending_amount': pendingAmount,
        'completion_rate': totalBills > 0
            ? (completedBills / totalBills * 100)
            : 0,
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
          .select('status, amount, house!inner(village_id)')
          .eq('house.village_id', villageId);

      int totalBills = allBills.length;
      int completedBills = allBills
          .where((bill) => bill['status'] == 'RECEIPT_SENT')
          .length;
      int pendingBills = allBills
          .where((bill) => bill['status'] == 'PENDING')
          .length;
      int rejectedBills = allBills
          .where((bill) => bill['status'] == 'REJECTED')
          .length;
      int underReviewBills = allBills
          .where((bill) => bill['status'] == 'UNDER_REVIEW')
          .length;
      int overdueBills = allBills
          .where((bill) => bill['status'] == 'OVERDUE')
          .length;

      double totalAmount = 0;
      double completedAmount = 0;
      double pendingAmount = 0;

      for (var bill in allBills) {
        double amount = (bill['amount'] ?? 0).toDouble();
        totalAmount += amount;

        String status = bill['status'] ?? '';
        if (status == 'RECEIPT_SENT') {
          completedAmount += amount;
        } else if (status == 'PENDING') {
          pendingAmount += amount;
        }
      }

      return {
        'total_bills': totalBills,
        'completed_bills': completedBills,
        'pending_bills': pendingBills,
        'rejected_bills': rejectedBills,
        'under_review_bills': underReviewBills,
        'overdue_bills': overdueBills,
        'total_amount': totalAmount,
        'completed_amount': completedAmount,
        'pending_amount': pendingAmount,
        'completion_rate': totalBills > 0
            ? (completedBills / totalBills * 100)
            : 0,
      };
    } catch (e) {
      print('Error getting village payment stats: $e');
      return {};
    }
  }

  // Utility - นับจำนวนบิลตาม status ของบ้าน
  static Future<int> countByStatusInHouse(int houseId, String status) async {
    try {
      final response = await _client
          .from(_table)
          .select('bill_id')
          .eq('house_id', houseId)
          .eq('status', status);

      return response.length;
    } catch (e) {
      print('Error counting bills by status in house: $e');
      return 0;
    }
  }

  // Utility - คำนวณยอดรวมตาม status ของบ้าน
  static Future<double> getTotalByStatusInHouse(
      int houseId,
      String status,
      ) async {
    try {
      final response = await _client
          .from(_table)
          .select('amount')
          .eq('house_id', houseId)
          .eq('status', status);

      double total = 0;
      for (var item in response) {
        total += (item['amount'] ?? 0).toDouble();
      }

      return total;
    } catch (e) {
      print('Error calculating total by status in house: $e');
      return 0;
    }
  }
}
