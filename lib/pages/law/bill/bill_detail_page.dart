// lib/pages/law/bill/bill_detail_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/law/bill/bill_edit_page.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BillDetailPage extends StatefulWidget {
  final BillModel bill;

  const BillDetailPage({super.key, required this.bill});

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  late BillModel currentBill;
  String? houseNumber;
  String? serviceName;
  bool _isLoading = false;

  // ===== Palette (match LawDashboardPage) =====

  // แมปประเภทบริการให้เป็นภาษาไทย
  final Map<String, String> _serviceTranslations = const {
    'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
    'Trash Fee': 'ค่าขยะ',
    'water Fee': 'ค่าน้ำ',
    'Water Fee': 'ค่าน้ำ',
    'enegy Fee': 'ค่าไฟ',
    'Energy Fee': 'ค่าไฟ',
    'Electricity Fee': 'ค่าไฟ',
  };

  // ข้อมูลสถานะบิลทั้งหมด
  final Map<String, Map<String, dynamic>> _billStatuses = {
    'DRAFT': {
      'name': 'แบบร่าง',
      'icon': Icons.edit_outlined,
      'color': Colors.grey,
      'description': 'บิลที่ยังอยู่ในระหว่างการเตรียม',
    },
    'PENDING': {
      'name': 'รอชำระ',
      'icon': Icons.schedule,
      'color': Color(0xFFD48B5C), // ThemeColors.softTerracotta
      'description': 'รอการชำระเงินจากลูกบ้าน',
    },
    'UNDER_REVIEW': {
      'name': 'กำลังตรวจสอบ',
      'icon': Icons.search,
      'color': ThemeColors.softBrown, // ThemeColors.softBrown
      'description': 'กำลังตรวจสอบหลักฐานการชำระเงิน',
    },
    'RECEIPT_SENT': {
      'name': 'ส่งใบเสร็จแล้ว',
      'icon': Icons.check_circle,
      'color': ThemeColors.oliveGreen, // ThemeColors.oliveGreen
      'description': 'ชำระเงินสมบูรณ์และส่งใบเสร็จแล้ว',
    },
    'REJECTED': {
      'name': 'ถูกปฏิเสธ',
      'icon': Icons.cancel,
      'color': Colors.red,
      'description': 'หลักฐานการชำระเงินไม่ถูกต้อง',
    },
    'OVERDUE': {
      'name': 'เกินกำหนด',
      'icon': Icons.warning,
      'color': Colors.red,
      'description': 'เกินกำหนดชำระเงิน',
    },
  };

  @override
  void initState() {
    super.initState();
    currentBill = widget.bill;
    _fetchAdditionalData();
  }

  Future<void> _fetchAdditionalData() async {
    try {
      final results = await Future.wait([
        SupabaseConfig.client
            .from('house')
            .select('house_number')
            .eq('house_id', currentBill.houseId)
            .single(),
        SupabaseConfig.client
            .from('service')
            .select('name')
            .eq('service_id', currentBill.service)
            .single(),
      ]);

      if (!mounted) return;
      setState(() {
        houseNumber = results[0]['house_number'];
        serviceName = results[1]['name'];
      });
    } catch (e) {
      debugPrint('Error fetching additional data: $e');
    }
  }

  String formatDate(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);

  String formatDateTime(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(date);

  String getPaidStatus(int status) => status == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ';

  Color getPaidStatusColor(int status) =>
      status == 1 ? ThemeColors.oliveGreen : ThemeColors.softTerracotta;

  String _getServiceNameTh(String? englishName) =>
      _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุประเภท';

  String _getStatusText() {
    return _billStatuses[currentBill.status.toUpperCase()]?['name'] ??
        (currentBill.paidStatus == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ');
  }

  Color _getStatusColor() {
    return _billStatuses[currentBill.status.toUpperCase()]?['color'] ??
        (currentBill.paidStatus == 1
            ? ThemeColors.oliveGreen
            : ThemeColors.softTerracotta);
  }

  IconData _getStatusIcon() {
    return _billStatuses[currentBill.status.toUpperCase()]?['icon'] ??
        Icons.schedule;
  }

  bool _isOverdue() {
    if (currentBill.paidStatus == 1) return false;
    return DateTime.now().isAfter(currentBill.dueDate);
  }

  int _getDaysUntilDue() {
    if (currentBill.paidStatus == 1) return 0;
    final today = DateTime.now();
    final dueDate = currentBill.dueDate;
    return dueDate.difference(today).inDays;
  }

  // ===== ฟังก์ชันเปลี่ยนสถานะบิล =====
  Future<void> _showStatusChangeDialog() async {
    String? selectedStatus = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.swap_horiz, color: ThemeColors.softBrown),
              const SizedBox(width: 8),
              Text(
                'เปลี่ยนสถานะบิล',
                style: TextStyle(
                  color: ThemeColors.softBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'เลือกสถานะใหม่สำหรับบิล #${currentBill.billId}',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                const SizedBox(height: 16),
                ..._billStatuses.entries.map((entry) {
                  final status = entry.key;
                  final statusData = entry.value;
                  final isCurrentStatus =
                      status == currentBill.status.toUpperCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isCurrentStatus
                          ? statusData['color'].withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: isCurrentStatus
                            ? null
                            : () => Navigator.pop(context, status),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isCurrentStatus
                                  ? statusData['color']
                                  : ThemeColors.sandyTan.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                statusData['icon'],
                                color: statusData['color'],
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          statusData['name'],
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isCurrentStatus
                                                ? statusData['color']
                                                : ThemeColors.earthClay,
                                          ),
                                        ),
                                        if (isCurrentStatus) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusData['color'],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'ปัจจุบัน',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      statusData['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ThemeColors.earthClay.withValues(
                                          alpha: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isCurrentStatus)
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: ThemeColors.earthClay.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: ThemeColors.warmStone,
              ),
              child: const Text('ยกเลิก'),
            ),
          ],
        );
      },
    );

    if (selectedStatus != null) {
      await _confirmStatusChange(selectedStatus);
    }
  }

  Future<void> _confirmStatusChange(String newStatus) async {
    final statusData = _billStatuses[newStatus];
    if (statusData == null) return;

    // ถ้าเป็นสถานะ RECEIPT_SENT ต้องอัปโหลดรูปใบเสร็จ
    if (newStatus == 'RECEIPT_SENT') {
      await _showReceiptUploadDialog();
      return;
    }

    // สำหรับสถานะอื่นๆ ใช้ dialog ปกติ
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ยืนยันการเปลี่ยนสถานะ',
          style: TextStyle(
            color: ThemeColors.softBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ต้องการเปลี่ยนสถานะบิล #${currentBill.billId} เป็น',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusData['color'].withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: statusData['color'].withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(statusData['icon'], color: statusData['color']),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusData['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusData['color'],
                          ),
                        ),
                        Text(
                          statusData['description'],
                          style: TextStyle(
                            fontSize: 12,
                            color: ThemeColors.earthClay,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'การดำเนินการนี้จะอัพเดทสถานะในระบบทันที',
              style: TextStyle(
                color: ThemeColors.earthClay.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.warmStone),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: statusData['color'],
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateBillStatus(newStatus);
    }
  }

  Future<void> _updateBillStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      // กำหนด paid_status ตามสถานะใหม่
      int newPaidStatus = currentBill.paidStatus;
      String? newPaidDate = currentBill.paidDate?.toIso8601String();
      String? newPaidMethod = currentBill.paidMethod;

      // อัพเดท paid_status อัตโนมัติตามสถานะ
      if (newStatus == 'RECEIPT_SENT') {
        newPaidStatus = 1;
        if (currentBill.paidDate == null) {
          newPaidDate = DateTime.now().toIso8601String();
        }
        if (currentBill.paidMethod == null || currentBill.paidMethod!.isEmpty) {
          newPaidMethod = 'โอนเงิน';
        }
      } else if (newStatus == 'PENDING' ||
          newStatus == 'DRAFT' ||
          newStatus == 'REJECTED') {
        // ไม่เปลี่ยน paid_status ถ้าเป็นสถานะเหล่านี้
        // ให้ Admin ตัดสินใจเอง
      }

      final success = await BillDomain.update(
        billId: currentBill.billId,
        status: newStatus,
        paidStatus: newPaidStatus,
        paidDate: newPaidDate,
        paidMethod: newPaidMethod,
      );

      if (success && mounted) {
        setState(() {
          currentBill = BillModel(
            billId: currentBill.billId,
            houseId: currentBill.houseId,
            billDate: currentBill.billDate,
            amount: currentBill.amount,
            paidStatus: newPaidStatus,
            paidDate: newPaidDate != null ? DateTime.parse(newPaidDate) : null,
            paidMethod: newPaidMethod,
            service: currentBill.service,
            dueDate: currentBill.dueDate,
            referenceNo: currentBill.referenceNo,
            status: newStatus,
            slipImg: currentBill.slipImg,
            billImg: currentBill.billImg,
            receiptImg: currentBill.receiptImg,
            slipDate: currentBill.slipDate,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'เปลี่ยนสถานะเป็น "${_billStatuses[newStatus]?['name']}" สำเร็จ',
            ),
            backgroundColor: ThemeColors.oliveGreen,
          ),
        );
      } else {
        throw Exception('ไม่สามารถอัพเดทสถานะได้');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===== ฟังก์ชันอัปโหลดรูปใบเสร็จ =====
  Future<void> _showReceiptUploadDialog() async {
    File? selectedImage;
    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: ThemeColors.ivoryWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(Icons.receipt, color: ThemeColors.oliveGreen),
                  const SizedBox(width: 8),
                  Text(
                    'อัปโหลดใบเสร็จ',
                    style: TextStyle(
                      color: ThemeColors.softBrown,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'กรุณาอัปโหลดรูปใบเสร็จสำหรับบิล #${currentBill.billId}',
                      style: TextStyle(color: ThemeColors.earthClay),
                    ),
                    const SizedBox(height: 16),

                    // พื้นที่แสดงรูปที่เลือก
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: ThemeColors.sandyTan.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ThemeColors.warmStone,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                selectedImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 48,
                                  color: ThemeColors.earthClay,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'แตะเพื่อเลือกรูปใบเสร็จ',
                                  style: TextStyle(
                                    color: ThemeColors.earthClay,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'รองรับไฟล์ JPG, PNG',
                                  style: TextStyle(
                                    color: ThemeColors.earthClay.withValues(
                                      alpha: 0.7,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 16),

                    // ปุ่มเลือกรูป
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1920,
                                maxHeight: 1920,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setDialogState(() {
                                  selectedImage = File(image.path);
                                });
                              }
                            },
                            icon: Icon(
                              Icons.photo_library,
                              color: ThemeColors.softBrown,
                            ),
                            label: Text(
                              'เลือกจากแกลเลอรี่',
                              style: TextStyle(color: ThemeColors.softBrown),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: ThemeColors.softBrown),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1920,
                                maxHeight: 1920,
                                imageQuality: 85,
                              );
                              if (image != null) {
                                setDialogState(() {
                                  selectedImage = File(image.path);
                                });
                              }
                            },
                            icon: Icon(
                              Icons.camera_alt,
                              color: ThemeColors.softBrown,
                            ),
                            label: Text(
                              'ถ่ายรูป',
                              style: TextStyle(color: ThemeColors.softBrown),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: ThemeColors.softBrown),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (selectedImage != null) const SizedBox(height: 12),
                    if (selectedImage != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeColors.oliveGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ThemeColors.oliveGreen.withValues(
                              alpha: 0.3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: ThemeColors.oliveGreen,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'เลือกรูปแล้ว - พร้อมอัปโหลด',
                              style: TextStyle(
                                color: ThemeColors.oliveGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeColors.warmStone,
                  ),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  onPressed: selectedImage != null
                      ? () async {
                          Navigator.pop(context);
                          await _updateBillStatusWithReceipt(
                            'RECEIPT_SENT',
                            selectedImage!,
                          );
                        }
                      : null,
                  icon: Icon(
                    selectedImage != null ? Icons.cloud_upload : Icons.upload,
                    size: 18,
                  ),
                  label: Text(
                    selectedImage != null ? 'ส่งใบเสร็จ' : 'เลือกรูปก่อน',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedImage != null
                        ? ThemeColors.oliveGreen
                        : ThemeColors.warmStone,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ฟังก์ชันอัปเดทสถานะพร้อมรูปใบเสร็จ
  Future<void> _updateBillStatusWithReceipt(
    String newStatus,
    File receiptImage,
  ) async {
    setState(() => _isLoading = true);
    try {
      // กำหนด paid_status ตามสถานะใหม่
      int newPaidStatus = 1; // เมื่อส่งใบเสร็จ = ชำระแล้ว
      String newPaidDate =
          currentBill.paidDate?.toIso8601String() ??
          DateTime.now().toIso8601String();
      String newPaidMethod = currentBill.paidMethod ?? 'โอนเงิน';

      final success = await BillDomain.update(
        billId: currentBill.billId,
        status: newStatus,
        paidStatus: newPaidStatus,
        paidDate: newPaidDate,
        paidMethod: newPaidMethod,
        receiptImageFile: receiptImage, // อัปโหลดรูปใบเสร็จ
      );

      if (success && mounted) {
        // รีเฟรชข้อมูลบิลจากฐานข้อมูล
        final updatedBill = await BillDomain.getById(currentBill.billId);
        if (updatedBill != null) {
          setState(() {
            currentBill = updatedBill;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Text('ส่งใบเสร็จสำเร็จ! สถานะอัปเดทเป็น "ส่งใบเสร็จแล้ว"'),
                ],
              ),
              backgroundColor: ThemeColors.oliveGreen,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('ไม่สามารถอัพเดทสถานะและอัปโหลดใบเสร็จได้');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('เกิดข้อผิดพลาด: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade400,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageDialog(String imageUrl, String title) async {
    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: ThemeColors.softBrown,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Image area
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: InteractiveViewer(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  ThemeColors.softBrown,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: ThemeColors.sandyTan,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 48,
                                color: ThemeColors.earthClay,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'ไม่สามารถโหลดรูปภาพได้',
                                style: TextStyle(color: ThemeColors.earthClay),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageCard(String? imageUrl, String title, IconData icon) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: ThemeColors.sandyTan.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeColors.warmStone.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: ThemeColors.earthClay),
            const SizedBox(height: 8),
            Text(
              'ไม่มี$title',
              style: const TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showImageDialog(imageUrl, title),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeColors.warmStone),
          boxShadow: [
            BoxShadow(
              color: ThemeColors.warmStone.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: ThemeColors.sandyTan,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          ThemeColors.softBrown,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: ThemeColors.sandyTan,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 32,
                        color: ThemeColors.earthClay,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ไม่สามารถโหลดรูปได้',
                        style: TextStyle(
                          color: ThemeColors.earthClay,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.zoom_in, size: 16, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportSingleBillAsPdf() async {
    setState(() => _isLoading = true);
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'ใบแจ้งค่าส่วนกลาง',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Bill #${currentBill.billId}',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'ข้อมูลบิล',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('รหัสบิล: ${currentBill.billId}'),
              pw.Text('บ้านเลขที่: ${houseNumber ?? currentBill.houseId}'),
              pw.Text('ประเภทบริการ: ${_getServiceNameTh(serviceName)}'),
              pw.Text(
                'จำนวนเงิน: ${NumberFormat('#,##0.00').format(currentBill.amount)} บาท',
              ),
              pw.Text('สถานะ: ${_getStatusText()}'),
              pw.SizedBox(height: 16),
              pw.Text(
                'ข้อมูลวันที่',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('วันที่ออกบิล: ${formatDate(currentBill.billDate)}'),
              pw.Text('วันครบกำหนด: ${formatDate(currentBill.dueDate)}'),
              if (currentBill.paidDate != null)
                pw.Text('วันที่ชำระ: ${formatDate(currentBill.paidDate)}'),
              if (currentBill.slipDate != null)
                pw.Text(
                  'วันที่อัพโหลดสลิป: ${formatDate(currentBill.slipDate)}',
                ),
              pw.Spacer(),
              pw.Divider(),
              pw.Text(
                'สร้างเมื่อ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เกิดข้อผิดพลาดในการสร้าง PDF: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ยืนยันการลบ',
          style: TextStyle(
            color: ThemeColors.softBrown,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'คุณต้องการลบบิลนี้หรือไม่?',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 8),
            Text(
              'บิล #${currentBill.billId} - ${NumberFormat('#,##0.00').format(currentBill.amount)} บาท',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'การดำเนินการนี้ไม่สามารถย้อนกลับได้',
              style: TextStyle(color: Colors.red.shade400, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: ThemeColors.warmStone),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final success = await BillDomain.delete(currentBill.billId);
        if (success) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('ลบบิลสำเร็จ'),
              backgroundColor: ThemeColors.oliveGreen,
            ),
          );
          Navigator.pop(context, true);
        } else {
          throw Exception('ไม่สามารถลบบิลได้');
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red.shade400,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // ฟังก์ชันเปลี่ยนสถานะการชำระเงินแบบเดิม (เก็บไว้สำหรับ backward compatibility)
  Future<void> _updatePaymentStatus() async {
    if (currentBill.paidStatus == 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ยืนยันการเปลี่ยนสถานะ',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'ต้องการเปลี่ยนสถานะเป็น "ยังไม่ชำระ" หรือไม่?',
            style: TextStyle(color: ThemeColors.earthClay),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.softTerracotta,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยัน'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          final success = await BillDomain.update(
            billId: currentBill.billId,
            paidStatus: 0,
            paidDate: null,
            paidMethod: null,
            status: 'PENDING',
          );
          if (success && mounted) {
            setState(() {
              currentBill = BillModel(
                billId: currentBill.billId,
                houseId: currentBill.houseId,
                billDate: currentBill.billDate,
                amount: currentBill.amount,
                paidStatus: 0,
                paidDate: null,
                paidMethod: null,
                service: currentBill.service,
                dueDate: currentBill.dueDate,
                referenceNo: currentBill.referenceNo,
                status: 'PENDING',
                slipImg: currentBill.slipImg,
                billImg: currentBill.billImg,
                receiptImg: currentBill.receiptImg,
                slipDate: currentBill.slipDate,
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('อัพเดทสถานะสำเร็จ'),
                backgroundColor: ThemeColors.softTerracotta,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e'),
                backgroundColor: Colors.red.shade400,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'ยืนยันการชำระเงิน',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'ยืนยันว่าได้รับชำระเงินแล้วหรือไม่?',
            style: TextStyle(color: ThemeColors.earthClay),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.oliveGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('ยืนยันการชำระ'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        try {
          final success = await BillDomain.update(
            billId: currentBill.billId,
            paidStatus: 1,
            paidDate: DateTime.now().toIso8601String(),
            paidMethod: 'เงินสด',
            status: 'RECEIPT_SENT',
          );
          if (success && mounted) {
            setState(() {
              currentBill = BillModel(
                billId: currentBill.billId,
                houseId: currentBill.houseId,
                billDate: currentBill.billDate,
                amount: currentBill.amount,
                paidStatus: 1,
                paidDate: DateTime.now(),
                paidMethod: 'เงินสด',
                service: currentBill.service,
                dueDate: currentBill.dueDate,
                referenceNo: currentBill.referenceNo,
                status: 'RECEIPT_SENT',
                slipImg: currentBill.slipImg,
                billImg: currentBill.billImg,
                receiptImg: currentBill.receiptImg,
                slipDate: currentBill.slipDate,
              );
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('อัพเดทสถานะสำเร็จ'),
                backgroundColor: ThemeColors.oliveGreen,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เกิดข้อผิดพลาด: $e'),
                backgroundColor: Colors.red.shade400,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool overdue = _isOverdue();
    final Color stateColor = _getStatusColor();

    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: Text(
          'บิล #${currentBill.billId}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ThemeColors.softBrown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _isLoading
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BillEditPage(bill: currentBill),
                      ),
                    );
                    if (result == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _isLoading ? null : () => _confirmDelete(context),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(
                  ThemeColors.softBrown,
                ),
                backgroundColor: ThemeColors.sandyTan.withValues(alpha: 0.5),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== Banner Status =====
                  Container(
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.25),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(), color: stateColor, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusText(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: stateColor,
                                ),
                              ),
                              if (overdue)
                                Text(
                                  'เกินกำหนด ${_getDaysUntilDue().abs()} วัน',
                                  style: TextStyle(color: Colors.red.shade400),
                                )
                              else if (currentBill.paidStatus == 0)
                                Text(
                                  'เหลืออีก ${_getDaysUntilDue()} วัน',
                                  style: TextStyle(
                                    color: ThemeColors.softTerracotta,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== บัตรข้อมูลบิล =====
                  _themedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('ข้อมูลบิล'),
                        const Divider(),
                        _buildInfoRow('รหัสบิล', '${currentBill.billId}'),
                        _buildInfoRow(
                          'บ้านเลขที่',
                          houseNumber ?? '${currentBill.houseId}',
                        ),
                        _buildInfoRow(
                          'ประเภทบริการ',
                          _getServiceNameTh(serviceName),
                        ),
                        _buildInfoRow(
                          'จำนวนเงิน',
                          '${NumberFormat('#,##0.00').format(currentBill.amount)} บาท',
                          valueStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.softBrown,
                          ),
                        ),
                        _buildInfoRow('สถานะ', _getStatusText()),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== บัตรข้อมูลวันที่ =====
                  _themedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('ข้อมูลวันที่'),
                        const Divider(),
                        _buildInfoRow(
                          'วันที่ออกบิล',
                          formatDate(currentBill.billDate),
                        ),
                        _buildInfoRow(
                          'วันครบกำหนด',
                          formatDate(currentBill.dueDate),
                        ),
                        if (currentBill.paidDate != null)
                          _buildInfoRow(
                            'วันที่ชำระ',
                            formatDate(currentBill.paidDate),
                          ),
                        if (currentBill.slipDate != null)
                          _buildInfoRow(
                            'วันที่อัพโหลดสลิป',
                            formatDate(currentBill.slipDate),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== บัตรข้อมูลการชำระ =====
                  if (currentBill.paidStatus == 1) ...[
                    _themedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _cardTitle('ข้อมูลการชำระเงิน'),
                          const Divider(),
                          if (currentBill.paidMethod != null)
                            _buildInfoRow(
                              'วิธีชำระเงิน',
                              currentBill.paidMethod!,
                            ),
                          if (currentBill.referenceNo != null)
                            _buildInfoRow(
                              'เลขอ้างอิง',
                              currentBill.referenceNo!,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ===== บัตรรูปภาพ =====
                  _themedCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _cardTitle('รูปภาพเอกสาร'),
                        const Divider(),
                        const SizedBox(height: 8),

                        // แถวแรก: รูปบิล และ รูปสลิปการโอน
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'รูปบิล',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: ThemeColors.earthClay,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildImageCard(
                                    currentBill.billImg,
                                    'รูปบิล',
                                    Icons.receipt_long,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'สลิปการโอน',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: ThemeColors.earthClay,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildImageCard(
                                    currentBill.slipImg,
                                    'สลิปการโอน',
                                    Icons.payment,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // แถวที่สอง: รูปใบเสร็จ (เต็มความกว้าง)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ใบเสร็จการชำระเงิน',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: ThemeColors.earthClay,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildImageCard(
                              currentBill.receiptImg,
                              'ใบเสร็จการชำระเงิน',
                              Icons.receipt,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== ปุ่มจัดการสถานะ =====
                  Row(
                    children: [
                      // ปุ่มเปลี่ยนสถานะบิล (ปุ่มหลัก)
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading
                              ? null
                              : _showStatusChangeDialog,
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('เปลี่ยนสถานะบิล'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ThemeColors.softBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // ปุ่มเปลี่ยนสถานะการชำระ (ปุ่มย่อย)
                      Expanded(
                        flex: 1,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _updatePaymentStatus,
                          icon: Icon(
                            currentBill.paidStatus == 1
                                ? Icons.undo
                                : Icons.check,
                            size: 18,
                          ),
                          label: Text(
                            currentBill.paidStatus == 1 ? 'ยกเลิก' : 'ชำระ',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: currentBill.paidStatus == 1
                                ? ThemeColors.softTerracotta
                                : ThemeColors.oliveGreen,
                            side: BorderSide(
                              color: currentBill.paidStatus == 1
                                  ? ThemeColors.softTerracotta
                                  : ThemeColors.oliveGreen,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80), // เผื่อ FloatingActionButton
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _exportSingleBillAsPdf,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf),
        label: Text(_isLoading ? 'กำลังสร้าง...' : 'Export PDF'),
        backgroundColor: ThemeColors.burntOrange,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ===== Helpers =====
  Widget _themedCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ThemeColors.sandyTan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: ThemeColors.warmStone.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }

  Widget _cardTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18,
        color: ThemeColors.softBrown,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ThemeColors.earthClay,
              ),
            ),
          ),
          Expanded(child: Text(value, style: valueStyle ?? const TextStyle())),
        ],
      ),
    );
  }
}
