// lib/pages/law/bill/bill_detail_page.dart
import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/pages/law/bill/bill_edit_page.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/theme/Color.dart';
import 'package:fullproject/services/image_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class BillDetailPage extends StatefulWidget {
  final BillModel bill;

  const BillDetailPage({super.key, required this.bill});

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage>
    with SingleTickerProviderStateMixin {
  late Future<BillModel?> _billFuture;
  late TabController _tabController;
  late List<Map<String, dynamic>> _imageTabs;

  String? houseNumber;
  String? serviceName;
  bool _isLoading = false;
  File? _selectedImageFile;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  bool _hasSelectedImage() {
    return (kIsWeb && _selectedImageBytes != null) ||
        (!kIsWeb && _selectedImageFile != null);
  }

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
      'color': ThemeColors.burntOrange,
      'description': 'รอการชำระเงินจากลูกบ้าน',
    },
    'UNDER_REVIEW': {
      'name': 'กำลังตรวจสอบ',
      'icon': Icons.search,
      'color': ThemeColors.warmStone,
      'description': 'กำลังตรวจสอบหลักฐานการชำระเงิน',
    },
    'RECEIPT_SENT': {
      'name': 'เสร็จสิ้น',
      'icon': Icons.check_circle,
      'color': ThemeColors.oliveGreen,
      'description': 'ชำระเงินสมบูรณ์และส่งใบเสร็จแล้ว',
    },
    'REJECTED': {
      'name': 'สลิปไม่ผ่าน',
      'icon': Icons.cancel,
      'color': ThemeColors.softTerracotta,
      'description': 'หลักฐานการชำระเงินไม่ถูกต้อง',
    },
    'OVERDUE': {
      'name': 'เลยกำหนด',
      'icon': Icons.warning,
      'color': ThemeColors.clayOrange,
      'description': 'เกินกำหนดชำระเงิน',
    },
  };

  @override
  void initState() {
    super.initState();
    _billFuture = _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<BillModel?> _initializeData() async {
    try {
      // Fetch bill data and additional info
      final bill = await BillDomain.getById(widget.bill.billId);
      if (bill != null) {
        await _fetchAdditionalData(bill);
        _initializeTabs(bill);
        _tabController = TabController(length: _imageTabs.length, vsync: this);
      }
      return bill;
    } catch (e) {
      debugPrint('Error initializing data: $e');
      return null;
    }
  }

  void _refreshBill() {
    setState(() {
      _billFuture = _initializeData();
    });
  }

  Future<void> _fetchAdditionalData(BillModel bill) async {
    try {
      final results = await Future.wait([
        SupabaseConfig.client
            .from('house')
            .select('house_number')
            .eq('house_id', bill.houseId)
            .single(),
        SupabaseConfig.client
            .from('service')
            .select('name')
            .eq('service_id', bill.service)
            .single(),
      ]);

      houseNumber = results[0]['house_number'];
      serviceName = results[1]['name'];
    } catch (e) {
      debugPrint('Error fetching additional data: $e');
    }
  }

  void _initializeTabs(BillModel bill) {
    _imageTabs = [
      {
        'title': 'บิล',
        'icon': Icons.receipt_long,
        'imagePath': bill.billImg,
        'bucket': 'bill/bill',
        'emptyMessage': 'ไม่มีรูปบิล',
        'description': 'รูปบิลจะแสดงที่นี่เมื่อมีการอัปโหลด',
      },
      {
        'title': 'สลิป',
        'icon': Icons.payment,
        'imagePath': bill.slipImg,
        'bucket': 'bill/slip',
        'emptyMessage': 'ไม่มีสลิปการโอน',
        'description': 'สลิปการโอนจะแสดงที่นี่เมื่อชำระเงิน',
      },
      {
        'title': 'ใบเสร็จ',
        'icon': Icons.receipt,
        'imagePath': bill.receiptImg,
        'bucket': 'bill/receipt',
        'emptyMessage': 'ไม่มีใบเสร็จ',
        'description': 'ใบเสร็จจะแสดงที่นี่เมื่อการชำระเสร็จสิ้น',
      },
    ];
  }

  String _formatDate(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yyyy').format(date);

  String _formatDateTime(DateTime? date) =>
      date == null ? '-' : DateFormat('dd/MM/yyyy HH:mm').format(date);

  String _getServiceNameTh(String? englishName) =>
      _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุประเภท';

  String _getStatusText(BillModel bill) {
    return _billStatuses[bill.status.toUpperCase()]?['name'] ??
        (bill.paidStatus == 1 ? 'ชำระแล้ว' : 'ยังไม่ชำระ');
  }

  Color _getStatusColor(BillModel bill) {
    return _billStatuses[bill.status.toUpperCase()]?['color'] ??
        (bill.paidStatus == 1
            ? ThemeColors.oliveGreen
            : ThemeColors.softTerracotta);
  }

  IconData _getStatusIcon(BillModel bill) {
    return _billStatuses[bill.status.toUpperCase()]?['icon'] ?? Icons.schedule;
  }

  String _getStatusDescription(BillModel bill) {
    return _billStatuses[bill.status.toUpperCase()]?['description'] ?? '';
  }

  bool _isOverdue(BillModel bill) {
    if (bill.paidStatus == 1) return false;
    return DateTime.now().isAfter(bill.dueDate);
  }

  int _getDaysUntilDue(BillModel bill) {
    if (bill.paidStatus == 1) return 0;
    final today = DateTime.now();
    final dueDate = bill.dueDate;
    return dueDate.difference(today).inDays;
  }

  bool _canEdit(String status) {
    return status.toUpperCase() == 'PENDING';
  }

  // ===== Workflow Buttons =====
  // แทนที่ฟังก์ชัน _buildWorkflowButtons ด้วยโค้ดนี้

  Widget _buildWorkflowButtons(BillModel bill) {
    final currentStatus = bill.status.toUpperCase();
    final isPaid = bill.paidStatus == 1;

    // ถ้าชำระเสร็จแล้ว ไม่แสดงปุ่ม
    if (isPaid || currentStatus == 'RECEIPT_SENT') {
      return const SizedBox.shrink();
    }

    // DRAFT / PENDING / REJECTED / OVERDUE -> ปุ่ม "รอตรวจสอบ"
    if (['DRAFT', 'PENDING', 'REJECTED', 'OVERDUE'].contains(currentStatus)) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _updateToUnderReview(bill),
          icon: const Icon(Icons.visibility),
          label: const Text('รอตรวจสอบ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.softBrown,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    // UNDER_REVIEW -> ปุ่ม "ตรวจสอบใบ"
    if (currentStatus == 'UNDER_REVIEW') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : () => _updateToWaitReceipt(bill),
              icon: const Icon(Icons.check_circle),
              label: const Text('ตรวจสอบใบ'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ThemeColors.oliveGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _updateToPending(bill),
              icon: const Icon(Icons.error_outline),
              label: const Text('สลิปไม่ถูกต้อง'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ThemeColors.clayOrange,
                side: BorderSide(color: ThemeColors.clayOrange),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // WAIT_RECEIPT -> ปุ่ม "ส่งใบเสร็จ"
    if (currentStatus == 'WAIT_RECEIPT') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : () => _showReceiptUploadDialog(bill),
          icon: const Icon(Icons.receipt),
          label: const Text('ส่งใบเสร็จ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: ThemeColors.oliveGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  // เพิ่มฟังก์ชันใหม่สำหรับอัปเดตเป็น WAIT_RECEIPT
  Future<void> _updateToWaitReceipt(BillModel bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ยืนยันการตรวจสอบ',
          style: TextStyle(
            color: ThemeColors.oliveGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ต้องการเปลี่ยนสถานะบิล #${bill.billId} เป็น',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.infoBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeColors.infoBlue.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_rounded, color: ThemeColors.infoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'รอส่งใบเสร็จ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.infoBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'สลิปการโอนผ่านการตรวจสอบแล้ว พร้อมส่งใบเสร็จ',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.infoBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateBillStatus(bill, 'WAIT_RECEIPT');
    }
  }

  // ===== อัปเดตสถานะ =====
  Future<void> _updateBillStatus(
    BillModel bill,
    String newStatus, {
    bool setPaid = false,
  }) async {
    setState(() => _isLoading = true);
    try {
      int newPaidStatus = bill.paidStatus;
      String? newPaidDate = bill.paidDate?.toIso8601String();
      String? newPaidMethod = bill.paidMethod;

      // ถ้าชำระเสร็จสิ้น
      if (newStatus == 'RECEIPT_SENT' || setPaid) {
        newPaidStatus = 1;
        newPaidDate = DateTime.now().toIso8601String();
        newPaidMethod = newPaidMethod ?? 'เงินสด';
      }

      final success = await BillDomain.update(
        billId: bill.billId,
        status: newStatus,
        paidStatus: newPaidStatus,
        paidDate: newPaidDate,
        paidMethod: newPaidMethod,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'อัพเดทสถานะเป็น "${_billStatuses[newStatus]?['name'] ?? newStatus}" สำเร็จ',
            ),
            backgroundColor: ThemeColors.oliveGreen,
          ),
        );
        _refreshBill(); // Refresh data
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

  // เปลี่ยนเป็นสถานะ "UNDER_REVIEW"
  Future<void> _updateToUnderReview(BillModel bill) async {
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
              'ต้องการเปลี่ยนสถานะบิล #${bill.billId} เป็น',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.softBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeColors.softBrown.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility, color: ThemeColors.softBrown),
                  const SizedBox(width: 8),
                  Text(
                    'กำลังตรวจสอบ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.softBrown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.softBrown,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateBillStatus(bill, 'UNDER_REVIEW');
    }
  }

  // เปลี่ยนเป็น "ชำระเสร็จสิ้น" (RECEIPT_SENT + paid=1)
  Future<void> _updateToResolved(BillModel bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'ยืนยันการชำระเสร็จสิ้น',
          style: TextStyle(
            color: ThemeColors.oliveGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ต้องการเปลี่ยนสถานะบิล #${bill.billId} เป็น "ชำระเสร็จสิ้น"',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.oliveGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeColors.oliveGreen.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: ThemeColors.oliveGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ชำระเสร็จสิ้น',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ThemeColors.oliveGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'จำเป็นต้องอัปโหลดใบเสร็จเพื่อยืนยันการชำระเงิน',
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.receipt),
            label: const Text('อัปโหลดใบเสร็จ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.oliveGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    // ถ้ายืนยัน → เปิด dialog อัปโหลดใบเสร็จ
    if (confirm == true) {
      await _showReceiptUploadDialog(bill);
    }
  }

  // เปลี่ยนกลับเป็น "PENDING" (สลิปไม่ถูกต้อง)
  Future<void> _updateToPending(BillModel bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ThemeColors.ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'สลิปไม่ถูกต้อง',
          style: TextStyle(
            color: ThemeColors.clayOrange,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'บิล #${bill.billId} จะถูกส่งกลับไปสถานะ "ยังไม่ชำระ" เพื่อให้ลูกบ้านส่งสลิปใหม่',
              style: TextStyle(color: ThemeColors.earthClay),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeColors.clayOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ThemeColors.clayOrange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: ThemeColors.clayOrange),
                  const SizedBox(width: 8),
                  Text(
                    'ส่งกลับเพื่อแก้ไข',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ThemeColors.clayOrange,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeColors.clayOrange,
              foregroundColor: Colors.white,
            ),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateBillStatus(bill, 'PENDING');
    }
  }

  // ฟังก์ชันอัปโหลดรูปใบเสร็จ
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageFile = null;
          });
        } else {
          setState(() {
            _selectedImageFile = File(image.path);
            _selectedImageBytes = null;
          });
        }
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการถ่ายภาพ: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ThemeColors.ivoryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'เลือกรูปภาพ',
            style: TextStyle(
              color: ThemeColors.softBrown,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: ThemeColors.oliveGreen,
                  ),
                ),
                title: Text(
                  'เลือกจากแกลเลอรี่',
                  style: TextStyle(color: ThemeColors.earthClay),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              if (!kIsWeb) // ซ่อนตัวเลือกกล้องใน Web
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ThemeColors.burntOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: ThemeColors.burntOrange,
                    ),
                  ),
                  title: Text(
                    'ถ่ายภาพ',
                    style: TextStyle(color: ThemeColors.earthClay),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFromCamera();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageBytes = null;
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red.shade400),
      );
    }
  }

  Future<void> _showReceiptUploadDialog(BillModel bill) async {
    // รีเซ็ตรูปที่เลือก
    _removeImage();

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
                      'กรุณาอัปโหลดรูปใบเสร็จสำหรับบิล #${bill.billId}',
                      style: TextStyle(color: ThemeColors.earthClay),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'หมายเหตุ: การอัปโหลดใบเสร็จจะอัปเดทสถานะเป็น "ชำระเสร็จสิ้น" โดยอัตโนมัติ',
                      style: TextStyle(
                        color: ThemeColors.earthClay.withOpacity(0.7),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // พื้นที่แสดงรูปที่เลือก
                    GestureDetector(
                      onTap: () => _showImageSourceDialog(),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: ThemeColors.sandyTan.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ThemeColors.warmStone,
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                        ),
                        child: _hasSelectedImage()
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: kIsWeb
                                        ? Image.memory(
                                            _selectedImageBytes!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          )
                                        : Image.file(
                                            _selectedImageFile!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          _removeImage();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                                      color: ThemeColors.earthClay.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),

                    if (_hasSelectedImage()) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ThemeColors.oliveGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ThemeColors.oliveGreen.withOpacity(0.3),
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
                              'เลือกรูปแล้ว - พร้อมอัปโหลดและอัปเดทสถานะ',
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _removeImage();
                    Navigator.pop(context);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: ThemeColors.warmStone,
                  ),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  onPressed: _hasSelectedImage()
                      ? () async {
                          Navigator.pop(context);
                          await _updateBillStatusWithReceiptCompatible(
                            bill,
                            'RECEIPT_SENT',
                          );
                        }
                      : null,
                  icon: Icon(
                    _hasSelectedImage() ? Icons.cloud_upload : Icons.upload,
                    size: 18,
                  ),
                  label: Text(
                    _hasSelectedImage()
                        ? 'ชำระเสร็จสิ้น & ส่งใบเสร็จ'
                        : 'เลือกรูปก่อน',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasSelectedImage()
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

  Future<void> _updateBillStatusWithReceiptCompatible(
    BillModel bill,
    String newStatus,
  ) async {
    setState(() => _isLoading = true);
    try {
      final success = await BillDomain.update(
        billId: bill.billId,
        status: newStatus,
        paidStatus: 1,
        paidDate: DateTime.now().toIso8601String(),
        paidMethod: bill.paidMethod ?? 'โอนเงิน',
        receiptImageFile: kIsWeb ? _selectedImageBytes : _selectedImageFile,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('ส่งใบเสร็จสำเร็จ! สถานะอัปเดทเป็น "ชำระเสร็จสิ้น"'),
              ],
            ),
            backgroundColor: ThemeColors.oliveGreen,
            duration: Duration(seconds: 3),
          ),
        );
        _refreshBill(); // Refresh data
      } else {
        throw Exception('ไม่สามารถอัปเดทสถานะและอัปโหลดใบเสร็จได้');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
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
      if (mounted) {
        setState(() => _isLoading = false);
        _removeImage();
      }
    }
  }

  Future<void> _exportSingleBillAsPdf(BillModel bill) async {
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
                    'Bill #${bill.billId}',
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
              pw.Text('รหัสบิล: ${bill.billId}'),
              pw.Text('บ้านเลขที่: ${houseNumber ?? bill.houseId}'),
              pw.Text('ประเภทบริการ: ${_getServiceNameTh(serviceName)}'),
              pw.Text(
                'จำนวนเงิน: ${NumberFormat('#,##0.00').format(bill.amount)} บาท',
              ),
              pw.Text('สถานะ: ${_getStatusText(bill)}'),
              pw.SizedBox(height: 16),
              pw.Text(
                'ข้อมูลวันที่',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('วันที่ออกบิล: ${_formatDate(bill.billDate)}'),
              pw.Text('วันครบกำหนด: ${_formatDate(bill.dueDate)}'),
              if (bill.paidDate != null)
                pw.Text('วันที่ชำระ: ${_formatDate(bill.paidDate)}'),
              if (bill.slipDate != null)
                pw.Text('วันที่อัพโหลดสลิป: ${_formatDate(bill.slipDate)}'),
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

  Future<void> _confirmDelete(BuildContext context, BillModel bill) async {
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
              'บิล #${bill.billId} - ${NumberFormat('#,##0.00').format(bill.amount)} บาท',
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
        final success = await BillDomain.delete(bill.billId);
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

  Widget _buildImageTab(Map<String, dynamic> tab) {
    final hasImage = tab['imagePath'] != null;

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            tab['icon'],
            size: 16,
            color: hasImage ? null : const Color(0xFFDCDCDC),
          ),
          const SizedBox(width: 6),
          Text(tab['title']),
          if (hasImage) ...[
            const SizedBox(width: 4),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: ThemeColors.oliveGreen,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> tab) {
    if (tab['imagePath'] == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ThemeColors.softBorder, width: 1),
          color: ThemeColors.ivoryWhite,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(tab['icon'], size: 48, color: const Color(0xFFDCDCDC)),
            const SizedBox(height: 12),
            Text(
              tab['emptyMessage'],
              style: const TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tab['description'],
              style: const TextStyle(
                color: ThemeColors.warmStone,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeColors.oliveGreen.withOpacity(0.3),
          width: 1,
        ),
        color: ThemeColors.ivoryWhite,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            BuildImage(
              imagePath: tab['imagePath'],
              tablePath: tab['bucket'],
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _showFullScreenImage(tab),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(Map<String, dynamic> tab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black.withOpacity(0.5),
            foregroundColor: Colors.white,
            title: Text(
              'รูป${tab['title']}',
              style: const TextStyle(color: Colors.white),
            ),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4.0,
              child: BuildImage(
                imagePath: tab['imagePath'],
                tablePath: tab['bucket'],
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeColors.ivoryWhite,
      appBar: AppBar(
        title: Text(
          'บิลเลขที่ ${widget.bill.billId}',
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
            icon: const Icon(Icons.refresh),
            onPressed: _refreshBill,
            tooltip: 'รีเฟรชข้อมูล',
          ),
        ],
      ),
      body: FutureBuilder<BillModel?>(
        future: _billFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: ThemeColors.softBrown),
                  SizedBox(height: 16),
                  Text(
                    'กำลังโหลดข้อมูลบิล...',
                    style: TextStyle(color: ThemeColors.earthClay),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ThemeColors.softTerracotta,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ไม่สามารถโหลดข้อมูลบิลได้',
                    style: TextStyle(
                      fontSize: 16,
                      color: ThemeColors.earthClay,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ThemeColors.burntOrange,
                      foregroundColor: ThemeColors.ivoryWhite,
                    ),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ],
              ),
            );
          }

          final bill = snapshot.data!;
          final bool overdue = _isOverdue(bill);
          final Color stateColor = _getStatusColor(bill);

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== Banner Status =====
                      _buildStatusCard(bill, overdue, stateColor),

                      const SizedBox(height: 16),

                      // ===== บัตรข้อมูลบิล =====
                      _buildBillDetailsCard(bill),

                      const SizedBox(height: 16),

                      // ===== บัตรข้อมูลวันที่ =====
                      _buildDateDetailsCard(bill),

                      const SizedBox(height: 16),

                      // ===== บัตรข้อมูลการชำระ (ถ้ามี) =====
                      if (bill.paidStatus == 1 ||
                          bill.paidDate != null ||
                          bill.paidMethod != null ||
                          bill.referenceNo != null ||
                          bill.slipDate != null) ...[
                        _buildPaymentDetailsCard(bill),
                        const SizedBox(height: 16),
                      ],

                      // ===== รูปภาพที่เกี่ยวข้อง =====
                      _buildImageViewerCard(bill),

                      const SizedBox(height: 24),

                      // ===== ปุ่มตาม Workflow ใหม่ =====
                      _buildWorkflowButtons(bill),

                      const SizedBox(height: 80), // เผื่อ FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ปุ่ม Edit (แสดงเฉพาะสถานะ PENDING)
          FutureBuilder<BillModel?>(
            future: _billFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final bill = snapshot.data!;

              if (!_canEdit(bill.status)) return const SizedBox.shrink();

              return FloatingActionButton(
                heroTag: "edit_fab",
                onPressed: _isLoading
                    ? null
                    : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillEditPage(bill: bill),
                          ),
                        );
                        if (result == true && mounted) {
                          _refreshBill();
                        }
                      },
                backgroundColor: ThemeColors.warmStone,
                foregroundColor: Colors.white,
                child: const Icon(Icons.edit),
              );
            },
          ),

          const SizedBox(width: 16),

          // ปุ่ม Delete
          FloatingActionButton(
            heroTag: "delete_fab",
            onPressed: _isLoading
                ? null
                : () {
                    _billFuture.then((bill) {
                      if (bill != null) _confirmDelete(context, bill);
                    });
                  },
            backgroundColor: Colors.red.shade400,
            foregroundColor: Colors.white,
            child: const Icon(Icons.delete),
          ),

          const SizedBox(width: 16),

          // ปุ่ม Export PDF
          FloatingActionButton.extended(
            heroTag: "pdf_fab",
            onPressed: _isLoading
                ? null
                : () {
                    _billFuture.then((bill) {
                      if (bill != null) _exportSingleBillAsPdf(bill);
                    });
                  },
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(BillModel bill, bool overdue, Color stateColor) {
    return Card(
      color: ThemeColors.beige,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stateColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(bill),
                    color: stateColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'สถานะบิล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: stateColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: stateColor.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                _getStatusText(bill),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: stateColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getStatusDescription(bill),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ThemeColors.earthClay,
                fontSize: 14,
              ),
            ),
            if (overdue) ...[
              const SizedBox(height: 8),
              Text(
                'เกินกำหนด ${_getDaysUntilDue(bill).abs()} วัน',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (bill.paidStatus == 0) ...[
              const SizedBox(height: 8),
              Text(
                'เหลืออีก ${_getDaysUntilDue(bill)} วัน',
                style: const TextStyle(
                  color: ThemeColors.softTerracotta,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBillDetailsCard(BillModel bill) {
    return Card(
      color: ThemeColors.inputFill,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.softBrown.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long,
                    color: ThemeColors.softBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'รายละเอียดบิล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('เลขที่บิล', bill.billId.toString()),
            _buildDetailRow(
              'บ้านเลขที่',
              houseNumber ?? bill.houseId.toString(),
            ),
            _buildDetailRow('ประเภทบริการ', _getServiceNameTh(serviceName)),
            const Divider(color: ThemeColors.sandyTan),
            _buildDetailRow(
              'จำนวนเงิน',
              '฿${bill.amount.toStringAsFixed(2)}',
              isAmount: true,
            ),
            _buildDetailRow(
              'สถานะการจ่าย',
              bill.paidStatus == 1 ? 'จ่ายแล้ว' : 'ยังไม่จ่าย',
              statusColor: bill.paidStatus == 1
                  ? ThemeColors.oliveGreen
                  : ThemeColors.burntOrange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDetailsCard(BillModel bill) {
    return Card(
      color: ThemeColors.inputFill,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.burntOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: ThemeColors.burntOrange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ข้อมูลวันที่',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('วันที่ออกบิล', _formatDate(bill.billDate)),
            _buildDetailRow('วันครบกำหนด', _formatDate(bill.dueDate)),
            if (bill.paidDate != null)
              _buildDetailRow('วันที่ชำระ', _formatDate(bill.paidDate)),
            if (bill.slipDate != null)
              _buildDetailRow('วันที่อัพโหลดสลิป', _formatDate(bill.slipDate)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard(BillModel bill) {
    return Card(
      color: ThemeColors.inputFill,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.oliveGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.payment,
                    color: ThemeColors.oliveGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ข้อมูลการชำระเงิน',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bill.slipDate != null)
              _buildDetailRow(
                'วันที่-เวลาโอนเงิน',
                _formatDateTime(bill.slipDate!),
              ),
            if (bill.paidDate != null)
              _buildDetailRow('วันที่จ่าย', _formatDate(bill.paidDate!)),
            if (bill.paidMethod != null)
              _buildDetailRow('วิธีการจ่าย', bill.paidMethod!),
            if (bill.referenceNo != null)
              _buildDetailRow('เลขที่อ้างอิง', bill.referenceNo!),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewerCard(BillModel bill) {
    final hasAnyImage = _imageTabs.any((tab) => tab['imagePath'] != null);

    return Card(
      color: ThemeColors.inputFill,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ThemeColors.warmStone.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: ThemeColors.warmStone,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'รูปภาพที่เกี่ยวข้อง',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: ThemeColors.softBrown,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (!hasAnyImage) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ThemeColors.softBorder, width: 1),
                  color: ThemeColors.beige,
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      color: ThemeColors.earthClay,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'ยังไม่มีรูปภาพที่เกี่ยวข้อง',
                      style: TextStyle(
                        color: ThemeColors.earthClay,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  color: ThemeColors.beige,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ThemeColors.sandyTan, width: 1),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: ThemeColors.softBrown,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  indicatorPadding: const EdgeInsets.all(3),
                  dividerColor: Colors.transparent,
                  labelColor: ThemeColors.ivoryWhite,
                  unselectedLabelColor: ThemeColors.earthClay,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                  ),
                  tabs: _imageTabs.map((tab) => _buildImageTab(tab)).toList(),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 250,
                child: TabBarView(
                  controller: _tabController,
                  children: _imageTabs
                      .map((tab) => _buildTabContent(tab))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isAmount = false,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: ThemeColors.earthClay,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
                color: statusColor ?? ThemeColors.softBrown,
                fontSize: isAmount ? 16 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
