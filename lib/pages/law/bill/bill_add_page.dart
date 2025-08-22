import 'package:flutter/material.dart';
import 'package:fullproject/models/bill_model.dart';
import 'package:fullproject/config/supabase_config.dart';
import 'package:fullproject/services/auth_service.dart';
import 'package:fullproject/domains/bill_domain.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BillAddPage extends StatefulWidget {
  const BillAddPage({super.key});

  @override
  State<BillAddPage> createState() => _BillAddPageState();
}

class _BillAddPageState extends State<BillAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  DateTime? _dueDate;
  int? _selectedHouseId;
  int? _selectedServiceId;

  // Image files
  File? _billImageFile;
  File? _slipImageFile;
  File? _receiptImageFile;

  List<Map<String, dynamic>> _houses = [];
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = false;

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
  static const Color mutedBurntSienna = Color(0xFFC8755A);
  static const Color disabledGrey = Color(0xFFDCDCDC);

  // แมปประเภทบริการให้เป็นภาษาไทย
  final Map<String, String> _serviceTranslations = {
    'Area Fee': 'ค่าพื้นที่ส่วนกลาง',
    'Trash Fee': 'ค่าขยะ',
    'water Fee': 'ค่าน้ำ',
    'Water Fee': 'ค่าน้ำ',
    'enegy Fee': 'ค่าไฟ',
    'Energy Fee': 'ค่าไฟ',
    'Electricity Fee': 'ค่าไฟ',
  };

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);

    try {
      final law = await AuthService.getCurrentUser();

      final results = await Future.wait([
        SupabaseConfig.client
            .from('house')
            .select('house_id, house_number')
            .eq('village_id', law.villageId),
        SupabaseConfig.client
            .from('service')
            .select('service_id, name'),
      ]);

      setState(() {
        _houses = List<Map<String, dynamic>>.from(results[0]);
        _services = List<Map<String, dynamic>>.from(results[1]);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showErrorSnackBar('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e');
      }
    }
  }

  String _getServiceNameTh(String? englishName) {
    return _serviceTranslations[englishName] ?? englishName ?? 'ไม่ระบุ';
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

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: softTerracotta,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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

      if (pickedFile != null) {
        setState(() {
          switch (type) {
            case ImageType.bill:
              _billImageFile = File(pickedFile.path);
              break;
            case ImageType.slip:
              _slipImageFile = File(pickedFile.path);
              break;
            case ImageType.receipt:
              _receiptImageFile = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการเลือกรูปภาพ: $e');
    }
  }

  Future<void> _showImageSourceDialog(ImageType type) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ivoryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'เลือกแหล่งรูปภาพ',
          style: TextStyle(color: softBrown, fontWeight: FontWeight.bold),
        ),
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

  Future<void> _pickImageFromCamera(ImageType type) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          switch (type) {
            case ImageType.bill:
              _billImageFile = File(pickedFile.path);
              break;
            case ImageType.slip:
              _slipImageFile = File(pickedFile.path);
              break;
            case ImageType.receipt:
              _receiptImageFile = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาดในการถ่ายรูป: $e');
    }
  }

  Widget _buildImagePicker({
    required String title,
    required IconData icon,
    required File? imageFile,
    required VoidCallback onTap,
    required VoidCallback? onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (imageFile != null) ...[
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
                    child: Image.file(
                      imageFile,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
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
              ),
            ),
            const SizedBox(height: 12),
          ],
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: Icon(
                  imageFile != null ? Icons.edit : Icons.add_a_photo,
                  size: 18,
                ),
                label: Text(
                  imageFile != null ? 'เปลี่ยนรูป' : 'เลือกรูป',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: imageFile != null ? warmStone : burntOrange,
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
        _selectedServiceId == null) {
      _showWarningSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await BillDomain.create(
        houseId: _selectedHouseId!,
        billDate: DateTime.now().toIso8601String(),
        amount: double.parse(_amountController.text),
        service: _selectedServiceId!,
        dueDate: _dueDate!.toIso8601String(),
        referenceNo: _referenceController.text.isNotEmpty
            ? _referenceController.text
            : 'REF${DateTime.now().millisecondsSinceEpoch}',
        status: 'PENDING',
        billImageFile: _billImageFile,
        paidImageFile: _slipImageFile,
        receiptImageFile: _receiptImageFile,
      );

      if (result != null) {
        _showSuccessSnackBar('เพิ่มบิลสำเร็จ');
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('ไม่สามารถเพิ่มบิลได้');
      }
    } catch (e) {
      _showErrorSnackBar('เกิดข้อผิดพลาด: เพิ่มบิลไม่สำเร็จ\n${e.toString()}');
      debugPrint('Error creating bill: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  child: Icon(
                    icon,
                    color: iconColor ?? softBrown,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    return Scaffold(
      backgroundColor: sandyTan,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: softBrown,
        foregroundColor: Colors.white,
        title: const Text(
          'เพิ่มค่าส่วนกลาง',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      body: _isLoading && (_houses.isEmpty || _services.isEmpty)
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(softBrown),
            ),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูล...',
              style: TextStyle(color: earthClay),
            ),
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
            boxShadow: [
              BoxShadow(
                color: earthClay.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: softTerracotta.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.warning_amber_outlined,
                  color: softTerracotta,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ไม่พบข้อมูล',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: softTerracotta,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'ไม่พบข้อมูลบ้านหรือประเภทบริการ',
                textAlign: TextAlign.center,
                style: TextStyle(color: earthClay),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _fetchInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: burntOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // การ์ดเลือกบ้าน
              _buildFormCard(
                title: 'เลือกบ้านเลขที่',
                icon: Icons.home_rounded,
                iconColor: softBrown,
                child: Container(
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: softBorder),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _houses.any((h) => h['house_id'] == _selectedHouseId)
                        ? _selectedHouseId
                        : null,
                    items: _houses.map((house) {
                      return DropdownMenuItem<int>(
                        value: house['house_id'],
                        child: Text('บ้านเลขที่ ${house['house_number']}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedHouseId = val),
                    decoration: InputDecoration(
                      hintText: 'เลือกบ้านเลขที่',
                      hintStyle: const TextStyle(color: earthClay),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (value) =>
                    value == null ? 'กรุณาเลือกบ้าน' : null,
                  ),
                ),
              ),

              // การ์ดเลือกประเภทบริการ
              _buildFormCard(
                title: 'เลือกประเภทบริการ',
                icon: Icons.receipt_long_rounded,
                iconColor: warmStone,
                child: Container(
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: softBorder),
                  ),
                  child: DropdownButtonFormField<int>(
                    value: _selectedServiceId,
                    items: _services.map((service) {
                      return DropdownMenuItem<int>(
                        value: service['service_id'],
                        child: Text(_getServiceNameTh(service['name'])),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedServiceId = val),
                    decoration: InputDecoration(
                      hintText: 'เลือกประเภทบริการ',
                      hintStyle: const TextStyle(color: earthClay),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (value) =>
                    value == null ? 'กรุณาเลือกประเภทบริการ' : null,
                  ),
                ),
              ),

              // การ์ดกรอกจำนวนเงิน
              _buildFormCard(
                title: 'จำนวนเงิน',
                icon: Icons.attach_money_rounded,
                iconColor: oliveGreen,
                child: Container(
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: softBorder),
                  ),
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'กรอกจำนวนเงิน',
                      hintStyle: const TextStyle(color: earthClay),
                      suffixText: 'บาท',
                      suffixStyle: const TextStyle(
                        color: oliveGreen,
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'กรุณากรอกจำนวนเงิน';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'กรุณากรอกจำนวนเงินที่ถูกต้อง';
                      }
                      return null;
                    },
                  ),
                ),
              ),

              // การ์ดเลขอ้างอิง (Optional)
              _buildFormCard(
                title: 'เลขอ้างอิง (ไม่บังคับ)',
                icon: Icons.confirmation_number_rounded,
                iconColor: mutedBurntSienna,
                child: Container(
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: softBorder),
                  ),
                  child: TextFormField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      hintText: 'กรอกเลขอ้างอิง (หากมี)',
                      hintStyle: const TextStyle(color: earthClay),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),

              // การ์ดเลือกวันครบกำหนด
              _buildFormCard(
                title: 'วันครบกำหนดชำระ',
                icon: Icons.calendar_today_rounded,
                iconColor: mutedBurntSienna,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: softBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dueDate == null
                                  ? 'ยังไม่ได้เลือกวันที่'
                                  : DateFormat('EEEE ที่ dd MMMM yyyy', 'th')
                                  .format(_dueDate!),
                              style: TextStyle(
                                color: _dueDate == null ? clayOrange : Colors.black87,
                                fontSize: 16,
                                fontWeight: _dueDate == null
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                            if (_dueDate != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'อีก ${_dueDate!.difference(DateTime.now()).inDays} วัน',
                                style: const TextStyle(
                                  color: earthClay,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _dueDate ??
                                DateTime.now().add(const Duration(days: 30)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: softBrown,
                                    onPrimary: Colors.white,
                                    surface: sandyTan,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() => _dueDate = picked);
                          }
                        },
                        icon: const Icon(Icons.event_rounded, size: 18),
                        label: Text(_dueDate == null ? 'เลือกวันที่' : 'เปลี่ยน'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: burntOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // การ์ดอัปโหลดรูปภาพ
              _buildFormCard(
                title: 'รูปภาพประกอบ',
                icon: Icons.photo_library_rounded,
                iconColor: warmStone,
                child: Column(
                  children: [
                    // รูปบิล
                    _buildImagePicker(
                      title: 'รูปบิล',
                      icon: Icons.receipt_long,
                      imageFile: _billImageFile,
                      onTap: () => _showImageSourceDialog(ImageType.bill),
                      onRemove: () => setState(() => _billImageFile = null),
                    ),
                    const SizedBox(height: 16),

                    // รูปสลิปการโอน
                    _buildImagePicker(
                      title: 'สลิปการโอน (ถ้ามี)',
                      icon: Icons.payment,
                      imageFile: _slipImageFile,
                      onTap: () => _showImageSourceDialog(ImageType.slip),
                      onRemove: () => setState(() => _slipImageFile = null),
                    ),
                    const SizedBox(height: 16),

                    // รูปใบเสร็จ
                    _buildImagePicker(
                      title: 'ใบเสร็จ (ถ้ามี)',
                      icon: Icons.receipt,
                      imageFile: _receiptImageFile,
                      onTap: () => _showImageSourceDialog(ImageType.receipt),
                      onRemove: () => setState(() => _receiptImageFile = null),
                    ),
                  ],
                ),
              ),

              // ปุ่มเพิ่มรายการ
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: burntOrange.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Icon(Icons.add_rounded, size: 24),
                  label: Text(
                    _isLoading ? 'กำลังเพิ่มรายการ...' : 'เพิ่มรายการ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: burntOrange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: disabledGrey,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}

enum ImageType {
  bill,
  slip,
  receipt,
}