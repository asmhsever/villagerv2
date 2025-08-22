import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class BillEditPage extends StatefulWidget {
  final BillModel bill;

  const BillEditPage({super.key, required this.bill});

  @override
  State<BillEditPage> createState() => _BillEditPageState();
}

// ใช้กับตัวเลือกอัปโหลดรูป
enum ImageType { bill, slip, receipt }

class _BillEditPageState extends State<BillEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  DateTime? _dueDate;
  int? _selectedHouseId;
  int? _selectedServiceId;
  String? _selectedStatus;

  // ภาพใหม่ที่เลือก (ถ้าไม่เลือกจะเป็น null และระบบจะคงรูปเดิมไว้)
  File? _billImageFile;
  File? _slipImageFile;
  File? _receiptImageFile;

  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = false;
  bool _isInitialLoading = true;

  final ImagePicker _picker = ImagePicker();

  // 🎨 Warm Natural Color Scheme
  static const Color softBrown = Color(0xFFA47551);
  static const Color ivoryWhite = Color(0xFFFFFDF6);
  static const Color sandyTan = Color(0xFFD8CAB8);
  static const Color earthClay = Color(0xFFBFA18F);
  static const Color warmStone = Color(0xFFC7B9A5);
  static const Color oliveGreen = Color(0xFFA3B18A);
  static const Color burntOrange = Color(0xFFE08E45);
  static const Color softBorder = Color(0xFFD0C4B0);
  static const Color inputFill = Color(0xFFFBF9F3);
  static const Color softTerracotta = Color(0xFFD48B5C);
  static const Color clayOrange = Color(0xFFCC7748);

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

  final List<Map<String, String>> _statusOptions = const [
    {'value': 'DRAFT', 'label': 'แบบร่าง'},
    {'value': 'PENDING', 'label': 'รอชำระ'},
    {'value': 'UNDER_REVIEW', 'label': 'กำลังตรวจสอบ'},
    {'value': 'RECEIPT_SENT', 'label': 'ส่งใบเสร็จแล้ว'},
    {'value': 'REJECTED', 'label': 'ถูกปฏิเสธ'},
    {'value': 'OVERDUE', 'label': 'เกินกำหนด'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    _amountController.text = widget.bill.amount.toString();
    _referenceController.text = widget.bill.referenceNo ?? '';
    _dueDate = widget.bill.dueDate;
    _selectedHouseId = widget.bill.houseId;
    _selectedServiceId = widget.bill.service;
    _selectedStatus = widget.bill.status;
    await _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isInitialLoading = true);
    try {
      final law = await AuthService.getCurrentUser();
      final results = await Future.wait([
        SupabaseConfig.client
            .from('house')
            .select('house_id, house_number')
            .eq('village_id', law.villageId)
            .order('house_number'),
        SupabaseConfig.client
            .from('service')
            .select('service_id, name')
            .order('service_id'),
      ]);

      setState(() {
        _houses = List<Map<String, dynamic>>.from(results[0]);
        _services = List<Map<String, dynamic>>.from(results[1]);
        _isInitialLoading = false;
      });
    } catch (e) {
      setState(() => _isInitialLoading = false);
      if (mounted) _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
    }
  }

  String _getServiceNameTh(String? englishName) =>
      _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุ';

  // แปลงสถานะเป็นข้อความไทย (ใช้โชว์ “สถานะเดิม”)
  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'DRAFT':
        return 'แบบร่าง';
      case 'PENDING':
        return 'รอชำระ';
      case 'UNDER_REVIEW':
        return 'กำลังตรวจสอบ';
      case 'RECEIPT_SENT':
        return 'ส่งใบเสร็จแล้ว';
      case 'REJECTED':
        return 'ถูกปฏิเสธ';
      case 'OVERDUE':
        return 'เกินกำหนด';
      default:
        return status;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: clayOrange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: oliveGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickImage(ImageType type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (pickedFile == null) return;

      setState(() {
        final file = File(pickedFile.path);
        if (type == ImageType.bill) _billImageFile = file;
        if (type == ImageType.slip) _slipImageFile = file;
        if (type == ImageType.receipt) _receiptImageFile = file;
      });
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _pickImageFromCamera(ImageType type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      if (pickedFile == null) return;

      setState(() {
        final file = File(pickedFile.path);
        if (type == ImageType.bill) _billImageFile = file;
        if (type == ImageType.slip) _slipImageFile = file;
        if (type == ImageType.receipt) _receiptImageFile = file;
      });
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการถ่ายรูป: $e');
    }
  }

  Future<void> _showImageSourceDialog(ImageType type) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('เลือกแหล่งรูปภาพ',
            style: TextStyle(color: softBrown, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: burntOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: burntOrange),
              ),
              title: const Text('ถ่ายรูป'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFromCamera(type);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: oliveGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: oliveGreen),
              ),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(type);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection({
    required String title,
    required IconData icon,
    required String? currentImageUrl,
    required File? newImageFile,
    required VoidCallback onPickImage,
    required VoidCallback onRemoveNew,
    VoidCallback? onRemoveCurrent, // ถ้าไม่รองรับการลบรูปเดิม ให้ส่ง null
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // หัวข้อ
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: warmStone, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: earthClay,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // รูปเดิม (เมื่อยังไม่เลือกไฟล์ใหม่)
          if (currentImageUrl != null &&
              currentImageUrl.isNotEmpty &&
              newImageFile == null) ...[
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: softBorder),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      currentImageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: sandyTan,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 32, color: earthClay),
                            Text('ไม่สามารถโหลดรูปได้',
                                style:
                                TextStyle(color: earthClay, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (onRemoveCurrent != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onRemoveCurrent,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // รูปใหม่
          if (newImageFile != null) ...[
            Container(
              height: 120,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: burntOrange, width: 2),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      newImageFile,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemoveNew,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ปุ่มเลือก/เปลี่ยนรูป
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onPickImage,
                icon: Icon(
                  newImageFile != null ||
                      (currentImageUrl != null && currentImageUrl.isNotEmpty)
                      ? Icons.edit
                      : Icons.add_a_photo,
                  size: 18,
                ),
                label: Text(
                  newImageFile != null
                      ? 'เปลี่ยนรูปใหม่'
                      : ((currentImageUrl != null &&
                      currentImageUrl.isNotEmpty)
                      ? 'เปลี่ยนรูป'
                      : 'เลือกรูป'),
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burntOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _dueDate == null ||
        _selectedHouseId == null ||
        _selectedServiceId == null ||
        _selectedStatus == null) {
      _showErrorSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await BillDomain.update(
        billId: widget.bill.billId,
        houseId: _selectedHouseId,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate!.toIso8601String(),
        service: _selectedServiceId,
        referenceNo: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : null,
        status: _selectedStatus,
        billImageFile: _billImageFile,
        slipImageFile: _slipImageFile,
        receiptImageFile: _receiptImageFile,
      );

      if (success) {
        _showSuccessSnackBar('อัพเดทบิลสำเร็จ');
        if (mounted) Navigator.pop(context, true);
      } else {
        throw Exception('ไม่สามารถอัพเดทบิลได้');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: อัพเดทบิลไม่สำเร็จ\n$e');
      debugPrint('Error updating bill: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmCancel() async {
    final hasChanges = _hasUnsavedChanges();
    if (!hasChanges) {
      Navigator.pop(context);
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('ยกเลิกการแก้ไข',
            style: TextStyle(color: softBrown, fontWeight: FontWeight.bold)),
        content: const Text('คุณมีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก\nต้องการออกจากหน้านี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: warmStone),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: clayOrange, foregroundColor: Colors.white),
            child: const Text('ออกจากหน้านี้'),
          ),
        ],
      ),
    );

    if (shouldLeave == true && mounted) Navigator.pop(context);
  }

  bool _hasUnsavedChanges() {
    return _amountController.text != widget.bill.amount.toString() ||
        _dueDate != widget.bill.dueDate ||
        _selectedHouseId != widget.bill.houseId ||
        _selectedServiceId != widget.bill.service ||
        _selectedStatus != widget.bill.status ||
        _referenceController.text.trim() !=
            (widget.bill.referenceNo ?? '').trim() ||
        _billImageFile != null ||
        _slipImageFile != null ||
        _receiptImageFile != null;
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: ivoryWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: softBorder),
        boxShadow: [
          BoxShadow(
            color: earthClay.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
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
                    color: (iconColor ?? softBrown).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor ?? softBrown, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ข้อมูล',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges()) await _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: sandyTan,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: softBrown,
          foregroundColor: Colors.white,
          title: Text(
            'แก้ไขบิล #${widget.bill.billId}',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _confirmCancel,
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            if (_hasUnsavedChanges())
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'รีเซ็ตการเปลี่ยนแปลง',
                onPressed: () {
                  setState(() {
                    _amountController.text = widget.bill.amount.toString();
                    _referenceController.text = widget.bill.referenceNo ?? '';
                    _dueDate = widget.bill.dueDate;
                    _selectedHouseId = widget.bill.houseId;
                    _selectedServiceId = widget.bill.service;
                    _selectedStatus = widget.bill.status;
                    _billImageFile = null;
                    _slipImageFile = null;
                    _receiptImageFile = null;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
        body: _isInitialLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(softBrown),
              ),
              SizedBox(height: 16),
              Text('กำลังโหลดข้อมูล...', style: TextStyle(color: earthClay)),
            ],
          ),
        )
            : _houses.isEmpty || _services.isEmpty
            ? Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ivoryWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: softBorder),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_outlined,
                    color: softTerracotta, size: 48),
                SizedBox(height: 16),
                Text('ไม่พบข้อมูล',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: softTerracotta)),
                SizedBox(height: 8),
                Text('ไม่พบข้อมูลบ้านหรือประเภทบริการ',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: earthClay)),
              ],
            ),
          ),
        )
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // กล่องแสดงข้อมูลเดิม
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: oliveGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: oliveGreen.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: oliveGreen, size: 20),
                          const SizedBox(width: 8),
                          Text('ข้อมูลบิลเดิม',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: oliveGreen)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('รหัสบิล: ${widget.bill.billId}'),
                      Text(
                          'จำนวนเงินเดิม: ${NumberFormat('#,##0.00').format(widget.bill.amount)} บาท'),
                      Text(
                          'วันครบกำหนดเดิม: ${DateFormat('dd/MM/yyyy').format(widget.bill.dueDate)}'),
                      Text('สถานะเดิม: ${_getStatusText(widget.bill.status)}'),
                      if (widget.bill.referenceNo?.isNotEmpty ?? false)
                        Text('เลขอ้างอิงเดิม: ${widget.bill.referenceNo}'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // เลือกบ้าน
                _buildFormCard(
                  title: 'เลือกบ้านเลขที่',
                  icon: Icons.home_rounded,
                  iconColor: softBrown,
                  child: DropdownButtonFormField<int>(
                    value: _selectedHouseId,
                    isExpanded: true,
                    items: _houses
                        .map(
                          (h) => DropdownMenuItem<int>(
                        value: h['house_id'] as int,
                        child: Text(
                          '${h['house_number']} (ID: ${h['house_id']})',
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedHouseId = v;
                    }),
                    validator: (v) =>
                    v == null ? 'กรุณาเลือกบ้านเลขที่' : null,
                    decoration: _inputDecoration('บ้านเลขที่'),
                    dropdownColor: ivoryWhite,
                  ),
                ),

                // เลือกประเภทบริการ
                _buildFormCard(
                  title: 'ประเภทบริการ',
                  icon: Icons.category_rounded,
                  iconColor: softBrown,
                  child: DropdownButtonFormField<int>(
                    value: _selectedServiceId,
                    isExpanded: true,
                    items: _services
                        .map(
                          (s) => DropdownMenuItem<int>(
                        value: s['service_id'] as int,
                        child: Text(
                          _getServiceNameTh(s['name'] as String),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selectedServiceId = v;
                    }),
                    validator: (v) =>
                    v == null ? 'กรุณาเลือกประเภทบริการ' : null,
                    decoration: _inputDecoration('ประเภทบริการ'),
                    dropdownColor: ivoryWhite,
                  ),
                ),

                // จำนวนเงิน
                _buildFormCard(
                  title: 'จำนวนเงิน',
                  icon: Icons.payments_rounded,
                  iconColor: softBrown,
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDecoration('จำนวนเงิน (บาท)'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'กรุณากรอกจำนวนเงิน';
                      }
                      final d = double.tryParse(v);
                      if (d == null || d <= 0) {
                        return 'จำนวนเงินไม่ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                ),

                // วันครบกำหนด
                _buildFormCard(
                  title: 'วันครบกำหนด',
                  icon: Icons.event_rounded,
                  iconColor: softBrown,
                  child: InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (picked != null) {
                        setState(() => _dueDate = DateTime(
                            picked.year, picked.month, picked.day));
                      }
                    },
                    child: InputDecorator(
                      decoration: _inputDecoration('วันครบกำหนด'),
                      child: Text(
                        _dueDate == null
                            ? 'แตะเพื่อเลือกวันที่'
                            : DateFormat('dd/MM/yyyy')
                            .format(_dueDate!),
                      ),
                    ),
                  ),
                ),

                // สถานะบิล
                _buildFormCard(
                  title: 'สถานะบิล',
                  icon: Icons.flag_rounded,
                  iconColor: softBrown,
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    isExpanded: true,
                    items: _statusOptions
                        .map(
                          (m) => DropdownMenuItem<String>(
                        value: m['value'],
                        child: Text(m['label']!),
                      ),
                    )
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedStatus = v),
                    validator: (v) =>
                    v == null ? 'กรุณาเลือกสถานะ' : null,
                    decoration: _inputDecoration('สถานะ'),
                    dropdownColor: ivoryWhite,
                  ),
                ),

                // เลขอ้างอิง
                _buildFormCard(
                  title: 'เลขอ้างอิง (ไม่บังคับ)',
                  icon: Icons.numbers_rounded,
                  iconColor: softBrown,
                  child: TextFormField(
                    controller: _referenceController,
                    decoration: _inputDecoration('เลขอ้างอิง'),
                  ),
                ),

                // ส่วนรูปภาพ
                _buildFormCard(
                  title: 'รูปบิล',
                  icon: Icons.receipt_long,
                  iconColor: softBrown,
                  child: _buildImageSection(
                    title: 'รูปบิล',
                    icon: Icons.receipt_long,
                    currentImageUrl: widget.bill.billImg,
                    newImageFile: _billImageFile,
                    onPickImage: () =>
                        _showImageSourceDialog(ImageType.bill),
                    onRemoveNew: () =>
                        setState(() => _billImageFile = null),
                    onRemoveCurrent: null,
                  ),
                ),
                _buildFormCard(
                  title: 'สลิปการโอน',
                  icon: Icons.payment,
                  iconColor: softBrown,
                  child: _buildImageSection(
                    title: 'สลิปการโอน',
                    icon: Icons.payment,
                    currentImageUrl: widget.bill.slipImg,
                    newImageFile: _slipImageFile,
                    onPickImage: () =>
                        _showImageSourceDialog(ImageType.slip),
                    onRemoveNew: () =>
                        setState(() => _slipImageFile = null),
                    onRemoveCurrent: null,
                  ),
                ),
                _buildFormCard(
                  title: 'ใบเสร็จ',
                  icon: Icons.receipt,
                  iconColor: softBrown,
                  child: _buildImageSection(
                    title: 'ใบเสร็จการชำระเงิน',
                    icon: Icons.receipt,
                    currentImageUrl: widget.bill.receiptImg,
                    newImageFile: _receiptImageFile,
                    onPickImage: () =>
                        _showImageSourceDialog(ImageType.receipt),
                    onRemoveNew: () =>
                        setState(() => _receiptImageFile = null),
                    onRemoveCurrent: null,
                  ),
                ),

                const SizedBox(height: 12),

                // ปุ่มบันทึก
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.save_rounded),
                    label: Text(_isLoading ? 'กำลังบันทึก...' : 'บันทึกการแก้ไข'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: softBrown,
                      foregroundColor: Colors.white,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: softBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: softBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: softBrown),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
